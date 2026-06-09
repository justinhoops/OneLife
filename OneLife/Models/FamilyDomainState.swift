import Foundation

// MARK: - Family Domain

enum PregnancyIntent: String, Codable, CaseIterable {
    case avoid
    case chance
    case trying
}

enum PregnancyPhase: String, Codable, CaseIterable {
    case firstTrimester
    case secondTrimester
    case thirdTrimester
}

struct PregnancyState: Codable, Equatable {
    var phase: PregnancyPhase = .firstTrimester
    var otherParentName: String
    var isPlanned: Bool
    var isHighRisk: Bool = false
    var yearsActive: Int = 0
}

struct ChildRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var age: Int = 0
    var livesAtHome: Bool = true
    var otherParentName: String
    var supportLoad: Int = 50

    // Phase 2 (Family Domain): Lightweight personality + development scaffolding.
    // These are the foundation for visible emotional texture and long-term payoffs.
    var temperament: ChildTemperament = .easygoing
    var bondWithPlayer: Int = 55          // 0-100 core emotional connection; drifts with investment + life stress
    var curiosity: Int = 50
    var emotionalSensitivity: Int = 50
    /// Short recent development notes / vibes for richer history and UI (e.g. "had a tough first year at school").
    var developmentNotes: [String] = []

    // Phase 2.3: Long-term adult outcomes and texture
    var leftHomeAtAge: Int?
    var adultProfile: AdultChildProfile?

    static func == (lhs: ChildRecord, rhs: ChildRecord) -> Bool {
        lhs.name == rhs.name &&
        lhs.age == rhs.age &&
        lhs.livesAtHome == rhs.livesAtHome &&
        lhs.otherParentName == rhs.otherParentName &&
        lhs.supportLoad == rhs.supportLoad &&
        lhs.temperament == rhs.temperament &&
        lhs.bondWithPlayer == rhs.bondWithPlayer &&
        lhs.curiosity == rhs.curiosity &&
        lhs.emotionalSensitivity == rhs.emotionalSensitivity &&
        lhs.leftHomeAtAge == rhs.leftHomeAtAge &&
        lhs.adultProfile == rhs.adultProfile
        // developmentNotes intentionally excluded from equality (they are narrative, not identity)
    }

    /// Phase 2 polish: convenient summary for UI and notes.
    var currentVibe: String {
        if let adult = adultProfile {
            let relWord: String
            if adult.relationshipQuality >= 75 { relWord = "still close" }
            else if adult.relationshipQuality >= 55 { relWord = "on decent terms" }
            else if adult.relationshipQuality >= 35 { relWord = "strained" }
            else { relWord = "mostly distant" }
            let recent = adult.keyStories.last ?? adult.lifeVibe
            return "\(adult.outcome.rawValue.capitalized) — \(relWord). \(recent)"
        }

        let temp = temperament.shortDescription
        let bondWord: String
        if bondWithPlayer >= 75 { bondWord = "very close" }
        else if bondWithPlayer >= 60 { bondWord = "solidly bonded" }
        else if bondWithPlayer >= 45 { bondWord = "connected but distant some days" }
        else { bondWord = "feeling the distance" }

        let recent = developmentNotes.last ?? ""
        if !recent.isEmpty {
            return "\(temp.capitalized), \(bondWord). \(recent)"
        }
        return "\(temp.capitalized), \(bondWord)"
    }
}

/// Simple temperament archetypes that influence how children respond to stress, school, and the player's presence.
/// Used for flavorful notes and future parenting trade-offs.
enum ChildTemperament: String, Codable, CaseIterable, Equatable {
    case easygoing   // rolls with changes, lower sensitivity impact
    case spirited    // big feelings, high energy, can be a handful or a delight
    case sensitive   // deeply affected by environment and parent's state
    case independent // prefers autonomy, bond grows slower but more resilient
    case intense     // all-or-nothing; big highs and difficult lows

    var shortDescription: String {
        switch self {
        case .easygoing: return "easygoing"
        case .spirited: return "spirited"
        case .sensitive: return "sensitive"
        case .independent: return "independent"
        case .intense: return "intense"
        }
    }
}

/// Phase 2.3: Long-term adult child outcomes for emotional texture and legacy.
enum AdultChildOutcome: String, Codable, CaseIterable, Equatable {
    case thriving
    case stable
    case struggling
    case distant
}

struct AdultChildProfile: Codable, Equatable {
    var outcome: AdultChildOutcome = .stable
    var relationshipQuality: Int = 55          // evolved from childhood bond
    var lifeVibe: String = ""                  // short flavorful summary e.g. "solid career, one kid, lives across the country"
    var keyStories: [String] = []              // memorable events that reappear in late life
}

struct FamilyState: Codable, Equatable {
    var children: [ChildRecord] = []
    var pregnancy: PregnancyState? = nil
    var pregnancyIntent: PregnancyIntent = .chance
    var postpartumYearsRemaining: Int = 0

    var childCount: Int { children.count }
    var infantCount: Int { children.filter { $0.age <= 1 && $0.livesAtHome }.count }
    var dependentChildCount: Int { children.filter(\.livesAtHome).count }
    var isPregnant: Bool { pregnancy != nil }
}

