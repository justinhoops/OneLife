import Foundation
import os

enum LifeLoadResult {
    case loaded(LifeState)
    case freshStart(message: String?)
}

protocol LifePersisting: AnyObject, Sendable {
    var automaticallyPersistsCommits: Bool { get }
    func save(_ state: LifeState) -> Result<Void, Error>
    func clear()
}

extension LifePersisting {
    var automaticallyPersistsCommits: Bool { true }
}

/// Immutable configuration makes a persistence instance safe to use from the
/// simulator's serial background save queue.
final class LifePersistence: LifePersisting, @unchecked Sendable {
    private static let performanceLog = OSLog(
        subsystem: "LifeApp.OneLife",
        category: .pointsOfInterest
    )
    private let fileManager: FileManager
    private let url: URL?
    private let legacyURLs: [URL]

    init(fileManager: FileManager = .default, saveURL: URL? = nil, legacySaveURL: URL? = nil) {
        self.fileManager = fileManager
        if let saveURL {
            url = saveURL
            if let legacySaveURL {
                legacyURLs = [legacySaveURL]
            } else {
                legacyURLs = []
            }
        } else {
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            url = documents?.appendingPathComponent("onelife-v3.json")
            legacyURLs = [
                documents?.appendingPathComponent("onelife-v2.json"),
                documents?.appendingPathComponent("onelife-v1.json")
            ].compactMap { $0 }
        }
    }

    func load() -> LifeLoadResult {
        let signpostID = OSSignpostID(log: Self.performanceLog)
        os_signpost(.begin, log: Self.performanceLog, name: "Save Load", signpostID: signpostID)
        defer {
            os_signpost(.end, log: Self.performanceLog, name: "Save Load", signpostID: signpostID)
        }
        guard let url else {
            return .freshStart(message: "Save location unavailable. You can still start a new life.")
        }

        if fileManager.fileExists(atPath: url.path) {
            return decode(at: url, allowMigrate: true)
        }

        // Prefer newer legacy first
        for legacy in legacyURLs where fileManager.fileExists(atPath: legacy.path) {
            if legacy.lastPathComponent == "onelife-v1.json" {
                return .freshStart(message: "Your earlier life was kept safe. This update needs a fresh life for the new relationship system.")
            }
            let result = decode(at: legacy, allowMigrate: true)
            if case .loaded(let state) = result {
                // Promote to current path without destroying legacy until save succeeds
                if case .success = save(state) {
                    return .loaded(state)
                }
                return .loaded(state)
            }
            return .freshStart(message: "Your earlier life was kept safe. This update needs a fresh life for the new core systems.")
        }

        return .freshStart(message: nil)
    }

    @discardableResult
    func save(_ state: LifeState) -> Result<Void, Error> {
        let signpostID = OSSignpostID(log: Self.performanceLog)
        os_signpost(.begin, log: Self.performanceLog, name: "Background Save", signpostID: signpostID)
        defer {
            os_signpost(.end, log: Self.performanceLog, name: "Background Save", signpostID: signpostID)
        }
        guard let url else { return .failure(CocoaError(.fileNoSuchFile)) }
        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            var stamped = state
            stamped.saveVersion = LifeState.currentSaveVersion
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(stamped)
            // Atomic write via temp + replace
            let temp = url.appendingPathExtension("tmp")
            try data.write(to: temp, options: .atomic)
            if fileManager.fileExists(atPath: url.path) {
                _ = try fileManager.replaceItemAt(url, withItemAt: temp)
            } else {
                try fileManager.moveItem(at: temp, to: url)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func clear() {
        guard let url else { return }
        try? fileManager.removeItem(at: url)
        try? fileManager.removeItem(at: url.appendingPathExtension("tmp"))
        for legacy in legacyURLs {
            try? fileManager.removeItem(at: legacy)
        }
    }

    func saveNow(_ state: LifeState) -> String {
        switch save(state) {
        case .success: return "Saved life at age \(state.character.age)."
        case .failure: return "Could not save this life."
        }
    }

    private func decode(at fileURL: URL, allowMigrate: Bool) -> LifeLoadResult {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let state = try decoder.decode(LifeState.self, from: data)
            guard state.isValidSave else {
                preserveRejectedSave(at: fileURL)
                return .freshStart(message: "This save is incomplete. It was kept safe; start fresh when ready.")
            }
            if state.saveVersion == LifeState.currentSaveVersion {
                return .loaded(state)
            }
            if allowMigrate, state.saveVersion < LifeState.currentSaveVersion {
                let backup = fileURL.appendingPathExtension("before-economy-v33")
                if state.saveVersion < 33 && !fileManager.fileExists(atPath: backup.path) {
                    try fileManager.copyItem(at: fileURL, to: backup)
                }
                guard let migrated = migrate(state) else {
                    preserveRejectedSave(at: fileURL)
                    return .freshStart(message: "This save needs a newer app or is incomplete. It was kept safe; start fresh when ready.")
                }
                return .loaded(migrated)
            }
            preserveRejectedSave(at: fileURL)
            return .freshStart(message: "This save needs a newer app. It was kept safe; start fresh when ready.")
        } catch {
            preserveRejectedSave(at: fileURL)
            return .freshStart(message: "We could not read the existing save. It was not overwritten; you can start fresh.")
        }
    }

    /// A fresh run will eventually replace the primary save path. Keep one
    /// immutable sibling copy first so "kept safe" remains true after play resumes.
    /// Legacy saves already live at a separate path and do not need duplication.
    private func preserveRejectedSave(at fileURL: URL) {
        guard fileURL == url else { return }
        let preservedURL = fileURL.appendingPathExtension("preserved")
        guard !fileManager.fileExists(atPath: preservedURL.path) else { return }
        try? fileManager.copyItem(at: fileURL, to: preservedURL)
    }

    /// Decode defaults make old JSON structurally readable; this step owns the
    /// version-to-version invariants so schema evolution remains explicit.
    private func migrate(_ decoded: LifeState) -> LifeState? {
        guard decoded.saveVersion > 0, decoded.saveVersion < LifeState.currentSaveVersion else { return nil }
        var migrated = decoded

        switch decoded.saveVersion {
        case ...3:
            // v3 predates lightweight NPC persistence. Decode defaults provide
            // an empty directory; do not eagerly resolve people during load.
            var npcs = migrated.npcs
            npcs.pruneInactiveBackground(in: migrated)
            migrated.npcs = npcs
            fallthrough
        case 4:
            // v4 predates immutable run identity. LifeState decoding preserves
            // deterministic continuation by deriving it from the saved RNG.
            fallthrough
        case 5:
            // v5 predates anti-repeat memory.
            migrated.recentEventIDs = Array(migrated.recentEventIDs.prefix(6))
            fallthrough
        case 6:
            // v7 introduces canonical CareerState from the decoded legacy job.
            migrated.career.clamp()
            fallthrough
        case 7:
            // v8 household finance defaults are intentionally debt-free renting.
            migrated.finance.clamp()
            fallthrough
        case 8:
            // v9 preserves the existing partner and begins with no fabricated children.
            migrated.family.clamp()
            fallthrough
        case 9:
            // v10 decoder maps the displayed legacy health into both wellbeing axes.
            migrated.health.clamp()
            fallthrough
        case 10:
            // v11 identity defaults are neutral and old lives gain no retroactive bonus.
            migrated.lifeThreads = Array(migrated.lifeThreads.prefix(3))
            fallthrough
        case 11:
            // v12 adds a neutral world to existing lives without consuming the
            // gameplay RNG or retroactively changing prior settlements.
            migrated.world = WorldSystem.neutral(
                runSeed: migrated.runSeed,
                age: migrated.character.age
            )
            fallthrough
        case 12:
            // v13 adds a separately seeded public-health lane. Preserve every
            // economic field and RNG byte from v12 while initializing neutral care.
            migrated.world.publicHealth = WorldSystem.neutralPublicHealth(
                runSeed: migrated.runSeed,
                age: migrated.character.age
            )
            fallthrough
        case 13:
            // v14 moves the legacy single home into the canonical Assets domain.
            // The adapter is reset only after value, mortgage, cost, and delinquency
            // have been copied without touching any RNG stream.
            migrated.assets = AssetSystem.migrateLegacyHousing(
                migrated.finance.housing,
                age: migrated.character.age
            )
            migrated.finance.housing = HousingState()
            fallthrough
        case 14:
            // v15 introduced adolescence. Its Codable defaults remain neutral.
            fallthrough
        case 15:
            // v16 adds a dedicated legal stream. Existing lives begin clear,
            // and initialization does not advance any established RNG stream.
            migrated.legal = LegalSystem.initialize(runSeed: migrated.runSeed)
            fallthrough
        case 16:
            // v17 adds school legacy. Existing adult lives receive no invented
            // mechanical influence, commitments, memories, debt, or RNG work.
            migrated.education.commitmentYears = [:]
            migrated.education.legacyFlags = []
            migrated.education.launchInfluenceYearsRemaining = 0
            migrated.education.legacySnapshot = nil
            fallthrough
        case 17:
            // v18 adds cash-funded property amenities. OwnedProperty's explicit
            // decoder supplies an empty list without touching finances or RNG.
            migrated.assets.normalize()
            fallthrough
        case 18:
            // v19 makes college explicit. Preserve credits, debt, career, and
            // every RNG stream while adapting only already-enrolled college saves.
            if migrated.flags.attendsSchool,
               migrated.education.phase == .postsecondary,
               migrated.education.postSchoolPath == .scholarship || migrated.education.postSchoolPath == .college {
                migrated.education.college = CollegeState(
                    status: .enrolled,
                    institution: migrated.education.postSchoolPath == .scholarship ? .scholarshipUniversity : .publicUniversity,
                    field: .generalStudies,
                    credits: migrated.education.progress,
                    academicStanding: migrated.stats.school,
                    campusBelonging: migrated.stats.love,
                    lastTuitionAge: migrated.character.age
                )
            }
            if migrated.education.credential, migrated.education.credentialKind == .none {
                migrated.education.credentialKind = .legacyCredential
            }
            fallthrough
        case 19:
            // v20 adds explicit vehicle classes. Preserve each movable asset's
            // identity and value while classifying legacy car listings as cars.
            migrated.assets.normalize()
            fallthrough
        case 20:
            // v21 adds compact education recovery. Existing saves receive no
            // invented enrollment, progress, debt, credential, or RNG work.
            migrated.education.recovery = EducationRecoveryState()
            fallthrough
        case 21:
            // v22 unifies character personality and splits deterministic RNG
            // lanes. Old identity and social flags map without retroactive
            // talent, stat, relationship, world, or history changes.
            migrated.personality = PersonalitySystem.legacyPlayer(trait: migrated.coreTrait)
            migrated.personality.talent = nil
            if var partner = migrated.partner {
                partner.personality = PersonalitySystem.legacyPartner(flags: partner.flags)
                migrated.partner = partner
            }
            for role in NPCRole.allCases {
                if var npc = migrated.npcs[role] {
                    npc.personality = PersonalitySystem.legacyNPC(flags: npc.coreFlags)
                    migrated.npcs[role] = npc
                }
            }
            migrated.randomStreams = SimulationRandomStreams(runSeed: migrated.runSeed)
            fallthrough
        case 22:
            // v23 added independently persisted life domains. Their explicit
            // Codable defaults preserve old lives without retroactive effects.
            fallthrough
        case 23:
            // v24 adds school identity. Only active high-school saves receive
            // a generated environment; no RNG stream or adult outcome changes.
            if migrated.education.phase == .highSchool, migrated.character.age < 18 {
                migrated.education.schoolEnvironment = EducationSystem.schoolEnvironment(for: migrated.runSeed)
            }
            migrated.education.schoolReputation = 50
            migrated.education.activityStage = migrated.education.activity == .none ? .none : .committed
            migrated.education.schoolMemories = []
            migrated.education.frozenDefiningMemory = nil
            fallthrough
        case 24:
            // v25 remembers established personality polarities so flags remain
            // stable through the neutral band. Derivation is deterministic and
            // changes no axis, relationship, world value, or RNG stream.
            migrated.personality.refreshEstablishedFlags()
            if var partner = migrated.partner {
                partner.personality.refreshEstablishedFlags()
                migrated.partner = partner
            }
            for role in NPCRole.allCases {
                if var npc = migrated.npcs[role] {
                    npc.personality.refreshEstablishedFlags()
                    migrated.npcs[role] = npc
                }
            }
            fallthrough
        case 25:
            // v26 adds manufacturer-free car metadata and private vehicle names.
            // Codable defaults and normalization preserve every existing asset,
            // price, identity, financial value, and random stream.
            migrated.assets.normalize()
            fallthrough
        case 26:
            // v27 remembers relationships that ended. Existing saves start with
            // no invented relationship history and preserve every live partner.
            migrated.formerRelationships = []
            fallthrough
        case 27:
            // v28 distinguishes active conditions from conditions stabilized
            // by ongoing care. The decoder treats every legacy condition as active.
            fallthrough
        case 28:
            // v29 remembers sold and foreclosed properties. Existing saves gain
            // no invented housing history; AssetState's decoder supplies an empty ledger.
            fallthrough
        case 29:
            // v30 models post-case legal supervision. Existing felony saves are
            // treated as having completed supervision rather than inventing new time.
            fallthrough
        case 30:
            // v31 adds the sovereign rental-property lifecycle. Existing homes
            // retain their identity and finances without inventing tenants or RNG work.
            AssetSystem.migrateRealEstateState(&migrated.assets, runSeed: migrated.runSeed)
            fallthrough
        case 31:
            // v32 gives yearly summaries stable typed presentation data. Rebuild
            // only from already-recorded history; gameplay state and RNG are untouched.
            for index in migrated.history.indices {
                guard var summary = migrated.history[index].yearSummary else { continue }
                if summary.age == 0 { summary.age = migrated.history[index].age }
                if summary.headline == "Year Summary" { summary.headline = migrated.history[index].headline }
                let deltas = summary.deltas.isEmpty ? migrated.history[index].deltas : summary.deltas
                migrated.history[index].yearSummary = YearSummarySystem.finalize(
                    summary,
                    headline: summary.headline,
                    deltas: deltas
                )
            }
            if var summary = migrated.lastYearSummary {
                if summary.age == 0 { summary.age = migrated.character.age }
                let latest = migrated.history.first
                if summary.headline == "Year Summary", let latest { summary.headline = latest.headline }
                let deltas = summary.deltas.isEmpty ? latest?.deltas ?? DeltaSummary() : summary.deltas
                migrated.lastYearSummary = YearSummarySystem.finalize(
                    summary,
                    headline: summary.headline,
                    deltas: deltas
                )
            }
            break
        case 32, 33:
            // v34 adds persistent situations. Codable defaults keep existing
            // lives neutral and do not invent an active arc.
            break
        case 34:
            // v35 gives family contacts their own personality and passive
            // stance. Old contacts retain their bond and begin neutral.
            break
        case 35:
            // v36 gives contextual NPCs stable cast identities, activity, and
            // remembered interactions. Their role, personality, and rapport
            // are preserved exactly; decoder defaults keep them active.
            break
        case 36:
            // v37 records the last caused situation per cast member. Legacy
            // members default to no prior situation, so no event history is
            // fabricated during migration.
            break
        case 37:
            // v38 separates durable bond from current rapport, adds hidden
            // trait discovery and compressed independent NPC lives, and keeps
            // biography-grade timeline entries outside the bounded journal.
            // Explicit decoders derive only compatibility-safe defaults.
            break
        case 38:
            // v39 makes career class explicit. Existing careers remain normal;
            // no income, level, performance, or RNG history is rewritten.
            break
        case 39:
            // v40 gives family situations their own cooldown. Existing
            // appraisal history remains intact; legacy contacts simply have
            // no prior caused family moment.
            break
        case 40:
            // v41 adds stable character values, evidence-based observations,
            // quiet personal goals, and role history to the living cast.
            // The deterministic backfill below does not consume gameplay RNG.
            break
        case 44:
            // v45 adds investigation and lightweight pretrial fields. Codable
            // compatibility defaults preserve existing legal cases and never
            // consume a random stream during migration.
            break
        case 45:
            // v46 adds bounded enterprise target records and front-business
            // legal scrutiny. Existing cases stay single-target until their
            // next legal resolution; no target is fabricated here and no RNG
            // stream is consumed during migration.
            break
        case 46:
            // v47 adds case-level cooperation offers and permanent cooperation
            // records. Codable defaults keep existing cases neutral and do not
            // consume legal or gameplay RNG during migration.
            break
        case 47:
            // v48 retains old use ages as one use in that age. No stream is
            // advanced and pending legacy decisions remain the current card.
            migrated.actionUseRecords = decoded.actionUsage.mapValues {
                ActionUseRecord(age: $0, count: 1)
            }
            migrated.recentFlavorIDs = []
            migrated.queuedYearEvents = []
            migrated.yearChoicesResolved = 0
            break
        case 48:
            // v49 switches persisted RNG state to SplitMix64. The saved seed
            // is the generator state, so carrying it forward keeps each lane
            // deterministic without consuming draws or reseeding the life.
            break
        case 49:
            // v50 stores source-level lifetime earnings and moves peak-cash
            // observation out of decoding. Seed the missing legacy peak here.
            migrated.aggregates.peakCash = max(migrated.aggregates.peakCash, migrated.cash)
            break
        case 50:
            // Venture state is optional; pre-venture saves decode as no active company.
            break
        case 51:
            // v52 adds bounded reaction history and deferred consequences.
            // Missing fields decode to an empty state without consuming RNG.
            break
        default:
            break
        }

        for member in migrated.npcs.all {
            var updated = member
            CharacterTagSystem.backfill(member: &updated, runSeed: migrated.runSeed)
            migrated.npcs.update(updated)
        }

        guard let converted = try? EconomyMigration.convert(migrated) else { return nil }
        migrated = converted
        migrated.saveVersion = LifeState.currentSaveVersion
        migrated.clamp()
        return migrated.isValidSave ? migrated : nil
    }
}
