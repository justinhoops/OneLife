import Foundation

// MARK: - Shared character personality

enum PersonalityAxis: String, Codable, CaseIterable, Identifiable {
    case drive, empathy, sociability, riskTolerance, adaptability

    var id: String { rawValue }
    var title: String {
        switch self {
        case .drive: "Drive"
        case .empathy: "Empathy"
        case .sociability: "Sociability"
        case .riskTolerance: "Risk tolerance"
        case .adaptability: "Adaptability"
        }
    }
}

enum PersonalityFlag: String, Codable, CaseIterable, Identifiable {
    case driven, content
    case empathetic, selfReliant
    case outgoing, reserved
    case adventurous, cautious
    case adaptable, steadfast

    var id: String { rawValue }
    var title: String {
        switch self {
        case .selfReliant: "Self-reliant"
        default: rawValue.capitalized
        }
    }

    var axis: PersonalityAxis {
        switch self {
        case .driven, .content: .drive
        case .empathetic, .selfReliant: .empathy
        case .outgoing, .reserved: .sociability
        case .adventurous, .cautious: .riskTolerance
        case .adaptable, .steadfast: .adaptability
        }
    }

    var favorsHighValue: Bool {
        switch self {
        case .driven, .empathetic, .outgoing, .adventurous, .adaptable: true
        case .content, .selfReliant, .reserved, .cautious, .steadfast: false
        }
    }

    var strategicHelp: String {
        switch self {
        case .driven: "Education, skill growth, and visible effort"
        case .content: "Recovery, sustainable pace, and ordinary satisfaction"
        case .empathetic: "Trust, repair, caregiving, and emotional accuracy"
        case .selfReliant: "Financial control, boundaries, and crisis response"
        case .outgoing: "Belonging, networks, and opportunity discovery"
        case .reserved: "Focused practice, observation, and private restoration"
        case .adventurous: "Volatile opportunities, novelty, and decisive pivots"
        case .cautious: "Buffers, prevention, and downside protection"
        case .adaptable: "Recovery from disruption and finding new routes"
        case .steadfast: "Routine, mastery, and durable commitments"
        }
    }

    var strategicStrain: String {
        switch self {
        case .driven: "Burnout and neglected relationships"
        case .content: "Slower income and reputation growth"
        case .empathetic: "Absorbed strain and exploitation"
        case .selfReliant: "Accepting help and sustaining intimacy"
        case .outgoing: "Spending, exposure, and social fatigue"
        case .reserved: "Visibility and deliberate relationship upkeep"
        case .adventurous: "Health, legal, and financial exposure"
        case .cautious: "Time-sensitive opportunities and spontaneity"
        case .adaptable: "Long routines and deep specialization"
        case .steadfast: "Sudden change and necessary exits"
        }
    }
}

enum SpecialTalent: String, Codable, CaseIterable, Identifiable {
    case athletic, entrepreneurial, publicLeadership, survivalInstinct

    var id: String { rawValue }
    var title: String {
        switch self {
        case .athletic: "Athletic"
        case .entrepreneurial: "Entrepreneurial"
        case .publicLeadership: "Public leadership"
        case .survivalInstinct: "Survival instinct"
        }
    }

    var detail: String {
        switch self {
        case .athletic: "Physical practice compounds faster, but health and opportunity still matter."
        case .entrepreneurial: "Independent work and calculated bets land more often, without bypassing capital."
        case .publicLeadership: "Social leadership and reputation grow faster, without guaranteeing authority."
        case .survivalInstinct: "Recovery and high-pressure choices gain an edge, without erasing consequences."
        }
    }
}

struct PersonalityVector: Codable, Equatable {
    var drive: Int = 50
    var empathy: Int = 50
    var sociability: Int = 50
    var riskTolerance: Int = 50
    var adaptability: Int = 50

    subscript(axis: PersonalityAxis) -> Int {
        get {
            switch axis {
            case .drive: drive
            case .empathy: empathy
            case .sociability: sociability
            case .riskTolerance: riskTolerance
            case .adaptability: adaptability
            }
        }
        set {
            switch axis {
            case .drive: drive = newValue
            case .empathy: empathy = newValue
            case .sociability: sociability = newValue
            case .riskTolerance: riskTolerance = newValue
            case .adaptability: adaptability = newValue
            }
        }
    }

    mutating func clamp() {
        for axis in PersonalityAxis.allCases { self[axis] = min(100, max(0, self[axis])) }
    }

    func applying(_ impulse: PersonalityImpulse, limit: Int = 4) -> PersonalityVector {
        var copy = self
        for axis in PersonalityAxis.allCases {
            copy[axis] += min(limit, max(-limit, impulse[axis]))
        }
        copy.clamp()
        return copy
    }
}

struct PersonalityImpulse: Codable, Equatable {
    var drive = 0
    var empathy = 0
    var sociability = 0
    var riskTolerance = 0
    var adaptability = 0

    static let zero = PersonalityImpulse()
    var isEmpty: Bool { self == .zero }

    subscript(axis: PersonalityAxis) -> Int {
        get {
            switch axis {
            case .drive: drive
            case .empathy: empathy
            case .sociability: sociability
            case .riskTolerance: riskTolerance
            case .adaptability: adaptability
            }
        }
        set {
            switch axis {
            case .drive: drive = newValue
            case .empathy: empathy = newValue
            case .sociability: sociability = newValue
            case .riskTolerance: riskTolerance = newValue
            case .adaptability: adaptability = newValue
            }
        }
    }

    static func + (lhs: PersonalityImpulse, rhs: PersonalityImpulse) -> PersonalityImpulse {
        PersonalityImpulse(
            drive: lhs.drive + rhs.drive,
            empathy: lhs.empathy + rhs.empathy,
            sociability: lhs.sociability + rhs.sociability,
            riskTolerance: lhs.riskTolerance + rhs.riskTolerance,
            adaptability: lhs.adaptability + rhs.adaptability
        )
    }
}

extension PersonalityImpulse {
    private enum CodingKeys: String, CodingKey { case drive, empathy, sociability, riskTolerance, adaptability }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        drive = try c.decodeIfPresent(Int.self, forKey: .drive) ?? 0
        empathy = try c.decodeIfPresent(Int.self, forKey: .empathy) ?? 0
        sociability = try c.decodeIfPresent(Int.self, forKey: .sociability) ?? 0
        riskTolerance = try c.decodeIfPresent(Int.self, forKey: .riskTolerance) ?? 0
        adaptability = try c.decodeIfPresent(Int.self, forKey: .adaptability) ?? 0
    }
}

struct PersonalityDevelopment: Codable, Equatable, Identifiable {
    var id: String { "\(age)-\(axis.rawValue)-\(flag.rawValue)" }
    let age: Int
    let flag: PersonalityFlag
    var previousFlag: PersonalityFlag?
    var axis: PersonalityAxis
    var amount: Int
    let note: String

    init(
        age: Int,
        flag: PersonalityFlag,
        previousFlag: PersonalityFlag? = nil,
        axis: PersonalityAxis? = nil,
        amount: Int = 0,
        note: String
    ) {
        self.age = age
        self.flag = flag
        self.previousFlag = previousFlag
        self.axis = axis ?? flag.axis
        self.amount = amount
        self.note = note
    }
}

extension PersonalityDevelopment {
    private enum CodingKeys: String, CodingKey { case age, flag, previousFlag, axis, amount, note }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        age = try c.decode(Int.self, forKey: .age)
        flag = try c.decode(PersonalityFlag.self, forKey: .flag)
        previousFlag = try c.decodeIfPresent(PersonalityFlag.self, forKey: .previousFlag)
        axis = try c.decodeIfPresent(PersonalityAxis.self, forKey: .axis) ?? flag.axis
        amount = try c.decodeIfPresent(Int.self, forKey: .amount) ?? 0
        note = try c.decode(String.self, forKey: .note)
    }
}

enum IdentitySignatureID: String, Codable, CaseIterable, Identifiable {
    case methodicalBuilder, boldStriver, quietAnchor, socialCaretaker, lonePillar
    case socialCatalyst, bridgeBuilder, groundedKeeper, restlessAdapter, deliberateIndividualist
    case purposeful, grounded, compassionate, independent, expressive, reflective, bold, deliberate, fluid, resolute

    var id: String { rawValue }
}

struct IdentitySignature: Equatable {
    let id: IdentitySignatureID
    let title: String
    let detail: String
    let flags: [PersonalityFlag]
}

struct PersonalityProfile: Codable, Equatable {
    var baseline: PersonalityVector
    var current: PersonalityVector
    var definingTrait: PersonalityFlag
    var talent: SpecialTalent?
    /// One remembered polarity per axis. This makes identity stable near a
    /// threshold without pretending that neutral values express a strong flag.
    var establishedFlags: [PersonalityFlag] = []
    var pendingImpulse: PersonalityImpulse = .zero
    var development: [PersonalityDevelopment] = []

    static let neutral = PersonalityProfile(
        baseline: PersonalityVector(),
        current: PersonalityVector(),
        definingTrait: .adaptable,
        talent: nil
    )

    var activeFlags: [PersonalityFlag] {
        PersonalityAxis.allCases.compactMap { axis in
            PersonalitySystem.activeFlag(
                axis: axis,
                value: current[axis],
                established: establishedFlags.first { $0.axis == axis }
            )
        }
    }

    var salientFlags: [PersonalityFlag] {
        activeFlags
            .map { ($0, abs(current[$0.axis] - 50)) }
            .sorted {
                if $0.1 == $1.1 { return $0.0.rawValue < $1.0.rawValue }
                return $0.1 > $1.1
            }
            .prefix(3)
            .map(\.0)
    }

    func has(_ flag: PersonalityFlag) -> Bool {
        activeFlags.contains(flag)
    }

    var identitySignature: IdentitySignature {
        PersonalitySystem.identitySignature(for: self)
    }

    mutating func refreshEstablishedFlags() {
        establishedFlags = PersonalityAxis.allCases.compactMap { axis in
            PersonalitySystem.activeFlag(
                axis: axis,
                value: current[axis],
                established: establishedFlags.first { $0.axis == axis }
            )
        }
    }

    mutating func clamp() {
        baseline.clamp()
        current.clamp()
        refreshEstablishedFlags()
        development = Array(development.prefix(6))
    }
}

extension PersonalityProfile {
    private enum CodingKeys: String, CodingKey {
        case baseline, current, definingTrait, talent, establishedFlags, pendingImpulse, development
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        baseline = try c.decode(PersonalityVector.self, forKey: .baseline)
        current = try c.decode(PersonalityVector.self, forKey: .current)
        definingTrait = try c.decode(PersonalityFlag.self, forKey: .definingTrait)
        talent = try c.decodeIfPresent(SpecialTalent.self, forKey: .talent)
        establishedFlags = try c.decodeIfPresent([PersonalityFlag].self, forKey: .establishedFlags) ?? []
        pendingImpulse = try c.decodeIfPresent(PersonalityImpulse.self, forKey: .pendingImpulse) ?? .zero
        development = try c.decodeIfPresent([PersonalityDevelopment].self, forKey: .development) ?? []
        if establishedFlags.isEmpty { refreshEstablishedFlags() }
    }
}

enum PersonalitySystem {
    static let activationHigh = 62
    static let activationLow = 38
    static let retentionHigh = 47
    static let retentionLow = 53

    static func flag(for axis: PersonalityAxis, high: Bool) -> PersonalityFlag {
        switch (axis, high) {
        case (.drive, true): .driven
        case (.drive, false): .content
        case (.empathy, true): .empathetic
        case (.empathy, false): .selfReliant
        case (.sociability, true): .outgoing
        case (.sociability, false): .reserved
        case (.riskTolerance, true): .adventurous
        case (.riskTolerance, false): .cautious
        case (.adaptability, true): .adaptable
        case (.adaptability, false): .steadfast
        }
    }

    static func activeFlag(axis: PersonalityAxis, value: Int, established: PersonalityFlag?) -> PersonalityFlag? {
        if value >= activationHigh { return flag(for: axis, high: true) }
        if value <= activationLow { return flag(for: axis, high: false) }
        guard established?.axis == axis else { return nil }
        if established?.favorsHighValue == true, value >= retentionHigh { return established }
        if established?.favorsHighValue == false, value <= retentionLow { return established }
        return nil
    }

    static func generated(
        definingTrait: PersonalityFlag? = nil,
        talent: SpecialTalent? = nil,
        random: inout SeededRandom
    ) -> PersonalityProfile {
        var vector = PersonalityVector(
            drive: centeredRoll(using: &random),
            empathy: centeredRoll(using: &random),
            sociability: centeredRoll(using: &random),
            riskTolerance: centeredRoll(using: &random),
            adaptability: centeredRoll(using: &random)
        )
        let trait = definingTrait ?? {
            let axis = PersonalityAxis.allCases[random.next(in: 0...(PersonalityAxis.allCases.count - 1))]
            return flag(for: axis, high: random.next(in: 0...1) == 1)
        }()
        vector[trait.axis] = trait.favorsHighValue ? max(72, vector[trait.axis]) : min(28, vector[trait.axis])
        vector.clamp()
        var profile = PersonalityProfile(baseline: vector, current: vector, definingTrait: trait, talent: talent)
        profile.refreshEstablishedFlags()
        return profile
    }

    static func legacyPlayer(trait: CoreTrait) -> PersonalityProfile {
        var vector = PersonalityVector()
        let flag: PersonalityFlag
        switch trait {
        case .driven: flag = .driven; vector.drive = 76; vector.riskTolerance = 58
        case .empathetic: flag = .empathetic; vector.empathy = 76; vector.sociability = 58
        case .adaptable: flag = .adaptable; vector.adaptability = 76; vector.drive = 54
        }
        var profile = PersonalityProfile(baseline: vector, current: vector, definingTrait: flag, talent: nil)
        profile.refreshEstablishedFlags()
        return profile
    }

    static func legacyPartner(flags: [PartnerFlag]) -> PersonalityProfile {
        var vector = PersonalityVector()
        for flag in flags {
            switch flag {
            case .demanding: vector.drive += 18; vector.empathy -= 8
            case .loyal: vector.empathy += 15; vector.adaptability -= 8
            case .independent: vector.sociability -= 16; vector.empathy -= 4
            case .supportive: vector.empathy += 18; vector.adaptability += 5
            case .adventurous: vector.riskTolerance += 20; vector.sociability += 5
            case .cautious: vector.riskTolerance -= 20; vector.adaptability -= 4
            case .secure, .guarded: break
            }
        }
        vector.clamp()
        let defining = mostSalientFlag(in: vector)
        var profile = PersonalityProfile(baseline: vector, current: vector, definingTrait: defining, talent: nil)
        profile.refreshEstablishedFlags()
        return profile
    }

    static func legacyNPC(flags: [NPCFlag]) -> PersonalityProfile {
        var vector = PersonalityVector()
        for flag in flags {
            switch flag {
            case .sociable: vector.sociability += 22
            case .dependable: vector.adaptability -= 14; vector.empathy += 8
            case .critical: vector.empathy -= 18; vector.drive += 10
            case .encouraging: vector.empathy += 20; vector.sociability += 6
            case .ambitious: vector.drive += 22; vector.riskTolerance += 6
            case .fair: vector.empathy += 10; vector.adaptability -= 8
            }
        }
        vector.clamp()
        var profile = PersonalityProfile(
            baseline: vector,
            current: vector,
            definingTrait: mostSalientFlag(in: vector),
            talent: nil
        )
        profile.refreshEstablishedFlags()
        return profile
    }

    static func record(_ impulse: PersonalityImpulse, profile: inout PersonalityProfile) {
        profile.pendingImpulse = profile.pendingImpulse + impulse
    }

    /// Acting against an established tendency is deliberate development, so
    /// it leaves a slightly stronger trace than repeating an existing habit.
    static func developmentImpulse(_ impulse: PersonalityImpulse, for profile: PersonalityProfile) -> PersonalityImpulse {
        var result = impulse
        for axis in PersonalityAxis.allCases {
            let amount = impulse[axis]
            guard amount != 0,
                  let established = profile.establishedFlags.first(where: { $0.axis == axis }) else { continue }
            let movesHigh = amount > 0
            if movesHigh != established.favorsHighValue {
                result[axis] += amount > 0 ? 1 : -1
            }
        }
        return result
    }

    @discardableResult
    static func resolveYear(profile: inout PersonalityProfile, age: Int) -> PersonalityDevelopment? {
        guard !profile.pendingImpulse.isEmpty else { return nil }
        let before = profile.activeFlags
        let prior = profile.current
        var yearlyImpulse = profile.pendingImpulse
        let definingAxis = profile.definingTrait.axis
        let definingAmount = yearlyImpulse[definingAxis]
        let movesAwayFromCore = definingAmount != 0
            && (definingAmount > 0) != profile.definingTrait.favorsHighValue
        if movesAwayFromCore {
            let resistance = min(1, abs(definingAmount))
            yearlyImpulse[definingAxis] += definingAmount > 0 ? -resistance : resistance
        }
        profile.current = profile.current.applying(yearlyImpulse)
        profile.pendingImpulse = .zero
        profile.refreshEstablishedFlags()
        let after = profile.activeFlags
        let changedAxis = PersonalityAxis.allCases.max {
            abs(profile.current[$0] - prior[$0]) < abs(profile.current[$1] - prior[$1])
        } ?? .adaptability
        let amount = profile.current[changedAxis] - prior[changedAxis]
        let gained = after.first { !before.contains($0) }
        let lost = before.first { !after.contains($0) && $0.axis == changedAxis }
        guard let visibleFlag = gained ?? after.first(where: { $0.axis == changedAxis }) ?? lost,
              gained != nil || lost != nil || abs(amount) >= 3 else { return nil }
        let note: String
        if let gained {
            note = "Repeated choices established a more \(gained.title.lowercased()) pattern."
        } else if let lost {
            note = "Your \(lost.title.lowercased()) pattern softened toward the middle."
        } else {
            note = "Repeated choices shifted your \(changedAxis.title.lowercased()) \(amount > 0 ? "up" : "down")."
        }
        let change = PersonalityDevelopment(
            age: age,
            flag: visibleFlag,
            previousFlag: lost,
            axis: changedAxis,
            amount: amount,
            note: note
        )
        profile.development.insert(change, at: 0)
        profile.development = Array(profile.development.prefix(6))
        return change
    }

    static func identitySignature(for profile: PersonalityProfile) -> IdentitySignature {
        let active = Set(profile.activeFlags)
        let compounds: [(IdentitySignatureID, String, String, [PersonalityFlag])] = [
            (.methodicalBuilder, "Methodical builder", "Ambition moves through preparation, buffers, and controlled bets.", [.driven, .cautious]),
            (.boldStriver, "Bold striver", "Ambition and appetite for risk can open doors—and expose weak footing.", [.driven, .adventurous]),
            (.quietAnchor, "Quiet anchor", "Care is expressed through steadiness and close, low-noise loyalty.", [.empathetic, .reserved]),
            (.socialCaretaker, "Social caretaker", "Connection comes easily, and other people’s needs are hard to ignore.", [.empathetic, .outgoing]),
            (.lonePillar, "Lone pillar", "Independence and constancy make you reliable, but difficult to reach.", [.selfReliant, .steadfast]),
            (.socialCatalyst, "Social catalyst", "Energy and risk tolerance turn rooms, groups, and chances into momentum.", [.outgoing, .adventurous]),
            (.bridgeBuilder, "Bridge builder", "Empathy and flexibility help you translate between people under strain.", [.empathetic, .adaptable]),
            (.groundedKeeper, "Grounded keeper", "Enoughness and constancy protect what already matters.", [.content, .steadfast]),
            (.restlessAdapter, "Restless adapter", "Change is fuel; reinvention comes easier than staying put.", [.adventurous, .adaptable]),
            (.deliberateIndividualist, "Deliberate individualist", "Caution and self-reliance favor private plans over borrowed certainty.", [.selfReliant, .cautious])
        ]
        if let match = compounds.first(where: { Set($0.3).isSubset(of: active) }) {
            return IdentitySignature(id: match.0, title: match.1, detail: match.2, flags: match.3)
        }
        let fallbackFlag = profile.salientFlags.first ?? profile.definingTrait
        let fallback: (IdentitySignatureID, String, String)
        switch fallbackFlag {
        case .driven: fallback = (.purposeful, "Purposeful", "Progress and visible effort pull harder than comfort.")
        case .content: fallback = (.grounded, "Grounded", "Enoughness and a sustainable pace matter more than constant ascent.")
        case .empathetic: fallback = (.compassionate, "Compassionate", "Other people’s feelings register quickly and shape the next move.")
        case .selfReliant: fallback = (.independent, "Independent", "Private judgment and self-sufficiency carry unusual weight.")
        case .outgoing: fallback = (.expressive, "Expressive", "People and shared energy are a natural source of momentum.")
        case .reserved: fallback = (.reflective, "Reflective", "Depth, privacy, and a smaller social radius protect attention.")
        case .adventurous: fallback = (.bold, "Bold", "Uncertainty feels usable when the possible upside is alive.")
        case .cautious: fallback = (.deliberate, "Deliberate", "Preparation and downside protection come before speed.")
        case .adaptable: fallback = (.fluid, "Fluid", "Changing conditions invite adjustment more than resistance.")
        case .steadfast: fallback = (.resolute, "Resolute", "Consistency and held commitments outlast passing pressure.")
        }
        return IdentitySignature(id: fallback.0, title: fallback.1, detail: fallback.2, flags: [fallbackFlag])
    }

    static func requiredFlags(for signature: IdentitySignatureID) -> [PersonalityFlag] {
        switch signature {
        case .methodicalBuilder: [.driven, .cautious]
        case .boldStriver: [.driven, .adventurous]
        case .quietAnchor: [.empathetic, .reserved]
        case .socialCaretaker: [.empathetic, .outgoing]
        case .lonePillar: [.selfReliant, .steadfast]
        case .socialCatalyst: [.outgoing, .adventurous]
        case .bridgeBuilder: [.empathetic, .adaptable]
        case .groundedKeeper: [.content, .steadfast]
        case .restlessAdapter: [.adventurous, .adaptable]
        case .deliberateIndividualist: [.selfReliant, .cautious]
        case .purposeful: [.driven]
        case .grounded: [.content]
        case .compassionate: [.empathetic]
        case .independent: [.selfReliant]
        case .expressive: [.outgoing]
        case .reflective: [.reserved]
        case .bold: [.adventurous]
        case .deliberate: [.cautious]
        case .fluid: [.adaptable]
        case .resolute: [.steadfast]
        }
    }

    static func compatibility(_ lhs: PersonalityProfile, _ rhs: PersonalityProfile) -> Int {
        let distance = PersonalityAxis.allCases.reduce(0) { $0 + abs(lhs.current[$1] - rhs.current[$1]) }
        return min(100, max(0, 100 - distance / PersonalityAxis.allCases.count))
    }

    private static func centeredRoll(using random: inout SeededRandom) -> Int {
        (random.next(in: 25...75) + random.next(in: 25...75)) / 2
    }

    private static func mostSalientFlag(in vector: PersonalityVector) -> PersonalityFlag {
        let axis = PersonalityAxis.allCases.max {
            abs(vector[$0] - 50) < abs(vector[$1] - 50)
        } ?? .adaptability
        return flag(for: axis, high: vector[axis] >= 50)
    }
}

// MARK: - Stable character texture and quiet goals

enum CharacterTagSystem {
    static func generated(
        for personality: PersonalityProfile,
        random: inout SeededRandom
    ) -> [CharacterTag] {
        let vector = personality.current
        var candidates: [CharacterTag] = []

        if vector.empathy >= 55 { candidates += [.loyal, .forgiving, .protective, .generous, .familyOriented] }
        if vector.empathy <= 45 { candidates += [.competitive, .materialistic, .opportunistic, .vindictive] }
        if vector.drive >= 58 { candidates += [.competitive, .statusSeeking, .dutyBound, .approvalSeeking] }
        if vector.drive <= 42 { candidates += [.patient, .familyOriented] }
        if vector.riskTolerance >= 58 { candidates += [.impulsive, .opportunistic, .curious, .creative] }
        if vector.riskTolerance <= 42 { candidates += [.patient, .principled, .dutyBound] }
        if vector.sociability >= 58 { candidates += [.approvalSeeking, .generous, .controlling] }
        if vector.sociability <= 42 { candidates += [.privatePerson, .honest, .creative] }
        if vector.adaptability >= 58 { candidates += [.curious, .forgiving, .creative] }
        if vector.adaptability <= 42 { candidates += [.loyal, .principled, .vindictive, .dutyBound] }

        if candidates.count < 4 { candidates += CharacterTag.allCases }

        var pool = Array(Set(candidates)).sorted { $0.rawValue < $1.rawValue }
        let targetCount = 2 + random.next(in: 0...2)
        var selected: [CharacterTag] = []
        while !pool.isEmpty, selected.count < targetCount {
            let index = random.next(in: 0...(pool.count - 1))
            let candidate = pool.remove(at: index)
            guard selected.allSatisfy({ !$0.incompatibleTags.contains(candidate) }) else { continue }
            selected.append(candidate)
        }
        return selected.sorted { $0.rawValue < $1.rawValue }
    }

    static func backfill(member: inout NPCState, runSeed: UInt64) {
        var random = SimulationRandomStreams.npcStream(
            runSeed: runSeed,
            identity: "character-tags-\(member.memberID)"
        )
        if member.stableTags.isEmpty {
            member.stableTags = generated(for: member.personality, random: &random)
        }
        if member.goals.isEmpty {
            member.goals = NPCGoalSystem.initialGoals(
                personality: member.personality,
                tags: member.stableTags,
                age: member.lastInteractionAge,
                random: &random
            )
        }
        if member.connections.isEmpty {
            member.connections = [NPCConnection(
                kind: connectionKind(for: member.role),
                startedAge: member.lastInteractionAge,
                endedAge: nil
            )]
        }
        member.clamp()
    }

    static func areCompatible(_ tags: [CharacterTag]) -> Bool {
        tags.allSatisfy { tag in tags.allSatisfy { other in !tag.incompatibleTags.contains(other) } }
    }

    static func connectionKind(for role: NPCRole) -> NPCConnectionKind {
        switch role {
        case .friend: .friend
        case .teacher: .mentor
        case .boss: .manager
        }
    }
}

enum NPCGoalSystem {
    static func initialGoals(
        personality: PersonalityProfile,
        tags: [CharacterTag],
        age: Int,
        random: inout SeededRandom
    ) -> [NPCGoalState] {
        var candidates: [NPCGoalKind] = []
        if personality.current.drive >= 55 { candidates += [.careerProgress, .status] }
        if personality.current.riskTolerance >= 58 { candidates += [.adventure, .creativeAchievement] }
        if personality.current.riskTolerance <= 42 { candidates += [.financialSecurity, .stability] }
        if personality.current.empathy >= 55 { candidates += [.family, .belonging] }
        if tags.contains(.familyOriented) { candidates += [.family] }
        if tags.contains(.materialistic) { candidates += [.financialSecurity] }
        if tags.contains(.creative) { candidates += [.creativeAchievement] }
        if tags.contains(.statusSeeking) { candidates += [.status] }
        if candidates.isEmpty { candidates = [.stability, .belonging] }

        var pool = Array(Set(candidates)).sorted { $0.rawValue < $1.rawValue }
        let count = min(pool.count, random.next(in: 1...2))
        var goals: [NPCGoalState] = []
        while !pool.isEmpty, goals.count < count {
            let index = random.next(in: 0...(pool.count - 1))
            let kind = pool.remove(at: index)
            goals.append(NPCGoalState(
                kind: kind,
                progress: random.next(in: 15...45),
                momentum: 0,
                lastResolvedAge: age
            ))
        }
        return goals.sorted { $0.kind.rawValue < $1.kind.rawValue }
    }

    static func advance(
        member: inout NPCState,
        age: Int,
        random: inout SeededRandom
    ) -> NPCGoalKind? {
        guard !member.goals.isEmpty else { return nil }
        let index = random.next(in: 0...(member.goals.count - 1))
        var goal = member.goals[index]
        let prior = goal.progress
        let circumstancePenalty = member.currentCircumstance.map { circumstance in
            [.stressed, .grieving, .financiallyStrained, .burnedOut].contains(circumstance.kind)
                ? circumstance.intensity * 2 : 0
        } ?? 0
        let driveBonus = max(-2, min(4, (member.personality.current.drive - 50) / 10))
        let tagBonus = goalTagBonus(goal.kind, tags: member.stableTags)
        let change = random.next(in: 1...6) + driveBonus + tagBonus - circumstancePenalty
        goal.momentum = change
        goal.progress += change
        goal.lastResolvedAge = age
        goal.clamp()
        member.goals[index] = goal
        return prior < 100 && goal.progress == 100 ? goal.kind : nil
    }

    private static func goalTagBonus(_ goal: NPCGoalKind, tags: [CharacterTag]) -> Int {
        switch goal {
        case .careerProgress: tags.contains(.dutyBound) || tags.contains(.competitive) ? 2 : 0
        case .financialSecurity: tags.contains(.materialistic) || tags.contains(.patient) ? 2 : 0
        case .family: tags.contains(.familyOriented) || tags.contains(.protective) ? 2 : 0
        case .status: tags.contains(.statusSeeking) || tags.contains(.approvalSeeking) ? 2 : 0
        case .creativeAchievement: tags.contains(.creative) || tags.contains(.curious) ? 2 : 0
        case .stability: tags.contains(.patient) || tags.contains(.dutyBound) ? 2 : 0
        case .adventure: tags.contains(.impulsive) || tags.contains(.curious) ? 2 : 0
        case .belonging: tags.contains(.loyal) || tags.contains(.generous) ? 2 : 0
        }
    }
}

// MARK: - Stable random lanes

struct SimulationRandomStreams: Codable, Equatable {
    var generation: SeededRandom
    var action: SeededRandom
    var career: SeededRandom
    var finance: SeededRandom
    var family: SeededRandom
    var health: SeededRandom
    var mortality: SeededRandom
    var personality: SeededRandom
    var social: SeededRandom
    var event: SeededRandom
    var narrative: SeededRandom

    init(runSeed: UInt64) {
        generation = SeededRandom(seed: Self.derive(runSeed, salt: 1))
        action = SeededRandom(seed: Self.derive(runSeed, salt: 2))
        career = SeededRandom(seed: Self.derive(runSeed, salt: 3))
        finance = SeededRandom(seed: Self.derive(runSeed, salt: 4))
        family = SeededRandom(seed: Self.derive(runSeed, salt: 5))
        health = SeededRandom(seed: Self.derive(runSeed, salt: 6))
        mortality = SeededRandom(seed: Self.derive(runSeed, salt: 7))
        personality = SeededRandom(seed: Self.derive(runSeed, salt: 8))
        social = SeededRandom(seed: Self.derive(runSeed, salt: 9))
        event = SeededRandom(seed: Self.derive(runSeed, salt: 10))
        narrative = SeededRandom(seed: Self.derive(runSeed, salt: 11))
    }

    static func npcStream(runSeed: UInt64, identity: String) -> SeededRandom {
        let hash = identity.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
        return SeededRandom(seed: derive(runSeed ^ hash, salt: 97))
    }

    private static func derive(_ seed: UInt64, salt: UInt64) -> UInt64 {
        var value = seed ^ (salt &* 0x9E37_79B9_7F4A_7C15)
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}

// MARK: - Unified read-only rule signals

enum SimulationRole: String, Codable, CaseIterable {
    case partner, friend, teacher, boss

    var npcRole: NPCRole? {
        switch self {
        case .partner: nil
        case .friend: .friend
        case .teacher: .teacher
        case .boss: .boss
        }
    }
}

enum RelationshipSignalStance: String, Codable, CaseIterable {
    case warm, wary, secure, guarded
}

enum ContentDomainState: String, Codable, CaseIterable {
    case attendsSchool, employed, partnered, inRecovery, hasDebt, hasDependents, hasCondition

    func matches(_ state: LifeState) -> Bool {
        switch self {
        case .attendsSchool: state.flags.attendsSchool
        case .employed: state.flags.hasJob
        case .partnered: state.partner != nil
        case .inRecovery: state.recovery != nil
        case .hasDebt: state.finance.totalDebt > 0
        case .hasDependents: state.family.dependentLoad > 0
        case .hasCondition: !state.health.conditions.isEmpty
        }
    }
}

struct SimulationSignalSnapshot: Equatable {
    let player: PersonalityProfile
    let identitySignature: IdentitySignatureID
    let npc: PersonalityProfile?
    let role: SimulationRole?
    let relationshipStance: RelationshipSignalStance?
    let talent: SpecialTalent?
    let worldFlags: Set<WorldFlag>
    let lifeStage: LifeStage
    let stats: LifeStats

    init(state: LifeState, npc: NPCState? = nil) {
        player = state.personality
        identitySignature = state.personality.identitySignature.id
        self.npc = npc?.personality ?? state.partner?.personality
        role = npc.map { SimulationRole(rawValue: $0.role.rawValue)! } ?? (state.partner == nil ? nil : .partner)
        if let stance = npc?.learnedStance {
            relationshipStance = stance == .warm ? .warm : .wary
        } else if state.partner?.flags.contains(.secure) == true {
            relationshipStance = .secure
        } else if state.partner?.flags.contains(.guarded) == true {
            relationshipStance = .guarded
        } else {
            relationshipStance = nil
        }
        talent = state.personality.talent
        worldFlags = state.world.flags
        lifeStage = state.lifeStage
        stats = state.stats
    }
}

struct ReactionPredicate: Codable, Equatable {
    var playerFlags: [PersonalityFlag] = []
    var npcFlags: [PersonalityFlag] = []
    var identitySignatures: [IdentitySignatureID] = []
    var talent: SpecialTalent?
    var role: SimulationRole?
    var relationshipStance: RelationshipSignalStance?
    var worldFlags: [WorldFlag] = []

    func matches(_ signals: SimulationSignalSnapshot) -> Bool {
        playerFlags.allSatisfy(signals.player.has)
            && npcFlags.allSatisfy { signals.npc?.has($0) == true }
            && (identitySignatures.isEmpty || identitySignatures.contains(signals.identitySignature))
            && talent.map { signals.talent == $0 } ?? true
            && role.map { signals.role == $0 } ?? true
            && relationshipStance.map { signals.relationshipStance == $0 } ?? true
            && worldFlags.allSatisfy { signals.worldFlags.contains($0) }
    }

    /// Higher scores represent narrower rules. Resolution never depends on
    /// declaration order; ties fall back to the stable rule ID.
    var specificity: Int {
        identitySignatures.count * 20
            + playerFlags.count * 10
            + npcFlags.count * 10
            + worldFlags.count * 6
            + (talent == nil ? 0 : 8)
            + (role == nil ? 0 : 4)
            + (relationshipStance == nil ? 0 : 3)
    }
}

enum ReactionChannel: String, Codable, CaseIterable {
    case playerPersonality
    case npcOrPartner
    case world
    case talent

    var title: String {
        switch self {
        case .playerPersonality: "Identity"
        case .npcOrPartner: "Relationship"
        case .world: "World"
        case .talent: "Talent"
        }
    }
}

struct ReactionImpact: Codable, Equatable {
    var effects: EffectRange = EffectRange()
    /// Signed normalized money units. One unit is resolved against the
    /// current cost of living instead of becoming irrelevant in adult life.
    var cashUnits = 0
    var partner: PartnerEffect = PartnerEffect()
    var rapport = 0

    var benefitUnits: Int {
        positive(effects.school) + positive(effects.cash) + positive(effects.love)
            + positive(effects.play) + positive(effects.health) + positive(effects.looks)
            + positive(effects.rep) + max(0, cashUnits) + max(0, partner.bond)
            + max(0, -partner.resentment) + max(0, rapport)
    }

    var costUnits: Int {
        negative(effects.school) + negative(effects.cash) + negative(effects.love)
            + negative(effects.play) + negative(effects.health) + negative(effects.looks)
            + negative(effects.rep) + max(0, -cashUnits) + max(0, -partner.bond)
            + max(0, partner.resentment) + max(0, -rapport)
    }

    private func positive(_ range: ClosedRange<Int>) -> Int { max(0, range.upperBound) }
    private func negative(_ range: ClosedRange<Int>) -> Int { max(0, -range.lowerBound) }
}

enum ReactionBalancePolicy {
    static let standardPersonalityBudget = 3
    static let compoundPersonalityBudget = 5
    static let socialBudget = 2
    static let combinedBenefitBudget = 6

    static func cashUnit(in state: LifeState) -> Int {
        let cost = state.finance.annualLedger.livingCosts > 0 ? state.finance.annualLedger.livingCosts : EconomyCalculator.essentialCost(state, world: WorldSystem.modifiers(for: state.world))
        return max(100, EconomyPolicy.rate(cost, 250))
    }

    static func resolvedEffects(for impact: ReactionImpact, state: LifeState) -> EffectRange {
        impact.effects.shifted(cash: impact.cashUnits * cashUnit(in: state))
    }

    static func isWithinChannelBudget(_ rule: ReactionRule) -> Bool {
        switch rule.channel {
        case .playerPersonality:
            let limit = rule.isCompoundIdentity ? compoundPersonalityBudget : standardPersonalityBudget
            return rule.impact.benefitUnits + rule.impact.costUnits <= limit
        case .npcOrPartner:
            return rule.impact.benefitUnits + rule.impact.costUnits <= socialBudget
        case .world, .talent:
            return rule.impact.benefitUnits + rule.impact.costUnits <= 2
        }
    }
}

struct ReactionRule: Codable, Equatable, Identifiable {
    let id: String
    var actionIDs: [ActionID]
    var predicate: ReactionPredicate
    var channel: ReactionChannel
    var impact: ReactionImpact
    var isCompoundIdentity = false
    var personalityImpulse: PersonalityImpulse = .zero
    var headline: String
    var narrative: String
    var previewHint: String
    var cause: String = ""

    init(
        id: String,
        actionIDs: [ActionID],
        predicate: ReactionPredicate,
        channel: ReactionChannel,
        modifier: EffectRange = EffectRange(),
        cashUnits: Int = 0,
        partnerModifier: PartnerEffect = PartnerEffect(),
        personalityImpulse: PersonalityImpulse = .zero,
        rapportDelta: Int = 0,
        isCompoundIdentity: Bool = false,
        headline: String,
        narrative: String,
        previewHint: String,
        cause: String = ""
    ) {
        self.id = id
        self.actionIDs = actionIDs
        self.predicate = predicate
        self.channel = channel
        impact = ReactionImpact(effects: modifier, cashUnits: cashUnits, partner: partnerModifier, rapport: rapportDelta)
        self.isCompoundIdentity = isCompoundIdentity
        self.personalityImpulse = personalityImpulse
        self.headline = headline
        self.narrative = narrative
        self.previewHint = previewHint
        self.cause = cause
    }

    var modifier: EffectRange { impact.effects }
    var partnerModifier: PartnerEffect { impact.partner }
    var rapportDelta: Int { impact.rapport }

    func matches(action: ActionID, signals: SimulationSignalSnapshot) -> Bool {
        (actionIDs.isEmpty || actionIDs.contains(action)) && predicate.matches(signals)
    }
}

enum UnifiedReactionRegistry {
    static let rules: [ReactionRule] = coreRules + partnerDepthRules + npcDepthRules + worldDepthRules

    private static let coreRules: [ReactionRule] = [
        ReactionRule(
            id: "methodical-builder-compounds",
            actionIDs: [.budget, .developSkill, .pursuePromotion, .payDebt],
            predicate: ReactionPredicate(identitySignatures: [.methodicalBuilder]),
            channel: .playerPersonality,
            modifier: EffectRange(health: -2 ... -2, rep: 2...2),
            cashUnits: 1,
            personalityImpulse: PersonalityImpulse(drive: 1, riskTolerance: -1),
            isCompoundIdentity: true,
            headline: "Preparation Turned Into Quiet Leverage",
            narrative: "Your methodical ambition found an advantage, while the vigilance still cost energy.",
            previewHint: "Preparation improves the return, with a small stress cost.",
            cause: "Methodical builder"
        ),
        ReactionRule(
            id: "quiet-anchor-shows-up",
            actionIDs: [.reachOut, .repairConflict, .familyDinner, .caregiving, .parentingPresence],
            predicate: ReactionPredicate(identitySignatures: [.quietAnchor]),
            channel: .playerPersonality,
            modifier: EffectRange(love: 3...3, health: -2 ... -2),
            personalityImpulse: PersonalityImpulse(empathy: 1, sociability: -1),
            isCompoundIdentity: true,
            headline: "Quiet Care Carried Real Weight",
            narrative: "You stayed close without making a performance of it, deepening trust and carrying some strain home.",
            previewHint: "Private care lands deeply but takes something out of you.",
            cause: "Quiet anchor"
        ),
        ReactionRule(
            id: "social-catalyst-momentum",
            actionIDs: [.findYourPeople, .commitActivity, .networkContacts, .seeFriends, .party],
            predicate: ReactionPredicate(identitySignatures: [.socialCatalyst]),
            channel: .playerPersonality,
            modifier: EffectRange(love: 1...1, play: 1...1, health: -2 ... -2, rep: 1...1),
            personalityImpulse: PersonalityImpulse(sociability: 1, riskTolerance: 1),
            isCompoundIdentity: true,
            headline: "The Room Gathered Around You",
            narrative: "Your appetite for people and uncertainty created momentum, along with a little wear.",
            previewHint: "Social momentum grows faster, with a small energy cost.",
            cause: "Social catalyst"
        ),
        ReactionRule(
            id: "driven-effort-compounds",
            actionIDs: [.focusGrades, .study, .attendClass, .skillCourse, .workShift, .developSkill, .pursuePromotion],
            predicate: ReactionPredicate(playerFlags: [.driven]),
            channel: .playerPersonality,
            modifier: EffectRange(school: 2...2, health: -1 ... -1),
            personalityImpulse: PersonalityImpulse(drive: 1),
            headline: "Effort Compounded Beyond The Task",
            narrative: "Your drive extracted more progress, while making it harder to leave the work untouched.",
            previewHint: "Drive improves progress and reputation, with a stress cost.",
            cause: "Driven tendency"
        ),
        ReactionRule(
            id: "content-protects-pace",
            actionIDs: [.quietNight, .pursueHobby, .protectBoundaries, .rest, .familyDinner, .cutBack],
            predicate: ReactionPredicate(playerFlags: [.content]),
            channel: .playerPersonality,
            modifier: EffectRange(play: 1...1, health: 1...1, rep: -1 ... -1),
            personalityImpulse: PersonalityImpulse(drive: -1),
            headline: "Enough Was A Real Decision",
            narrative: "You protected a sustainable pace, even if someone else read it as a lack of hunger.",
            previewHint: "Contentment improves recovery but can soften outside momentum.",
            cause: "Content tendency"
        ),
        ReactionRule(
            id: "empathetic-care-costs",
            actionIDs: [.helpAtHome, .reachOut, .repairConflict, .familyDinner, .caregiving, .parentingPresence, .therapySupport, .chooseCareService],
            predicate: ReactionPredicate(playerFlags: [.empathetic]),
            channel: .playerPersonality,
            modifier: EffectRange(love: 2...2, health: -1 ... -1),
            personalityImpulse: PersonalityImpulse(empathy: 1),
            headline: "You Felt The Need First",
            narrative: "Your empathy made the care more precise and the emotional cost harder to avoid.",
            previewHint: "Empathy strengthens connection while absorbing strain.",
            cause: "Empathetic tendency"
        ),
        ReactionRule(
            id: "self-reliant-carries-load",
            actionIDs: [.budget, .cutBack, .workShift, .sideHustle, .protectBoundaries, .payDebt, .sellOrDownsize],
            predicate: ReactionPredicate(playerFlags: [.selfReliant]),
            channel: .playerPersonality,
            modifier: EffectRange(love: -1 ... -1),
            cashUnits: 2,
            personalityImpulse: PersonalityImpulse(empathy: -1),
            headline: "You Carried It Without Asking",
            narrative: "Self-reliance protected the numbers while making support easier to miss.",
            previewHint: "Independence improves control but can create distance.",
            cause: "Self-reliant tendency"
        ),
        ReactionRule(
            id: "outgoing-social-lift",
            actionIDs: [.findYourPeople, .commitActivity, .joinClub, .networkContacts, .goOnDate, .seeFriends, .party],
            predicate: ReactionPredicate(playerFlags: [.outgoing]),
            channel: .playerPersonality,
            modifier: EffectRange(love: 1...1, rep: 1...1),
            cashUnits: -1,
            personalityImpulse: PersonalityImpulse(sociability: 1),
            headline: "People Became Part Of Momentum",
            narrative: "Your outgoing nature made access and belonging easier, though participation was not free.",
            previewHint: "Sociability boosts connection and visibility at a small cost.",
            cause: "Outgoing tendency"
        ),
        ReactionRule(
            id: "reserved-focus-deepens",
            actionIDs: [.focusGrades, .study, .pursueHobby, .quietNight, .skillCourse, .developSkill, .preventiveCare],
            predicate: ReactionPredicate(playerFlags: [.reserved]),
            channel: .playerPersonality,
            modifier: EffectRange(school: 2...2, love: -1 ... -1),
            personalityImpulse: PersonalityImpulse(sociability: -1),
            headline: "Solitude Made The Work Deeper",
            narrative: "Privacy protected your concentration, while the social world moved a little farther away.",
            previewHint: "Reserve improves depth but reduces connection.",
            cause: "Reserved tendency"
        ),
        ReactionRule(
            id: "adventurous-opportunity-risk",
            actionIDs: [.findYourPeople, .goOnDate, .party, .sideHustle, .chooseFreelance, .changeCareer],
            predicate: ReactionPredicate(playerFlags: [.adventurous]),
            channel: .playerPersonality,
            modifier: EffectRange(play: 1...1, health: -1 ... -1, rep: 1...1),
            personalityImpulse: PersonalityImpulse(riskTolerance: 1),
            headline: "Uncertainty Opened A Wider Door",
            narrative: "Risk tolerance widened the upside and made the bodily cost easier to discount.",
            previewHint: "Adventure improves opportunity and fun, with real downside.",
            cause: "Adventurous tendency"
        ),
        ReactionRule(
            id: "cautious-builds-buffer",
            actionIDs: [.helpAtHome, .budget, .cutBack, .preventiveCare, .jobSearch, .payDebt, .adjustRetirement],
            predicate: ReactionPredicate(playerFlags: [.cautious]),
            channel: .playerPersonality,
            modifier: EffectRange(play: -1 ... -1, health: 1...1),
            cashUnits: 1,
            personalityImpulse: PersonalityImpulse(riskTolerance: -1),
            headline: "Preparation Bought A Little Room",
            narrative: "Caution reduced exposure, though some of the present was traded for protection.",
            previewHint: "Caution builds a buffer at the cost of spontaneity.",
            cause: "Cautious tendency"
        ),
        ReactionRule(
            id: "adaptable-finds-pivot",
            actionIDs: [.findYourPeople, .changeCareer, .jobSearch, .returnToEducation, .applyToCollege, .separate, .sellOrDownsize],
            predicate: ReactionPredicate(playerFlags: [.adaptable]),
            channel: .playerPersonality,
            modifier: EffectRange(school: 1...1, rep: 1...1),
            cashUnits: -1,
            personalityImpulse: PersonalityImpulse(adaptability: 1),
            headline: "The Pivot Found Usable Ground",
            narrative: "Adaptability shortened the distance between disruption and a workable next move.",
            previewHint: "Adaptability improves pivots, though transitions still cost money.",
            cause: "Adaptable tendency"
        ),
        ReactionRule(
            id: "steadfast-routine-holds",
            actionIDs: [.exercise, .attendClass, .workShift, .developSkill, .parentingPresence, .manageCondition, .preventiveCare],
            predicate: ReactionPredicate(playerFlags: [.steadfast]),
            channel: .playerPersonality,
            modifier: EffectRange(play: -1 ... -1, health: 1...1, rep: 1...1),
            personalityImpulse: PersonalityImpulse(adaptability: -1),
            headline: "Routine Held When Motivation Did Not",
            narrative: "Steadfastness protected the commitment, even when repetition narrowed the day.",
            previewHint: "Steadfastness improves consistency but costs flexibility.",
            cause: "Steadfast tendency"
        ),
        ReactionRule(
            id: "partner-cautious-risk",
            actionIDs: [.party, .sideHustle, .chooseFreelance],
            predicate: ReactionPredicate(npcFlags: [.cautious], role: .partner),
            channel: .npcOrPartner,
            partnerModifier: PartnerEffect(bond: -1, resentment: 1),
            headline: "Risk Landed Harder At Home",
            narrative: "Their cautious nature made the uncertainty feel personal.",
            previewHint: "A cautious partner feels this risk more sharply.",
            cause: "Cautious partner"
        ),
        ReactionRule(
            id: "partner-empathetic-connection",
            actionIDs: [.reachOut, .goOnDate, .repairConflict, .familyDinner],
            predicate: ReactionPredicate(npcFlags: [.empathetic], role: .partner),
            channel: .npcOrPartner,
            partnerModifier: PartnerEffect(bond: 1, resentment: -1),
            headline: "Care Met Care",
            narrative: "Their empathy gave the gesture somewhere soft to land.",
            previewHint: "An empathetic partner responds to visible care.",
            cause: "Empathetic partner"
        ),
        ReactionRule(
            id: "teacher-driven-study",
            actionIDs: [.focusGrades, .study, .attendClass],
            predicate: ReactionPredicate(npcFlags: [.driven], role: .teacher),
            channel: .npcOrPartner,
            modifier: EffectRange(school: 1...1),
            rapportDelta: 1,
            headline: "Your Teacher Matched The Effort",
            narrative: "Their drive turned visible work into higher expectations and real attention.",
            previewHint: "A driven teacher notices sustained effort.",
            cause: "Driven teacher"
        ),
        ReactionRule(
            id: "friend-outgoing-social",
            actionIDs: [.findYourPeople, .commitActivity, .seeFriends, .party],
            predicate: ReactionPredicate(npcFlags: [.outgoing], role: .friend),
            channel: .npcOrPartner,
            modifier: EffectRange(love: 1...1),
            rapportDelta: 1,
            headline: "Your Friend Opened The Room",
            narrative: "Their outgoing nature made belonging easier without making it automatic.",
            previewHint: "An outgoing friend amplifies social time.",
            cause: "Outgoing friend"
        ),
        ReactionRule(
            id: "boss-driven-work",
            actionIDs: [.workShift, .pursuePromotion, .developSkill],
            predicate: ReactionPredicate(npcFlags: [.driven], role: .boss),
            channel: .npcOrPartner,
            modifier: EffectRange(rep: 1...1),
            rapportDelta: 1,
            headline: "Your Boss Saw Momentum",
            narrative: "Their drive made results more legible than promises.",
            previewHint: "A driven boss rewards visible progress.",
            cause: "Driven boss"
        ),
        ReactionRule(
            id: "recession-survival-instinct",
            actionIDs: [.jobSearch, .protectBoundaries, .cutBack],
            predicate: ReactionPredicate(talent: .survivalInstinct, worldFlags: [.recession]),
            channel: .talent,
            modifier: EffectRange(health: 1...1),
            personalityImpulse: PersonalityImpulse(adaptability: 1),
            headline: "Pressure Found An Old Instinct",
            narrative: "The recession narrowed the options; your survival instinct found usable ground.",
            previewHint: "Survival instinct helps under recession pressure.",
            cause: "Survival instinct · Recession"
        )
    ]

    private struct FlagReactionTemplate {
        let aligned: [ActionID]
        let friction: [ActionID]
        let npcRole: SimulationRole
        let favorableWorld: WorldFlag
        let adverseWorld: WorldFlag
    }

    private static func template(for flag: PersonalityFlag) -> FlagReactionTemplate {
        switch flag {
        case .driven:
            FlagReactionTemplate(aligned: [.focusGrades, .study, .workShift, .pursuePromotion], friction: [.rest, .quietNight, .protectBoundaries], npcRole: .boss, favorableWorld: .expansion, adverseWorld: .recession)
        case .content:
            FlagReactionTemplate(aligned: [.rest, .quietNight, .pursueHobby, .protectBoundaries], friction: [.pursuePromotion, .sideHustle], npcRole: .friend, favorableWorld: .steadyEconomy, adverseWorld: .inflationShock)
        case .empathetic:
            FlagReactionTemplate(aligned: [.helpAtHome, .caregiving, .parentingPresence, .therapySupport], friction: [.sideHustle, .protectBoundaries], npcRole: .friend, favorableWorld: .strongSafetyNet, adverseWorld: .thinSafetyNet)
        case .selfReliant:
            FlagReactionTemplate(aligned: [.budget, .workShift, .payDebt, .protectBoundaries], friction: [.reachOut, .repairConflict, .seekCare], npcRole: .boss, favorableWorld: .thinSafetyNet, adverseWorld: .constrainedHealthcare)
        case .outgoing:
            FlagReactionTemplate(aligned: [.findYourPeople, .joinClub, .seeFriends, .party], friction: [.quietNight, .pursueHobby], npcRole: .friend, favorableWorld: .stablePublicHealth, adverseWorld: .publicHealthOutbreak)
        case .reserved:
            FlagReactionTemplate(aligned: [.study, .quietNight, .pursueHobby, .developSkill], friction: [.party, .networkContacts], npcRole: .teacher, favorableWorld: .stablePublicHealth, adverseWorld: .expansion)
        case .adventurous:
            FlagReactionTemplate(aligned: [.party, .chooseFreelance, .changeCareer, .sideHustle], friction: [.budget, .preventiveCare], npcRole: .friend, favorableWorld: .expansion, adverseWorld: .recession)
        case .cautious:
            FlagReactionTemplate(aligned: [.budget, .preventiveCare, .payDebt, .adjustRetirement], friction: [.changeCareer, .buyHome], npcRole: .boss, favorableWorld: .recession, adverseWorld: .expansion)
        case .adaptable:
            FlagReactionTemplate(aligned: [.changeCareer, .jobSearch, .returnToEducation, .sellOrDownsize], friction: [.attendClass, .manageCondition], npcRole: .teacher, favorableWorld: .volatileLabor, adverseWorld: .resilientLabor)
        case .steadfast:
            FlagReactionTemplate(aligned: [.attendClass, .workShift, .developSkill, .manageCondition], friction: [.changeCareer, .separate, .sellOrDownsize], npcRole: .boss, favorableWorld: .resilientLabor, adverseWorld: .volatileLabor)
        }
    }

    /// Every pole has both a moment of recognition and a point of friction in
    /// close relationships. These are expression/tradeoff rules, never locks.
    private static let partnerDepthRules: [ReactionRule] = PersonalityFlag.allCases.flatMap { flag in
        let values = template(for: flag)
        return [
            ReactionRule(
                id: "partner-\(flag.rawValue)-aligned", actionIDs: values.aligned,
                predicate: ReactionPredicate(npcFlags: [flag], role: .partner), channel: .npcOrPartner,
                partnerModifier: PartnerEffect(bond: 1),
                headline: "Your Partner Recognized The Choice",
                narrative: "Their \(flag.title.lowercased()) nature recognized what this choice was trying to protect.",
                previewHint: "A \(flag.title.lowercased()) partner recognizes this choice.", cause: "\(flag.title) partner · aligned"
            ),
            ReactionRule(
                id: "partner-\(flag.rawValue)-friction", actionIDs: values.friction,
                predicate: ReactionPredicate(npcFlags: [flag], role: .partner), channel: .npcOrPartner,
                partnerModifier: PartnerEffect(resentment: 1),
                headline: "The Choice Rubbed Against Them",
                narrative: "Their \(flag.title.lowercased()) nature made the tradeoff harder to dismiss.",
                previewHint: "This may conflict with a \(flag.title.lowercased()) partner.", cause: "\(flag.title) partner · friction"
            )
        ]
    }

    /// Recurring NPCs use the same paired flags. Compatible behavior earns
    /// attention; conflicting behavior changes rapport rather than blocking it.
    private static let npcDepthRules: [ReactionRule] = PersonalityFlag.allCases.flatMap { flag in
        let values = template(for: flag)
        let alignedEffect: EffectRange = switch values.npcRole {
        case .teacher: EffectRange(school: 1...1)
        case .friend: EffectRange(love: 1...1)
        case .boss: EffectRange(rep: 1...1)
        case .partner: EffectRange()
        }
        return [
            ReactionRule(
                id: "npc-\(values.npcRole.rawValue)-\(flag.rawValue)-aligned", actionIDs: values.aligned,
                predicate: ReactionPredicate(npcFlags: [flag], role: values.npcRole), channel: .npcOrPartner,
                modifier: alignedEffect, rapportDelta: 1,
                headline: "Someone Recognized How You Moved",
                narrative: "Their \(flag.title.lowercased()) outlook made your approach legible.",
                previewHint: "This approach connects with their \(flag.title.lowercased()) outlook.",
                cause: "\(flag.title) \(values.npcRole.rawValue) · compatible"
            ),
            ReactionRule(
                id: "npc-\(values.npcRole.rawValue)-\(flag.rawValue)-friction", actionIDs: values.friction,
                predicate: ReactionPredicate(npcFlags: [flag], role: values.npcRole), channel: .npcOrPartner,
                rapportDelta: -1,
                headline: "Your Approach Met Some Resistance",
                narrative: "Their \(flag.title.lowercased()) outlook read the choice differently.",
                previewHint: "This approach conflicts with their \(flag.title.lowercased()) outlook.",
                cause: "\(flag.title) \(values.npcRole.rawValue) · conflict"
            )
        ]
    }

    /// World rules change whether a tendency is timely. Their one-unit impact
    /// stays subordinate to the personality tradeoff itself.
    private static let worldDepthRules: [ReactionRule] = PersonalityFlag.allCases.flatMap { flag in
        let values = template(for: flag)
        return [
            ReactionRule(
                id: "world-\(flag.rawValue)-favorable", actionIDs: values.aligned,
                predicate: ReactionPredicate(playerFlags: [flag], worldFlags: [values.favorableWorld]), channel: .world,
                modifier: EffectRange(rep: 1...1),
                headline: "The Moment Fit Your Instinct",
                narrative: "Conditions made your \(flag.title.lowercased()) instinct unusually useful.",
                previewHint: "Current conditions strengthen this tendency.", cause: "\(values.favorableWorld.title) · strengthens \(flag.title)"
            ),
            ReactionRule(
                id: "world-\(flag.rawValue)-adverse", actionIDs: values.aligned,
                predicate: ReactionPredicate(playerFlags: [flag], worldFlags: [values.adverseWorld]), channel: .world,
                modifier: EffectRange(health: -1 ... -1),
                headline: "The World Pushed Back Harder",
                narrative: "Conditions exposed the cost inside your \(flag.title.lowercased()) instinct.",
                previewHint: "Current conditions sharpen this tendency's cost.", cause: "\(values.adverseWorld.title) · challenges \(flag.title)"
            )
        ]
    }

    static func bestMatch(channel: ReactionChannel, action: ActionID, signals: SimulationSignalSnapshot) -> ReactionRule? {
        rules
            .filter { $0.channel == channel && $0.matches(action: action, signals: signals) }
            .sorted {
                if $0.predicate.specificity == $1.predicate.specificity { return $0.id < $1.id }
                return $0.predicate.specificity > $1.predicate.specificity
            }
            .first
    }
}

// MARK: - Life generation

struct LifeGenerationPreview: Equatable, Identifiable {
    var id: UInt64 { seed }
    let seed: UInt64
    let origin: OriginPreset
    let context: StartingContext
    let state: LifeState
}

enum LifeGenerationSystem {
    private static let names = ["Avery", "Jordan", "Riley", "Cameron", "Taylor", "Morgan", "Casey", "Quinn"]

    static func randomPreview(seed: UInt64) -> LifeGenerationPreview {
        var streams = SimulationRandomStreams(runSeed: seed)
        let contextRoll = streams.generation.next(in: 1...100)
        let context: StartingContext = contextRoll <= 15 ? .supported : (contextRoll <= 80 ? .ordinary : .precarious)
        let originRoll = streams.generation.next(in: 1...100)
        let origin: OriginPreset = originRoll <= 50 ? .balanced : (originRoll <= 75 ? .academic : .social)
        let talent: SpecialTalent? = streams.generation.next(in: 1...100) <= 25
            ? SpecialTalent.allCases[streams.generation.next(in: 0...(SpecialTalent.allCases.count - 1))]
            : nil
        let name = names[streams.generation.next(in: 0...(names.count - 1))]
        return makePreview(name: name, seed: seed, origin: origin, context: context, definingTrait: nil, talent: talent)
    }

    static func customPreview(
        name: String,
        seed: UInt64,
        origin: OriginPreset,
        context: StartingContext,
        definingTrait: PersonalityFlag,
        talent: SpecialTalent?
    ) -> LifeGenerationPreview {
        makePreview(name: name, seed: seed, origin: origin, context: context, definingTrait: definingTrait, talent: talent)
    }

    private static func makePreview(
        name: String,
        seed: UInt64,
        origin: OriginPreset,
        context: StartingContext,
        definingTrait: PersonalityFlag?,
        talent: SpecialTalent?
    ) -> LifeGenerationPreview {
        let compatibilityTrait: CoreTrait
        switch definingTrait {
        case .driven: compatibilityTrait = .driven
        case .empathetic: compatibilityTrait = .empathetic
        default: compatibilityTrait = .adaptable
        }
        var state = LifeState(
            name: name,
            seed: seed,
            origin: origin,
            context: context,
            trait: compatibilityTrait,
            startingAge: 14
        )
        state.randomStreams = SimulationRandomStreams(runSeed: seed)
        state.personality = PersonalitySystem.generated(
            definingTrait: definingTrait,
            talent: talent,
            random: &state.randomStreams.generation
        )
        applyStartingVariation(state: &state)
        applyTalentTradeoff(state: &state)
        state.npcs[.friend] = generatedNPC(role: .friend, importance: .recurring, state: state)
        state.npcs[.teacher] = generatedNPC(role: .teacher, importance: .pivotal, state: state)
        state.clamp()
        return LifeGenerationPreview(seed: seed, origin: origin, context: context, state: state)
    }

    static func generatedNPC(role: NPCRole, importance: NPCImportance, state: LifeState) -> NPCState {
        let names: [NPCRole: [String]] = [
            .friend: ["Jamie", "Taylor", "Avery", "Cameron"],
            .teacher: ["Ms. Rivera", "Mr. Chen", "Dr. Patel", "Ms. Brooks"],
            .boss: ["Dana", "Reese", "Quinn", "Parker"]
        ]
        var random = SimulationRandomStreams.npcStream(runSeed: state.runSeed, identity: role.rawValue)
        let pool = names[role] ?? [role.title]
        let name = pool[random.next(in: 0...(pool.count - 1))]
        let personality = PersonalitySystem.generated(random: &random)
        let flags = legacyNPCFlags(for: personality)
        let tags = CharacterTagSystem.generated(for: personality, random: &random)
        let goals = NPCGoalSystem.initialGoals(
            personality: personality,
            tags: tags,
            age: state.character.age,
            random: &random
        )
        return NPCState(
            memberID: "\(role.rawValue)-primary",
            name: name,
            role: role,
            importance: importance,
            coreFlags: flags,
            personality: personality,
            stableTags: tags,
            goals: goals,
            connections: [NPCConnection(
                kind: CharacterTagSystem.connectionKind(for: role),
                startedAge: state.character.age,
                endedAge: nil
            )],
            lastInteractionAge: state.character.age
        )
    }

    private static func applyStartingVariation(state: inout LifeState) {
        let variation = -3...3
        state.stats.school += state.randomStreams.generation.next(in: variation)
        state.stats.love += state.randomStreams.generation.next(in: variation)
        state.stats.play += state.randomStreams.generation.next(in: variation)
        state.stats.health += state.randomStreams.generation.next(in: variation)
        state.stats.looks += state.randomStreams.generation.next(in: variation)
        state.stats.rep += state.randomStreams.generation.next(in: variation)
        _ = state.randomStreams.generation.next(in: -20...20) // Preserve the generation lane without hidden cash allocation.
    }

    private static func applyTalentTradeoff(state: inout LifeState) {
        switch state.personality.talent {
        case .athletic: state.stats.school -= 3
        case .entrepreneurial: state.stats.love -= 3
        case .publicLeadership: state.stats.health -= 2
        case .survivalInstinct: state.stats.play -= 4
        case nil: break
        }
    }

    private static func legacyNPCFlags(for personality: PersonalityProfile) -> [NPCFlag] {
        personality.salientFlags.prefix(2).map {
            switch $0 {
            case .outgoing: .sociable
            case .empathetic: .encouraging
            case .driven: .ambitious
            case .steadfast, .cautious: .dependable
            case .selfReliant, .content, .reserved: .critical
            case .adventurous, .adaptable: .fair
            }
        }
    }
}

enum TalentSystem {
    static func modifiedEffects(for action: DomainAction, state: LifeState) -> EffectRange {
        guard let talent = state.personality.talent else { return action.effects }
        switch talent {
        case .athletic where action.id == .exercise:
            return action.effects.shifted(health: 2, looks: 1)
        case .entrepreneurial where ([ActionID.sideHustle, .chooseFreelance, .developSkill]).contains(action.id):
            return action.effects.shifted(cash: 200, rep: 1)
        case .publicLeadership where ([ActionID.findYourPeople, .commitActivity, .networkContacts, .seeFriends]).contains(action.id):
            return action.effects.shifted(love: 1, rep: 2)
        case .survivalInstinct where ([ActionID.rest, .cutBack, .protectBoundaries, .helpAtHome]).contains(action.id):
            return action.effects.shifted(health: 2)
        default:
            return action.effects
        }
    }

    static func context(for action: DomainAction, state: LifeState) -> String? {
        guard modifiedEffects(for: action, state: state) != action.effects, let talent = state.personality.talent else { return nil }
        return "\(talent.title) talent"
    }

    static func careerChanceBonus(state: LifeState) -> Int {
        switch state.personality.talent {
        case .entrepreneurial where state.career.track == .freelance || state.career.track == .undecided: 8
        case .publicLeadership where state.career.track == .office || state.career.track == .careService: 5
        case .survivalInstinct where state.world.flags.contains(.recession): 4
        default: 0
        }
    }

    static func eventWeight(eventID: String, baseWeight: Int, state: LifeState) -> Int {
        guard baseWeight > 0, let talent = state.personality.talent else { return baseWeight }
        let relevant: Set<String>
        switch talent {
        case .athletic: relevant = ["activity-tryout", "health-reset"]
        case .entrepreneurial: relevant = ["cash-opening", "mentor-referral", "promotion-or-plateau"]
        case .publicLeadership: relevant = ["friend-group-split", "mentor-referral", "recommendation-window", "leadership-talent-finds-room"]
        case .survivalInstinct: relevant = ["second-chance-application", "skilled-work-setback", "cautious-life-meets-recession"]
        }
        return relevant.contains(eventID) ? min(100, baseWeight + max(2, baseWeight / 3)) : baseWeight
    }
}
