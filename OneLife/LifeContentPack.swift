import Foundation

struct ContentEffect: Codable, Equatable {
    var school = 0
    var cash = 0
    var love = 0
    var play = 0
    var health = 0
    var looks = 0
    var rep = 0

    var range: EffectRange {
        EffectRange(
            school: school...school,
            cash: cash...cash,
            love: love...love,
            play: play...play,
            health: health...health,
            looks: looks...looks,
            rep: rep...rep
        )
    }
}

extension ContentEffect {
    private enum CodingKeys: String, CodingKey { case school, cash, love, play, health, looks, rep }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        school = try c.decodeIfPresent(Int.self, forKey: .school) ?? 0
        cash = try c.decodeIfPresent(Int.self, forKey: .cash) ?? 0
        love = try c.decodeIfPresent(Int.self, forKey: .love) ?? 0
        play = try c.decodeIfPresent(Int.self, forKey: .play) ?? 0
        health = try c.decodeIfPresent(Int.self, forKey: .health) ?? 0
        looks = try c.decodeIfPresent(Int.self, forKey: .looks) ?? 0
        rep = try c.decodeIfPresent(Int.self, forKey: .rep) ?? 0
    }
}

struct ContentPredicate: Codable, Equatable {
    var playerFlags: [PersonalityFlag] = []
    var identitySignatures: [IdentitySignatureID] = []
    var npcRole: SimulationRole?
    var npcFlags: [PersonalityFlag] = []
    var npcTags: [CharacterTag] = []
    var npcCircumstances: [NPCCircumstanceKind] = []
    var npcGoals: [NPCGoalKind] = []
    var npcConnections: [NPCConnectionKind] = []
    var requiredNPCMemoryActions: [ActionID] = []
    var independentChapters: [NPCLifeChapter] = []
    var relationshipStance: RelationshipSignalStance?
    var talent: SpecialTalent?
    var worldFlags: [WorldFlag] = []
    var minimumPlayerAxes: [PersonalityAxis: Int] = [:]
    var maximumPlayerAxes: [PersonalityAxis: Int] = [:]
    var minimumNPCAxes: [PersonalityAxis: Int] = [:]
    var maximumNPCAxes: [PersonalityAxis: Int] = [:]
    var minimumStats: [Domain: Int] = [:]
    var maximumStats: [Domain: Int] = [:]
    var requiredDomainStates: [ContentDomainState] = []
    var forbiddenDomainStates: [ContentDomainState] = []
    var minimumBond: Int?
    var maximumBond: Int?
    var minimumRapport: Int?
    var maximumRapport: Int?
    var minimumYearsSinceContact: Int?
    var maximumYearsSinceContact: Int?

    func matches(_ state: LifeState) -> Bool {
        let npc = npcRole?.npcRole.flatMap { state.npcs[$0] }
        let signals = SimulationSignalSnapshot(state: state, npc: npc)
        guard playerFlags.allSatisfy(signals.player.has),
              (identitySignatures.isEmpty || identitySignatures.contains(signals.identitySignature)),
              npcFlags.allSatisfy({ signals.npc?.has($0) == true }),
              npcTags.allSatisfy({ npc?.stableTags.contains($0) == true }),
              npcCircumstances.allSatisfy({ kind in npc?.circumstances.contains(where: { $0.kind == kind }) == true }),
              npcGoals.allSatisfy({ kind in npc?.goals.contains(where: { $0.kind == kind }) == true }),
              npcConnections.allSatisfy({ kind in npc?.connections.contains(where: { $0.kind == kind && $0.isCurrent }) == true }),
              requiredNPCMemoryActions.allSatisfy({ action in npc?.memories.contains(where: { $0.actionID == action }) == true }),
              independentChapters.isEmpty || npc.map({ independentChapters.contains($0.independentLife.chapter) }) == true,
              npcRole.map({ signals.role == $0 }) ?? true,
              relationshipStance.map({ signals.relationshipStance == $0 }) ?? true,
              talent.map({ signals.talent == $0 }) ?? true,
              worldFlags.allSatisfy({ signals.worldFlags.contains($0) }),
              requiredDomainStates.allSatisfy({ $0.matches(state) }),
              forbiddenDomainStates.allSatisfy({ !$0.matches(state) }) else { return false }
        if let minimumBond, (npc?.bond ?? -1) < minimumBond { return false }
        if let maximumBond, (npc?.bond ?? 101) > maximumBond { return false }
        if let minimumRapport, (npc?.rapport ?? -101) < minimumRapport { return false }
        if let maximumRapport, (npc?.rapport ?? 101) > maximumRapport { return false }
        let yearsSinceContact = npc.map { max(0, state.character.age - $0.lastInteractionAge) }
        if let minimumYearsSinceContact, (yearsSinceContact ?? -1) < minimumYearsSinceContact { return false }
        if let maximumYearsSinceContact, (yearsSinceContact ?? Int.max) > maximumYearsSinceContact { return false }
        for (axis, value) in minimumPlayerAxes where signals.player.current[axis] < value { return false }
        for (axis, value) in maximumPlayerAxes where signals.player.current[axis] > value { return false }
        for (axis, value) in minimumNPCAxes where (signals.npc?.current[axis] ?? -1) < value { return false }
        for (axis, value) in maximumNPCAxes where (signals.npc?.current[axis] ?? 101) > value { return false }
        for (domain, value) in minimumStats where state.stats[domain] < value { return false }
        for (domain, value) in maximumStats where state.stats[domain] > value { return false }
        return true
    }
}

extension ContentPredicate {
    private enum CodingKeys: String, CodingKey {
        case playerFlags, identitySignatures, npcRole, npcFlags, npcTags, npcCircumstances, npcGoals
        case npcConnections, requiredNPCMemoryActions, independentChapters
        case relationshipStance, talent, worldFlags
        case minimumPlayerAxes, maximumPlayerAxes, minimumNPCAxes, maximumNPCAxes
        case minimumStats, maximumStats, requiredDomainStates, forbiddenDomainStates
        case minimumBond, maximumBond, minimumRapport, maximumRapport
        case minimumYearsSinceContact, maximumYearsSinceContact
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        playerFlags = try c.decodeIfPresent([PersonalityFlag].self, forKey: .playerFlags) ?? []
        identitySignatures = try c.decodeIfPresent([IdentitySignatureID].self, forKey: .identitySignatures) ?? []
        npcRole = try c.decodeIfPresent(SimulationRole.self, forKey: .npcRole)
        npcFlags = try c.decodeIfPresent([PersonalityFlag].self, forKey: .npcFlags) ?? []
        npcTags = try c.decodeIfPresent([CharacterTag].self, forKey: .npcTags) ?? []
        npcCircumstances = try c.decodeIfPresent([NPCCircumstanceKind].self, forKey: .npcCircumstances) ?? []
        npcGoals = try c.decodeIfPresent([NPCGoalKind].self, forKey: .npcGoals) ?? []
        npcConnections = try c.decodeIfPresent([NPCConnectionKind].self, forKey: .npcConnections) ?? []
        requiredNPCMemoryActions = try c.decodeIfPresent([ActionID].self, forKey: .requiredNPCMemoryActions) ?? []
        independentChapters = try c.decodeIfPresent([NPCLifeChapter].self, forKey: .independentChapters) ?? []
        relationshipStance = try c.decodeIfPresent(RelationshipSignalStance.self, forKey: .relationshipStance)
        talent = try c.decodeIfPresent(SpecialTalent.self, forKey: .talent)
        worldFlags = try c.decodeIfPresent([WorldFlag].self, forKey: .worldFlags) ?? []
        minimumPlayerAxes = try Self.decodeAxes(c, forKey: .minimumPlayerAxes)
        maximumPlayerAxes = try Self.decodeAxes(c, forKey: .maximumPlayerAxes)
        minimumNPCAxes = try Self.decodeAxes(c, forKey: .minimumNPCAxes)
        maximumNPCAxes = try Self.decodeAxes(c, forKey: .maximumNPCAxes)
        minimumStats = try Self.decodeStats(c, forKey: .minimumStats)
        maximumStats = try Self.decodeStats(c, forKey: .maximumStats)
        requiredDomainStates = try c.decodeIfPresent([ContentDomainState].self, forKey: .requiredDomainStates) ?? []
        forbiddenDomainStates = try c.decodeIfPresent([ContentDomainState].self, forKey: .forbiddenDomainStates) ?? []
        minimumBond = try c.decodeIfPresent(Int.self, forKey: .minimumBond)
        maximumBond = try c.decodeIfPresent(Int.self, forKey: .maximumBond)
        minimumRapport = try c.decodeIfPresent(Int.self, forKey: .minimumRapport)
        maximumRapport = try c.decodeIfPresent(Int.self, forKey: .maximumRapport)
        minimumYearsSinceContact = try c.decodeIfPresent(Int.self, forKey: .minimumYearsSinceContact)
        maximumYearsSinceContact = try c.decodeIfPresent(Int.self, forKey: .maximumYearsSinceContact)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if !playerFlags.isEmpty { try c.encode(playerFlags, forKey: .playerFlags) }
        if !identitySignatures.isEmpty { try c.encode(identitySignatures, forKey: .identitySignatures) }
        try c.encodeIfPresent(npcRole, forKey: .npcRole)
        if !npcFlags.isEmpty { try c.encode(npcFlags, forKey: .npcFlags) }
        if !npcTags.isEmpty { try c.encode(npcTags, forKey: .npcTags) }
        if !npcCircumstances.isEmpty { try c.encode(npcCircumstances, forKey: .npcCircumstances) }
        if !npcGoals.isEmpty { try c.encode(npcGoals, forKey: .npcGoals) }
        if !npcConnections.isEmpty { try c.encode(npcConnections, forKey: .npcConnections) }
        if !requiredNPCMemoryActions.isEmpty { try c.encode(requiredNPCMemoryActions, forKey: .requiredNPCMemoryActions) }
        if !independentChapters.isEmpty { try c.encode(independentChapters, forKey: .independentChapters) }
        try c.encodeIfPresent(relationshipStance, forKey: .relationshipStance)
        try c.encodeIfPresent(talent, forKey: .talent)
        if !worldFlags.isEmpty { try c.encode(worldFlags, forKey: .worldFlags) }
        try Self.encodeAxes(minimumPlayerAxes, to: &c, forKey: .minimumPlayerAxes)
        try Self.encodeAxes(maximumPlayerAxes, to: &c, forKey: .maximumPlayerAxes)
        try Self.encodeAxes(minimumNPCAxes, to: &c, forKey: .minimumNPCAxes)
        try Self.encodeAxes(maximumNPCAxes, to: &c, forKey: .maximumNPCAxes)
        if !minimumStats.isEmpty {
            try c.encode(Dictionary(uniqueKeysWithValues: minimumStats.map { ($0.key.rawValue, $0.value) }), forKey: .minimumStats)
        }
        if !maximumStats.isEmpty {
            try c.encode(Dictionary(uniqueKeysWithValues: maximumStats.map { ($0.key.rawValue, $0.value) }), forKey: .maximumStats)
        }
        if !requiredDomainStates.isEmpty { try c.encode(requiredDomainStates, forKey: .requiredDomainStates) }
        if !forbiddenDomainStates.isEmpty { try c.encode(forbiddenDomainStates, forKey: .forbiddenDomainStates) }
        try c.encodeIfPresent(minimumBond, forKey: .minimumBond)
        try c.encodeIfPresent(maximumBond, forKey: .maximumBond)
        try c.encodeIfPresent(minimumRapport, forKey: .minimumRapport)
        try c.encodeIfPresent(maximumRapport, forKey: .maximumRapport)
        try c.encodeIfPresent(minimumYearsSinceContact, forKey: .minimumYearsSinceContact)
        try c.encodeIfPresent(maximumYearsSinceContact, forKey: .maximumYearsSinceContact)
    }

    private static func decodeStats(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> [Domain: Int] {
        let raw = try container.decodeIfPresent([String: Int].self, forKey: key) ?? [:]
        return try Dictionary(uniqueKeysWithValues: raw.map { name, value in
            guard let domain = Domain(rawValue: name) else {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: container,
                    debugDescription: "Unknown domain '\(name)'"
                )
            }
            return (domain, value)
        })
    }

    private static func decodeAxes(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> [PersonalityAxis: Int] {
        let raw = try container.decodeIfPresent([String: Int].self, forKey: key) ?? [:]
        return try Dictionary(uniqueKeysWithValues: raw.map { name, value in
            guard let axis = PersonalityAxis(rawValue: name) else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Unknown personality axis '\(name)'")
            }
            return (axis, value)
        })
    }

    private static func encodeAxes(
        _ axes: [PersonalityAxis: Int],
        to container: inout KeyedEncodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws {
        guard !axes.isEmpty else { return }
        try container.encode(Dictionary(uniqueKeysWithValues: axes.map { ($0.key.rawValue, $0.value) }), forKey: key)
    }
}

struct BundledEventChoice: Codable, Equatable {
    let id: EventChoiceID
    let title: String
    let detail: String
    let narrative: String
    var effects = ContentEffect()
    var personalityImpulse: PersonalityImpulse? = nil
    var partnerEffect: PartnerEffect? = nil
    var npcRapportDelta: Int? = nil

    func eventChoice(targetRole: SimulationRole?) -> EventChoice {
        EventChoice(
            id: id,
            title: title,
            detail: detail,
            effects: effects.range,
            partnerEffect: partnerEffect ?? PartnerEffect(),
            narrative: narrative,
            personalityImpulse: personalityImpulse,
            relationshipRole: targetRole,
            npcRapportDelta: npcRapportDelta
        )
    }
}

struct BundledLifeEvent: Codable, Equatable, Identifiable {
    let id: String
    let headline: String
    let detail: String
    var narrativeVariants: [String] = []
    let baseWeight: Int
    var cooldown: Int = 6
    var stages: [LifeStage] = []
    var predicate = ContentPredicate()
    let choices: [BundledEventChoice]

    func weight(in state: LifeState) -> Int {
        guard stages.isEmpty || stages.contains(state.lifeStage), predicate.matches(state) else { return 0 }
        if let recentIndex = state.recentEventIDs.firstIndex(of: id), recentIndex < cooldown { return 0 }
        return baseWeight
    }

    func lifeEvent(for state: LifeState) -> LifeEvent {
        let flavor = narrativeVariants.isEmpty ? detail : narrativeVariants[stableVariantIndex(state: state)]
        return LifeEvent(
            id: id,
            headline: headline,
            detail: flavor,
            weight: { self.weight(in: $0) },
            choices: choices.map { $0.eventChoice(targetRole: predicate.npcRole) }
        )
    }

    private func stableVariantIndex(state: LifeState) -> Int {
        let hash = id.utf8.reduce(state.runSeed ^ UInt64(state.character.age)) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
        return Int(hash % UInt64(narrativeVariants.count))
    }
}

extension BundledLifeEvent {
    private enum CodingKeys: String, CodingKey {
        case id, headline, detail, narrativeVariants, baseWeight, cooldown, stages, predicate, choices
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        headline = try c.decode(String.self, forKey: .headline)
        detail = try c.decode(String.self, forKey: .detail)
        narrativeVariants = try c.decodeIfPresent([String].self, forKey: .narrativeVariants) ?? []
        baseWeight = try c.decode(Int.self, forKey: .baseWeight)
        cooldown = try c.decodeIfPresent(Int.self, forKey: .cooldown) ?? 6
        stages = try c.decodeIfPresent([LifeStage].self, forKey: .stages) ?? []
        predicate = try c.decodeIfPresent(ContentPredicate.self, forKey: .predicate) ?? ContentPredicate()
        choices = try c.decode([BundledEventChoice].self, forKey: .choices)
    }
}

struct LifeContentPack: Codable, Equatable {
    let schemaVersion: Int
    let events: [BundledLifeEvent]
}

enum LifeContentValidationError: Error, Equatable, CustomStringConvertible {
    case unsupportedSchema(Int)
    case duplicateID(String)
    case invalidHeadline(String)
    case invalidWeight(String)
    case invalidCooldown(String)
    case invalidChoiceCount(String)
    case duplicateChoice(String)
    case invalidStatRange(String)
    case incompatibleFlags(String)
    case unreachablePredicate(String)
    case malformedImpact(String)

    var description: String {
        switch self {
        case .unsupportedSchema(let value): "Unsupported content schema \(value)"
        case .duplicateID(let id): "Duplicate event ID: \(id)"
        case .invalidHeadline(let id): "Event \(id) needs a 5–7 word headline"
        case .invalidWeight(let id): "Event \(id) has an invalid weight"
        case .invalidCooldown(let id): "Event \(id) has an invalid cooldown"
        case .invalidChoiceCount(let id): "Event \(id) needs one to three choices"
        case .duplicateChoice(let id): "Event \(id) has duplicate choice IDs"
        case .invalidStatRange(let id): "Event \(id) has a stat threshold outside 0...100"
        case .incompatibleFlags(let id): "Event \(id) requires incompatible paired flags"
        case .unreachablePredicate(let id): "Event \(id) contains an unreachable predicate"
        case .malformedImpact(let id): "Event \(id) has malformed headline, detail, or impact data"
        }
    }
}

enum LifeContentValidator {
    static func validate(_ pack: LifeContentPack) throws {
        guard pack.schemaVersion == 1 else { throw LifeContentValidationError.unsupportedSchema(pack.schemaVersion) }
        var ids = Set<String>()
        for event in pack.events {
            guard ids.insert(event.id).inserted else { throw LifeContentValidationError.duplicateID(event.id) }
            let words = event.headline.split(whereSeparator: { $0.isWhitespace })
            guard (5...7).contains(words.count) else { throw LifeContentValidationError.invalidHeadline(event.id) }
            guard (1...100).contains(event.baseWeight) else { throw LifeContentValidationError.invalidWeight(event.id) }
            guard (0...6).contains(event.cooldown) else { throw LifeContentValidationError.invalidCooldown(event.id) }
            guard (1...3).contains(event.choices.count) else { throw LifeContentValidationError.invalidChoiceCount(event.id) }
            guard Set(event.choices.map(\.id)).count == event.choices.count else { throw LifeContentValidationError.duplicateChoice(event.id) }
            let thresholds = Array(event.predicate.minimumStats.values) + Array(event.predicate.maximumStats.values)
                + Array(event.predicate.minimumPlayerAxes.values) + Array(event.predicate.maximumPlayerAxes.values)
                + Array(event.predicate.minimumNPCAxes.values) + Array(event.predicate.maximumNPCAxes.values)
            guard thresholds.allSatisfy({ (0...100).contains($0) }) else { throw LifeContentValidationError.invalidStatRange(event.id) }
            guard flagsAreCompatible(event.predicate.playerFlags), flagsAreCompatible(event.predicate.npcFlags) else {
                throw LifeContentValidationError.incompatibleFlags(event.id)
            }
            guard CharacterTagSystem.areCompatible(event.predicate.npcTags) else {
                throw LifeContentValidationError.incompatibleFlags(event.id)
            }
            guard identityRequirementsAreReachable(event.predicate) else {
                throw LifeContentValidationError.unreachablePredicate(event.id)
            }
            let hasNPCSpecificPredicate = !event.predicate.npcTags.isEmpty
                || !event.predicate.npcCircumstances.isEmpty
                || !event.predicate.npcGoals.isEmpty
                || !event.predicate.npcConnections.isEmpty
                || !event.predicate.requiredNPCMemoryActions.isEmpty
                || !event.predicate.independentChapters.isEmpty
                || event.predicate.minimumBond != nil || event.predicate.maximumBond != nil
                || event.predicate.minimumRapport != nil || event.predicate.maximumRapport != nil
                || event.predicate.minimumYearsSinceContact != nil || event.predicate.maximumYearsSinceContact != nil
            let bondRangeIsValid = boundedRange(
                minimum: event.predicate.minimumBond,
                maximum: event.predicate.maximumBond,
                allowed: 0...100
            )
            let rapportRangeIsValid = boundedRange(
                minimum: event.predicate.minimumRapport,
                maximum: event.predicate.maximumRapport,
                allowed: -100...100
            )
            let contactRangeIsValid = boundedRange(
                minimum: event.predicate.minimumYearsSinceContact,
                maximum: event.predicate.maximumYearsSinceContact,
                allowed: 0...120
            )
            guard thresholdsAreReachable(event.predicate.minimumStats, event.predicate.maximumStats),
                  thresholdsAreReachable(event.predicate.minimumPlayerAxes, event.predicate.maximumPlayerAxes),
                  thresholdsAreReachable(event.predicate.minimumNPCAxes, event.predicate.maximumNPCAxes),
                  Set(event.predicate.requiredDomainStates).isDisjoint(with: event.predicate.forbiddenDomainStates),
                  event.predicate.npcFlags.isEmpty || event.predicate.npcRole != nil,
                  event.predicate.minimumNPCAxes.isEmpty || event.predicate.npcRole != nil,
                  event.predicate.maximumNPCAxes.isEmpty || event.predicate.npcRole != nil,
                  !hasNPCSpecificPredicate || event.predicate.npcRole?.npcRole != nil,
                  bondRangeIsValid, rapportRangeIsValid, contactRangeIsValid else {
                throw LifeContentValidationError.unreachablePredicate(event.id)
            }
            guard !event.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  event.choices.allSatisfy({ !$0.title.isEmpty && !$0.detail.isEmpty && !$0.narrative.isEmpty }) else {
                throw LifeContentValidationError.malformedImpact(event.id)
            }
        }
    }

    private static func flagsAreCompatible(_ flags: [PersonalityFlag]) -> Bool {
        Dictionary(grouping: flags, by: \.axis).values.allSatisfy { values in
            Set(values.map(\.favorsHighValue)).count <= 1
        }
    }

    private static func identityRequirementsAreReachable(_ predicate: ContentPredicate) -> Bool {
        let candidates: [[PersonalityFlag]] = predicate.identitySignatures.isEmpty
            ? [predicate.playerFlags]
            : predicate.identitySignatures.map { predicate.playerFlags + PersonalitySystem.requiredFlags(for: $0) }
        return candidates.contains { flags in
            guard flagsAreCompatible(flags) else { return false }
            return flags.allSatisfy { flag in
                let minimum = predicate.minimumPlayerAxes[flag.axis] ?? 0
                let maximum = predicate.maximumPlayerAxes[flag.axis] ?? 100
                return flag.favorsHighValue
                    ? maximum >= PersonalitySystem.activationHigh
                    : minimum <= PersonalitySystem.activationLow
            }
        }
    }


    private static func thresholdsAreReachable<Key: Hashable>(_ minimum: [Key: Int], _ maximum: [Key: Int]) -> Bool {
        minimum.allSatisfy { key, value in maximum[key].map { value <= $0 } ?? true }
    }

    private static func boundedRange(
        minimum: Int?,
        maximum: Int?,
        allowed: ClosedRange<Int>
    ) -> Bool {
        if let minimum, !allowed.contains(minimum) { return false }
        if let maximum, !allowed.contains(maximum) { return false }
        if let minimum, let maximum, minimum > maximum { return false }
        return true
    }
}

enum BundledLifeContentRegistry {
    static let pack: LifeContentPack = {
        let developmentURL = ProcessInfo.processInfo.environment["ONELIFE_CONTENT_PATH"].map {
            URL(fileURLWithPath: $0).appendingPathComponent("PersonalityEvents.json")
        }
        let urls = [Bundle.main.url(forResource: "PersonalityEvents", withExtension: "json"), developmentURL].compactMap { $0 }
        for url in urls {
            guard let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode(LifeContentPack.self, from: data),
                  (try? LifeContentValidator.validate(decoded)) != nil else { continue }
            return decoded
        }
        return LifeContentPack(schemaVersion: 1, events: [])
    }()

    static var eventIDs: Set<String> { Set(pack.events.map(\.id)) }
    static var headlines: Set<String> { Set(pack.events.map(\.headline)) }
}
