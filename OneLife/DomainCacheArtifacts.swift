import Foundation

struct DomainCacheKey: Codable, Hashable, Equatable {
    var domain: DomainArtifactDomain
    var ageBand: String
    var lifePath: String
    var criticalStatusSignature: String
    var schemaVersion: Int
    var situationID: String
}

struct DomainCachePayload: Codable, Equatable {
    var summary: String
    var riskSignals: [String]
    var eventWeightHints: [String: Int]
    var topSignals: [String]
}

struct DomainCacheArtifact: Codable, Equatable {
    var key: DomainCacheKey
    var contentHash: String
    var generatedAt: Date
    var payload: DomainCachePayload
}

struct DomainCacheArtifactStore {
    static let schemaVersion = 1

    let fileManager: FileManager
    let directoryProvider: () throws -> URL

    init(
        fileManager: FileManager = .default,
        directoryProvider: @escaping () throws -> URL = {
            let baseURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directory = baseURL.appendingPathComponent("OneLifeDomainCache", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        }
    ) {
        self.fileManager = fileManager
        self.directoryProvider = directoryProvider
    }

    func write(_ artifact: DomainCacheArtifact) throws {
        let directory = try directoryProvider()
        let url = fileURL(for: artifact.key, in: directory)
        let data = try JSONEncoder().encode(artifact)
        try data.write(to: url, options: [.atomic])
    }

    func load(key: DomainCacheKey) throws -> DomainCacheArtifact? {
        let directory = try directoryProvider()
        let url = fileURL(for: key, in: directory)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(DomainCacheArtifact.self, from: data)
    }

    func isValid(_ artifact: DomainCacheArtifact, for key: DomainCacheKey, contentHash: String) -> Bool {
        artifact.key == key && artifact.key.schemaVersion == Self.schemaVersion && artifact.contentHash == contentHash
    }

    private func fileURL(for key: DomainCacheKey, in directory: URL) -> URL {
        directory.appendingPathComponent("\(key.domain.rawValue)-\(key.situationID).json")
    }
}

final class DomainCacheGenerationCoordinator {
    private let store: DomainCacheArtifactStore
    private let queue: DispatchQueue
    private let builder: DomainCacheArtifactBuilder

    init(
        store: DomainCacheArtifactStore = DomainCacheArtifactStore(),
        queue: DispatchQueue = DispatchQueue(label: "onelife.domain-cache", qos: .utility),
        builder: DomainCacheArtifactBuilder = DomainCacheArtifactBuilder()
    ) {
        self.store = store
        self.queue = queue
        self.builder = builder
    }

    func refreshArtifacts(for snapshot: WorldSnapshot) {
        let artifacts = builder.buildArtifacts(for: snapshot)
        queue.async {
            for artifact in artifacts {
                do {
                    if let existing = try self.store.load(key: artifact.key),
                       self.store.isValid(existing, for: artifact.key, contentHash: artifact.contentHash) {
                        continue
                    }
                    try self.store.write(artifact)
                } catch {
                    #if DEBUG
                    print("OneLife domain cache write failed: \(error)")
                    #endif
                }
            }
        }
    }

    func refreshOnIdle(for snapshot: WorldSnapshot) {
        queue.asyncAfter(deadline: .now() + 0.35) {
            self.refreshArtifacts(for: snapshot)
        }
    }
}

struct DomainCacheArtifactBuilder {
    func buildArtifacts(for snapshot: WorldSnapshot) -> [DomainCacheArtifact] {
        DomainArtifactDomain.allCases.map { domain in
            let key = DomainCacheKey(
                domain: domain,
                ageBand: snapshot.cache.ageBand,
                lifePath: snapshot.state.progress.currentLifePath?.rawValue ?? "none",
                criticalStatusSignature: snapshot.cache.criticalStatuses.joined(separator: ","),
                schemaVersion: DomainCacheArtifactStore.schemaVersion,
                situationID: snapshot.cache.situationID
            )
            let payload = payload(for: domain, snapshot: snapshot)
            let contentHash = hash(for: key, payload: payload)
            return DomainCacheArtifact(key: key, contentHash: contentHash, generatedAt: Date(), payload: payload)
        }
    }

    private func payload(for domain: DomainArtifactDomain, snapshot: WorldSnapshot) -> DomainCachePayload {
        switch domain {
        case .education:
            return DomainCachePayload(
                summary: "School standing \(snapshot.state.education.schoolStanding), burnout \(snapshot.state.education.burnoutRisk), belonging \(snapshot.state.education.schoolBelonging).",
                riskSignals: riskSignals(from: [snapshot.state.education.burnoutRisk > 55 ? "burnout" : nil, snapshot.state.education.attendancePressure > 55 ? "attendance" : nil]),
                eventWeightHints: ["school": max(1, snapshot.state.education.schoolStanding / 10), "routine": max(1, snapshot.state.education.engagement / 15)],
                topSignals: topSignals(from: ["Standing \(snapshot.state.education.schoolStanding)", "Belonging \(snapshot.state.education.schoolBelonging)", "Readiness \(snapshot.state.education.applicationReadiness)"])
            )
        case .career:
            return DomainCachePayload(
                summary: "Career status \(snapshot.state.career.status.rawValue), performance \(snapshot.state.career.performance), income \(snapshot.state.career.annualIncome).",
                riskSignals: riskSignals(from: [snapshot.state.career.performance < 35 ? "low_performance" : nil, snapshot.state.specialCareer.track != .inactive ? "special_track" : nil]),
                eventWeightHints: ["career": max(1, snapshot.state.career.performance / 10), "chance": snapshot.state.specialCareer.track == .inactive ? 1 : 4],
                topSignals: topSignals(from: ["Performance \(snapshot.state.career.performance)", "Income \(snapshot.state.career.annualIncome)", "Track \(snapshot.state.specialCareer.track.rawValue)"])
            )
        case .crime:
            return DomainCachePayload(
                summary: "Crime status \(snapshot.state.crime.status.rawValue), heat \(snapshot.state.crime.heat), notoriety \(snapshot.state.crime.notoriety).",
                riskSignals: riskSignals(from: [snapshot.state.crime.status == .active ? "active_crime" : nil, snapshot.state.crime.heat > 55 ? "heat" : nil]),
                eventWeightHints: ["risk": max(1, snapshot.state.crime.notoriety / 10), "money": max(1, snapshot.state.crime.lastPayout / 1_000)],
                topSignals: topSignals(from: ["Heat \(snapshot.state.crime.heat)", "Notoriety \(snapshot.state.crime.notoriety)", "Payout \(snapshot.state.crime.lastPayout)"])
            )
        case .finance:
            return DomainCachePayload(
                summary: "Cash \(snapshot.state.finance.cashOnHand), stress \(snapshot.state.finance.financialStress), balance \(snapshot.state.finance.lastYearBalanceDelta).",
                riskSignals: riskSignals(from: [snapshot.state.finance.cashOnHand < 0 ? "negative_cash" : nil, snapshot.state.finance.financialStress >= 45 ? "stress" : nil]),
                eventWeightHints: ["money": max(1, snapshot.state.finance.financialStress / 10), "cost": max(1, abs(snapshot.state.finance.lastYearBalanceDelta) / 1_000)],
                topSignals: topSignals(from: ["Cash \(snapshot.state.finance.cashOnHand)", "Stress \(snapshot.state.finance.financialStress)", "Debt \(snapshot.state.finance.studentDebt)"])
            )
        case .relationships:
            return DomainCachePayload(
                summary: "Connections \(snapshot.cache.socialConnectionCount), strongest bond \(snapshot.cache.strongestRelationshipBond), strained \(snapshot.cache.strainedRelationshipCount).",
                riskSignals: riskSignals(from: [snapshot.cache.strainedRelationshipCount > 0 ? "strain" : nil, snapshot.cache.socialConnectionCount == 0 ? "isolated" : nil]),
                eventWeightHints: ["social": max(1, snapshot.cache.socialConnectionCount * 2), "romance": snapshot.state.relationships.hasPartner ? 4 : 2],
                topSignals: topSignals(from: ["Bonds \(snapshot.cache.strongestRelationshipBond)", "Strained \(snapshot.cache.strainedRelationshipCount)", "Partner \(snapshot.state.relationships.hasPartner ? "yes" : "no")"])
            )
        case .health:
            return DomainCachePayload(
                summary: "Physical \(snapshot.state.healthProfile.physicalWellness), mental \(snapshot.state.healthProfile.mentalWellness), conditions \(snapshot.cache.activeHealthConditionCount).",
                riskSignals: riskSignals(from: [snapshot.state.healthProfile.mentalWellness < 45 ? "mental" : nil, snapshot.cache.activeHealthConditionCount > 0 ? "conditions" : nil]),
                eventWeightHints: ["health": max(1, (100 - min(snapshot.state.healthProfile.physicalWellness, snapshot.state.healthProfile.mentalWellness)) / 10), "routine": max(1, snapshot.state.healthProfile.habits.stressManagement / 15)],
                topSignals: topSignals(from: ["Physical \(snapshot.state.healthProfile.physicalWellness)", "Mental \(snapshot.state.healthProfile.mentalWellness)", "Care \(snapshot.state.healthProfile.hasPrimaryCare ? "primary" : "none")"])
            )
        case .housing:
            return DomainCachePayload(
                summary: "Housing \(snapshot.state.housing.livingArrangement.rawValue), stability \(snapshot.state.housing.housingStability), cost band \(snapshot.state.housing.housingCostBand).",
                riskSignals: riskSignals(from: [snapshot.state.housing.housingStability < 42 ? "instability" : nil, snapshot.state.housing.livingArrangement == .couchSurfing ? "temporary" : nil]),
                eventWeightHints: ["cost": max(1, snapshot.state.housing.housingCostBand / 10), "routine": snapshot.state.housing.housingStability < 50 ? 5 : 2],
                topSignals: topSignals(from: ["Stability \(snapshot.state.housing.housingStability)", "Arrangement \(snapshot.state.housing.livingArrangement.rawValue)", "Roommate \(snapshot.state.housing.hasRoommate ? "yes" : "no")"])
            )
        case .family:
            return DomainCachePayload(
                summary: "Children \(snapshot.state.family.childCount), pregnant \(snapshot.state.family.isPregnant ? "yes" : "no"), postpartum \(snapshot.state.family.postpartumYearsRemaining).",
                riskSignals: riskSignals(from: [snapshot.state.family.isPregnant ? "pregnancy" : nil, snapshot.state.family.childCount > 0 ? "dependents" : nil]),
                eventWeightHints: ["family": max(1, snapshot.state.family.childCount * 3 + (snapshot.state.family.isPregnant ? 4 : 0)), "cost": max(1, snapshot.cache.dependentChildCount * 2)],
                topSignals: topSignals(from: ["Children \(snapshot.state.family.childCount)", "Pregnancy \(snapshot.state.family.isPregnant ? "active" : "none")", "Intent \(snapshot.state.family.pregnancyIntent.rawValue)"])
            )
        case .assets:
            return DomainCachePayload(
                summary: "Owns home \(snapshot.state.assets.ownsHome ? "yes" : "no"), cash \(snapshot.state.finance.cashOnHand), stability \(snapshot.state.housing.housingStability).",
                riskSignals: riskSignals(from: [snapshot.state.assets.ownsHome ? nil : "no_home" ]),
                eventWeightHints: ["asset": snapshot.state.assets.ownsHome ? 1 : 4, "money": max(1, snapshot.state.finance.cashOnHand / 25_000)],
                topSignals: topSignals(from: ["Owns home \(snapshot.state.assets.ownsHome ? "yes" : "no")", "Cash \(snapshot.state.finance.cashOnHand)", "Housing \(snapshot.state.housing.housingStability)"])
            )
        case .progress:
            return DomainCachePayload(
                summary: "Life path \(snapshot.state.progress.currentLifePath?.rawValue ?? "none"), legacy \(snapshot.state.progress.legacyScore), milestones \(snapshot.state.progress.unlockedMilestones.count).",
                riskSignals: riskSignals(from: [snapshot.state.progress.currentLifePath == .survivor ? "survival_arc" : nil]),
                eventWeightHints: ["progress": max(1, snapshot.state.progress.legacyScore / 10), "chance": snapshot.state.progress.currentLifePath == nil ? 2 : 4],
                topSignals: topSignals(from: ["Path \(snapshot.state.progress.currentLifePath?.rawValue ?? "none")", "Legacy \(snapshot.state.progress.legacyScore)", "Milestones \(snapshot.state.progress.unlockedMilestones.count)"])
            )
        }
    }

    private func riskSignals(from signals: [String?]) -> [String] {
        signals.compactMap { $0 }
    }

    private func topSignals(from signals: [String]) -> [String] {
        Array(signals.prefix(3))
    }

    private func hash(for key: DomainCacheKey, payload: DomainCachePayload) -> String {
        let raw = "\(key.domain.rawValue)|\(key.ageBand)|\(key.lifePath)|\(key.criticalStatusSignature)|\(payload.summary)|\(payload.riskSignals.joined(separator: ","))|\(payload.topSignals.joined(separator: ","))|\(payload.eventWeightHints.sorted { $0.key < $1.key })"
        var hash: UInt64 = 5381
        for byte in raw.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(hash, radix: 16)
    }
}
