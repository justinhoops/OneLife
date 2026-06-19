import Foundation

// MARK: - Core Game Models
struct Player: Codable, Equatable {
    var name: String = "Player"
    var age: Int = 14
    var traits: [PersonalityTrait] = []

    // Broad life-sim stats stay here; domain-specific simulation lives elsewhere.
    var happiness: Int = 58
    var smarts: Int = 56
    var looks: Int = 52
    var health: Int = 60

    mutating func clampStats() {
        happiness = happiness.clamped(to: 0...100)
        smarts = smarts.clamped(to: 0...100)
        looks = looks.clamped(to: 0...100)
        health = health.clamped(to: 0...100)
    }

    /// Mirrored from GameState for convenient use inside domain systems that only receive Player.
    /// Kept in sync by the orchestrator and origin system.
    var _resilience: LifeResilience = .resilient

    /// Effective dampener for health decline (lower = less punishing spirals).
    var healthDeclineDampener: Double {
        _resilience.scaling.healthDeclineDampener
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case age
        case traits
        case happiness
        case smarts
        case looks
        case health
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Player"
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 14
        traits = try container.decodeIfPresent([PersonalityTrait].self, forKey: .traits) ?? []
        happiness = try container.decodeIfPresent(Int.self, forKey: .happiness) ?? 58
        smarts = try container.decodeIfPresent(Int.self, forKey: .smarts) ?? 56
        looks = try container.decodeIfPresent(Int.self, forKey: .looks) ?? 52
        health = try container.decodeIfPresent(Int.self, forKey: .health) ?? 60
    }
}
/// Meta-progression state that persists across all lives.
struct MetaState: Codable, Equatable {
    /// Semantic flags earned from previous lives (e.g. "reached_retirement", "wealthy_dynasty").
    var generationFlags: Set<String> = []
    /// Cumulative stats across all playthroughs.
    var totalLivesPlayed: Int = 0
    var totalYearsLived: Int = 0
    /// Unlocked origin templates that aren't available by default.
    var unlockedTemplateIDs: Set<OriginTemplateID> = []
    /// Currency earned in-game that can be spent on meta-upgrades or starting bonuses.
    var legacyPoints: Int = 0
    
    init() {}
}
/// Thumb-zone shortcut pinned to the domain bar (persists across lives via UserDefaults).
struct DomainShortcutPin: Codable, Equatable, Identifiable {
    enum Target: Codable, Equatable {
        case tab(raw: String)
        case quickAction(domainRaw: String, choiceIDRaw: String)
        case special(id: String)
    }

    var id: String
    var title: String
    var symbol: String
    var target: Target

    static func stableID(for target: Target) -> String {
        switch target {
        case .tab(let raw): return "tab:\(raw)"
        case .quickAction(let domainRaw, let choiceIDRaw): return "qa:\(domainRaw):\(choiceIDRaw)"
        case .special(let id): return "special:\(id)"
        }
    }
}
struct OriginProfile: Codable, Equatable {
    var startMode: StartMode
    var templateID: OriginTemplateID?
    var householdPressure: String
    var schoolStanding: String
    var socialSupport: String
    var starterTraitBias: [PersonalityTrait]
    var startingCashBand: String
    var focusTags: [String]
    var openingEventSeed: [String]
    var homeSummary: String
    var schoolSummary: String
    var selfSummary: String
    var signalHighlights: [String]
}
// MARK: - Childhood Generation Engine Models
/// Six-axis aptitude profile seeded from childhood. Drives career unlock thresholds
/// and stat modifiers at age 14. Hidden from the player; surfaced only as "hints."
struct CareerAptitude: Codable, Equatable {
    /// Logic, analysis, numbers — paths to Law, Medicine, Finance, Engineering
    var analytical: Int = 50
    /// Expression, imagination — paths to Arts, Writing, Design, Media
    var creative: Int = 50
    /// Body, endurance, coordination — paths to Athletics, Military, Trades
    var physical: Int = 50
    /// Reading people, influence, care — paths to Politics, Teaching, Sales, Therapy
    var social: Int = 50
    /// Risk tolerance + hustle instinct — paths to Entrepreneurship, Startups
    var entrepreneurial: Int = 50
    /// Systems, tools, craft — paths to Engineering, IT, Skilled Trades
    var technical: Int = 50

    mutating func clamp() {
        analytical      = analytical.clamped(to: 0...100)
        creative        = creative.clamped(to: 0...100)
        physical        = physical.clamped(to: 0...100)
        social          = social.clamped(to: 0...100)
        entrepreneurial = entrepreneurial.clamped(to: 0...100)
        technical       = technical.clamped(to: 0...100)
    }

    /// Returns the player-visible aptitude hint labels (top 2 axes only).
    var visibleHints: [String] {
        let axes: [(String, Int)] = [
            ("Analytical", analytical),
            ("Creative", creative),
            ("Physical", physical),
            ("Social", social),
            ("Entrepreneurial", entrepreneurial),
            ("Technical", technical)
        ]
        return axes.sorted { $0.1 > $1.1 }.prefix(2).map { "Natural aptitude: \($0.0)" }
    }
}
/// The full procedural backstory package produced by the ChildhoodGenerationEngine.
/// Attached to GameState at character creation; referenced by OriginSystem and career unlock logic.
struct ChildhoodDossier: Codable, Equatable {
    /// Full prose backstory (3–5 sentences). Shown on the Preview step as "Life Before."
    var narrative: String
    /// The six-axis career aptitude profile — the hidden "Career DNA."
    var aptitudes: CareerAptitude
    /// Domain tags for the player's early interests (e.g. "science", "sport", "music").
    var earlyInterests: [String]
    /// One sentence capturing the single most formative childhood moment.
    var formativeEvent: String
    /// Player-visible aptitude hints derived from the top two aptitude axes.
    var visibleHints: [String]
}
struct TrajectoryState: Codable, Equatable {
    var lifePhase: LifePhase = .adolescence
    var direction: TrajectoryDirection = .stable
    var socioeconomicPressure: Int = 50
    var familyStability: Int = 50
    var educationalAccess: Int = 50
    var socialCapital: Int = 50
    var neighborhoodSafety: Int = 50
    var resilience: Int = 50
    var momentum: Int = 50
    var setbackPressure: Int = 0
    var luckWindow: Int = 0
    var opportunityVisibility: Int = 45

    mutating func clamp() {
        socioeconomicPressure = socioeconomicPressure.clamped(to: 0...100)
        familyStability = familyStability.clamped(to: 0...100)
        educationalAccess = educationalAccess.clamped(to: 0...100)
        socialCapital = socialCapital.clamped(to: 0...100)
        neighborhoodSafety = neighborhoodSafety.clamped(to: 0...100)
        resilience = resilience.clamped(to: 0...100)
        momentum = momentum.clamped(to: 0...100)
        setbackPressure = setbackPressure.clamped(to: 0...100)
        luckWindow = luckWindow.clamped(to: -20...20)
        opportunityVisibility = opportunityVisibility.clamped(to: 0...100)
    }
}
struct HousingState: Codable, Equatable {
    enum HousingLifeStage: String, Codable, CaseIterable, Equatable {
        case familyHome
        case unsafeRental
        case roommates
        case soloRenting
        case housePoor
        case ownerOccupied
        case foreclosed
        case downsized
        case inheritedHome
        case luxuryEstate
    }

    enum SocialClassBand: String, Codable, CaseIterable, Equatable {
        case precarious
        case working
        case stableMiddle
        case affluent
        case elite
        case untouchable

        var title: String {
            switch self {
            case .precarious: return "Precarious"
            case .working: return "Working Class"
            case .stableMiddle: return "Stable Middle"
            case .affluent: return "Affluent"
            case .elite: return "Elite"
            case .untouchable: return "Untouchable"
            }
        }
    }

    var livingArrangement: LivingArrangement = .familyHome
    var housingCostBand: Int = 25
    var housingStability: Int = 68
    var hasRoommate: Bool = false
    var lifeStage: HousingLifeStage = .familyHome
    var socialClassBand: SocialClassBand = .working
    var stabilityHistory: [Int] = []

    mutating func clamp() {
        housingCostBand = housingCostBand.clamped(to: 0...100)
        housingStability = housingStability.clamped(to: 0...100)
        stabilityHistory = Array(stabilityHistory.suffix(6))
    }
}
struct LegacyInheritanceSnapshot: Codable, Equatable {
    var parentName: String
    var childName: String
    var childAge: Int
    var inheritedCash: Int
    var inheritedProperty: PrimaryResidenceState?
    var inheritedReputation: Int
    var parentDeathAge: Int
    var parentLegacyHeadline: String? = nil
    var familyMemory: String = ""
    var reputationShadow: String = ""
    var wealthContext: String = ""
    var parentalPattern: String = ""
    var estateFriction: Int = 0
    var inheritedPressureSummary: String = ""
}

struct LifeSummarySnapshot: Codable, Equatable {
    struct LegacyAxis: Codable, Equatable, Identifiable {
        var id: String
        var title: String
        var value: String
        var tone: PlannerTone
        var detail: String
    }

    var headline: String
    var closingLine: String
    var lifePathTitle: String
    var relationshipLine: String
    var reputationLine: String
    var achievements: [String]
    var regrets: [String]
    var legacyScore: Int
    var legacyPointsEarned: Int
    var legacyAxes: [LegacyAxis] = []
    var legacySignals: [String] = []
    var endgameMode: String = "Unfinished"
    var meaningLine: String = ""
    var inheritedPressureSummary: String = ""
}
