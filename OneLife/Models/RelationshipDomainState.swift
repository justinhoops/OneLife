import Foundation

// MARK: - Relationship Domain

enum RelationshipStage: String, Codable, CaseIterable {
    case dating
    case committed
    case engaged
    case married
}

enum RelationshipType: String, Codable, CaseIterable {
    case friend
    case romantic
}

enum RelationshipStatus: String, Codable, CaseIterable {
    case active
    case strained
    case ended
}

enum RelationshipTensionSource: String, Codable, CaseIterable {
    case rumor
    case breakup
    case ignoredConnection
    case cohabitation
    case familyPlanning
    case milestoneConflict
    case moneyStress
    case workSpillover
}

enum RelationshipTensionTarget: String, Codable, CaseIterable {
    case socialCircle
    case partner
    case friend
    case household
    case future
}

struct RelationshipTension: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var headline: String
    var impactLine: String
    var severity: Int
    var source: RelationshipTensionSource
    var target: RelationshipTensionTarget
    var createdAge: Int
    var targetName: String? = nil
    var impactedDomains: [HistoryDomainTag] = []

    mutating func clamp() {
        severity = severity.clamped(to: 0...100)
    }
}

struct FutureAlignmentState: Codable, Equatable {
    var cohabitationReadiness: Int = 50
    var familyReadiness: Int = 50
    var retrainingReadiness: Int = 50
    var homeReadiness: Int = 50
    var activeConflictHeadline: String? = nil

    mutating func clamp() {
        cohabitationReadiness = cohabitationReadiness.clamped(to: 0...100)
        familyReadiness = familyReadiness.clamped(to: 0...100)
        retrainingReadiness = retrainingReadiness.clamped(to: 0...100)
        homeReadiness = homeReadiness.clamped(to: 0...100)
    }

    var averageReadiness: Int {
        (cohabitationReadiness + familyReadiness + retrainingReadiness + homeReadiness) / 4
    }
}

enum NPCPersonality: String, Codable, CaseIterable {
    case loyal
    case ambitious
    case needy
    case unstable
    case generous
    case selfish
}

struct Relationship: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: RelationshipType
    var status: RelationshipStatus = .active
    var bond: Int
    var yearsKnown: Int = 0
    var stage: RelationshipStage = .dating
    var isCohabiting: Bool = false
    var commitmentAlignment: Int = 50
    var isSecret: Bool = false
    var hasPrenup: Bool = false
    
    // Social Capital & Autonomy
    var influence: Int = 10 
    var profession: String? = nil
    var personality: NPCPersonality = .loyal
    var hiddenNeedLevel: Int = 0 // 0-100, triggers autonomous asks
    var hiddenResentment: Int = 0 // 0-100, triggers shifts or breakups
    
    // Scheduled Autonomy
    var nextAutonomyYear: Int? = nil
    var currentGoal: String? = nil

    static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        lhs.name == rhs.name &&
        lhs.type == rhs.type &&
        lhs.status == rhs.status &&
        lhs.bond == rhs.bond &&
        lhs.yearsKnown == rhs.yearsKnown &&
        lhs.stage == rhs.stage &&
        lhs.isCohabiting == rhs.isCohabiting &&
        lhs.commitmentAlignment == rhs.commitmentAlignment &&
        lhs.isSecret == rhs.isSecret &&
        lhs.hasPrenup == rhs.hasPrenup &&
        lhs.nextAutonomyYear == rhs.nextAutonomyYear &&
        lhs.currentGoal == rhs.currentGoal
    }
}

enum CareLoadSource: String, Codable, CaseIterable, Equatable {
    case agingParent
    case sickPartner
    case dependentAdultChild
    case householdCrisis
}

struct CareLoadRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var source: CareLoadSource
    var personName: String
    var intensity: Int
    var yearsActive: Int = 0
    var storyLine: String

    mutating func clamp() {
        intensity = intensity.clamped(to: 0...100)
        yearsActive = max(0, yearsActive)
        if storyLine.isEmpty { storyLine = "Someone needs more from you this year." }
    }
}

struct CareLoadState: Codable, Equatable {
    var records: [CareLoadRecord] = []
    var lastResolvedAge: Int? = nil

    var totalIntensity: Int {
        min(100, records.reduce(0) { $0 + max(0, $1.intensity) })
    }

    var isActive: Bool { totalIntensity > 0 }

    var topLine: String {
        records.max { $0.intensity < $1.intensity }?.storyLine ?? "No active care load"
    }

    mutating func clamp() {
        records.indices.forEach { records[$0].clamp() }
        records = Array(records.filter { $0.intensity > 0 }.sorted { $0.intensity > $1.intensity }.prefix(3))
    }
}

struct RelationshipState: Codable, Equatable {
    var friends: [Relationship] = []
    var romanticPartners: [Relationship] = []
    var ambientContacts: [AmbientContact] = []
    var socialCapital: Int = 0
    var publicReputation: Int = 50
    var privateReputation: Int = 50
    var activeRumorHeat: Int = 10
    var knownForTags: [String] = []
    var recentSocialHit: String? = nil
    var recentSocialLift: String? = nil
    var tensions: [RelationshipTension] = []
    var futureAlignment: FutureAlignmentState = FutureAlignmentState()
    var careLoad: CareLoadState = CareLoadState()

    private enum CodingKeys: String, CodingKey {
        case friends
        case romanticPartners
        case romanticPartner // legacy
        case ambientContacts
        case spouseName
        case publicReputation
        case privateReputation
        case activeRumorHeat
        case socialCapital
        case knownForTags
        case recentSocialHit
        case recentSocialLift
        case tensions
        case futureAlignment
        case careLoad
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        friends = try container.decodeIfPresent([Relationship].self, forKey: .friends) ?? []
        
        if let partners = try container.decodeIfPresent([Relationship].self, forKey: .romanticPartners) {
            romanticPartners = partners
        } else if let singlePartner = try container.decodeIfPresent(Relationship.self, forKey: .romanticPartner) {
            romanticPartners = [singlePartner]
        } else {
            romanticPartners = []
        }
        
        ambientContacts = try container.decodeIfPresent([AmbientContact].self, forKey: .ambientContacts) ?? []
        publicReputation = try container.decodeIfPresent(Int.self, forKey: .publicReputation) ?? 50
        privateReputation = try container.decodeIfPresent(Int.self, forKey: .privateReputation) ?? 50
        activeRumorHeat = try container.decodeIfPresent(Int.self, forKey: .activeRumorHeat) ?? 10
        socialCapital = try container.decodeIfPresent(Int.self, forKey: .socialCapital) ?? 20
        knownForTags = try container.decodeIfPresent([String].self, forKey: .knownForTags) ?? []
        recentSocialHit = try container.decodeIfPresent(String.self, forKey: .recentSocialHit)
        recentSocialLift = try container.decodeIfPresent(String.self, forKey: .recentSocialLift)
        tensions = try container.decodeIfPresent([RelationshipTension].self, forKey: .tensions) ?? []
        futureAlignment = try container.decodeIfPresent(FutureAlignmentState.self, forKey: .futureAlignment) ?? FutureAlignmentState()
        careLoad = try container.decodeIfPresent(CareLoadState.self, forKey: .careLoad) ?? CareLoadState()
        clampSocialSignals()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(friends, forKey: .friends)
        try container.encode(romanticPartners, forKey: .romanticPartners)
        try container.encode(ambientContacts, forKey: .ambientContacts)
        try container.encode(publicReputation, forKey: .publicReputation)
        try container.encode(privateReputation, forKey: .privateReputation)
        try container.encode(activeRumorHeat, forKey: .activeRumorHeat)
        try container.encode(socialCapital, forKey: .socialCapital)
        try container.encode(knownForTags, forKey: .knownForTags)
        try container.encodeIfPresent(recentSocialHit, forKey: .recentSocialHit)
        try container.encodeIfPresent(recentSocialLift, forKey: .recentSocialLift)
        try container.encode(tensions, forKey: .tensions)
        try container.encode(futureAlignment, forKey: .futureAlignment)
        try container.encode(careLoad, forKey: .careLoad)
    }

    var primaryPartner: Relationship? {
        romanticPartners.first(where: { !$0.isSecret })
    }

    /// Legacy/test alias for the visible romantic partner.
    var romanticPartner: Relationship? {
        get { primaryPartner }
        set {
            if let newValue {
                if let index = romanticPartners.firstIndex(where: { !$0.isSecret }) {
                    romanticPartners[index] = newValue
                } else {
                    romanticPartners.append(newValue)
                }
            } else if let index = romanticPartners.firstIndex(where: { !$0.isSecret }) {
                romanticPartners.remove(at: index)
            }
        }
    }

    var hasPartner: Bool { primaryPartner != nil }
    var partnerName: String? { primaryPartner?.name }
    var partnerBond: Int { primaryPartner?.bond ?? 0 }
    var hasCohabitingPartner: Bool { primaryPartner?.isCohabiting ?? false }
    var isMarried: Bool { primaryPartner?.stage == .married }
    var hasSpouse: Bool { isMarried }
    
    var partnerStatus: RelationshipStatus? { primaryPartner?.status }
    var partnerStage: RelationshipStage? { primaryPartner?.stage }
    
    var spouseName: String? {
        get { isMarried ? primaryPartner?.name : nil }
        set {
            guard let index = romanticPartners.firstIndex(where: { !$0.isSecret }) else { return }
            if newValue == nil {
                if romanticPartners[index].stage == .married {
                    romanticPartners[index].stage = .committed
                }
            } else {
                romanticPartners[index].stage = .married
            }
        }
    }

    var strongestAmbientContact: AmbientContact? {
        ambientContacts.max { $0.bond < $1.bond }
    }

    var activeTensionCount: Int {
        tensions.filter { $0.severity >= 25 }.count
    }

    var strongestTension: RelationshipTension? {
        tensions.max { $0.severity < $1.severity }
    }

    var socialClimateLabel: String {
        if activeRumorHeat >= 60 { return "Rumors are running hot" }
        if activeTensionCount >= 2 { return "Loose ends are piling up" }
        if publicReputation >= 65 && privateReputation >= 60 { return "People are leaning toward you" }
        if publicReputation <= 40 || privateReputation <= 42 { return "Trust feels conditional" }
        return "Social ground is still forming"
    }

    var futureAlignmentLabel: String {
        if let activeConflictHeadline {
            return activeConflictHeadline
        }
        if futureAlignment.averageReadiness >= 66 { return "Future alignment is warm" }
        if futureAlignment.averageReadiness <= 42 { return "Future alignment is strained" }
        return "The future is still unsettled"
    }

    var activeConflictHeadline: String? {
        futureAlignment.activeConflictHeadline
    }

    mutating func clampSocialSignals() {
        publicReputation = publicReputation.clamped(to: 0...100)
        privateReputation = privateReputation.clamped(to: 0...100)
        activeRumorHeat = activeRumorHeat.clamped(to: 0...100)
        knownForTags = Array(NSOrderedSet(array: knownForTags.compactMap { $0.isEmpty ? nil : $0 }).array as? [String] ?? []).prefix(4).map { $0 }
        tensions.indices.forEach { tensions[$0].clamp() }
        tensions = Array(tensions.sorted { $0.severity > $1.severity }.prefix(3))
        futureAlignment.clamp()
        careLoad.clamp()
    }
}
