import Foundation

enum ArcTheme: String, Codable, CaseIterable, Identifiable {
    case ambitionVsPressure
    case scarcityVsEscape
    case charmVsImpulse
    case disciplineVsDrift
    case stabilityVsSacrifice
    case healthVsMomentum
    case luckVsRestlessness
    case belongingVsRisk

    var id: String { rawValue }

    var previewLabel: String {
        switch self {
        case .ambitionVsPressure: return "Pressure vs ambition"
        case .scarcityVsEscape: return "Escape vs scarcity"
        case .charmVsImpulse: return "Charm vs impulse"
        case .disciplineVsDrift: return "Discipline vs drift"
        case .stabilityVsSacrifice: return "Stability vs sacrifice"
        case .healthVsMomentum: return "Health vs momentum"
        case .luckVsRestlessness: return "Luck vs restlessness"
        case .belongingVsRisk: return "Belonging vs risk"
        }
    }
}


enum ArcDomain: String, Codable, CaseIterable, Identifiable {
    case education
    case career
    case finance
    case relationships
    case health
    case family
    case housing
    case identity

    var id: String { rawValue }
}

enum ArcMoodTone: String, Codable, CaseIterable, Identifiable {
    case focused
    case tense
    case exposed
    case restless
    case guarded
    case hopeful
    case cornered
    case steady
    case isolated

    var id: String { rawValue }

    var signalText: String {
        switch self {
        case .focused: return "pressure is turning into focus"
        case .tense: return "pressure is tightening around performance"
        case .exposed: return "life feels more visible and fragile"
        case .restless: return "the life is leaning toward motion over calm"
        case .guarded: return "every gain still feels conditional"
        case .hopeful: return "opportunity still feels reachable"
        case .cornered: return "systems are starting to close in"
        case .steady: return "the life is holding shape without much noise"
        case .isolated: return "distance is becoming part of the pattern"
        }
    }
}

struct ArcPivotMetadata: Codable, Equatable {
    var chapterTrigger: String? = nil
    var pivotThreshold: Int = 58
    var collapseThreshold: Int = 38
    var minimumYearsBetweenPivots: Int = 2
}

struct ArcInfluenceProfile: Codable, Equatable {
    var eventTagWeights: [String: Int] = [:]
    var moodBias: [ArcMoodTone] = []
    var riskFlags: [String] = []
    var opportunityFlags: [String] = []
    var pivotMetadata: ArcPivotMetadata = ArcPivotMetadata()
}

struct NarrativeArcSeed: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var theme: ArcTheme
    var primaryDomains: [ArcDomain]
    var influence: ArcInfluenceProfile
}

struct NarrativeArcCandidate: Codable, Equatable, Identifiable {
    var seed: NarrativeArcSeed
    var generationScore: Int

    var id: String { seed.id }
}

struct NarrativeArcState: Codable, Equatable {
    var candidates: [NarrativeArcCandidate] = []
    var primaryArcID: String? = nil
    var secondaryArcID: String? = nil
    var lastPivotAge: Int? = nil
    var suppressedArcIDs: [String] = []
    var currentMoodTone: ArcMoodTone? = nil
    var arcAlignmentScores: [String: Int] = [:]

    func candidate(for id: String?) -> NarrativeArcCandidate? {
        guard let id else { return nil }
        return candidates.first(where: { $0.id == id })
    }

    var primaryCandidate: NarrativeArcCandidate? {
        candidate(for: primaryArcID)
    }

    var secondaryCandidate: NarrativeArcCandidate? {
        candidate(for: secondaryArcID)
    }

    var activeCandidates: [NarrativeArcCandidate] {
        [primaryCandidate, secondaryCandidate].compactMap { $0 }
    }

    var previewTensionLabels: [String] {
        Array(Set(candidates.prefix(3).map { $0.seed.theme.previewLabel }))
    }

    var currentSignalLine: String? {
        guard let currentMoodTone else { return nil }
        return currentMoodTone.signalText.capitalized + "."
    }
}

struct ArcSeedContext: Equatable {
    var templateID: OriginTemplateID?
    var focusTags: [String]
    var openingTags: [String]
    var householdPressure: String
    var schoolStandingText: String
    var socialSupportText: String
    var startingCashBand: String
    var age: Int
    var traits: [PersonalityTrait]
    var happiness: Int
    var smarts: Int
    var looks: Int
    var health: Int
    var schoolStanding: Int
    var engagement: Int
    var financialStress: Int
    var cashOnHand: Int
    var housingStability: Int
}

enum WorldEra: String, Codable, Equatable, CaseIterable {
    case stable
    case bullMarket
    case recession
    case highInflation
    case techBoom
    case wartime
    case pandemic

    var displayName: String {
        switch self {
        case .stable: return "Stable Growth"
        case .bullMarket: return "Bull Market"
        case .recession: return "Economic Recession"
        case .highInflation: return "High Inflation"
        case .techBoom: return "Tech Boom"
        case .wartime: return "Geopolitical Conflict"
        case .pandemic: return "Global Pandemic"
        }
    }

    var icon: String {
        switch self {
        case .stable: return "chart.line.uptrend.xyaxis.circle"
        case .bullMarket: return "chart.line.uptrend.xyaxis"
        case .recession: return "chart.line.downtrend.xyaxis"
        case .highInflation: return "arrow.up.circle"
        case .techBoom: return "cpu"
        case .wartime: return "shield.lefthalf.filled"
        case .pandemic: return "facemask.fill"
        }
    }

    var tone: PlannerTone {
        switch self {
        case .bullMarket, .techBoom: return .positive
        case .recession, .highInflation, .wartime, .pandemic: return .warning
        default: return .neutral
        }
    }

    // Macro Modifiers
    var jobSecurityMod: Int {
        switch self {
        case .recession: return -15
        case .bullMarket: return 5
        case .techBoom: return 10
        case .pandemic: return -10
        default: return 0
        }
    }

    var livingCostMod: Int {
        switch self {
        case .highInflation: return 3000
        case .recession: return -500
        case .pandemic: return 1000
        case .wartime: return 1500
        default: return 0
        }
    }

    var houseValueRateMod: Int {
        switch self {
        case .bullMarket: return 4
        case .recession: return -6
        case .techBoom: return 2
        default: return 0
        }
    }

    var investmentReturnMod: Double {
        switch self {
        case .bullMarket: return 0.08
        case .techBoom: return 0.12
        case .recession: return -0.15
        case .pandemic: return -0.05
        default: return 0.0
        }
    }
}

