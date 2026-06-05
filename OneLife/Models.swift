import Foundation

enum CharacterCreationStep: Int, CaseIterable, Codable {
    case name       = 0
    case origin     = 1
    case trait      = 2
    case resilience = 3   // "Life Feel" choice — key for replayability tuning
}

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

enum StartupState: String, Codable, Equatable {
    case choosingOrigin
    case active
    case inheritingLegacy
}

enum StartMode: String, Codable, CaseIterable, Identifiable {
    case quickStart
    case template
    case custom

    var id: String { rawValue }
}

enum OriginTemplateID: String, Codable, CaseIterable, Identifiable {
    case stableHomeAverageMeans
    case financialStrainToughenedEarly
    case academicPromise
    case socialMagnet
    case fragileHealthStart
    case chaoticHomeSelfReliant
    case luckyBreak
    case wealthyDynasty
    case academicLegacy
    case ruralEscapist
    case techProdigy
    case artisticDrifter
    var id: String { rawValue }
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

enum LifePhase: String, Codable, CaseIterable {
    case adolescence
    case launch
    case earlyCareer
    case familyBuilder
    case midlife
    case laterLife
}

enum TrajectoryDirection: String, Codable, CaseIterable {
    case rising
    case stable
    case fragile
    case sliding
}

/// Controls the overall "bite" of the life simulation for replayability.
/// .resilient (default) softens death spirals and spillovers so players can recover from bad stretches
/// without the run feeling immediately doomed — while still preserving meaningful consequences.
/// .grounded is the full unflinching "Life Killer" experience for veterans.
enum LifeResilience: String, Codable, CaseIterable, Identifiable {
    case resilient
    case grounded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .resilient: return "Resilient"
        case .grounded: return "Grounded"
        }
    }

    var description: String {
        switch self {
        case .resilient:
            return "More room to recover from rough years. Still authentic, but less punishing spirals."
        case .grounded:
            return "Full Life Killer experience. Harsh consequences, minimal safety nets. For veterans."
        }
    }

    var isDefault: Bool { self == .resilient }
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

enum EducationPathway: String, Codable, CaseIterable {
    case student
    case dropout
    case training
    case graduate
    case rotc
}

enum EducationStage: String, Codable, CaseIterable {
    case secondary
    case university
    case tradeTraining
    case adultEd
    case inactive
}

enum AcademicTrack: String, Codable, CaseIterable {
    case general
    case honors
    case struggling
    case vocational
}

enum StudyFocus: String, Codable, CaseIterable {
    case generalStudies
    case business
    case technology
    case medicine
    case law
    case computerScience
    case arts
    case health
    case trades
}

struct EducationState: Codable, Equatable {
    var pathway: EducationPathway = .student
    var stage: EducationStage = .secondary
    var academicTrack: AcademicTrack = .general
    var schoolStanding: Int = 56
    var engagement: Int = 55
    var attendancePressure: Int = 18
    var activityMomentum: Int = 20
    var schoolBelonging: Int = 48
    var reputationRisk: Int = 22
    var teacherSupport: Int = 44
    var applicationReadiness: Int = 24
    var campusFit: Int = 50
    var burnoutRisk: Int = 18
    var disciplineRecord: Int = 76
    var mentorSupport: Int = 32
    var peerPressure: Int = 26
    var yearsInStage: Int = 0
    var studyFocus: StudyFocus? = nil
    var credentials: [String] = []
    var hasScholarship: Bool = false
    /// D3: Education pathway differentiation support. credentialStrength starts higher for honors, decays over time unless refreshed (or trade track maintains via practice).
    /// Used for handoff income ramps, special entry bias, and long-term credential value in career.
    var credentialStrength: Int = 65
    var yearsSinceCredential: Int = 0

    private enum CodingKeys: String, CodingKey {
        case pathway
        case stage
        case academicTrack
        case schoolStanding
        case engagement
        case attendancePressure
        case activityMomentum
        case schoolBelonging
        case reputationRisk
        case teacherSupport
        case applicationReadiness
        case campusFit
        case burnoutRisk
        case disciplineRecord
        case mentorSupport
        case peerPressure
        case yearsInStage
        case studyFocus
        case credentials
        case hasScholarship
        case credentialStrength  // D3
        case yearsSinceCredential
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pathway = try container.decodeIfPresent(EducationPathway.self, forKey: .pathway) ?? .student
        stage = try container.decodeIfPresent(EducationStage.self, forKey: .stage) ?? .secondary
        academicTrack = try container.decodeIfPresent(AcademicTrack.self, forKey: .academicTrack) ?? .general
        schoolStanding = try container.decodeIfPresent(Int.self, forKey: .schoolStanding) ?? 56
        engagement = try container.decodeIfPresent(Int.self, forKey: .engagement) ?? 55
        attendancePressure = try container.decodeIfPresent(Int.self, forKey: .attendancePressure) ?? 18
        activityMomentum = try container.decodeIfPresent(Int.self, forKey: .activityMomentum) ?? 20
        schoolBelonging = try container.decodeIfPresent(Int.self, forKey: .schoolBelonging) ?? 48
        reputationRisk = try container.decodeIfPresent(Int.self, forKey: .reputationRisk) ?? 22
        teacherSupport = try container.decodeIfPresent(Int.self, forKey: .teacherSupport) ?? 44
        applicationReadiness = try container.decodeIfPresent(Int.self, forKey: .applicationReadiness) ?? 24
        campusFit = try container.decodeIfPresent(Int.self, forKey: .campusFit) ?? 50
        burnoutRisk = try container.decodeIfPresent(Int.self, forKey: .burnoutRisk) ?? 18
        disciplineRecord = try container.decodeIfPresent(Int.self, forKey: .disciplineRecord) ?? 76
        mentorSupport = try container.decodeIfPresent(Int.self, forKey: .mentorSupport) ?? 32
        peerPressure = try container.decodeIfPresent(Int.self, forKey: .peerPressure) ?? 26
        yearsInStage = try container.decodeIfPresent(Int.self, forKey: .yearsInStage) ?? 0
        studyFocus = try container.decodeIfPresent(StudyFocus.self, forKey: .studyFocus)
        credentials = try container.decodeIfPresent([String].self, forKey: .credentials) ?? []
        hasScholarship = try container.decodeIfPresent(Bool.self, forKey: .hasScholarship) ?? false
        credentialStrength = try container.decodeIfPresent(Int.self, forKey: .credentialStrength) ?? 65
        yearsSinceCredential = try container.decodeIfPresent(Int.self, forKey: .yearsSinceCredential) ?? 0
        clamp()
    }

    mutating func clamp() {
        schoolStanding = schoolStanding.clamped(to: 0...100)
        engagement = engagement.clamped(to: 0...100)
        attendancePressure = attendancePressure.clamped(to: 0...100)
        activityMomentum = activityMomentum.clamped(to: 0...100)
        schoolBelonging = schoolBelonging.clamped(to: 0...100)
        reputationRisk = reputationRisk.clamped(to: 0...100)
        teacherSupport = teacherSupport.clamped(to: 0...100)
        applicationReadiness = applicationReadiness.clamped(to: 0...100)
        campusFit = campusFit.clamped(to: 0...100)
        burnoutRisk = burnoutRisk.clamped(to: 0...100)
        disciplineRecord = disciplineRecord.clamped(to: 0...100)
        mentorSupport = mentorSupport.clamped(to: 0...100)
        peerPressure = peerPressure.clamped(to: 0...100)
        yearsInStage = max(0, yearsInStage)
        credentialStrength = credentialStrength.clamped(to: 0...100)
        yearsSinceCredential = max(0, yearsSinceCredential)
    }
}

enum LivingArrangement: String, Codable, CaseIterable {
    case familyHome
    case roommates
    case soloRenting
    case ownerOccupied
    case couchSurfing
}

struct HousingState: Codable, Equatable {
    var livingArrangement: LivingArrangement = .familyHome
    var housingCostBand: Int = 25
    var housingStability: Int = 68
    var hasRoommate: Bool = false

    mutating func clamp() {
        housingCostBand = housingCostBand.clamped(to: 0...100)
        housingStability = housingStability.clamped(to: 0...100)
    }
}

struct ActiveEffect: Equatable, Identifiable {
    var id: String { title }
    let title: String
    let detail: String
    let tone: PlannerTone
}

enum YearlyStanceID: String, Codable, CaseIterable, Identifiable {
    case stabilizeMoney
    case protectHealth
    case repairPeople
    case pushCareer
    case letYearDrift
    case soldierStance
    case studentStance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stabilizeMoney: return "Stabilize Money"
        case .protectHealth: return "Protect Health"
        case .repairPeople: return "Repair People"
        case .pushCareer: return "Push Career"
        case .letYearDrift: return "Let The Year Drift"
        case .soldierStance: return "Standard Service"
        case .studentStance: return "Academic Focus"
        }
    }

    var domain: ActionDomain? {
        switch self {
        case .stabilizeMoney: return .finance
        case .protectHealth: return .health
        case .repairPeople: return .relationships
        case .pushCareer: return .career
        case .soldierStance: return .military
        case .studentStance: return .education
        case .letYearDrift: return nil
        }
    }

    func preferredAction(for state: GameState) -> ActionChoiceID? {
        switch self {
        case .stabilizeMoney:
            if state.finance.creditDebt + state.finance.medicalDebt + state.finance.studentDebt > 2_500 { return .minimumPayments }
            return state.finance.cashOnHand < 1_500 ? .smallHustle : .cutSpending
        case .protectHealth:
            return state.healthProfile.mentalWellness < 48 ? .protectSleep : .rest
        case .repairPeople:
            if state.relationships.activeTensionCount > 0 || (state.relationships.hasPartner && state.relationships.partnerBond < 55) { return .repairTension }
            return state.relationships.friends.isEmpty ? .findYourCrowd : .reachOut
        case .pushCareer:
            return state.career.status == .unemployed ? .jobHunt : .workHard
        case .soldierStance:
            return .militaryService
        case .studentStance:
            return .studyConsistently
        case .letYearDrift:
            return nil
        }
    }
}

extension YearlyStanceID {
    /// Short hint on Year Goal chips so Resilient vs Grounded changes how the year reads.
    func yearGoalHint(for state: GameState) -> String? {
        switch self {
        case .protectHealth:
            return state.resilience == .grounded
                ? "Grounded: care choices land harder when you actually take them."
                : "Resilient: recovery has more slack if you protect the year."
        case .stabilizeMoney:
            return state.resilience == .grounded
                ? "Grounded: money fixes are real wins, not guaranteed saves."
                : nil
        case .letYearDrift:
            return state.resilience == .grounded
                ? "Grounded: drift often costs more than it looks."
                : nil
        default:
            return nil
        }
    }
}

struct YearlyStanceMemory: Codable, Equatable {
    var selectedStance: YearlyStanceID? = nil
    var lastCompletedStance: YearlyStanceID? = nil
    var repeatCount: Int = 0
    var lastOutcomeLine: String? = nil
    /// D4: recent focus residue for echoes, ruts, autonomy bias, life-shape, silent/continuity flavor (capped low overhead)
    var recentStances: [YearlyStanceID] = []
}

/// Lightweight state tracking the "momentum" from recent instant actions and autonomous world reactions.
/// Used in Phase 2 to let micro-actions meaningfully influence the upcoming year's stakes and events.
struct InstantMomentumState: Codable, Equatable {
    var overallStrength: Int = 0          // 0-100 scale
    var healthMomentum: Int = 0
    var financeMomentum: Int = 0
    var relationshipMomentum: Int = 0
    var lastUpdatedAge: Int = 0

    mutating func recordReaction(domain: ActionDomain, strength: Int, currentAge: Int) {
        let clamped = max(1, min(25, strength))

        switch domain {
        case .health:
            healthMomentum = min(100, healthMomentum + clamped)
        case .finance:
            financeMomentum = min(100, financeMomentum + clamped)
        case .relationships:
            relationshipMomentum = min(100, relationshipMomentum + clamped)
        default:
            break
        }

        overallStrength = min(100, (healthMomentum + financeMomentum + relationshipMomentum) / 3)
        lastUpdatedAge = currentAge
    }

    mutating func decay() {
        healthMomentum = max(0, healthMomentum - 8)
        financeMomentum = max(0, financeMomentum - 8)
        relationshipMomentum = max(0, relationshipMomentum - 8)
        overallStrength = max(0, (healthMomentum + financeMomentum + relationshipMomentum) / 3)
    }

    mutating func clear() {
        self = InstantMomentumState()
    }

    /// True when recent quick moves are strong enough to surface the momentum strip.
    var isVisible: Bool { overallStrength >= 12 }

    /// Domains ranked for the console strip (highest first).
    var rankedDomainMomentum: [(domain: ActionDomain, value: Int)] {
        [
            (.health, healthMomentum),
            (.finance, financeMomentum),
            (.relationships, relationshipMomentum)
        ]
        .filter { $0.value > 0 }
        .sorted { $0.value > $1.value }
    }

    /// Coach copy for how to build momentum before the next Age Up.
    func buildHint(resilience: LifeResilience) -> String {
        guard let weakest = rankedDomainMomentum.last else {
            return "Repeat focused quick moves in one lane before Age Up — the forecast will read your pattern."
        }
        let lane: String
        let sample: String
        switch weakest.domain {
        case .health:
            lane = "health"
            sample = resilience == .grounded ? "Rest or protect sleep" : "Rest, protect sleep, or see a doctor"
        case .finance:
            lane = "money"
            sample = "Cut spending or pay down debt"
        case .relationships:
            lane = "people"
            sample = "Reach out or repair tension"
        default:
            lane = "your focus"
            sample = "the quick action that matches this year"
        }
        if resilience == .grounded {
            return "Grounded runs reward repeats in \(lane). Try \(sample) twice, then Age Up — momentum carries into the forecast."
        }
        return "Stack quick moves in \(lane) (e.g. \(sample)) — repeats build momentum that softens the next year."
    }
}

enum PlayerPattern: String, Codable, CaseIterable, Identifiable {
    case overworker
    case drifter
    case caregiver
    case riskChaser
    case stabilizer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overworker: return "Overworker"
        case .drifter: return "Drifter"
        case .caregiver: return "Caregiver"
        case .riskChaser: return "Risk Chaser"
        case .stabilizer: return "Stabilizer"
        }
    }

    var legacyLine: String {
        switch self {
        case .overworker: return "You kept trying to outwork the damage."
        case .drifter: return "You survived by letting years pass around you."
        case .caregiver: return "You kept spending yourself on other people."
        case .riskChaser: return "You reached for doors that could cut both ways."
        case .stabilizer: return "You kept choosing the smaller, steadier repair."
        }
    }

    var eventWeights: [String: Int] {
        switch self {
        case .overworker: return ["career": 5, "burnout": 4, "routine": 2]
        case .drifter: return ["routine": 4, "health": 2, "social": 2]
        case .caregiver: return ["family": 5, "social": 4, "health": 2]
        case .riskChaser: return ["risk": 6, "money": 3, "career": 2]
        case .stabilizer: return ["routine": 5, "money": 3, "health": 2]
        }
    }

    static func resolve(from state: GameState) -> PlayerPattern? {
        let counts = state.correlationLedger.actionCounts
        let scored: [(PlayerPattern, Int)] = [
            (.overworker, score(counts, [.workHard, .takeOvertime, .takeExtraShifts, .smallHustle])),
            (.drifter, score(counts, [.coast, .skipAndDrift, .spendToCope, .spendForRelief])),
            (.caregiver, score(counts, [.repairTension, .reachOut, .protectYourEnergy, .rest])),
            (.riskChaser, score(counts, [.dayTrade, .runScheme, .exploitLeverage, .chaseSpotlight, .compete, .intenseTraining])),
            (.stabilizer, score(counts, [.cutSpending, .payDownDebt, .minimumPayments, .studyConsistently, .lockInRoutine]))
        ]

        let stancePattern: PlayerPattern?
        if state.yearlyStance.repeatCount >= 3 {
            switch state.yearlyStance.lastCompletedStance {
            case .pushCareer, .soldierStance: stancePattern = .overworker
            case .letYearDrift: stancePattern = .drifter
            case .repairPeople: stancePattern = .caregiver
            case .stabilizeMoney, .studentStance: stancePattern = .stabilizer
            case .protectHealth, .none: stancePattern = nil
            }
        } else {
            stancePattern = nil
        }

        if let stancePattern,
           scored.first(where: { $0.0 == stancePattern })?.1 ?? 0 >= 1 {
            return stancePattern
        }

        return scored.max { lhs, rhs in
            if lhs.1 == rhs.1 {
                return lhs.0.rawValue < rhs.0.rawValue
            }
            return lhs.1 < rhs.1
        }.flatMap { $0.1 >= 3 ? $0.0 : nil }
    }

    private static func score(_ counts: [String: Int], _ choices: [ActionChoiceID]) -> Int {
        choices.reduce(0) { partial, choice in
            partial + counts[choice.rawValue, default: 0]
        }
    }
}

/// Tracks which in-game teaching moments the player has seen (Tier 1 / Phase 4 discoverability).
struct DiscoverabilityState: Codable, Equatable {
    var seenLongPressCoach: Bool = false
    var seenMomentumCoach: Bool = false
    var seenResilienceExplain: Bool = false
    var seenAdultChildrenCoach: Bool = false
    var seenInstantYearlyCoach: Bool = false
    var performedFirstQuickAction: Bool = false
    /// Ages at which we already added a resilience reflection to the journal.
    var resilienceJournalAges: Set<Int> = []

    mutating func markLongPressSeen() { seenLongPressCoach = true }
    mutating func markMomentumSeen() { seenMomentumCoach = true }
    mutating func markResilienceExplainSeen() { seenResilienceExplain = true }
    mutating func markAdultChildrenSeen() { seenAdultChildrenCoach = true }
    mutating func markInstantYearlySeen() { seenInstantYearlyCoach = true }

    /// One-line coach for the console banner (nil when nothing to show).
    func pendingCoachLine(
        quickActionsAvailable: Bool,
        mvpOnboardingActive: Bool,
        momentumActive: Bool = false,
        earlyDossierActive: Bool = false
    ) -> String? {
        if mvpOnboardingActive, !seenInstantYearlyCoach {
            return "Quick actions = instant feedback. Age Up commits a full year — plan both."
        }
        if momentumActive, !seenMomentumCoach {
            return "The momentum strip tracks repeat quick moves. Tap the globe icon to see how it feeds Age Up."
        }
        if quickActionsAvailable, performedFirstQuickAction, !seenLongPressCoach {
            return "Hold any quick action to preview effects before you tap."
        }
        // P5-4: Lightweight first-life teaching for powerful systems (dossier carry, stance/shape power)
        // Shown naturally in early years without new persisted flags (age-gated so it feels like discovery, not tutorial)
        if mvpOnboardingActive, earlyDossierActive, !seenInstantYearlyCoach {
            return "What you were at 14 is still wiring how the world answers you. Stance choices compound into your life shape."
        }
        return nil
    }
}

extension YearlyOutcomeSummary {
    /// Phase 7: One actionable nudge so even harsh years leave the player a clear next move.
    func actionableLesson(resilience: LifeResilience, state: GameState) -> YearlyOutcomeItem? {
        let harshYear = (topProblem?.tone == .warning) || (mainTradeoff?.tone == .warning)
        guard harshYear else { return nil }

        let stance = state.yearlyStance.lastCompletedStance ?? state.yearlyStance.selectedStance
        if let stance, let choiceID = stance.preferredAction(for: state) {
            let actionTitle = ActionChoiceCatalog.definition(for: choiceID).title
            let detail: String
            if resilience == .grounded {
                detail = "This year was loud. One focused \(actionTitle) before the next Age Up can still move the needle in a Grounded run."
            } else {
                detail = "Try \(actionTitle) as a quick action — repeats build momentum that shows up on the next forecast."
            }
            return YearlyOutcomeItem(
                title: "Small Win To Try",
                detail: detail,
                domain: historyDomain(for: stance.domain ?? .health),
                tone: .positive,
                impactScore: 3
            )
        }

        if let opportunity = topOpportunity {
            return YearlyOutcomeItem(
                title: "Small Win To Try",
                detail: "Lean into \(opportunity.title.lowercased()) while the window is open.",
                domain: opportunity.domain,
                tone: .positive,
                impactScore: 2
            )
        }
        return nil
    }

    private func historyDomain(for domain: ActionDomain) -> HistoryDomainTag {
        switch domain {
        case .health: return .health
        case .finance: return .finance
        case .relationships: return .relationships
        case .career: return .career
        case .education: return .education
        case .military: return .military
        case .crime: return .crime
        case .family: return .family
        case .identity: return .progress
        }
    }
}

/// Tier A: One rotating mission so each year has a clear target.
struct SoftRunGoal: Codable, Equatable, Identifiable {
    enum Status: String, Codable, Equatable {
        case inProgress
        case met
        case missed
    }

    var id: String
    var title: String
    var detail: String
    var progressHint: String
    var domain: ActionDomain
    var suggestedChoice: ActionChoiceID?
    var setAtAge: Int
    var status: Status = .inProgress
}

/// Tier A: Unified "what to do now" payload for console + feed.
struct NowLaneSnapshot: Equatable {
    var headline: String
    var detail: String
    var quickActionTitle: String?
    var quickActionDomain: ActionDomain?
    var quickActionChoice: ActionChoiceID?
    var ageUpHint: String
    var tone: PlannerTone
    var showsQuickAction: Bool
}

struct CastStripMember: Identifiable, Equatable {
    var id: String
    var name: String
    var roleLabel: String
    var line: String
    var icon: String
}

struct AutonomyToast: Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var tone: PlannerTone
}

struct MVPOnboardingState: Codable, Equatable {
    var startAge: Int? = nil
    var completed: Bool = false
    var endedByMajorMoment: Bool = false
    /// Scripted first-life beats (Tier A4).
    var beatQuickActionDone: Bool = false
    var beatHoldPreviewDone: Bool = false
    var beatForecastCommitDone: Bool = false

    mutating func activate(at age: Int) {
        startAge = age
        completed = false
        endedByMajorMoment = false
    }

    mutating func advance(afterAge age: Int, hadMajorMoment: Bool) {
        guard let startAge, !completed else { return }
        if hadMajorMoment {
            completed = true
            endedByMajorMoment = true
        } else if age - startAge >= 3 {
            completed = true
        }
    }

    func isActive(at age: Int) -> Bool {
        guard let startAge, !completed else { return false }
        return age - startAge < 3
    }

    func elapsedYears(at age: Int) -> Int {
        guard let startAge else { return 0 }
        return max(0, age - startAge)
    }

    /// Next scripted coaching line while first-life onboarding is active.
    func scriptedDirective(
        age: Int,
        performedQuickAction: Bool,
        seenHoldCoach: Bool,
        hasYearStance: Bool
    ) -> String? {
        guard isActive(at: age) else { return nil }
        if !beatQuickActionDone, !performedQuickAction {
            return "Step 1: Tap the Now quick action for instant feedback."
        }
        if !beatHoldPreviewDone, !seenHoldCoach {
            return "Step 2: Hold that action to preview effects before you tap."
        }
        if !beatForecastCommitDone, !hasYearStance {
            return "Step 3: Age Up, pick a year goal on the forecast, then Start The Year."
        }
        return "Step 4: Finish the year cards, then repeat — quick moves stack momentum."
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
}

struct LifeSummarySnapshot: Codable, Equatable {
    var headline: String
    var closingLine: String
    var lifePathTitle: String
    var relationshipLine: String
    var reputationLine: String
    var achievements: [String]
    var regrets: [String]
    var legacyScore: Int
    var legacyPointsEarned: Int
}

enum ActionChoiceID: String, Codable, CaseIterable, Identifiable {
    case studyHard
    case studyConsistently
    case cramAndSurvive
    case lockInRoutine
    case joinActivity
    case joinClub
    case buildPortfolio
    case layLow
    case skipClass
    case skipAndDrift
    case keepThePeace
    // Teen precursors (dossier-driven early sparks for special careers - available 14-17, seed substates + school buffs)
    case teenAthleticDrill      // physical -> athlete path
    case teenSideHustle         // entrepreneurial -> founder/crime trader
    case teenCreativeProject    // creative -> creator
    case teenLeadInitiative     // social -> politics
    case teenRiskyExperiment    // high risk tolerance lean -> criminal enterprise
    case workHard
    case protectYourEnergy
    case network
    case pivotCareer
    case trainNewSkill
    case retire
    case retrain
    case takeOvertime
    case coast
    case jobHunt
    case chaseSpotlight
    case startMovieActor
    case auditionRole
    case actingClass
    case buildActingReel
    case takeIndieRole
    case managePublicist
    case startMusicProducer
    case produceTrack
    case runStudioSession
    case shopBeats
    case collaborateWithArtist
    case polishSignatureSound
    case manageProducerCredits
    case startMovieProducer
    case optionScript
    case castProject
    case shootFilm
    case handleProductionCrisis
    case secureDistribution
    case manageBackEndPoints
    case startRecordLabel
    case signArtist
    case developArtist
    case releaseRecord
    case bookTour
    case payArtists
    case pushSingle
    case handleArtistDrama
    case startCoachingCareer
    case recruitTalent
    case hireCoachingStaff
    case installSystem
    case runTrainingCamp
    case manageLockerRoom
    case callBigGame
    case handleBoosterPressure
    case intenseTraining
    case compete
    // Phase S2: Dedicated athlete quick actions for frictionless sports pipeline
    case extraTrainingSession
    case mediaAppearance
    case recoveryFocus
    case teamBonding
    // S3a: The Myth & The Machine — doping / edge temptation
    case edgeProtocol
    // E2: Dedicated founder quick actions for frictionless entrepreneur experience
    case closeMajorDeal
    case allHandsRally
    case fundraiseSprint
    case takeRealBreak
    case hireKeyTalent
    // C2: Dedicated creator quick actions for frictionless content creator experience
    case postDaily
    case goLive
    case filmBanger
    case collab
    case addressDrama
    case takeMentalBreak
    case dropBrandDeal
    // P2: Dedicated politics quick actions
    case townHall
    case politicalFundraise
    case scandalResponse
    case policyPush
    case backroomDeal
    case mediaHit
    case takeAStand
    case attackOpponent
    case gatherIntelligence
    case exploitLeverage
    case dayTrade
    case analyzeMarkets
    case runScheme
    case buildCrew
    case cleanMoney
    case stepAway
    // CE2: Dedicated instant actions for Criminal Enterprise paths
    case ghostProtocol
    case burnEvidence
    case payTheFixer
    case launderThroughShell
    case hostStrategicGala
    case aggressiveTakeover
    case smallHustle
    case takeExtraShifts
    case saveForEscape
    case cutSpending
    case spendForRelief
    case spendToCope
    case takeSideWork
    case payDownDebt
    case consolidateDebt
    case minimumPayments
    case deferStudentLoans
    case declareBankruptcy
    case buildEmergencyFund
    case buyIndexFund
    case speculateStocks
    case holdPositions
    case sellToCover
    case saveForDownPayment
    case depositToHouseFund
    case buyStarterHome
    case refinanceMortgage
    case buildMaintenanceReserve
    case topUpHouseReserve
    // Econ4: Dedicated economic quick actions with strong era + special career flavor
    case panicSell
    case aggressiveSideHustle
    case bigLifestylePurchase
    case rideTheWave
    case quietFinancialQuit
    case sellHome
    // Econ1 (Stock Market)
    case checkPortfolio
    case rebalancePortfolio
    case researchTip
    case buyIndex
    case sellPosition
    // Assets3: Instant layer for luxury and signature assets
    case flexLuxuryAsset
    case liquidateLuxury
    case upgradeCollection
    case hostAtSignatureEstate
    case findYourCrowd
    case dateCarefully
    case startAffair
    case endAffair
    case buyEngagementRing
    case signPrenup
    case proposeMarriage
    case planWedding
    case fileForDivorce
    case chaseStatus
    case stayInvisible
    case leanOnMentor
    case reachOut
    case strengthenBond
    case discussFuture
    case moveInTogether
    case tryForBaby
    case avoidPregnancy
    case letChanceDecide
    case keepDistance
    case repairTension
    // Phase 2.2: Simple parenting mechanics with trade-offs
    case spendTimeWithKids
    case enforceRoutine
    case encourageIndependence
    case checkInOnChild
    case protectSleep
    case rest
    case pushThrough
    case seeDoctor
    case callInFavor
    case startCompany
    case pitchDeck
    case pivotBusiness
    case raiseCapital
    case aggressiveExpansion
    case manageFund
    case acquireCompetitor
    case stripAssets
    case ipoExit
    case hireAdvisor
    
    // Military
    case enlistArmy
    case enlistNavy
    case enlistAirForce
    case enlistMarines
    case enlistCoastGuard
    case enlistSpaceForce
    case commissionArmy
    case commissionNavy
    case commissionAirForce
    case commissionMarines
    case commissionCoastGuard
    case commissionSpaceForce
    case joinReservesArmy
    case joinReservesNavy
    case joinReservesAirForce
    case joinReservesMarines
    case joinReservesCoastGuard
    case joinReservesSpaceForce
    case militaryService
    case deploy
    case goAWOL
    case desert
    case militaryRetirement
    
    // Military V2
    case joinROTC
    case leaveROTC
    case selectCombatMOS
    case selectMedicalMOS
    case selectAviationMOS
    case selectIntelMOS
    case selectLogisticsMOS
    case useGIBill
    case seekVAHealthcare
    case claimPension
    
    // Investment Portfolios
    case buyStocks
    case sellStocks
    case buyCrypto
    case sellCrypto
    case buyRentalProperty
    case sellRentalProperty
    case manageRentals
    
    // Legacy
    case switchToChild
    
    // Specialized Civilian Careers
    case applyForResidency
    case completeResidency
    case openPrivatePractice
    case passBarExam
    case makePartner
    case becomeCTO
    case launchStartupSpinOff

    // D1: Identity domain activation — light self actions, always-available static instants
    case morningReflection
    case reconcileWithPast
    case tryNewPersona
    case publicReset
    case therapySession
    case processCrisis

    // D1: Military depth — new static instants + deploy tour
    case ptFocus
    case seekCounsel
    case studyTradition
    case deployTour

    // D1: Family light always — persistent low-commitment family statics
    case familyMeal
    case storyTime

    // D2: Finance/Assets mastery & collector loops (per-path unique assets, maintenance, era costs, fame/lifestyle/knownFor)
    case curateCollection
    case hostSignatureEvent
    case maintainAsset

    // D2: Health depth (condition management, aging curves by resilience/lifestyle, body-as-asset)
    case recurringTherapy
    case manageMeds
    case bodyConditioning

    // D2: Relationships depth (per-friend, rivalry, private vs public rep split)
    case deepenSpecificBond
    case fuelRivalry
    case splitReputation

    // D3: Education-to-everything branches (trade/uni/honors mechanical differences, lifelong learning, credential handoff)
    case pursueTradeCert
    case honorsTrack
    case uniApplication
    case lifelongLearning
    case credentialRefresh

    // D3: Regular career archetype parity (non-special deep paths, aging curves, side-hustle overlap)
    case corporateClimb
    case freelanceHustle
    case tradesMastery
    case pivotToGig
    // D3: additional regular archetypes for 6-way parity (public service, tech/engineering)
    case publicServiceGrind
    case techDeepWork

    var id: String { rawValue }
    
    var domain: ActionDomain {
        switch self {
        case .studyHard, .studyConsistently, .cramAndSurvive, .lockInRoutine, .joinClub, .buildPortfolio, .skipClass, .layLow, .skipAndDrift, .joinROTC, .leaveROTC:
            return .education
        case .workHard, .network, .pivotCareer, .trainNewSkill, .retire, .jobHunt, .takeOvertime, .takeExtraShifts, .chaseSpotlight, .startMovieActor, .auditionRole, .actingClass, .buildActingReel, .takeIndieRole, .managePublicist, .startMusicProducer, .produceTrack, .runStudioSession, .shopBeats, .collaborateWithArtist, .polishSignatureSound, .manageProducerCredits, .startMovieProducer, .optionScript, .castProject, .shootFilm, .handleProductionCrisis, .secureDistribution, .manageBackEndPoints, .startRecordLabel, .signArtist, .developArtist, .releaseRecord, .bookTour, .payArtists, .pushSingle, .handleArtistDrama, .startCoachingCareer, .recruitTalent, .hireCoachingStaff, .installSystem, .runTrainingCamp, .manageLockerRoom, .callBigGame, .handleBoosterPressure, .startCompany, .pitchDeck, .pivotBusiness, .raiseCapital, .aggressiveExpansion, .ipoExit, .hireAdvisor, .compete, .intenseTraining, .recoveryFocus, .mediaAppearance, .teamBonding, .extraTrainingSession, .edgeProtocol, .gatherIntelligence, .exploitLeverage, .applyForResidency, .completeResidency, .openPrivatePractice, .passBarExam, .makePartner, .becomeCTO, .launchStartupSpinOff,
             .closeMajorDeal, .allHandsRally, .fundraiseSprint, .takeRealBreak, .hireKeyTalent,
             .postDaily, .goLive, .filmBanger, .collab, .addressDrama, .takeMentalBreak, .dropBrandDeal,
             .townHall, .politicalFundraise, .scandalResponse, .policyPush, .backroomDeal, .mediaHit, .takeAStand, .attackOpponent:
            return .career
        case .enlistArmy, .enlistNavy, .enlistAirForce, .enlistMarines, .enlistCoastGuard, .enlistSpaceForce, .commissionArmy, .commissionNavy, .commissionAirForce, .commissionMarines, .commissionCoastGuard, .commissionSpaceForce, .joinReservesArmy, .joinReservesNavy, .joinReservesAirForce, .joinReservesMarines, .joinReservesCoastGuard, .joinReservesSpaceForce, .militaryService, .deploy, .goAWOL, .desert, .militaryRetirement, .selectCombatMOS, .selectMedicalMOS, .selectAviationMOS, .selectIntelMOS, .selectLogisticsMOS, .ptFocus, .seekCounsel, .studyTradition, .deployTour:
            return .military
        case .runScheme, .layLow, .buildCrew, .cleanMoney, .stepAway,
             .ghostProtocol, .burnEvidence, .payTheFixer, .launderThroughShell, .hostStrategicGala, .aggressiveTakeover:
            return .crime
        case .cutSpending, .spendForRelief, .spendToCope, .saveForEscape, .payDownDebt, .consolidateDebt, .minimumPayments, .deferStudentLoans, .declareBankruptcy, .dayTrade, .analyzeMarkets, .buyStocks, .sellStocks, .buyCrypto, .sellCrypto, .buyRentalProperty, .sellRentalProperty, .manageRentals, .claimPension,
             .saveForDownPayment, .depositToHouseFund, .buyStarterHome, .refinanceMortgage, .buildMaintenanceReserve, .topUpHouseReserve, .sellHome,
             .buildEmergencyFund, .buyIndexFund, .speculateStocks, .holdPositions, .sellToCover, .takeSideWork, .smallHustle, .takeExtraShifts,
             .panicSell, .aggressiveSideHustle, .bigLifestylePurchase, .rideTheWave, .quietFinancialQuit:
            return .finance
        case .reachOut, .repairTension, .keepDistance, .discussFuture, .moveInTogether, .callInFavor, .startAffair, .endAffair, .buyEngagementRing, .signPrenup, .proposeMarriage, .planWedding, .fileForDivorce:
            return .relationships
        case .seeDoctor, .rest, .protectSleep, .pushThrough, .seekVAHealthcare:
            return .health
        case .tryForBaby, .avoidPregnancy, .letChanceDecide, .checkInOnChild, .spendTimeWithKids, .enforceRoutine, .encourageIndependence:
            return .family
        // D1 new actions
        case .morningReflection, .reconcileWithPast, .tryNewPersona, .publicReset, .therapySession, .processCrisis:
            return .identity
        case .ptFocus, .seekCounsel, .studyTradition, .deployTour:
            return .military
        case .familyMeal, .storyTime:
            return .family
        // D2 new actions
        case .curateCollection, .hostSignatureEvent, .maintainAsset:
            return .finance
        case .recurringTherapy, .manageMeds, .bodyConditioning:
            return .health
        case .deepenSpecificBond, .fuelRivalry, .splitReputation:
            return .relationships
        // D3 education
        case .pursueTradeCert, .honorsTrack, .uniApplication, .lifelongLearning, .credentialRefresh:
            return .education
        // D3 regular career
        case .corporateClimb, .freelanceHustle, .tradesMastery, .pivotToGig, .publicServiceGrind, .techDeepWork:
            return .career
        default:
            return .career
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "phoneItIn":
            self = .layLow
        default:
            guard let value = ActionChoiceID(rawValue: rawValue) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ActionChoiceID: \(rawValue)")
            }
            self = value
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct PlayerYearAction: Codable, Equatable, Identifiable {
    var domain: ActionDomain
    var choiceID: ActionChoiceID

    var id: String { domain.rawValue }
}

struct ActionMemoryEntry: Codable, Equatable, Identifiable {
    var age: Int
    var domain: ActionDomain
    var choiceID: ActionChoiceID

    var id: String { "\(age)-\(domain.rawValue)-\(choiceID.rawValue)" }
}

struct ActionMemoryState: Codable, Equatable {
    var currentAge: Int? = nil
    var recentActions: [ActionMemoryEntry] = []
    var lastActionByDomain: [String: ActionChoiceID] = [:]

    var latestAction: PlayerYearAction? {
        recentActions.last.map { PlayerYearAction(domain: $0.domain, choiceID: $0.choiceID) }
    }

    var actionsThisAge: [PlayerYearAction] {
        recentActions.map { PlayerYearAction(domain: $0.domain, choiceID: $0.choiceID) }
    }

    func lastAction(for domain: ActionDomain) -> ActionChoiceID? {
        lastActionByDomain[domain.rawValue]
    }

    mutating func record(action: PlayerYearAction, age: Int) {
        if currentAge != age {
            currentAge = age
            recentActions = []
        }

        recentActions.removeAll { $0.domain == action.domain }
        recentActions.append(ActionMemoryEntry(age: age, domain: action.domain, choiceID: action.choiceID))
        lastActionByDomain[action.domain.rawValue] = action.choiceID

        if recentActions.count > 6 {
            recentActions = Array(recentActions.suffix(6))
        }
    }

    mutating func clearForNewAge(_ age: Int) {
        currentAge = age
        recentActions = []
    }
}

struct QuickActionMemoryState: Codable, Equatable {
    var currentAge: Int? = nil
    var completedThisAge: [ActionMemoryEntry] = []
    var maxActionsPerAge: Int = 3

    var countThisAge: Int { completedThisAge.count }

    mutating func rolloverIfNeeded(age: Int) {
        if currentAge != age {
            currentAge = age
            completedThisAge = []
        }
    }

    mutating func canPerform(_ action: PlayerYearAction, age: Int) -> Bool {
        rolloverIfNeeded(age: age)
        return !completedThisAge.contains { $0.domain == action.domain && $0.choiceID == action.choiceID }
            && completedThisAge.count < maxActionsPerAge
    }

    mutating func blockReason(for action: PlayerYearAction, age: Int) -> String? {
        rolloverIfNeeded(age: age)
        if completedThisAge.contains(where: { $0.domain == action.domain && $0.choiceID == action.choiceID }) {
            return "Already done this year."
        }
        if completedThisAge.count >= maxActionsPerAge {
            return "Quick actions are used up for this year."
        }
        return nil
    }

    mutating func record(_ action: PlayerYearAction, age: Int) {
        rolloverIfNeeded(age: age)
        guard !completedThisAge.contains(where: { $0.domain == action.domain && $0.choiceID == action.choiceID }) else { return }
        completedThisAge.append(ActionMemoryEntry(age: age, domain: action.domain, choiceID: action.choiceID))
    }
}

// MARK: - Engine1: Lightweight System Correlation Ledger
// Low-overhead bus that lets Instant layer, Autonomous systems, and Background engines
// publish and read very cheap signals without full simulation every frame.
// Designed for high correlation with minimal cost (fixed small size + automatic decay).

struct CorrelationSignal: Codable, Equatable {
    enum Kind: String, Codable, Equatable {
        case instantActionPulse      // Player did a meaningful instant/quick action
        case autonomousReaction      // An autonomous system reacted (NPC, finance, health, etc.)
        case momentumEcho            // Strong momentum carry from instant → yearly
        case economicPressureShift   // WorldEra or finance stress changed meaningfully
        case npcAutonomyPulse        // NPC autonomy system fired something noticeable
        case worldAutonomyPulse      // Macro/world event or era shift
        case focusStance             // D4: yearly focus/stance chosen or completed (residue + autonomy reactivity + silent flavor)
    }

    var kind: Kind
    var domain: String?              // e.g. "finance", "relationships", "career"
    var strength: Int                // 0-100 scale (higher = more significant)
    var age: Int                     // When the signal was recorded
}

struct SystemCorrelationLedger: Codable, Equatable {
    private var signals: [CorrelationSignal] = []
    private let maxSignals = 12      // Hard cap for low overhead

    // Engine4: Echo system - high-correlation moments can schedule future consequences
    private var echoHooks: [CorrelationEcho] = []
    private let maxEchoHooks = 6

    mutating func publish(_ signal: CorrelationSignal) {
        signals.removeAll { $0.kind == signal.kind && $0.domain == signal.domain }
        signals.append(signal)

        if signals.count > maxSignals {
            signals.sort { $0.strength > $1.strength }
            signals = Array(signals.prefix(maxSignals))
        }
    }

    /// Returns recent signals, optionally filtered by kind and minimum strength.
    func recentSignals(kind: CorrelationSignal.Kind? = nil, minStrength: Int = 0, sinceAge: Int? = nil) -> [CorrelationSignal] {
        signals.filter { sig in
            (kind == nil || sig.kind == kind) &&
            sig.strength >= minStrength &&
            (sinceAge == nil || sig.age >= sinceAge!)
        }
        .sorted { $0.age > $1.age }
    }

    /// Total "heat" from recent instant/autonomous activity
    var recentActivityLevel: Int {
        let recent = signals.filter { $0.age > (signals.first?.age ?? 0) - 3 }
        return min(100, recent.reduce(0) { $0 + $1.strength } / max(1, recent.count))
    }

    mutating func decay(oldAge: Int) {
        signals.removeAll { $0.age < oldAge - 8 }

        // Engine4: Also clean old echo hooks
        echoHooks.removeAll { $0.dueAge < oldAge }
    }

    // Engine4: Record a high-correlation "echo" that can fire later
    mutating func recordEcho(tag: String, dueAge: Int, strength: Int, domain: String?) {
        let echo = CorrelationEcho(tag: tag, dueAge: dueAge, strength: strength, domain: domain)
        echoHooks.removeAll { $0.tag == tag && $0.domain == domain }
        echoHooks.append(echo)

        if echoHooks.count > maxEchoHooks {
            echoHooks.sort { $0.strength > $1.strength }
            echoHooks = Array(echoHooks.prefix(maxEchoHooks))
        }
    }

    func pendingEchoes(currentAge: Int) -> [CorrelationEcho] {
        echoHooks.filter { $0.dueAge <= currentAge }
    }

    mutating func consumeEcho(_ echo: CorrelationEcho) {
        echoHooks.removeAll { $0.tag == echo.tag && $0.dueAge == echo.dueAge }
    }
}

struct CorrelationEcho: Codable, Equatable {
    var tag: String
    var dueAge: Int
    var strength: Int
    var domain: String?
}

struct PressureCause: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var domain: String
    var label: String
    var delta: Int
    var age: Int
    var sourceAction: ActionChoiceID?
}

struct CorrelationHook: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var tag: String
    var domain: String
    var dueAge: Int
    var strength: Int
    var sourceAction: ActionChoiceID?
}

struct CorrelationLedger: Codable, Equatable {
    var actionCounts: [String: Int] = [:]
    var domainResidue: [String: Int] = [:]
    var pressureCauses: [PressureCause] = []
    var npcImpressions: [String: [String: Int]] = [:]
    var unresolvedHooks: [CorrelationHook] = []

    mutating func recordAction(_ action: PlayerYearAction) -> Int {
        let key = action.choiceID.rawValue
        actionCounts[key, default: 0] += 1
        return actionCounts[key, default: 0]
    }

    mutating func adjustResidue(domain: String, delta: Int) {
        guard delta != 0 else { return }
        domainResidue[domain] = (domainResidue[domain, default: 0] + delta).clamped(to: -100...100)
        if domainResidue[domain] == 0 {
            domainResidue.removeValue(forKey: domain)
        }
    }

    mutating func recordPressureCause(domain: String, label: String, delta: Int, age: Int, sourceAction: ActionChoiceID?) {
        guard delta != 0 else { return }
        pressureCauses.append(
            PressureCause(
                domain: domain,
                label: label,
                delta: delta,
                age: age,
                sourceAction: sourceAction
            )
        )
        if pressureCauses.count > 30 {
            pressureCauses = Array(pressureCauses.suffix(30))
        }
    }

    mutating func adjustNPCImpression(id: String, key: String, delta: Int) {
        guard delta != 0 else { return }
        var impressions = npcImpressions[id, default: [:]]
        impressions[key] = (impressions[key, default: 0] + delta).clamped(to: -100...100)
        npcImpressions[id] = impressions.filter { $0.value != 0 }
        if npcImpressions[id]?.isEmpty == true {
            npcImpressions.removeValue(forKey: id)
        }
    }

    mutating func upsertHook(tag: String, domain: String, dueAge: Int, strength: Int, sourceAction: ActionChoiceID?) {
        if let index = unresolvedHooks.firstIndex(where: { $0.tag == tag && $0.domain == domain && $0.sourceAction == sourceAction }) {
            unresolvedHooks[index].dueAge = min(unresolvedHooks[index].dueAge, dueAge)
            unresolvedHooks[index].strength = max(unresolvedHooks[index].strength, strength)
        } else {
            unresolvedHooks.append(
                CorrelationHook(
                    tag: tag,
                    domain: domain,
                    dueAge: dueAge,
                    strength: strength,
                    sourceAction: sourceAction
                )
            )
        }
        if unresolvedHooks.count > 20 {
            unresolvedHooks = Array(unresolvedHooks.suffix(20))
        }
    }

    func pressureCauseLine(for domain: String, limit: Int = 2) -> String? {
        let causes = pressureCauses
            .filter { $0.domain == domain }
            .sorted { lhs, rhs in
                if lhs.age == rhs.age {
                    return abs(lhs.delta) > abs(rhs.delta)
                }
                return lhs.age > rhs.age
            }
            .prefix(limit)
            .map { "\($0.label) \($0.delta > 0 ? "+" : "")\($0.delta)" }
        guard !causes.isEmpty else { return nil }
        return causes.joined(separator: ", ")
    }

    // Engine1+ compatibility + real low-overhead bus for engine collaboration.
    // All background engines (Silent, Continuity, WorldAuto, NPCAuto) + instant publishers
    // read/write the same tiny capped structure so they can influence each other cheaply
    // without duplicating state or heavy computation.
    private var signals: [CorrelationSignal] = []
    private let maxSignals = 12
    private var echoHooks: [CorrelationEcho] = []
    private let maxEchoHooks = 6

    var recentActivityLevel: Int {
        // Prefer real signals if present (from Engine1 publish path); fallback to action count approx.
        if !signals.isEmpty {
            let recent = signals.filter { $0.age > (signals.first?.age ?? 0) - 3 }
            return min(100, recent.reduce(0) { $0 + $1.strength } / max(1, recent.count))
        }
        let total = actionCounts.values.reduce(0, +)
        return min(100, total * 3)
    }

    mutating func publish(_ signal: CorrelationSignal) {
        // Low overhead: dedup same kind/domain, cap at 12, keep strongest.
        signals.removeAll { $0.kind == signal.kind && $0.domain == signal.domain }
        signals.append(signal)

        if signals.count > maxSignals {
            signals.sort { $0.strength > $1.strength }
            signals = Array(signals.prefix(maxSignals))
        }
    }

    mutating func recordEcho(tag: String, dueAge: Int, strength: Int, domain: String?) {
        let echo = CorrelationEcho(tag: tag, dueAge: dueAge, strength: strength, domain: domain)
        echoHooks.removeAll { $0.tag == tag && $0.domain == domain }
        echoHooks.append(echo)

        if echoHooks.count > maxEchoHooks {
            echoHooks.sort { $0.strength > $1.strength }
            echoHooks = Array(echoHooks.prefix(maxEchoHooks))
        }
    }

    mutating func decay(oldAge: Int) {
        signals.removeAll { $0.age < oldAge - 8 }
        echoHooks.removeAll { $0.dueAge < oldAge }
    }

    func pendingEchoes(currentAge: Int) -> [CorrelationEcho] {
        echoHooks.filter { $0.dueAge <= currentAge }
    }

    mutating func consumeEcho(_ echo: CorrelationEcho) {
        echoHooks.removeAll { $0.tag == echo.tag && $0.dueAge == echo.dueAge }
    }

    /// Returns recent signals (for cross-engine reads, e.g. SilentYear reacting to autonomy pulses).
    /// Kept tiny and cheap. (real impl now lives on the active ledger)
    func recentSignals(kind: CorrelationSignal.Kind? = nil, minStrength: Int = 0, sinceAge: Int? = nil) -> [CorrelationSignal] {
        signals.filter { sig in
            (kind == nil || sig.kind == kind) &&
            sig.strength >= minStrength &&
            (sinceAge == nil || sig.age >= sinceAge!)
        }
        .sorted { $0.age > $1.age }
    }
}

enum ActionFrictionLevel: String, Codable, Equatable {
    case none
    case resistance // Harder to press, visual jitter
    case warning // Red pulse, heavy haptics
    case danger // Severe warning
    case locked // Cannot be selected due to state
}

enum ActionResolutionTier: String, Codable, Equatable, CaseIterable {
    /// BitLife-style tap: resolves immediately via `applyImmediateAction`.
    case instant
    /// Macro intent: queued in `pendingActions` and applied when the year resolves on Age Up.
    case committed
}

struct ActionChoiceDefinition: Equatable {
    var choiceID: ActionChoiceID
    var title: String
    var subtitle: String
    var detail: String = ""
    var identityLine: String
    var previewTags: [String]
    var preferredEventTags: [String: Int] = [:]
    
    // Friction & Micro-Beats
    var microBeat: String = "You make your move."
    var baseFriction: ActionFrictionLevel = .none
}

enum ActionChoiceCatalog {
    static func definition(for choiceID: ActionChoiceID) -> ActionChoiceDefinition {
        switch choiceID {
        case .studyHard:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Bury Yourself In The Work", subtitle: "Trade ease for standing.", identityLine: "You decide effort matters more than comfort this year.", previewTags: ["Standing", "Support", "Mood cost"], preferredEventTags: ["school": 7, "routine": 4], microBeat: "The library lights are humming.", baseFriction: .resistance)
        case .studyConsistently:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Disappear Into Your Schoolwork", subtitle: "Build slow, reliable traction.", identityLine: "You choose discipline over drama and let consistency define the year.", previewTags: ["Standing", "Readiness", "Burnout down"], preferredEventTags: ["school": 8, "routine": 5], microBeat: "One page at a time.", baseFriction: .none)
        case .cramAndSurvive:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hold It Together At The Last Minute", subtitle: "Results now, recovery later.", identityLine: "You decide to survive the pressure rather than solve it cleanly.", previewTags: ["Standing", "Burnout", "Recovery loss"], preferredEventTags: ["school": 6, "health": 2], microBeat: "Your eyes are stinging.", baseFriction: .resistance)
        case .lockInRoutine:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lock Into A Routine", subtitle: "Make structure your shield.", identityLine: "You want the year to feel controlled, even if it gets smaller.", previewTags: ["Standing", "Pressure down", "Teacher support"], preferredEventTags: ["routine": 6, "school": 5, "health": 2], microBeat: "The clock is your only friend.", baseFriction: .none)
        case .joinActivity:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Step Into Something Bigger", subtitle: "Choose visibility and structure.", identityLine: "You decide belonging is worth the risk of being seen.", previewTags: ["Belonging", "Momentum", "+Friends"], preferredEventTags: ["school": 4, "social": 6], microBeat: "Deep breath. Walk in.", baseFriction: .none)
        case .joinClub:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Put Yourself Out There", subtitle: "Try belonging on purpose.", identityLine: "You make a deliberate move toward people instead of waiting to be chosen.", previewTags: ["Belonging", "Mentor shot", "Friends"], preferredEventTags: ["social": 7, "school": 4], microBeat: "Scanning the room.", baseFriction: .none)
        case .buildPortfolio:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build Toward The Exit", subtitle: "Turn effort into options.", identityLine: "You treat this year like a proving ground for whatever comes next.", previewTags: ["Readiness", "Future fit", "Free time"], preferredEventTags: ["career": 5, "school": 5], microBeat: "Stacking the deck.", baseFriction: .none)
        case .layLow:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Keep Your Head Down", subtitle: "Reduce exposure, not tension.", identityLine: "You decide staying out of sight is safer than reaching for more.", previewTags: ["Pressure down", "Exposure down", "Momentum loss"], preferredEventTags: ["routine": 3, "health": 3], microBeat: "Stay invisible.", baseFriction: .none)
        case .skipClass:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Walk Away From The Day", subtitle: "Short relief, long memory.", identityLine: "You choose immediate breathing room and accept that school may remember it.", previewTags: ["Relief", "Rumor risk", "Support loss"], preferredEventTags: ["school": 5, "risk": 5, "social": 3], microBeat: "The door clicks shut behind you.", baseFriction: .none)
        case .skipAndDrift:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Let The Year Slide", subtitle: "Stop pushing and see what breaks.", identityLine: "You stop fighting the drift and let the consequences catch up later.", previewTags: ["Relief", "Standing down", "Momentum loss"], preferredEventTags: ["school": 5, "risk": 3, "health": 2], microBeat: "Watching the ceiling.", baseFriction: .none)
        case .keepThePeace:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Smooth The Edges", subtitle: "Stability over ambition.", identityLine: "You spend the year avoiding conflict instead of chasing momentum.", previewTags: ["Drama down", "Belonging down", "Stability"], preferredEventTags: ["social": 4, "routine": 3], microBeat: "Just nod and smile.", baseFriction: .none)
        // Teen 2 precursors
        case .teenAthleticDrill:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Athletic Drill", subtitle: "Push the body, build the future.", identityLine: "You treat after-school sweat like an investment in a version of yourself that performs.", previewTags: ["Momentum", "Body", "Athlete seed"], preferredEventTags: ["school": 4, "health": 6], microBeat: "Lungs burning in a good way.", baseFriction: .resistance)
        case .teenSideHustle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Side Hustle", subtitle: "Turn spare time into edge.", identityLine: "You decide small money and small reputation now will compound into options later.", previewTags: ["Cash", "Readiness", "Founder seed"], preferredEventTags: ["finance": 5, "school": 3, "chance": 4], microBeat: "Counting small wins.", baseFriction: .none)
        case .teenCreativeProject:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Creative Project", subtitle: "Make something that is yours.", identityLine: "You spend real hours on work that might never be graded but feels like the real thing.", previewTags: ["Voice", "Belonging", "Creator seed"], preferredEventTags: ["school": 3, "social": 5, "creative": 6], microBeat: "The idea won't leave you alone.", baseFriction: .none)
        case .teenLeadInitiative:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lead Initiative", subtitle: "Step up and be counted.", identityLine: "You organize something that requires other people to trust you. The taste of it is addictive.", previewTags: ["Presence", "Support", "Politics seed"], preferredEventTags: ["social": 7, "school": 4], microBeat: "People are looking at you.", baseFriction: .none)
        case .teenRiskyExperiment:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Risky Experiment", subtitle: "See what you can get away with.", identityLine: "You test a boundary because the safe version of the year feels too small.", previewTags: ["Heat", "Network", "Crime seed"], preferredEventTags: ["risk": 7, "money": 4, "school": 2], microBeat: "Adrenaline and second thoughts.", baseFriction: .warning)
        case .workHard:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lean Into The Grind", subtitle: "Push for traction.", identityLine: "You decide this year should move forward even if your body complains.", previewTags: ["Performance", "Mental cost"], preferredEventTags: ["career": 8, "money": 3], microBeat: "The coffee is cold. Again.", baseFriction: .resistance)
        case .protectYourEnergy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Protect Your Energy", subtitle: "Keep the job from eating the rest of you.", identityLine: "You decide your life has to remain livable, even if it slows your climb.", previewTags: ["Burnout down", "Health up", "Momentum softer"], preferredEventTags: ["health": 7, "routine": 5, "career": 2], microBeat: "Closing the laptop.", baseFriction: .none)
        case .network:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Work The Room", subtitle: "Visibility through people, not output alone.", identityLine: "You treat relationships as career infrastructure and accept the weirdness that comes with that.", previewTags: ["Promotion shot", "Contacts", "Authenticity cost"], preferredEventTags: ["career": 6, "social": 6, "chance": 3], microBeat: "Shake hands. Repeat.", baseFriction: .none)
        case .retrain:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Retrain For A Different Future", subtitle: "Pay now to stop repeating this version of work.", identityLine: "You decide this year should buy a new lane, not just survive the old one.", previewTags: ["Future fit", "Cash cost", "Short-term strain"], preferredEventTags: ["career": 7, "school": 4, "money": 3], microBeat: "Back to basics.", baseFriction: .resistance)
        case .takeOvertime:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Overtime", subtitle: "Push the margin harder.", identityLine: "You decide money needs to move now, even if the rest of life gets tighter.", previewTags: ["Cash up", "Burnout", "Relationship cost"], preferredEventTags: ["money": 8, "career": 5, "health": 3], microBeat: "One more hour. Then another.", baseFriction: .resistance)
        case .coast:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Phone It In", subtitle: "Stay employed, not invested.", identityLine: "You stop pretending work deserves your best energy this year.", previewTags: ["Ease", "Performance loss", "Drift"], preferredEventTags: ["routine": 3, "career": 2, "health": 2], microBeat: "Doing the minimum.", baseFriction: .none)
        case .jobHunt:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go Looking For A Better Door", subtitle: "Trade certainty for possibility.", identityLine: "You decide your current setup is not enough and start reaching outward.", previewTags: ["Cash shot", "Work shot"], preferredEventTags: ["career": 7, "chance": 3], microBeat: "Refreshing the inbox.", baseFriction: .none)
        case .chaseSpotlight:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Step Into The Spotlight", subtitle: "Visibility with volatility.", identityLine: "You want this year to notice you, even if it gets unstable fast.", previewTags: ["Fame shot", "Audience", "Stability loss"], preferredEventTags: ["career": 5, "social": 4, "risk": 5], microBeat: "All eyes on you.", baseFriction: .warning)
        case .startMovieActor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become Movie Actor", subtitle: "Audition for screen work.", identityLine: "You decide the camera is the room you want to survive in.", previewTags: ["Acting", "Auditions", "Fame shot"], preferredEventTags: ["career": 8, "fame": 5], microBeat: "The reader starts the scene.", baseFriction: .resistance)
        case .auditionRole:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Audition For Role", subtitle: "Chase the part.", identityLine: "You decide rejection is the price of being seen by the right room.", previewTags: ["Role shot", "Fame", "Burnout"], preferredEventTags: ["career": 8, "chance": 5, "fame": 5], microBeat: "Slate. Breath. Line.", baseFriction: .resistance)
        case .actingClass:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Acting Class", subtitle: "Build craft before attention.", identityLine: "You decide the work has to get better before the world gets louder.", previewTags: ["Craft +", "Range +", "Cash cost"], preferredEventTags: ["career": 7, "routine": 4], microBeat: "Again, but honest this time.", baseFriction: .none)
        case .buildActingReel:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build Acting Reel", subtitle: "Package the proof.", identityLine: "You decide talent needs evidence people can watch in two minutes.", previewTags: ["Auditions +", "Visibility", "Cash cost"], preferredEventTags: ["career": 7, "fame": 3], microBeat: "The best takes survive.", baseFriction: .none)
        case .takeIndieRole:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Indie Role", subtitle: "Trade money for credits.", identityLine: "You decide a strange little film might teach you more than waiting.", previewTags: ["Credits +", "Craft", "Low pay"], preferredEventTags: ["career": 7, "creative": 5], microBeat: "Tiny crew. Real work.", baseFriction: .none)
        case .managePublicist:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage Publicist", subtitle: "Shape the public story.", identityLine: "You decide the performance does not end when the camera cuts.", previewTags: ["Heat down", "Brand +", "Cash cost"], preferredEventTags: ["social": 6, "risk": 5, "fame": 4], microBeat: "The quote gets cleaned up.", baseFriction: .warning)
        case .startMusicProducer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become Music Producer", subtitle: "Build the sound behind the artist.", identityLine: "You decide your place in music is behind the board, shaping the record before anyone hears it.", previewTags: ["Credits", "Royalties", "Studio cost"], preferredEventTags: ["career": 8, "fame": 4, "money": 4], microBeat: "The session opens.", baseFriction: .resistance)
        case .produceTrack:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Produce Track", subtitle: "Turn a session into a credit.", identityLine: "You decide this beat, mix, and arrangement can carry your name further.", previewTags: ["Credit +", "Royalty shot", "Demand"], preferredEventTags: ["career": 8, "fame": 5, "money": 5], microBeat: "The drums finally hit.", baseFriction: .resistance)
        case .runStudioSession:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Run Studio Session", subtitle: "Keep the room productive.", identityLine: "You decide the vibe, the clock, and the take all need your hand on them.", previewTags: ["Network +", "Studio +", "Burnout"], preferredEventTags: ["career": 7, "social": 5], microBeat: "Take it from the top.", baseFriction: .none)
        case .shopBeats:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Shop Beats", subtitle: "Find the right ears.", identityLine: "You decide the hard drive is worthless unless the right artist hears what is on it.", previewTags: ["Demand +", "Cash shot", "Rejection"], preferredEventTags: ["career": 6, "money": 5, "chance": 4], microBeat: "The folder gets sent.", baseFriction: .none)
        case .collaborateWithArtist:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Collaborate With Artist", subtitle: "Borrow chemistry.", identityLine: "You decide the record needs another person's gravity, not just your control.", previewTags: ["Network", "Credit risk", "Hit chance"], preferredEventTags: ["social": 7, "career": 7], microBeat: "The room changes.", baseFriction: .resistance)
        case .polishSignatureSound:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Polish Signature Sound", subtitle: "Become recognizable.", identityLine: "You decide the sound needs to become yours before the industry can pay for it.", previewTags: ["Signature +", "Quality +", "Slow money"], preferredEventTags: ["routine": 6, "career": 6], microBeat: "You mute everything except the feeling.", baseFriction: .none)
        case .manageProducerCredits:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage Producer Credits", subtitle: "Protect the paperwork.", identityLine: "You decide the song is not done until the split sheet tells the truth.", previewTags: ["Disputes down", "Royalties", "Relationship risk"], preferredEventTags: ["money": 6, "risk": 7], microBeat: "The split sheet gets signed.", baseFriction: .warning)
        case .startMovieProducer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become Movie Producer", subtitle: "Put money and taste behind films.", identityLine: "You decide the next chapter is assembling the people, money, and chaos that make movies real.", previewTags: ["Diamond", "Slate", "Cash risk"], preferredEventTags: ["career": 8, "money": 6, "risk": 5], microBeat: "The script hits your desk.", baseFriction: .warning)
        case .optionScript:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Option Script", subtitle: "Buy a story before it exists.", identityLine: "You decide this idea is worth locking up before someone braver does.", previewTags: ["Slate +", "IP", "Cash cost"], preferredEventTags: ["career": 8, "money": 4], microBeat: "The option agreement lands.", baseFriction: .resistance)
        case .castProject:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cast Project", subtitle: "Attach people with gravity.", identityLine: "You decide the movie needs faces that make money answer the phone.", previewTags: ["Cast +", "Prestige", "Burn rate"], preferredEventTags: ["career": 8, "social": 6], microBeat: "Availability is everything.", baseFriction: .resistance)
        case .shootFilm:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Shoot Film", subtitle: "Turn the slate into footage.", identityLine: "You decide the only way out is through the production calendar.", previewTags: ["Film shot", "Overruns", "Prestige"], preferredEventTags: ["career": 8, "money": 6, "risk": 6], microBeat: "First day of principal.", baseFriction: .warning)
        case .handleProductionCrisis:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Handle Production Crisis", subtitle: "Stop chaos from becoming fatal.", identityLine: "You decide to solve the thing nobody wants to own.", previewTags: ["Chaos down", "Trust", "Cash cost"], preferredEventTags: ["risk": 8, "career": 6], microBeat: "Everyone is waiting.", baseFriction: .warning)
        case .secureDistribution:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Secure Distribution", subtitle: "Get the film seen and paid.", identityLine: "You decide a finished movie is still a liability until someone can sell it.", previewTags: ["Revenue shot", "Prestige", "Leverage"], preferredEventTags: ["money": 8, "career": 7], microBeat: "The offer letter opens.", baseFriction: .resistance)
        case .manageBackEndPoints:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage Backend Points", subtitle: "Protect payout math.", identityLine: "You decide the glamour can wait until the contracts make sense.", previewTags: ["Backend +", "Chaos down", "Relationship risk"], preferredEventTags: ["money": 7, "risk": 6], microBeat: "Every percentage has a lawyer.", baseFriction: .warning)
        case .startRecordLabel:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Start Record Label", subtitle: "Own the machine behind the music.", identityLine: "You decide the next chapter is not performing for the industry. It is building one.", previewTags: ["Roster", "Catalog", "Cash risk"], preferredEventTags: ["career": 8, "money": 5, "fame": 5], microBeat: "The label name goes on the contract.", baseFriction: .resistance)
        case .signArtist:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Sign New Artist", subtitle: "Bet on raw talent.", identityLine: "You decide someone else's voice is worth your money, time, and reputation.", previewTags: ["Roster +", "Cash cost", "Upside"], preferredEventTags: ["career": 8, "social": 5, "money": 4], microBeat: "The demo plays again.", baseFriction: .resistance)
        case .developArtist:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Develop Artist", subtitle: "Turn potential into work.", identityLine: "You decide the slow studio hours matter more than chasing a quick hit.", previewTags: ["Talent +", "Trust +", "Cash cost"], preferredEventTags: ["career": 7, "routine": 5], microBeat: "Another take from the top.", baseFriction: .none)
        case .releaseRecord:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Release Record", subtitle: "Add to the catalog.", identityLine: "You decide the song is ready to leave the room and face the world.", previewTags: ["Catalog", "Royalties", "Hit chance"], preferredEventTags: ["career": 8, "fame": 6, "money": 5], microBeat: "Upload scheduled.", baseFriction: .resistance)
        case .bookTour:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Book Tour", subtitle: "Put the roster on the road.", identityLine: "You decide the money is on stage, even if the road eats people alive.", previewTags: ["Tour upside", "Burnout", "Cancellation risk"], preferredEventTags: ["money": 8, "career": 6, "risk": 6], microBeat: "Dates go on sale.", baseFriction: .warning)
        case .payArtists:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pay Artists Fairly", subtitle: "Protect trust over margin.", identityLine: "You decide the people making the music should feel the money, not just the label.", previewTags: ["Trust +", "Heat down", "Cash cost"], preferredEventTags: ["social": 8, "money": 5], microBeat: "The statements are clean.", baseFriction: .none)
        case .pushSingle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push The Single", subtitle: "Spend for attention.", identityLine: "You decide this record needs a real campaign, not hope and a post.", previewTags: ["Popularity +", "Prestige", "Cash cost"], preferredEventTags: ["fame": 8, "money": 5, "career": 5], microBeat: "The hook follows you home.", baseFriction: .resistance)
        case .handleArtistDrama:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Handle Artist Drama", subtitle: "Keep the roster from cracking.", identityLine: "You decide to get in the room before the rumor becomes the story.", previewTags: ["Heat down", "Trust risk", "Morale"], preferredEventTags: ["risk": 8, "social": 6], microBeat: "Phones face down.", baseFriction: .warning)
        case .startCoachingCareer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become Program Coach", subtitle: "Run the whole sports machine.", identityLine: "You decide the next game is not played with your body. It is played through the people you can teach.", previewTags: ["Diamond", "Program", "Pressure"], preferredEventTags: ["career": 8, "sports": 7], microBeat: "The whistle hangs differently.", baseFriction: .warning)
        case .recruitTalent:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Recruit Talent", subtitle: "Win the living room.", identityLine: "You decide the season starts with convincing someone talented to believe you.", previewTags: ["Roster +", "Prestige", "Compliance risk"], preferredEventTags: ["career": 8, "social": 6], microBeat: "Family on one side. Future on the other.", baseFriction: .resistance)
        case .hireCoachingStaff:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hire Coaching Staff", subtitle: "Build the room behind the team.", identityLine: "You decide the program cannot be smarter than the people helping you run it.", previewTags: ["Staff +", "Culture", "Budget"], preferredEventTags: ["career": 7, "money": 4], microBeat: "Another headset joins the sideline.", baseFriction: .none)
        case .installSystem:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Install System", subtitle: "Teach the identity.", identityLine: "You decide what your team is supposed to become before the scoreboard argues back.", previewTags: ["Scheme +", "Development", "Short pain"], preferredEventTags: ["career": 8, "routine": 5], microBeat: "Whiteboard. Repetition. Again.", baseFriction: .resistance)
        case .runTrainingCamp:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Run Training Camp", subtitle: "Sharpen the roster.", identityLine: "You decide the team needs hard reps now so the season costs less later.", previewTags: ["Readiness +", "Injury risk", "Morale"], preferredEventTags: ["career": 8, "health": 3, "risk": 4], microBeat: "Two whistles. One more rep.", baseFriction: .warning)
        case .manageLockerRoom:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage Locker Room", subtitle: "Keep belief from splitting.", identityLine: "You decide culture is not a poster. It is every hard conversation nobody wants.", previewTags: ["Culture +", "Morale", "Drama down"], preferredEventTags: ["social": 8, "career": 6], microBeat: "The room gets quiet.", baseFriction: .none)
        case .callBigGame:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Call The Big Game", subtitle: "Risk the scheme under pressure.", identityLine: "You decide the moment needs your nerve, not just the binder.", previewTags: ["Win shot", "Prestige", "Heat"], preferredEventTags: ["career": 8, "chance": 6, "fame": 4], microBeat: "Fourth quarter. No hiding.", baseFriction: .warning)
        case .handleBoosterPressure:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Handle Booster Pressure", subtitle: "Survive the money people.", identityLine: "You decide who gets access without letting them own the program.", previewTags: ["Pressure down", "Budget risk", "Integrity"], preferredEventTags: ["money": 5, "risk": 7, "career": 6], microBeat: "Dinner with strings attached.", baseFriction: .warning)
        case .runScheme:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Chase Fast Money", subtitle: "Speed over safety.", identityLine: "You decide the clean route is too slow for the pressure you are under.", previewTags: ["Fast cash", "Heat", "Stability loss"], preferredEventTags: ["money": 5, "risk": 8], microBeat: "You check over your shoulder.", baseFriction: .warning)
        case .buildCrew:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build A Circle That Owes You", subtitle: "Power through people.", identityLine: "You choose influence and loyalty, knowing it will add pressure of its own.", previewTags: ["Loyalty", "Reach", "Pressure"], preferredEventTags: ["social": 5, "risk": 6], microBeat: "Making them an offer.", baseFriction: .warning)
        case .cleanMoney:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Make The Money Look Legit", subtitle: "Reduce heat at a cost.", identityLine: "You decide survival now depends on making your mess look stable.", previewTags: ["Heat down", "Cash cost", "Safety"], preferredEventTags: ["money": 4, "routine": 3], microBeat: "Scrubbing the trail.", baseFriction: .none)
        case .stepAway:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Back Away Before It Owns You", subtitle: "Choose air over pace.", identityLine: "You decide the year needs breathing room more than momentum.", previewTags: ["Exit risk", "Breathing room"], preferredEventTags: ["health": 5, "relationships": 2], microBeat: "Letting it go.", baseFriction: .none)
        // CE2: Dedicated instant actions for Criminal Enterprise paths
        case .ghostProtocol:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Ghost Protocol", subtitle: "Disappear for a while.", identityLine: "You decide the best move is to become very hard to find right now.", previewTags: ["Heat down", "Opportunity cost", "Isolation"], preferredEventTags: ["risk": 4, "routine": 3], microBeat: "Going dark.", baseFriction: .none)
        case .burnEvidence:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Burn The Evidence", subtitle: "Destroy what can be used against you.", identityLine: "You choose to erase proof even if it costs you leverage or money.", previewTags: ["Heat down", "Irreversible", "Loss"], preferredEventTags: ["risk": 5, "money": 3], microBeat: "Watching it burn.", baseFriction: .warning)
        case .payTheFixer:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pay The Fixer", subtitle: "Throw money at the problem.", identityLine: "You decide problems go away faster when the right person is well compensated.", previewTags: ["Heat down", "Cash cost", "Temporary"], preferredEventTags: ["money": 6, "risk": 4], microBeat: "Making the call.", baseFriction: .none)
        case .launderThroughShell:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Launder Through Shells", subtitle: "Make dirty money look clean.", identityLine: "You choose to spend time and resources making your cash harder to trace.", previewTags: ["Clean money up", "Time cost", "Complexity"], preferredEventTags: ["money": 5, "risk": 3], microBeat: "Paperwork and patience.", baseFriction: .none)
        case .hostStrategicGala:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Host The Strategic Gala", subtitle: "Use social cover.", identityLine: "You decide the best way to move right now is in plain sight, surrounded by the right people.", previewTags: ["Network up", "Social cost", "Cover"], preferredEventTags: ["social": 7, "risk": 3], microBeat: "Smiling for the room.", baseFriction: .none)
        case .aggressiveTakeover:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Aggressive Takeover", subtitle: "Move hard and fast.", identityLine: "You decide this is the moment to be ruthless. Win big or create enemies.", previewTags: ["Big swing", "Heat risk", "Reputation"], preferredEventTags: ["money": 7, "risk": 8], microBeat: "Going for the throat.", baseFriction: .warning)
        case .smallHustle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Scrape Together Your Own Money", subtitle: "A little freedom, a little strain.", identityLine: "You decide even a small cash buffer is worth carrying a little more weight.", previewTags: ["Cash", "-Mental", "Recovery loss"], preferredEventTags: ["money": 7, "career": 2], microBeat: "Counting every cent.", baseFriction: .none)
        case .takeExtraShifts:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Trade Your Time For Breathing Room", subtitle: "Cash now, stamina later.", identityLine: "You decide the margin matters more than rest this year.", previewTags: ["Cash", "Recovery loss", "School hit"], preferredEventTags: ["money": 7, "career": 4, "health": 3], microBeat: "Your feet ache.", baseFriction: .resistance)
        case .saveForEscape:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Stack Money For A Way Out", subtitle: "Live tight now, move later.", identityLine: "You frame the year as temporary sacrifice for future movement.", previewTags: ["Cash buffer", "Comfort loss"], preferredEventTags: ["money": 7, "housing": 3], microBeat: "Eyes on the exit.", baseFriction: .none)
        case .cutSpending:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Clamp Down And Get Through It", subtitle: "Shrink the year on purpose.", identityLine: "You decide control matters more than comfort until the pressure eases.", previewTags: ["Stress down", "Comfort loss"], preferredEventTags: ["money": 8, "routine": 3], microBeat: "Tightening the belt.", baseFriction: .none)
        case .spendForRelief:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Buy Yourself A Little Relief", subtitle: "Mood first, margin second.", identityLine: "You choose a lighter day now and let the numbers worry about themselves later.", previewTags: ["Mood", "Cash down"], preferredEventTags: ["spend": 7, "social": 2], microBeat: "Just this once.", baseFriction: .none)
        case .spendToCope:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Numb It With Spending", subtitle: "Temporary relief with a tail.", identityLine: "You let the stress pick the purchase and deal with the aftershock later.", previewTags: ["Relief", "Cash down", "Stress later"], preferredEventTags: ["spend": 8, "health": 2], microBeat: "Buying the silence.", baseFriction: .none)
        case .takeSideWork:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take Whatever Extra Work You Can Find", subtitle: "Stability through effort.", identityLine: "You choose labor over uncertainty and dare the year to keep up.", previewTags: ["Cash", "Mental cost", "Energy loss"], preferredEventTags: ["career": 5, "money": 6, "health": 2], microBeat: "Anything helps.", baseFriction: .resistance)
        case .payDownDebt:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Throw Real Money At The Balance", subtitle: "Trade comfort for future room.", identityLine: "You decide the debt should shrink this year even if your present gets tighter.", previewTags: ["Debt down", "Cash down", "Stress relief"], preferredEventTags: ["money": 8, "routine": 3], microBeat: "Watching the number fall.", baseFriction: .resistance)
        case .consolidateDebt:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Restructure The Damage", subtitle: "Buy breathing room at a price.", identityLine: "You decide the debt needs a different shape before it eats the whole year.", previewTags: ["Payments down", "Fees", "Relief cooldown"], preferredEventTags: ["money": 7, "chance": 2], microBeat: "Signing the paperwork.", baseFriction: .none)
        case .minimumPayments:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Keep The Accounts Barely Current", subtitle: "Survive this year first.", identityLine: "You decide staying afloat matters more than making a clean dent in the balance.", previewTags: ["Cash preserved", "Debt lingers", "Stress stays"], preferredEventTags: ["money": 7, "health": 2], microBeat: "Just enough to stay in the game.", baseFriction: .none)
        case .deferStudentLoans:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push The Student Debt Forward", subtitle: "Relief now, interest later.", identityLine: "You decide the present is too fragile to carry the full student payment this year.", previewTags: ["Cash relief", "Debt up later", "Stress"], preferredEventTags: ["money": 7, "school": 2], microBeat: "Kicking the bill down the road.", baseFriction: .resistance)
        case .declareBankruptcy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Let The Whole Thing Collapse On Paper", subtitle: "A brutal reset.", identityLine: "You decide surviving matters more than protecting the image of how this was supposed to go.", previewTags: ["Debt reset", "Wealth wiped", "Long shadow"], preferredEventTags: ["money": 8, "health": 3], microBeat: "Signing the surrender.", baseFriction: .warning)
        // Econ4: Rich instant economic actions with era + special career flavor
        case .panicSell:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Panic Sell And Get Out", subtitle: "Cut the bleeding now.", identityLine: "You decide the downside risk is no longer worth holding. Cash in hand feels safer than hope.", previewTags: ["Cash now", "Loss locked", "Relief"], preferredEventTags: ["money": 9, "risk": 4, "negative": 3], microBeat: "Selling at the bottom of your fear.", baseFriction: .warning)
        case .aggressiveSideHustle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go All In On Side Money", subtitle: "Grind when the main path is shaky.", identityLine: "You decide the official income isn't enough and you're willing to bleed for the gap.", previewTags: ["Extra cash", "Burnout risk", "Hidden hours"], preferredEventTags: ["money": 8, "career": 4, "health": 3], microBeat: "Another shift, another corner cut.", baseFriction: .resistance)
        case .bigLifestylePurchase:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Buy The Victory Lap", subtitle: "Spend like the good times are real.", identityLine: "You decide the numbers on the screen are permission to feel successful in public.", previewTags: ["Status up", "Cash down", "Lifestyle creep"], preferredEventTags: ["money": 6, "social": 5, "positive": 3], microBeat: "The keys feel heavy in the best way.", baseFriction: .none)
        case .rideTheWave:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Ride The Wave Hard", subtitle: "Lean all the way into the upswing.", identityLine: "You decide the economy is handing you a gift and you're not going to be the one who blinks first.", previewTags: ["Upside", "Risk on", "Momentum"], preferredEventTags: ["money": 7, "opportunity": 6, "career": 4], microBeat: "Saying yes to everything that feels hot.", baseFriction: .none)
        case .quietFinancialQuit:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Quiet Financial Quit", subtitle: "Protect what you still have.", identityLine: "You decide the game is rigged against you right now and the smartest move is to stop playing so loud.", previewTags: ["Risk down", "Growth paused", "Peace"], preferredEventTags: ["money": 5, "health": 4, "routine": 4], microBeat: "Choosing smaller to stay whole.", baseFriction: .none)
        // Assets3 instant actions
        case .flexLuxuryAsset:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Flex the Collection", subtitle: "Let people know what you own.", identityLine: "You decide the right move is to be seen with the toys.", previewTags: ["Status", "Social", "Fame risk"], preferredEventTags: ["social": 8, "opportunity": 4], microBeat: "Posting the keys.", baseFriction: .none)
        case .liquidateLuxury:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Liquidate the Toys", subtitle: "Cash out the lifestyle.", identityLine: "You decide the symbols of success are now liabilities.", previewTags: ["Cash now", "Prestige hit"], preferredEventTags: ["money": 9, "negative": 3], microBeat: "The garage is getting emptier.", baseFriction: .warning)
        case .upgradeCollection:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Level Up the Fleet", subtitle: "Make the toys even better.", identityLine: "You decide the current level of flex isn't enough.", previewTags: ["Prestige up", "Cash down"], preferredEventTags: ["money": 5, "social": 5], microBeat: "Bigger, faster, shinier.", baseFriction: .none)
        case .hostAtSignatureEstate:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Host at the Estate", subtitle: "Use the big house for influence.", identityLine: "You decide the property is a tool, not just a flex.", previewTags: ["Social", "Influence", "Cost"], preferredEventTags: ["social": 7, "career": 4], microBeat: "The guest list is strategic.", baseFriction: .none)
        case .buildEmergencyFund:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build A Real Cushion", subtitle: "Protect the floor first.", identityLine: "You decide resilience matters more than flashy upside this year.", previewTags: ["Cash floor", "Risk down", "Resilience"], preferredEventTags: ["money": 8, "routine": 4], microBeat: "Securing the floor.", baseFriction: .none)
        case .buyIndexFund:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Bet On The Long Run", subtitle: "Slow compounding over noise.", identityLine: "You choose patience and trust time to do more than adrenaline can.", previewTags: ["Compounding", "Liquidity loss", "Low drama"], preferredEventTags: ["money": 5, "chance": 2], microBeat: "Planting the seed.", baseFriction: .none)
        case .speculateStocks:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take A Swing", subtitle: "Accept volatility for upside.", identityLine: "You decide this year should feel alive enough to risk some instability.", previewTags: ["Upside", "Liquidity loss", "Volatility"], preferredEventTags: ["chance": 7, "money": 4, "risk": 4], microBeat: "Roll the dice.", baseFriction: .warning)
        case .holdPositions:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hold Your Nerve", subtitle: "Let the year play out.", identityLine: "You decide not every year needs a new move to matter.", previewTags: ["No new risk", "Ride returns"], preferredEventTags: ["money": 3], microBeat: "Still hands.", baseFriction: .none)
        case .sellToCover:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pull Money Back To Safety", subtitle: "Protect today from tomorrow.", identityLine: "You decide liquidity matters more than staying exposed to future upside.", previewTags: ["Cash", "Future growth loss", "Fees"], preferredEventTags: ["money": 5, "health": 1], microBeat: "Back to the bank.", baseFriction: .none)
        case .saveForDownPayment:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Start Building Toward A Place Of Your Own", subtitle: "Convert pressure into a target.", identityLine: "You turn this year into a long march toward stability you can point to.", previewTags: ["Home fund", "Flexible cash loss", "Stability goal"], preferredEventTags: ["housing": 6, "money": 6], microBeat: "Saving the keys.", baseFriction: .none)
        case .depositToHouseFund:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Deposit To House Fund", subtitle: "Move cash into a down-payment bucket now.", identityLine: "You earmark real money today instead of waiting for the year to decide.", previewTags: ["House fund up", "Cash down", "Ownership closer"], preferredEventTags: ["housing": 5, "money": 4], microBeat: "Saving the keys.", baseFriction: .none)
        case .buyStarterHome:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Make The Jump Into Ownership", subtitle: "Control with real weight attached.", identityLine: "You decide the next chapter should belong to you, even if the cost lingers.", previewTags: ["Equity", "Housing control", "Liquidity loss"], preferredEventTags: ["housing": 8, "money": 4], microBeat: "Signing the life away.", baseFriction: .resistance)
        case .refinanceMortgage:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Renegotiate The Weight", subtitle: "Buy breathing room.", identityLine: "You decide the year needs room to breathe more than pride about the original deal.", previewTags: ["Monthly cost down", "Breathing room", "Fees"], preferredEventTags: ["housing": 5, "money": 5], microBeat: "Changing the deal.", baseFriction: .none)
        case .buildMaintenanceReserve:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Prepare For The House To Ask Again", subtitle: "Plan for the next hit.", identityLine: "You decide stability means getting ahead of future problems before they arrive.", previewTags: ["Housing resilience", "Liquid cash down", "Surprise risk down"], preferredEventTags: ["housing": 7, "money": 4], microBeat: "Fortifying the walls.", baseFriction: .none)
        case .topUpHouseReserve:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Top Up Repair Reserve", subtitle: "Put cash aside before the house breaks something.", identityLine: "You fund the repair bucket now so the next leak does not become a crisis.", previewTags: ["Reserve up", "Cash down", "Repair risk down"], preferredEventTags: ["housing": 6, "money": 4], microBeat: "Fortifying the walls.", baseFriction: .none)
        case .sellHome:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cash Out And Reset", subtitle: "Trade permanence for flexibility.", identityLine: "You decide the year needs margin more than it needs roots.", previewTags: ["Cash", "Housing stability loss", "Flexibility"], preferredEventTags: ["housing": 6, "money": 5], microBeat: "Handing over the keys.", baseFriction: .none)
        // Econ1 (Stock Market)
        case .checkPortfolio:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Review Portfolio", subtitle: "Glance at the wins and scars.", identityLine: "You take a cold look at your positions. The numbers don't lie.", previewTags: ["Knowledge", "Market Pulse"], microBeat: "Scrolling through the deltas.", baseFriction: .none)
        case .rebalancePortfolio:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Rebalance Risk", subtitle: "Shift weight to protect the future.", identityLine: "You decide to adjust your exposure before the market decides for you.", previewTags: ["Risk Shift", "Momentum", "Fee hit"], microBeat: "Moving the sliders.", baseFriction: .resistance)
        case .researchTip:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Research Hot Sector", subtitle: "Chase the whisper of an edge.", identityLine: "You spend the afternoon digging into the data everyone else is ignoring.", previewTags: ["Intel", "Confidence", "Time cost"], microBeat: "Reading between the lines.", baseFriction: .none)
        case .buyIndex:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Buy Market Index", subtitle: "Broad exposure, steady growth.", identityLine: "You decide the whole market is better than any one bet.", previewTags: ["Cash down", "Index Fund up"], microBeat: "Setting up the auto-buy.", baseFriction: .none)
        case .sellPosition:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Liquidate Position", subtitle: "Turn paper wins into real cash.", identityLine: "You decide the cash is better in your hand than on the screen.", previewTags: ["Cash up", "Portfolio down"], microBeat: "Executing the trade.", baseFriction: .none)
        case .findYourCrowd:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Find Your People", subtitle: "Belonging on purpose.", identityLine: "You decide this year should feel less lonely, even if it gets messy.", previewTags: ["Belonging", "School", "Support"], preferredEventTags: ["social": 8, "school": 3], microBeat: "Finally, someone laughs.", baseFriction: .none)
        case .dateCarefully:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Let Someone In Carefully", subtitle: "Connection with caution.", identityLine: "You open the door to closeness without pretending it cannot complicate the year.", previewTags: ["Bond", "Belonging", "Risk"], preferredEventTags: ["romance": 8, "social": 3], microBeat: "A tentative text.", baseFriction: .none)
        case .startAffair:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Start an Affair", subtitle: "Seek connection on the side", detail: "Start a secret relationship. High risk of discovery and reputation damage.", identityLine: "You are leading a double life.", previewTags: ["Secret", "Rumor Heat", "Risk"], preferredEventTags: ["risk": 9, "social": 5], microBeat: "A late night text.", baseFriction: .warning)
        case .endAffair:
            return ActionChoiceDefinition(choiceID: choiceID, title: "End the Affair", subtitle: "Close the secret door", detail: "Break off your secret relationship before you get caught.", identityLine: "You are trying to fix your mistakes.", previewTags: ["Relief", "Safety"], preferredEventTags: ["social": 4], microBeat: "The final goodbye.", baseFriction: .none)
        case .buyEngagementRing:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Buy Engagement Ring", subtitle: "Prepare for the big question", detail: "Spend significant cash to buy a ring. Higher quality rings improve proposal success.", identityLine: "You are ready to commit.", previewTags: ["Cash cost", "Commitment"], preferredEventTags: ["money": 8, "social": 5], microBeat: "The box feels heavy in your pocket.", baseFriction: .resistance)
        case .signPrenup:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Sign Prenup", subtitle: "Protect your assets", detail: "A legal agreement to keep your finances separate. Lowers bond but provides security.", identityLine: "You are looking out for yourself.", previewTags: ["Financial Safety", "Bond hit"], preferredEventTags: ["money": 7], microBeat: "The lawyers are in the room.", baseFriction: .resistance)
        case .proposeMarriage:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Propose Marriage", subtitle: "Pop the question", detail: "Ask your partner to marry you. Success depends on bond and alignment.", identityLine: "You are taking the ultimate leap.", previewTags: ["Milestone", "Bond"], preferredEventTags: ["social": 10], microBeat: "The world holds its breath.", baseFriction: .none)
        case .planWedding:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Plan Wedding", subtitle: "The big day", detail: "Host a wedding. Costs significant cash but provides massive social capital.", identityLine: "You are celebrating your union.", previewTags: ["Cash cost", "Reputation", "Social Capital"], preferredEventTags: ["money": 10, "social": 10], microBeat: "Flowers and music.", baseFriction: .resistance)
        case .fileForDivorce:
            return ActionChoiceDefinition(choiceID: choiceID, title: "File for Divorce", subtitle: "End the union", detail: "End your marriage. Assets will be split 50/50 unless a prenup is active.", identityLine: "You are walking away.", previewTags: ["Asset Split", "Freedom", "Stress"], preferredEventTags: ["money": 9, "health": 6], microBeat: "Signing the papers.", baseFriction: .warning)
        case .chaseStatus:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Play For Attention", subtitle: "Visibility with heat.", identityLine: "You decide being seen matters enough to risk the backlash that follows.", previewTags: ["Visibility", "Peer heat", "Risk"], preferredEventTags: ["social": 6, "risk": 5], microBeat: "The likes are climbing.", baseFriction: .warning)
        case .stayInvisible:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Stay Hard To Reach", subtitle: "Minimize exposure.", identityLine: "You spend the year trying not to give anyone new leverage over you.", previewTags: ["Drama down", "Belonging down"], preferredEventTags: ["health": 2, "social": 1], microBeat: "Ghosting the noise.", baseFriction: .none)
        case .leanOnMentor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Let Someone Older Guide You", subtitle: "Borrow steadiness.", identityLine: "You decide the year needs perspective more than pride.", previewTags: ["Support", "Clarity", "Peer heat down"], preferredEventTags: ["school": 4, "career": 4, "social": 3], microBeat: "They've been here before.", baseFriction: .none)
        case .reachOut:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Reach Back Toward People", subtitle: "Repair the quiet distance.", identityLine: "You decide not every connection should be left to drift on its own.", previewTags: ["Bond", "Support"], preferredEventTags: ["social": 7, "relationships": 4], microBeat: "Breaking the silence.", baseFriction: .none)
        case .strengthenBond:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Invest In The Relationship You Already Have", subtitle: "Choose closeness on purpose.", identityLine: "You decide this year should feel more shared, not just survived side by side.", previewTags: ["Bond", "Security"], preferredEventTags: ["romance": 7, "family": 3], microBeat: "Holding on tight.", baseFriction: .none)
        case .discussFuture:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Force The Future Into The Room", subtitle: "Get clarity even if it stings.", identityLine: "You decide uncertainty is heavier than an honest conversation.", previewTags: ["Commitment", "Clarity"], preferredEventTags: ["romance": 6, "family": 3], microBeat: "The heavy question.", baseFriction: .resistance)
        case .moveInTogether:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Tie Your Daily Life Together", subtitle: "More intimacy, more exposure.", identityLine: "You decide closeness is worth letting housing, money, and tension touch the relationship.", previewTags: ["Commitment", "Housing risk"], preferredEventTags: ["housing": 4, "romance": 7], microBeat: "A shared key.", baseFriction: .resistance)
        case .tryForBaby:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Open The Door To A Family Shift", subtitle: "Hope and pressure together.", identityLine: "You decide the next chapter might be bigger than the one you can fully control.", previewTags: ["Pregnancy odds", "Pressure"], preferredEventTags: ["family": 8, "health": 2, "cost": 3], microBeat: "The quiet hope.", baseFriction: .resistance)
        case .avoidPregnancy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Keep The Line Clear", subtitle: "Prioritize control.", identityLine: "You decide this year needs fewer irreversible turns, not more.", previewTags: ["Pregnancy risk down", "Control"], preferredEventTags: ["family": 4, "health": 2], microBeat: "Safety first.", baseFriction: .none)
        case .letChanceDecide:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Stop Trying To Control Every Outcome", subtitle: "Let uncertainty in.", identityLine: "You let the year decide whether it wants to deepen into something bigger.", previewTags: ["Risk on", "Future unclear"], preferredEventTags: ["chance": 5, "family": 4, "romance": 4], microBeat: "Whatever happens, happens.", baseFriction: .none)
        case .keepDistance:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Keep Some Distance", subtitle: "Protect yourself first.", identityLine: "You decide staying intact matters more than staying close right now.", previewTags: ["Tension down", "Bond down"], preferredEventTags: ["health": 2, "relationships": 2], microBeat: "Building the wall.", baseFriction: .none)
        case .repairTension:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Try To Repair What Is Fraying", subtitle: "Choose the harder conversation.", identityLine: "You decide this year should not end with something important quietly worse.", previewTags: ["Bond", "Stability"], preferredEventTags: ["relationships": 8, "family": 3], microBeat: "I'm sorry.", baseFriction: .resistance)
        // Phase 2.2 parenting actions — simple, high-texture, meaningful trade-offs
        case .spendTimeWithKids:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Carve Out Real Time With Them", subtitle: "Presence over perfection.", identityLine: "You decide the year will include deliberate hours that belong only to your kids, not the to-do list.", previewTags: ["Bond up", "Mental cost", "Other plans down"], preferredEventTags: ["family": 9, "health": 2], microBeat: "You put the phone down.", baseFriction: .none)
        case .enforceRoutine:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hold The Line On Structure", subtitle: "Stability has a cost.", identityLine: "You decide some friction now is kinder than chaos later, even when it makes you the bad guy.", previewTags: ["Structure", "Some resentment", "Long-term calm"], preferredEventTags: ["family": 7, "routine": 5], microBeat: "Bedtime is bedtime.", baseFriction: .resistance)
        case .encourageIndependence:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Step Back So They Can Step Up", subtitle: "Growth through space.", identityLine: "You decide your job is to make yourself a little less necessary this year.", previewTags: ["Autonomy", "Bond risk", "Pride"], preferredEventTags: ["family": 6, "chance": 3], microBeat: "You let them try.", baseFriction: .none)
        case .checkInOnChild:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Ask The Real Questions", subtitle: "Emotional presence.", identityLine: "You decide to find out how they actually are, even if the answer is heavier than you wanted.", previewTags: ["Insight", "Bond", "Emotional load"], preferredEventTags: ["family": 8, "health": 3], microBeat: "The quiet conversation.", baseFriction: .resistance)
        // D1: Identity domain — light, always-available static self actions (dossier-flavored, instant)
        case .morningReflection:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Morning Reflection", subtitle: "Check in with yourself.", identityLine: "You decide the year needs at least one honest conversation with the person you are becoming.", previewTags: ["Clarity", "Mental", "Dossier echo"], preferredEventTags: ["health": 5, "identity": 4], microBeat: "The mirror is quiet.", baseFriction: .none)
        case .reconcileWithPast:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Reconcile With Where You Came From", subtitle: "Make peace with the dossier.", identityLine: "You decide the wiring from 14 still has something to teach you, even if it stings.", previewTags: ["Dossier tie", "Mental relief", "Legacy note"], preferredEventTags: ["health": 4, "family": 3, "identity": 5], microBeat: "The old story gets a footnote.", baseFriction: .resistance)
        case .tryNewPersona:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Try On A New Version Of You", subtitle: "Experiment with identity.", identityLine: "You decide this year is allowed to change what 'you' even means.", previewTags: ["Identity shift", "Rep risk", "Fresh start"], preferredEventTags: ["social": 5, "risk": 4, "identity": 6], microBeat: "New name in the mirror.", baseFriction: .warning)
        case .publicReset:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Public Reset", subtitle: "Change the story people tell.", identityLine: "You decide the version of you that the world has been carrying is due for an edit.", previewTags: ["Rep swing", "Fame cost/benefit"], preferredEventTags: ["social": 6, "career": 3, "identity": 4], microBeat: "The announcement lands.", baseFriction: .none)
        case .therapySession:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Therapy Session", subtitle: "Pay for perspective.", identityLine: "You decide some patterns are too expensive to keep carrying alone.", previewTags: ["Mental +", "Cash cost", "Insight"], preferredEventTags: ["health": 8, "money": 2], microBeat: "The hour that belongs only to you.", baseFriction: .none)
        case .processCrisis:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Process The Identity Crisis", subtitle: "Face the fracture.", identityLine: "You decide the version of you that has been running this life is due for a reckoning.", previewTags: ["Coherence", "Painful clarity", "Stance realign"], preferredEventTags: ["health": 6, "identity": 7, "risk": 3], microBeat: "The pieces on the table.", baseFriction: .resistance)
        // D1: Military depth statics + deploy
        case .ptFocus:
            return ActionChoiceDefinition(choiceID: choiceID, title: "PT Focus", subtitle: "Sharpen the machine.", identityLine: "You decide the body that serves is the one that survives.", previewTags: ["Fitness +", "Discipline +"], preferredEventTags: ["health": 6, "military": 5], microBeat: "Boots on the ground before dawn.", baseFriction: .resistance)
        case .seekCounsel:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Seek Counsel", subtitle: "Tend the invisible wounds.", identityLine: "You decide the things that don't bleed still need looking after.", previewTags: ["Trauma down", "Mental +"], preferredEventTags: ["health": 7, "military": 4], microBeat: "The quiet room.", baseFriction: .none)
        case .studyTradition:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Study The Tradition", subtitle: "Know why you wear the uniform.", identityLine: "You decide the history in the unit patch is part of the strength you carry.", previewTags: ["Discipline +", "Pride"], preferredEventTags: ["military": 6, "identity": 3], microBeat: "The stories that outlive the orders.", baseFriction: .none)
        case .deployTour:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Deploy On Tour", subtitle: "The real test.", identityLine: "You decide the only way to know what you are made of is to go where the year can take it from you.", previewTags: ["Medals", "Trauma risk", "Big payoff"], preferredEventTags: ["military": 9, "risk": 7, "health": 5], microBeat: "Wheels up.", baseFriction: .warning)
        // D1: Family light always statics
        case .familyMeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Family Meal", subtitle: "Anchor the day.", identityLine: "You decide the table is still the place where the year slows down and remembers who it belongs to.", previewTags: ["Bond +", "Dossier flavor"], preferredEventTags: ["family": 7, "health": 2], microBeat: "The chairs scrape back.", baseFriction: .none)
        case .storyTime:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Story Time", subtitle: "Pass the thread.", identityLine: "You decide the stories you tell them tonight are the dossier they will carry when you are not in the room.", previewTags: ["Child wiring", "Legacy"], preferredEventTags: ["family": 8, "identity": 4], microBeat: "The lamp clicks off.", baseFriction: .none)
        // D2: Finance/Assets collector & mastery statics (path-specific, era-reactive, fame/lifestyle boosts)
        case .curateCollection:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Curate Collection", subtitle: "Tend the assets that tell your story.", identityLine: "You decide the things you own say as much about you as the things you do.", previewTags: ["Lifestyle +", "Maintenance cost", "KnownFor"], preferredEventTags: ["assets": 8, "finance": 4, "fame": 3], microBeat: "Polishing the trophies.", baseFriction: .none)
        case .hostSignatureEvent:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Host at Signature", subtitle: "Use the house as stage.", identityLine: "You decide your home is the perfect backdrop for the deal, the deal, or the drama.", previewTags: ["Social leverage", "Era flex", "Rep swing"], preferredEventTags: ["social": 7, "assets": 6, "money": 3], microBeat: "The guests arrive.", baseFriction: .resistance)
        case .maintainAsset:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Maintain The Fleet", subtitle: "Keep the shine on the toys.", identityLine: "You decide neglect is more expensive than the upkeep in the long run.", previewTags: ["Asset health +", "Cash burn", "Era risk"], preferredEventTags: ["assets": 7, "finance": 5], microBeat: "The mechanic nods.", baseFriction: .none)
        // D2: Health mastery (condition loops, aging by resilience/lifestyle, body-as-asset)
        case .recurringTherapy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Recurring Therapy", subtitle: "Scheduled maintenance for the mind.", identityLine: "You decide the patterns don't fix themselves; they need regular appointments.", previewTags: ["Mental +", "Condition management", "Cash tie"], preferredEventTags: ["health": 8, "money": 3], microBeat: "The couch again.", baseFriction: .none)
        case .manageMeds:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage The Meds", subtitle: "Trade symptoms for side effects.", identityLine: "You decide the chemical balance is worth the daily ritual and the monthly bill.", previewTags: ["Condition down", "Finance hit", "Health trade"], preferredEventTags: ["health": 7, "money": 4], microBeat: "Pill organizer clicks.", baseFriction: .resistance)
        case .bodyConditioning:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Body Conditioning", subtitle: "Treat the machine as career asset.", identityLine: "You decide your body is the one investment that pays in every other domain.", previewTags: ["Athlete/creator edge", "Aging slow", "Discipline"], preferredEventTags: ["health": 6, "career": 5], microBeat: "The reps that matter.", baseFriction: .none)
        // D2: Relationships depth (per-friend, rivalry, rep split)
        case .deepenSpecificBond:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Deepen One Bond", subtitle: "Pick the person, go all in.", identityLine: "You decide quantity of friends is less valuable than the one who actually knows you.", previewTags: ["Per-friend depth", "Time cost", "Support up"], preferredEventTags: ["relationships": 9, "health": 2], microBeat: "The long conversation.", baseFriction: .none)
        case .fuelRivalry:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Fuel The Rivalry", subtitle: "Let the competition sharpen you.", identityLine: "You decide a little enemy in the circle keeps everyone honest — including you.", previewTags: ["Rivalry heat", "Performance up", "Rep risk"], preferredEventTags: ["social": 5, "career": 4, "risk": 4], microBeat: "The side-eye across the room.", baseFriction: .warning)
        case .splitReputation:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Split Public & Private", subtitle: "Different faces for different rooms.", identityLine: "You decide the version the world sees doesn't have to be the one you go home to.", previewTags: ["Public rep", "Private bond", "Ethics risk"], preferredEventTags: ["social": 6, "risk": 5, "identity": 3], microBeat: "The mask slips back on.", baseFriction: .resistance)
        // D3: Education branches and regular career parity defs
        case .pursueTradeCert:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pursue Trade Certification", subtitle: "Hands-on path, faster income.", identityLine: "You decide practical skills and quick earning power beat the long academic road.", previewTags: ["Income ramp", "Credential", "Trade bonus"], preferredEventTags: ["career": 7, "education": 5], microBeat: "The shop floor calls.", baseFriction: .none)
        case .honorsTrack:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lock Into Honors", subtitle: "Prestige and pressure.", identityLine: "You decide the elite track is worth the extra grind for the doors it will open.", previewTags: ["Standing up", "Burnout risk", "Special entry"], preferredEventTags: ["education": 8, "career": 4], microBeat: "The seminar is small.", baseFriction: .resistance)
        case .uniApplication:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Apply to University", subtitle: "The long game.", identityLine: "You decide the degree is the key that unlocks the higher ceiling later.", previewTags: ["Readiness", "Debt risk", "Future fit"], preferredEventTags: ["education": 6, "finance": 3], microBeat: "The applications go out.", baseFriction: .none)
        case .lifelongLearning:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Lifelong Learning", subtitle: "Never stop stacking.", identityLine: "You decide the credential from 22 is just the start; the world rewards the curious forever.", previewTags: ["Skill up", "Standing", "Small cost"], preferredEventTags: ["education": 5, "career": 6], microBeat: "The online module completes.", baseFriction: .none)
        case .credentialRefresh:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Refresh The Credential", subtitle: "Stay current or fade.", identityLine: "You decide the old degree needs new polish or it loses its power in the market.", previewTags: ["Decay reversal", "Cost", "Market edge"], preferredEventTags: ["education": 4, "career": 7], microBeat: "The renewal certificate arrives.", baseFriction: .resistance)
        case .corporateClimb:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Climb The Corporate Ladder", subtitle: "Play the long internal game.", identityLine: "You decide steady promotion inside the machine is safer and more predictable than striking out.", previewTags: ["Rank up", "Politics", "Stability"], preferredEventTags: ["career": 8, "social": 4], microBeat: "The review goes well.", baseFriction: .none)
        case .freelanceHustle:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go Full Freelance", subtitle: "Own your time and clients.", identityLine: "You decide the gig economy is freedom, even if the safety net is thinner.", previewTags: ["Flex income", "Uncertainty", "Brand"], preferredEventTags: ["career": 7, "finance": 5, "risk": 4], microBeat: "The next invoice lands.", baseFriction: .resistance)
        case .tradesMastery:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Master The Trade", subtitle: "Deep expertise, real value.", identityLine: "You decide becoming the best at a tangible skill beats chasing titles.", previewTags: ["Skill mastery", "Income stable", "Respect"], preferredEventTags: ["career": 8, "education": 3], microBeat: "The job is done right.", baseFriction: .none)
        case .pivotToGig:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pivot To The Gig Economy", subtitle: "Multiple streams, no boss.", identityLine: "You decide the 9-5 is overrated and you're ready to juggle projects instead.", previewTags: ["Side to main", "Variety", "Income variance"], preferredEventTags: ["career": 6, "finance": 6], microBeat: "The calendar fills with gigs.", baseFriction: .none)
        case .publicServiceGrind:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Grind In Public Service", subtitle: "Steady mission, slower pay.", identityLine: "You decide impact and stability inside the system beat chasing private upside.", previewTags: ["Mission", "Security", "Pension path"], preferredEventTags: ["career": 7, "social": 5], microBeat: "The forms are endless, but the work matters.", baseFriction: .none)
        case .techDeepWork:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Deep Technical Work", subtitle: "Mastery through focus.", identityLine: "You decide the real edge is in the quiet hours solving hard problems others avoid.", previewTags: ["Skill spike", "Focus", "IP edge"], preferredEventTags: ["career": 8, "education": 4], microBeat: "The commit compiles at 2am.", baseFriction: .resistance)
        case .protectSleep:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Protect Your Sleep Like It Matters", subtitle: "Recovery as a strategy.", identityLine: "You decide the year has to be survivable, not just productive.", previewTags: ["+Mental", "Recovery", "School pressure down"], preferredEventTags: ["health": 8, "routine": 4], microBeat: "The world goes dark.", baseFriction: .none)
        case .rest:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pull Back And Recover", subtitle: "Stabilize before you push again.", identityLine: "You decide not every year needs to prove something.", previewTags: ["Recovery", "Energy"], preferredEventTags: ["health": 7, "routine": 3], microBeat: "Finally, a moment of silence.", baseFriction: .none)
        case .pushThrough:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push Anyway", subtitle: "Output over recovery.", identityLine: "You decide getting through it matters more than what it costs you in the moment.", previewTags: ["Output", "Recovery loss"], preferredEventTags: ["career": 4, "school": 4, "health": 6], microBeat: "Just keep moving.", baseFriction: .resistance)
        case .seeDoctor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Get It Checked Before It Gets Worse", subtitle: "Spend for stability.", identityLine: "You decide uncertainty about your body is more expensive than the appointment.", previewTags: ["Care", "Cash cost"], preferredEventTags: ["health": 7, "money": 2], microBeat: "The waiting room smell.", baseFriction: .none)
        case .callInFavor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Call In A Favor", subtitle: "Spend social capital.", identityLine: "You decide to lean on your network to solve a problem that effort alone cannot reach.", previewTags: ["Favor", "Capital cost", "Door opening"], preferredEventTags: ["social": 6, "chance": 4], microBeat: "Dialing the direct line.", baseFriction: .none)
        case .startCompany:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Launch Your Own Venture", subtitle: "Trade capital for control.", identityLine: "You decide to stop building someone else's dream and start fighting for your own.", previewTags: ["Equity", "Burn rate", "Risk"], preferredEventTags: ["career": 6, "money": 4, "risk": 7], microBeat: "Your name is on the door.", baseFriction: .resistance)
        case .pitchDeck:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Present Pitch Deck", subtitle: "Define the sector & vision.", identityLine: "You step into the room to convince the world your idea is worth the risk.", previewTags: ["Sector selection", "Strategic vision"], preferredEventTags: ["career": 7, "social": 4], microBeat: "Next slide.", baseFriction: .none)
        case .manageFund:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Manage The Fund", subtitle: "Allocating other people's dreams.", identityLine: "You decide that picking the winners is better than being one of them.", previewTags: ["Management fees", "Performance risk"], preferredEventTags: ["money": 8, "career": 5], microBeat: "Capital deployed.", baseFriction: .resistance)
        case .acquireCompetitor:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hostile Takeover", subtitle: "Expand through force.", identityLine: "You decide that if you can't beat them, you'll simply buy them.", previewTags: ["Valuation jump", "Heat spike", "Debt"], preferredEventTags: ["career": 7, "risk": 8], microBeat: "Papers signed.", baseFriction: .warning)
        case .stripAssets:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Liquidate & Strip", subtitle: "Short-term gain, long-term ruin.", identityLine: "You decide the parts are worth more than the whole.", previewTags: ["Cash windfall", "Notoriety spike", "Board risk"], preferredEventTags: ["money": 10, "risk": 9], microBeat: "Everything must go.", baseFriction: .warning)
        case .pivotBusiness:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pivot The Strategy", subtitle: "Adapt to survive.", identityLine: "You decide the current path is a dead end and force a hard turn.", previewTags: ["Burn down", "Insight", "Momentum loss"], preferredEventTags: ["career": 5, "routine": 4], microBeat: "Hard left.", baseFriction: .resistance)
        case .raiseCapital:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Raise Venture Capital", subtitle: "Trade equity for runway.", identityLine: "You decide that your own money isn't enough and look for outside fuel.", previewTags: ["Cash injection", "Equity loss", "Board pressure"], preferredEventTags: ["money": 7, "social": 5], microBeat: "The check clears.", baseFriction: .none)
        case .aggressiveExpansion:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Scale Aggressively", subtitle: "Growth at all costs.", identityLine: "You decide to capture the market before it captures you.", previewTags: ["Valuation spike", "Burn rate up", "Burnout risk"], preferredEventTags: ["career": 8, "risk": 7], microBeat: "Burn the boats.", baseFriction: .warning)
        case .ipoExit:
            return ActionChoiceDefinition(choiceID: choiceID, title: "The Liquidity Event", subtitle: "Take the company public.", identityLine: "You decide the journey as a founder is done and it's time to cash in.", previewTags: ["Massive wealth", "Legacy", "Exit"], preferredEventTags: ["money": 10, "social": 6], microBeat: "Ringing the bell.", baseFriction: .resistance)
        // E2: New dedicated founder quick actions
        case .closeMajorDeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Close Major Deal", subtitle: "Land the big one.", identityLine: "You decide this partnership or customer could change everything.", previewTags: ["Traction +", "Cash", "Pressure up"], preferredEventTags: ["career": 8, "money": 6], microBeat: "The signature hits the table.", baseFriction: .resistance)
        case .allHandsRally:
            return ActionChoiceDefinition(choiceID: choiceID, title: "All-Hands Rally", subtitle: "Re-energize the team.", identityLine: "You stand in front of everyone and remind them why they're here.", previewTags: ["Team health +", "Culture up", "Short-term productivity"], preferredEventTags: ["social": 7, "career": 4], microBeat: "The room feels different.", baseFriction: .none)
        case .fundraiseSprint:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Fundraise Sprint", subtitle: "Hit the road for capital.", identityLine: "You decide the runway is too short and it's time to sell the vision again.", previewTags: ["Cash injection", "Equity risk", "Mental load"], preferredEventTags: ["money": 8, "risk": 6], microBeat: "Another pitch deck at 2am.", baseFriction: .warning)
        case .takeRealBreak:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take a Real Break", subtitle: "Step away from the machine.", identityLine: "You finally decide that burning out helps no one, least of all the company.", previewTags: ["Mental load down", "Execution dip", "Long-term health"], preferredEventTags: ["health": 8], microBeat: "The laptop stays closed.", baseFriction: .none)
        case .hireKeyTalent:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hire Key Talent", subtitle: "Bring in someone who changes the game.", identityLine: "You decide the right person is worth whatever it takes.", previewTags: ["Team strength +", "Culture risk", "Burn rate"], preferredEventTags: ["career": 7, "social": 5], microBeat: "The offer goes out.", baseFriction: .resistance)
        // C2: New dedicated creator quick actions
        case .postDaily:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Post Daily", subtitle: "Feed the algorithm.", identityLine: "You decide consistency is the only thing that matters right now.", previewTags: ["Algorithm +", "Burnout risk", "Small audience gain"], preferredEventTags: ["career": 6, "social": 4], microBeat: "Another caption written.", baseFriction: .resistance)
        case .goLive:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go Live", subtitle: "Raw connection.", identityLine: "You decide the unfiltered version of you is what people need tonight.", previewTags: ["Engagement spike", "Authenticity", "Risk of saying too much"], preferredEventTags: ["social": 8, "risk": 5], microBeat: "Stream is live.", baseFriction: .warning)
        case .filmBanger:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Film a Banger", subtitle: "Swing for the fences.", identityLine: "You decide this one piece of content could be the one that changes everything.", previewTags: ["Viral potential", "High effort", "All or nothing"], preferredEventTags: ["career": 9, "risk": 7], microBeat: "Lights, camera, obsession.", baseFriction: .resistance)
        case .collab:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Collab With Someone Big", subtitle: "Borrow their audience.", identityLine: "You decide the fastest way up is to stand next to someone already there.", previewTags: ["Audience cross-pollination", "Brand risk", "Relationship cost"], preferredEventTags: ["social": 7, "career": 6], microBeat: "The DM was sent.", baseFriction: .none)
        case .addressDrama:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Address The Drama", subtitle: "Control the narrative.", identityLine: "You decide silence is no longer an option.", previewTags: ["Damage control", "Authenticity hit", "Possible recovery"], preferredEventTags: ["social": 8, "risk": 6], microBeat: "The camera is on.", baseFriction: .warning)
        case .takeMentalBreak:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take a Mental Health Break", subtitle: "Log off.", identityLine: "You finally decide that disappearing for a bit might be the only way to stay alive.", previewTags: ["Burnout relief", "Audience dip", "Long-term health"], preferredEventTags: ["health": 9], microBeat: "Status: offline.", baseFriction: .none)
        case .dropBrandDeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Drop a Brand Deal", subtitle: "Cash the bag.", identityLine: "You decide the money is worth whatever it does to your soul this month.", previewTags: ["Cash", "Authenticity cost", "Sponsorship"], preferredEventTags: ["money": 9, "career": 5], microBeat: "The integration is filmed.", baseFriction: .resistance)
        // P2: New dedicated politics quick actions
        case .townHall:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Hold a Town Hall", subtitle: "Face the people.", identityLine: "You decide to stand in front of actual voters and hear what they think of you.", previewTags: ["Approval swing", "Authenticity", "Risk of gaffes"], preferredEventTags: ["social": 8, "career": 5], microBeat: "The room is full of faces.", baseFriction: .warning)
        case .politicalFundraise:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Fundraise Hard", subtitle: "Dial for dollars.", identityLine: "You decide the war chest matters more than your dignity tonight.", previewTags: ["Donor base +", "Ethics risk", "Time sink"], preferredEventTags: ["money": 8, "risk": 5], microBeat: "Another call.", baseFriction: .resistance)
        case .scandalResponse:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Respond to the Scandal", subtitle: "Damage control.", identityLine: "You decide how you will face the latest story about you.", previewTags: ["Scandal management", "Approval risk", "Narrative control"], preferredEventTags: ["social": 7, "risk": 8], microBeat: "The cameras are waiting.", baseFriction: .warning)
        case .policyPush:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push a Major Policy", subtitle: "Leave a mark.", identityLine: "You decide to bet political capital on something that actually matters.", previewTags: ["Policy legacy", "Approval cost", "Long game"], preferredEventTags: ["career": 9, "social": 4], microBeat: "The bill is introduced.", baseFriction: .resistance)
        case .backroomDeal:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cut a Backroom Deal", subtitle: "Trade favors.", identityLine: "You decide that the right compromise today can unlock real power tomorrow.", previewTags: ["Power gain", "Ethics hit", "Future leverage"], preferredEventTags: ["career": 7, "risk": 6], microBeat: "The handshake happens.", baseFriction: .warning)
        case .mediaHit:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Do a Big Media Hit", subtitle: "Control the story.", identityLine: "You decide to go on the biggest stage and shape how the country sees you tonight.", previewTags: ["Approval swing", "Charisma test", "Scandal risk"], preferredEventTags: ["social": 9, "career": 5], microBeat: "The lights are hot.", baseFriction: .warning)
        case .takeAStand:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Take a Public Stand", subtitle: "Risk it for principle.", identityLine: "You decide that some lines are worth drawing even if it costs you.", previewTags: ["Ethics gain", "Approval risk", "Polarization"], preferredEventTags: ["social": 6, "career": 7], microBeat: "The statement is released.", baseFriction: .resistance)
        case .attackOpponent:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Attack Your Opponent", subtitle: "Go negative.", identityLine: "You decide that the other side needs to be destroyed before they destroy you.", previewTags: ["Approval swing", "Ethics cost", "Escalation"], preferredEventTags: ["social": 5, "risk": 8], microBeat: "The attack ad drops.", baseFriction: .warning)
        case .intenseTraining:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push Your Physical Limits", subtitle: "Build the machine.", identityLine: "You decide your body is the only asset that matters this year.", previewTags: ["Peak up", "Burnout", "Injury risk"], preferredEventTags: ["health": 8, "routine": 5], microBeat: "The iron is heavy.", baseFriction: .resistance)
        case .compete:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Enter The Arena", subtitle: "Visibility through performance.", identityLine: "You step onto the stage where the only thing that matters is the result.", previewTags: ["Fame", "Fan base", "Injury risk"], preferredEventTags: ["career": 6, "social": 5, "risk": 4], microBeat: "Heartbeat in your ears.", baseFriction: .warning)
        // Phase S2: New dedicated athlete quick actions
        case .extraTrainingSession:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Extra Training Session", subtitle: "Push for marginal gains.", identityLine: "You decide one more rep today might be the difference.", previewTags: ["Peak +", "Injury risk", "Fatigue"], preferredEventTags: ["health": 7, "career": 5], microBeat: "The weights feel heavier tonight.", baseFriction: .resistance)
        case .mediaAppearance:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Media Appearance", subtitle: "Feed the spotlight.", identityLine: "You step in front of the cameras to keep your name relevant.", previewTags: ["Fame +", "Heat up", "Sponsor interest"], preferredEventTags: ["career": 6, "social": 4], microBeat: "The lights are hot.", baseFriction: .none)
        case .recoveryFocus:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Recovery Focus", subtitle: "Listen to the body.", identityLine: "You choose the ice bath and physio over another grind.", previewTags: ["Durability +", "Burnout down", "Short-term performance"], preferredEventTags: ["health": 9], microBeat: "The body finally gets a say.", baseFriction: .none)
        case .teamBonding:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Team Bonding", subtitle: "Invest in the locker room.", identityLine: "You spend time with the guys instead of chasing individual stats.", previewTags: ["Fan loyalty +", "Team chemistry", "Slight fatigue"], preferredEventTags: ["social": 5, "career": 3], microBeat: "Laughter in the weight room.", baseFriction: .none)
        // S3a: The Myth & The Machine — doping temptation (high risk, high reward)
        case .edgeProtocol:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Edge Protocol", subtitle: "Take the risk. Chase the ceiling.", identityLine: "You know exactly what this is. One more edge. One more year at the top.", previewTags: ["Peak ++", "Detection risk", "Health cost", "Legacy stain"], preferredEventTags: ["career": 9, "risk": 8, "health": 6], microBeat: "The needle or the pill. The line you said you'd never cross.", baseFriction: .danger)
        case .gatherIntelligence:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Infiltrate The Circle", subtitle: "Trade trust for leverage.", identityLine: "You decide that knowing what others are hiding is the fastest way up.", previewTags: ["Leverage", "Exposure", "Suspicion"], preferredEventTags: ["social": 5, "risk": 7], microBeat: "Watching. Listening.", baseFriction: .warning)
        case .exploitLeverage:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Play Your Hand", subtitle: "Trade secrets for gain.", identityLine: "You decide it's time to cash in the favors and fears you've collected.", previewTags: ["Promotion shot", "Cash", "Exposure"], preferredEventTags: ["career": 7, "money": 5, "risk": 6], microBeat: "Checkmate.", baseFriction: .warning)
        case .dayTrade:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Trade The Volatility", subtitle: "Short-term focus.", identityLine: "You decide to chase the noise of the market instead of its signal.", previewTags: ["Cash", "Stress", "Market risk"], preferredEventTags: ["money": 8, "risk": 6], microBeat: "The tape is moving fast today.", baseFriction: .warning)
        case .analyzeMarkets:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Study The Cycles", subtitle: "Trade activity for edge.", identityLine: "You decide patience and perspective are more profitable than adrenaline.", previewTags: ["Insight", "Capital access", "Patience"], preferredEventTags: ["money": 6, "routine": 5], microBeat: "The pattern emerges.", baseFriction: .none)
        
        // Military
        case .enlistArmy, .enlistNavy, .enlistAirForce, .enlistMarines, .enlistCoastGuard, .enlistSpaceForce:
            let branchName = MilitarySystem.branchName(for: choiceID)
            return ActionChoiceDefinition(choiceID: choiceID, title: "Enlist in the \(branchName)", subtitle: "Start your military career as a soldier", detail: "Sign a 4-year contract to serve. Provides discipline and fitness, but restricts freedom.", identityLine: "You are joining the \(branchName).", previewTags: ["Contract", "Discipline", "Fitness"], preferredEventTags: ["career": 8, "health": 4], microBeat: "Signing the papers.", baseFriction: .resistance)
        case .commissionArmy, .commissionNavy, .commissionAirForce, .commissionMarines, .commissionCoastGuard, .commissionSpaceForce:
            let branchName = MilitarySystem.branchName(for: choiceID)
            return ActionChoiceDefinition(choiceID: choiceID, title: "Commission in the \(branchName)", subtitle: "Leading from the front", detail: "Use your degree to start as an officer. Higher pay and responsibility.", identityLine: "You are taking a leadership role in the military.", previewTags: ["Officer", "Pay up", "Responsibility"], preferredEventTags: ["career": 9, "social": 5], microBeat: "Swearing the oath.", baseFriction: .resistance)
        case .joinReservesArmy, .joinReservesNavy, .joinReservesAirForce, .joinReservesMarines, .joinReservesCoastGuard, .joinReservesSpaceForce:
            let branchName = MilitarySystem.branchName(for: choiceID)
            return ActionChoiceDefinition(choiceID: choiceID, title: "Join \(branchName) Reserves", subtitle: "One weekend a month, two weeks a year", detail: "Balance civilian life with military service. Flexible, but always ready.", identityLine: "You are joining the \(branchName) Reserves.", previewTags: ["Reserve", "Balance", "Ready"], preferredEventTags: ["career": 6, "routine": 4], microBeat: "Reporting for drill.", baseFriction: .none)
        case .militaryService:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Standard Service", subtitle: "Perform your daily duties", detail: "Focus on excellence in your current role. Improves performance and discipline.", identityLine: "You are dedicated to your service.", previewTags: ["Performance", "Discipline", "Fitness"], preferredEventTags: ["career": 7, "routine": 5], microBeat: "Another day on duty.", baseFriction: .none)
        case .goAWOL:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Go AWOL", subtitle: "Walk away from your post", detail: "Abandon your duties temporarily. High risk of legal trouble.", identityLine: "You are running from your obligations.", previewTags: ["Freedom", "Heat", "Crime"], preferredEventTags: ["risk": 8, "social": 4], microBeat: "You don't look back.", baseFriction: .warning)
        case .desert:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Desert", subtitle: "Leave the military for good", detail: "Abandon your service entirely. You will be hunted by military police.", identityLine: "You are a deserter.", previewTags: ["Heat spike", "Dishonorable", "Risk"], preferredEventTags: ["risk": 10, "crime": 8], microBeat: "Disappearing into the night.", baseFriction: .warning)
        case .militaryRetirement:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Retire/Resign", subtitle: "Leave the service honorably", detail: "Complete your contract or retire after 20 years.", identityLine: "You are transitioning back to civilian life.", previewTags: ["Freedom", "Pension", "Transition"], preferredEventTags: ["career": 6, "money": 5], microBeat: "The final salute.", baseFriction: .resistance)
        case .deploy:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Volunteer for Deployment", subtitle: "Go where the action is", detail: "Seek an overseas mission. Higher risk, but higher reward.", identityLine: "You are stepping up for your country.", previewTags: ["Deployment", "Risk", "Valor"], preferredEventTags: ["career": 7, "risk": 7], microBeat: "Packing your gear.", baseFriction: .warning)
            
        case .joinROTC:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Join ROTC", subtitle: "Train while you study", detail: "Receive a stipend and specialized training. Requires a post-grad commission.", identityLine: "You are balancing books and boots.", previewTags: ["Stipend", "Discipline", "Commission"], preferredEventTags: ["education": 6, "career": 5], microBeat: "Marching on the quad.", baseFriction: .none)
        case .leaveROTC:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Leave ROTC", subtitle: "Focus solely on academics", detail: "Stop your military training. You lose your stipend and commission path.", identityLine: "You are returning to regular student life.", previewTags: ["Freedom", "No Stipend"], preferredEventTags: ["education": 4], microBeat: "Turning in your uniform.", baseFriction: .none)
        case .selectCombatMOS, .selectMedicalMOS, .selectAviationMOS, .selectIntelMOS, .selectLogisticsMOS:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Select Specialization", subtitle: "Define your role", detail: "Choose your primary Military Occupational Specialty (MOS).", identityLine: "You are choosing your path in the service.", previewTags: ["Specialty", "Stats"], preferredEventTags: ["career": 7], microBeat: "Filling out the preference sheet.", baseFriction: .none)
        case .useGIBill:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Use GI Bill", subtitle: "Fund your education", detail: "Apply your veteran benefits to cover tuition costs.", identityLine: "You are investing in your future after service.", previewTags: ["Free Tuition", "Smarts"], preferredEventTags: ["education": 9], microBeat: "Applying for benefits.", baseFriction: .none)
        case .seekVAHealthcare:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Seek VA Healthcare", subtitle: "Treat service-related issues", detail: "Access specialized care for physical and mental trauma.", identityLine: "You are taking care of your health.", previewTags: ["Recovery", "Wellness"], preferredEventTags: ["health": 8], microBeat: "Checking in at the clinic.", baseFriction: .none)
        case .claimPension:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Claim Pension", subtitle: "Receive retirement pay", detail: "Access the annual income you earned through 20+ years of service.", identityLine: "You are reaping the rewards of a long career.", previewTags: ["Passive Income", "Wealth"], preferredEventTags: ["money": 9], microBeat: "Verifying the direct deposit.", baseFriction: .none)
            
        case .applyForResidency:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Apply for Residency", subtitle: "Enter specialized training", detail: "The first step toward becoming an attending physician. Brutal hours, but high future upside.", identityLine: "You are entering the gauntlet of medical training.", previewTags: ["High Burnout", "MD Path"], preferredEventTags: ["career": 8, "health": 10], microBeat: "The match results are in.", baseFriction: .resistance)
        case .completeResidency:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Complete Residency", subtitle: "Become an Attending", detail: "Transition from training to a full professional role. Salary spikes and burnout stabilizes.", identityLine: "You are finally a fully licensed doctor.", previewTags: ["Salary Spike", "Reputation"], preferredEventTags: ["career": 10, "money": 8], microBeat: "Signing the contract.", baseFriction: .none)
        case .openPrivatePractice:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Open Private Practice", subtitle: "Be your own boss", detail: "Leave the hospital system to start your own clinic. High overhead, but highest income potential.", identityLine: "You are an independent medical professional.", previewTags: ["Entrepreneurial", "High Income"], preferredEventTags: ["career": 9, "money": 10], microBeat: "The keys are in your hand.", baseFriction: .resistance)
        case .passBarExam:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Pass the Bar", subtitle: "License to practice law", detail: "A critical milestone. Allows you to transition from Clerk to Associate.", identityLine: "You are a licensed attorney.", previewTags: ["License", "Associate Path"], preferredEventTags: ["career": 7, "smarts": 10], microBeat: "Your name is on the list.", baseFriction: .resistance)
        case .makePartner:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Make Partner", subtitle: "Peak legal achievement", detail: "Secure equity and leadership in the firm. Massive social capital and wealth.", identityLine: "You are at the top of the legal hierarchy.", previewTags: ["Equity", "Standing"], preferredEventTags: ["career": 10, "social": 10], microBeat: "The senior partners are waiting.", baseFriction: .resistance)
        case .becomeCTO:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Become CTO", subtitle: "Technological leadership", detail: "Take control of a company's technical direction. High fame and influence.", identityLine: "You are a technical leader.", previewTags: ["Fame", "Salary"], preferredEventTags: ["career": 9, "tech": 10], microBeat: "Leading the strategy.", baseFriction: .none)
        case .launchStartupSpinOff:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Launch Spin-off", subtitle: "Technical entrepreneurship", detail: "Use your industry expertise to launch a specialized startup.", identityLine: "You are technical visionary.", previewTags: ["Spec Career Path", "Risk"], preferredEventTags: ["career": 8, "money": 7], microBeat: "Drafting the whitepaper.", baseFriction: .resistance)

        default:
            return ActionChoiceDefinition(
                choiceID: choiceID,
                title: "Make Your Move",
                subtitle: "Carry the year forward.",
                identityLine: "You decide this year needs a deliberate push instead of drift.",
                previewTags: ["Momentum"],
                preferredEventTags: [:],
                microBeat: "You commit to the choice.",
                baseFriction: .none
            )
        }
    }

    static func baseResolutionTier(for choiceID: ActionChoiceID) -> ActionResolutionTier {
        switch choiceID {
        case .smallHustle, .takeSideWork, .takeExtraShifts, .rest, .protectSleep, .pushThrough,
             .reachOut, .joinClub, .findYourCrowd, .keepDistance, .seeDoctor, .cutSpending,
             .depositToHouseFund, .topUpHouseReserve,
             .layLow, .spendForRelief, .protectYourEnergy,
             .teenAthleticDrill, .teenSideHustle, .teenCreativeProject, .teenLeadInitiative, .teenRiskyExperiment,
             // D1: new always-static instants
             .morningReflection, .reconcileWithPast, .tryNewPersona, .publicReset, .therapySession, .processCrisis,
             .ptFocus, .seekCounsel, .studyTradition,
             .familyMeal, .storyTime,
             // D2: mastery static instants
             .curateCollection, .hostSignatureEvent, .maintainAsset,
             .recurringTherapy, .manageMeds, .bodyConditioning,
             .deepenSpecificBond, .fuelRivalry, .splitReputation,
             // D3: education branches and regular career statics (instant for quick access + parity)
             .pursueTradeCert, .honorsTrack, .uniApplication, .lifelongLearning, .credentialRefresh,
             .corporateClimb, .freelanceHustle, .tradesMastery, .pivotToGig, .publicServiceGrind, .techDeepWork,
             // Econ1: Stock Market
             .checkPortfolio, .rebalancePortfolio, .researchTip, .buyIndex, .sellPosition:
             return .instant

        default:
            return .committed
        }
    }

    static func resolutionTier(for choiceID: ActionChoiceID) -> ActionResolutionTier {
        baseResolutionTier(for: choiceID)
    }

    static func preferredEventWeights(for actions: [PlayerYearAction]) -> [String: Int] {
        var weights: [String: Int] = [:]
        for action in actions {
            for (tag, weight) in definition(for: action.choiceID).preferredEventTags {
                weights[tag, default: 0] += weight
            }
        }
        return weights
    }
}

enum QuickActionCatalog {
    static func choices(for domain: ActionDomain, state: GameState) -> [ActionChoiceID] {
        registry(for: state).availableQuick(for: domain)
    }

    static func title(for choiceID: ActionChoiceID) -> String {
        DomainActionRegistry.quickActionTitle(for: choiceID)
    }

    private static func registry(for state: GameState) -> DomainActionRegistry {
        let isTeen = state.player.age <= 17
        let isStudent = state.player.age <= 22 && (state.education.pathway == .student || state.education.pathway == .training)
        let reserve = max(2_500, state.finance.annualNetIncome / 4)
        return DomainActionRegistry(
            context: DomainActionContext(
                state: state,
                isTeenExperience: isTeen,
                isStudentLifeExperience: isStudent,
                canAccessInvesting: state.player.age >= 18 && state.finance.isEligibleToCompound(emergencyReserve: reserve),
                investmentEmergencyReserve: reserve
            )
        )
    }
}

extension ActionChoiceDefinition {
    var resolutionTier: ActionResolutionTier {
        ActionChoiceCatalog.resolutionTier(for: choiceID)
    }
}

struct ActionCorrelationSystem {
    func record(action: PlayerYearAction, age: Int, pressureDeltas: [String: Int], state: inout GameState) {
        let count = state.correlationLedger.recordAction(action)
        let label = pressureCauseLabel(for: action.choiceID)

        for (domain, delta) in pressureDeltas {
            state.correlationLedger.adjustResidue(domain: domain, delta: delta)
            state.correlationLedger.recordPressureCause(
                domain: domain,
                label: label,
                delta: delta,
                age: age,
                sourceAction: action.choiceID
            )
        }

        recordPatternHook(for: action, count: count, age: age, state: &state)
        recordNPCImpressions(for: action, state: &state)
    }

    private func recordPatternHook(for action: PlayerYearAction, count: Int, age: Int, state: inout GameState) {
        guard count >= 2 else { return }

        switch action.choiceID {
        case .takeExtraShifts, .takeSideWork, .takeOvertime, .smallHustle:
            state.correlationLedger.upsertHook(tag: "overwork", domain: "health", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        case .rest, .protectSleep, .seeDoctor:
            state.correlationLedger.upsertHook(tag: "recovery", domain: "health", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        case .spendForRelief, .spendToCope:
            state.correlationLedger.upsertHook(tag: "coping_spend", domain: "finance", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        case .reachOut, .joinClub, .findYourCrowd, .repairTension, .strengthenBond:
            state.correlationLedger.upsertHook(tag: "reachable", domain: "relationships", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        case .keepDistance, .stayInvisible, .layLow, .coast:
            state.correlationLedger.upsertHook(tag: "withdrawal", domain: "relationships", dueAge: age + 1, strength: min(20, count * 4), sourceAction: action.choiceID)
        default:
            break
        }
    }

    private func recordNPCImpressions(for action: PlayerYearAction, state: inout GameState) {
        let impressions = npcImpressionDeltas(for: action.choiceID)
        guard !impressions.isEmpty else { return }

        var ids: [String] = state.relationships.friends.map { $0.id.uuidString }
        if let partner = state.relationships.primaryPartner {
            ids.append(partner.id.uuidString)
        }

        for id in ids {
            for (key, delta) in impressions {
                state.correlationLedger.adjustNPCImpression(id: id, key: key, delta: delta)
            }
        }
    }

    private func npcImpressionDeltas(for choiceID: ActionChoiceID) -> [String: Int] {
        switch choiceID {
        case .reachOut, .joinClub, .findYourCrowd, .repairTension, .strengthenBond:
            return ["reachable": 2, "absent": -1]
        case .keepDistance, .stayInvisible, .layLow, .coast:
            return ["absent": 2]
        case .takeExtraShifts, .takeSideWork, .takeOvertime, .workHard:
            return ["overworked": 2]
        case .protectYourEnergy, .rest, .protectSleep:
            return ["available": 1, "overworked": -1]
        default:
            return [:]
        }
    }

    private func pressureCauseLabel(for choiceID: ActionChoiceID) -> String {
        switch choiceID {
        case .protectSleep: return "Sleep"
        case .rest: return "Rest"
        case .seeDoctor: return "Care"
        case .takeExtraShifts: return "Extra shifts"
        case .takeSideWork: return "Side work"
        case .smallHustle: return "Small hustle"
        case .takeOvertime: return "Overtime"
        case .cutSpending: return "Cut spending"
        case .buildEmergencyFund: return "Emergency fund"
        case .spendForRelief: return "Relief spend"
        case .spendToCope: return "Coping spend"
        case .pushThrough: return "Push through"
        case .repairTension: return "Repair"
        case .strengthenBond: return "Bond"
        case .discussFuture: return "Future talk"
        case .keepDistance: return "Distance"
        case .stayInvisible: return "Invisible"
        case .workHard: return "Work hard"
        case .network: return "Network"
        case .retrain: return "Retrain"
        case .protectYourEnergy: return "Protect energy"
        case .coast: return "Coast"
        case .layLow: return "Lay low"
        case .jobHunt: return "Job hunt"
        default: return ActionChoiceCatalog.definition(for: choiceID).title
        }
    }
}

enum AmbientContactRole: String, Codable, CaseIterable {
    case friend
    case guardian
    case mentor
    case partner
}

enum AmbientContactCadence: String, Codable, CaseIterable {
    case quiet
    case regular
    case frequent
}

struct AmbientContact: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var role: AmbientContactRole
    var bond: Int
    var reliability: Int
    var cadence: AmbientContactCadence
    var lastInteractionAge: Int? = nil
    var memoryFlags: [String] = []
}

enum YearChapterPhase: String, Codable, Equatable {
    case forecast
    case event
    case reaction
    case summary
    case resolution
    case crisis
}

struct YearForecastCard: Codable, Equatable, Identifiable {
    var id: String
    var age: Int
    var title: String
    var subtitle: String
    var focusTitle: String
    var focusDetail: String
    var pressureLabel: String
    var pressureDetail: String
    var anticipationTitle: String
    var anticipationDetail: String
    var tone: YearlyOutcomeTone
    /// Optional ambient contact voice surfaced on the forecast commit beat (Y2).
    var voiceName: String? = nil
    var voiceLine: String? = nil
}

struct TurnStakesSignal: Codable, Equatable, Identifiable {
    var id: String
    var label: String
    var title: String
    var detail: String
    var domain: HistoryDomainTag
    var tone: YearlyOutcomeTone
}

struct TurnStakesSnapshot: Codable, Equatable {
    var focus: TurnStakesSignal
    var topPressure: TurnStakesSignal
    var topOpportunity: TurnStakesSignal
    var ignoredRisk: TurnStakesSignal
    var spilloverRisk: TurnStakesSignal
    var momentum: TurnStakesSignal?   // Phase 2: Instant action momentum carrying into the year
}

struct YearReactionCard: Codable, Equatable, Identifiable {
    var id: String
    var kicker: String
    var title: String
    var detail: String
    var domain: HistoryDomainTag
    var tone: YearlyOutcomeTone
}

struct ActiveYearChapter: Codable, Equatable {
    var targetAge: Int
    var phase: YearChapterPhase = .forecast
    var plannedActions: [PlayerYearAction]
    var forecast: YearForecastCard
    var stakes: TurnStakesSnapshot? = nil
    var pendingEventIDs: [String] = []
    var eventID: String? = nil
    var selectedChoiceText: String? = nil
    var reactionCards: [YearReactionCard] = []
    var currentReactionIndex: Int = 0
    var pendingSummary: YearlyOutcomeSummary? = nil
    var pendingConsequencePreview: ConsequencePreview? = nil
    var dominantUnresolvedConsequence: ConsequencePreview? = nil
    var pendingResolution: ResolutionPreview? = nil
    var pendingCrisis: CrisisInteraction? = nil
    var pendingPitchDeck: PitchDeckInteraction? = nil
    var resolutionCardIndex: Int = 0
}

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

enum ActionDomain: String, Codable, CaseIterable, Identifiable {
    case education
    case career
    case military
    case finance
    case relationships
    case health
    case crime
    case family
    case identity

    var id: String { rawValue }
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

struct GameState: Codable, Equatable {
    var player: Player = Player()
    var trajectory: TrajectoryState = TrajectoryState()
    var education: EducationState = EducationState()
    var career: CareerState = CareerState()
    var specialCareer: SpecialCareerState = SpecialCareerState()
    var crime: CrimeState = CrimeState()
    var military: MilitaryState = MilitaryState()
    var finance: FinanceState = FinanceState()
    var relationships: RelationshipState = RelationshipState()
    var family: FamilyState = FamilyState()
    var healthProfile: HealthState = HealthState()
    var assets: AssetState = AssetState()
    var housing: HousingState = HousingState()
    var progress: ProgressState = ProgressState()
    var narrativeArcs: NarrativeArcState = NarrativeArcState()
    var consequences: ConsequenceState = ConsequenceState()
    var activities: ActivityState = ActivityState()
    // D1: Light identity coherence — 0-100, starts neutral. Self actions move it; low values create subtle pressure/crisis flavor.
    var identityCoherence: Int = 55
    
    // var correlationLedger: CorrelationLedger = CorrelationLedger()  // legacy duplicate — SystemCorrelationLedger (Engine1) is the active one below
    
    var economy: EconomyState = EconomyState()
    // Macro Autonomy
    var currentEra: WorldEra = .stable
    var eraYearsRemaining: Int = 10

    var activeYearChapter: ActiveYearChapter? = nil
    var pendingActions: [PlayerYearAction] = []
    var actionMemory: ActionMemoryState = ActionMemoryState()
    var quickActionMemory: QuickActionMemoryState = QuickActionMemoryState()
    var suggestedPlayerAction: SuggestedPlayerAction? = nil
    var yearlyStance: YearlyStanceMemory = YearlyStanceMemory()
    var mvpOnboarding: MVPOnboardingState = MVPOnboardingState()
    var softRunGoal: SoftRunGoal? = nil
    var discoverability: DiscoverabilityState = DiscoverabilityState()
    var history: [HistoryEntry] = []
    var lastEventYearById: [String: Int] = [:]
    var startupState: StartupState = .choosingOrigin
    var originProfile: OriginProfile? = nil
    var openingSummary: String? = nil
    var inheritedLegacy: LegacyInheritanceSnapshot? = nil
    var isGameOver: Bool = false
    var hasUsedCrisisBuyBack: Bool = false // One-time safety net
    /// Procedural childhood backstory + career aptitude DNA. Set by ChildhoodGenerationEngine at character creation.
    var childhoodDossier: ChildhoodDossier? = nil

    /// Controls how forgiving the simulation is of setbacks. Defaults to .resilient for better replayability.
    var resilience: LifeResilience = .resilient

    /// Tracks the strength of recent instant/quick actions and their autonomous reactions.
    /// This is the bridge for Phase 2: making micro-actions influence the next year's simulation.
    var instantMomentum: InstantMomentumState = InstantMomentumState()
    
    // Using rich CorrelationLedger with Engine shims for full build compatibility
    var correlationLedger: CorrelationLedger = CorrelationLedger()
    
    // Fame Web F1: Unified recognition profile. Every fame-adjacent avenue (special careers,
    // athlete personalBrand, military medals, lifestyle/wealth, social rep, events) will feed here.
    var fame: FameProfile = FameProfile()

    private enum CodingKeys: String, CodingKey {
        case player
        case trajectory
        case education
        case career
        case specialCareer
        case crime
        case military
        case finance
        case relationships
        case family
        case healthProfile
        case assets
        case housing
        case progress
        case narrativeArcs
        case consequences
        case activities
        case identityCoherence
        case correlationLedger
        case currentEra
        case eraYearsRemaining
        case activeYearChapter
        case pendingActions
        case actionMemory
        case quickActionMemory
        case suggestedPlayerAction
        case yearlyStance
        case mvpOnboarding
        case softRunGoal
        case discoverability
        case history
        case lastEventYearById
        case startupState
        case originProfile
        case openingSummary
        case inheritedLegacy
        case isGameOver
        case hasUsedCrisisBuyBack
        case childhoodDossier
        case resilience
        case instantMomentum
        case fame
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        player = try container.decodeIfPresent(Player.self, forKey: .player) ?? Player()
        trajectory = try container.decodeIfPresent(TrajectoryState.self, forKey: .trajectory) ?? TrajectoryState()
        education = try container.decodeIfPresent(EducationState.self, forKey: .education) ?? EducationState()
        career = try container.decodeIfPresent(CareerState.self, forKey: .career) ?? CareerState()
        specialCareer = try container.decodeIfPresent(SpecialCareerState.self, forKey: .specialCareer) ?? SpecialCareerState()
        crime = try container.decodeIfPresent(CrimeState.self, forKey: .crime) ?? CrimeState()
        military = try container.decodeIfPresent(MilitaryState.self, forKey: .military) ?? MilitaryState()
        if crime.status == .inactive, specialCareer.track == .crime {
            crime = CrimeState.migratingFromLegacySpecialCareer(specialCareer)
            specialCareer = SpecialCareerState()
        }
        let legacyMoney = try Self.decodeLegacyMoney(from: container)
        finance = try container.decodeIfPresent(FinanceState.self, forKey: .finance) ?? FinanceState(cashOnHand: legacyMoney ?? 250)
        relationships = try container.decodeIfPresent(RelationshipState.self, forKey: .relationships) ?? RelationshipState()
        family = try container.decodeIfPresent(FamilyState.self, forKey: .family) ?? FamilyState()
        healthProfile = try container.decodeIfPresent(HealthState.self, forKey: .healthProfile) ?? HealthState()
        assets = try container.decodeIfPresent(AssetState.self, forKey: .assets) ?? AssetState()
        housing = try container.decodeIfPresent(HousingState.self, forKey: .housing) ?? HousingState()
        progress = try container.decodeIfPresent(ProgressState.self, forKey: .progress) ?? ProgressState()
        narrativeArcs = try container.decodeIfPresent(NarrativeArcState.self, forKey: .narrativeArcs) ?? NarrativeArcState()
        consequences = try container.decodeIfPresent(ConsequenceState.self, forKey: .consequences) ?? ConsequenceState()
        activities = try container.decodeIfPresent(ActivityState.self, forKey: .activities) ?? ActivityState(currentYearAge: player.age)
        identityCoherence = try container.decodeIfPresent(Int.self, forKey: .identityCoherence) ?? 55
        correlationLedger = try container.decodeIfPresent(CorrelationLedger.self, forKey: .correlationLedger) ?? CorrelationLedger()

        currentEra = try container.decodeIfPresent(WorldEra.self, forKey: .currentEra) ?? .stable
        eraYearsRemaining = try container.decodeIfPresent(Int.self, forKey: .eraYearsRemaining) ?? 10

        activeYearChapter = try container.decodeIfPresent(ActiveYearChapter.self, forKey: .activeYearChapter)
        pendingActions = try container.decodeIfPresent([PlayerYearAction].self, forKey: .pendingActions) ?? []
        actionMemory = try container.decodeIfPresent(ActionMemoryState.self, forKey: .actionMemory) ?? ActionMemoryState()
        quickActionMemory = try container.decodeIfPresent(QuickActionMemoryState.self, forKey: .quickActionMemory) ?? QuickActionMemoryState()
        suggestedPlayerAction = try container.decodeIfPresent(SuggestedPlayerAction.self, forKey: .suggestedPlayerAction)
        yearlyStance = try container.decodeIfPresent(YearlyStanceMemory.self, forKey: .yearlyStance) ?? YearlyStanceMemory()
        mvpOnboarding = try container.decodeIfPresent(MVPOnboardingState.self, forKey: .mvpOnboarding) ?? MVPOnboardingState()
        softRunGoal = try container.decodeIfPresent(SoftRunGoal.self, forKey: .softRunGoal)
        discoverability = try container.decodeIfPresent(DiscoverabilityState.self, forKey: .discoverability) ?? DiscoverabilityState()
        history = try container.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? []
        lastEventYearById = try container.decodeIfPresent([String: Int].self, forKey: .lastEventYearById) ?? [:]
        startupState = try container.decodeIfPresent(StartupState.self, forKey: .startupState) ?? (player.traits.isEmpty ? .choosingOrigin : .active)
        originProfile = try container.decodeIfPresent(OriginProfile.self, forKey: .originProfile)
        openingSummary = try container.decodeIfPresent(String.self, forKey: .openingSummary)
        inheritedLegacy = try container.decodeIfPresent(LegacyInheritanceSnapshot.self, forKey: .inheritedLegacy)
        isGameOver = try container.decodeIfPresent(Bool.self, forKey: .isGameOver) ?? false
        hasUsedCrisisBuyBack = try container.decodeIfPresent(Bool.self, forKey: .hasUsedCrisisBuyBack) ?? false
        childhoodDossier = try container.decodeIfPresent(ChildhoodDossier.self, forKey: .childhoodDossier)
        resilience = try container.decodeIfPresent(LifeResilience.self, forKey: .resilience) ?? .resilient
        instantMomentum = try container.decodeIfPresent(InstantMomentumState.self, forKey: .instantMomentum) ?? InstantMomentumState()
        correlationLedger = try container.decodeIfPresent(CorrelationLedger.self, forKey: .correlationLedger) ?? CorrelationLedger()
        fame = try container.decodeIfPresent(FameProfile.self, forKey: .fame) ?? FameProfile()
    }

    private static func decodeLegacyMoney(from container: KeyedDecodingContainer<CodingKeys>) throws -> Int? {
        guard container.contains(.player) else { return nil }
        let playerContainer = try container.nestedContainer(keyedBy: LegacyPlayerCodingKeys.self, forKey: .player)
        return try playerContainer.decodeIfPresent(Int.self, forKey: .money)
    }

    private enum LegacyPlayerCodingKeys: String, CodingKey {
        case money
    }

    // MARK: - Vibe Layer (Codex IX)

    /// The current emotional register of this life, derived from state.
    /// Used by the UI to adjust visual treatment and by narrative systems
    /// to calibrate prose register. Never stored — always computed.
    var narrativeTone: NarrativeTone {
        NarrativeToneResolver().resolve(for: self)
    }

    var currentIdentityPattern: PlayerPattern? {
        PlayerPattern.resolve(from: self)
    }

    /// Keeps the Player's mirrored resilience in sync so domain systems can read it easily.
    mutating func syncResilienceToPlayer() {
        player._resilience = resilience
    }
}

struct ConsequenceState: Codable, Equatable {
    var narrativeFlags: [String: Int] = [:]
    var pressureByDomain: [String: Int] = [:]
    var scheduledEvents: [ScheduledConsequenceEvent] = []

    init() {}

    mutating func adjustPressure(domain: String, delta: Int) {
        let current = pressureByDomain[domain, default: 0]
        let nextValue = (current + delta).clamped(to: 0...100)
        if nextValue == 0 {
            pressureByDomain.removeValue(forKey: domain)
        } else {
            pressureByDomain[domain] = nextValue
        }
    }

    mutating func softenAllPressure(by amount: Int) {
        guard amount > 0 else { return }
        for key in pressureByDomain.keys {
            let nextValue = max(0, pressureByDomain[key, default: 0] - amount)
            if nextValue == 0 {
                pressureByDomain.removeValue(forKey: key)
            } else {
                pressureByDomain[key] = nextValue
            }
        }
    }
}

struct ScheduledConsequenceEvent: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var eventID: String
    var dueAge: Int
    var title: String? = nil
    var detail: String? = nil
    var sourceEventID: String? = nil
    var sourceEventTitle: String? = nil
    var sourceChoiceText: String? = nil
    var callbackFramingText: String? = nil
}

struct ConsequenceEffects: Codable, Equatable {
    var setFlags: [String] = []
    var clearFlags: [String] = []
    var pressureChanges: [String: Int] = [:]
    var scheduleEvents: [ScheduledEventTrigger] = []

    private enum CodingKeys: String, CodingKey {
        case setFlags
        case clearFlags
        case pressureChanges
        case scheduleEvents
    }

    init(
        setFlags: [String] = [],
        clearFlags: [String] = [],
        pressureChanges: [String: Int] = [:],
        scheduleEvents: [ScheduledEventTrigger] = []
    ) {
        self.setFlags = setFlags
        self.clearFlags = clearFlags
        self.pressureChanges = pressureChanges
        self.scheduleEvents = scheduleEvents
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        setFlags = try container.decodeIfPresent([String].self, forKey: .setFlags) ?? []
        clearFlags = try container.decodeIfPresent([String].self, forKey: .clearFlags) ?? []
        pressureChanges = try container.decodeIfPresent([String: Int].self, forKey: .pressureChanges) ?? [:]
        scheduleEvents = try container.decodeIfPresent([ScheduledEventTrigger].self, forKey: .scheduleEvents) ?? []
    }
}

enum ActivityCategory: String, Codable, CaseIterable, Identifiable {
    case mindBody
    case social
    case leisure
    case romanceSex
    case viceRisk
    case familyHome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mindBody: return "Mind & Body"
        case .social: return "Social"
        case .leisure: return "Leisure"
        case .romanceSex: return "Romance & Sex"
        case .viceRisk: return "Vice & Risk"
        case .familyHome: return "Family & Home"
        }
    }

    var symbol: String {
        switch self {
        case .mindBody: return "figure.mind.and.body"
        case .social: return "person.3.fill"
        case .leisure: return "gamecontroller.fill"
        case .romanceSex: return "heart.fill"
        case .viceRisk: return "flame.fill"
        case .familyHome: return "house.fill"
        }
    }
}

enum ActivityRiskLevel: String, Codable, Equatable {
    case grounding
    case easy
    case charged
    case dangerous

    var label: String {
        switch self {
        case .grounding: return "Grounding"
        case .easy: return "Low risk"
        case .charged: return "Charged"
        case .dangerous: return "Risky"
        }
    }

    var tone: YearlyOutcomeTone {
        switch self {
        case .grounding:
            return .positive
        case .easy:
            return .neutral
        case .charged, .dangerous:
            return .warning
        }
    }
}

struct ActivityEffects: Equatable {
    var happiness: Int = 0
    var smarts: Int = 0
    var looks: Int = 0
    var health: Int = 0
    var cash: Int = 0
    var financialStress: Int = 0
    var physicalWellness: Int = 0
    var mentalWellness: Int = 0
    var stressManagement: Int = 0
    var schoolStanding: Int = 0
    var engagement: Int = 0
    var schoolBelonging: Int = 0
    var activityMomentum: Int = 0
    var careerPerformance: Int = 0
    var careerBurnout: Int = 0
    var careerJobSecurity: Int = 0
    var friendBond: Int = 0
    var partnerBond: Int = 0
    var partnerCommitmentAlignment: Int = 0
    var crimeHeat: Int = 0
    var housingStability: Int = 0
    var consequences: [String: Int] = [:]
    var identityTags: [String: Int] = [:]
    var socialMomentum: Int = 0
    var recoveryBalance: Int = 0
    var riskLoad: Int = 0

    init(
        happiness: Int = 0,
        smarts: Int = 0,
        looks: Int = 0,
        health: Int = 0,
        cash: Int = 0,
        financialStress: Int = 0,
        physicalWellness: Int = 0,
        mentalWellness: Int = 0,
        stressManagement: Int = 0,
        schoolStanding: Int = 0,
        engagement: Int = 0,
        schoolBelonging: Int = 0,
        activityMomentum: Int = 0,
        careerPerformance: Int = 0,
        careerBurnout: Int = 0,
        careerJobSecurity: Int = 0,
        friendBond: Int = 0,
        partnerBond: Int = 0,
        partnerCommitmentAlignment: Int = 0,
        crimeHeat: Int = 0,
        housingStability: Int = 0,
        consequences: [String: Int] = [:],
        identityTags: [String: Int] = [:],
        socialMomentum: Int = 0,
        recoveryBalance: Int = 0,
        riskLoad: Int = 0
    ) {
        self.happiness = happiness
        self.smarts = smarts
        self.looks = looks
        self.health = health
        self.cash = cash
        self.financialStress = financialStress
        self.physicalWellness = physicalWellness
        self.mentalWellness = mentalWellness
        self.stressManagement = stressManagement
        self.schoolStanding = schoolStanding
        self.engagement = engagement
        self.schoolBelonging = schoolBelonging
        self.activityMomentum = activityMomentum
        self.careerPerformance = careerPerformance
        self.careerBurnout = careerBurnout
        self.careerJobSecurity = careerJobSecurity
        self.friendBond = friendBond
        self.partnerBond = partnerBond
        self.partnerCommitmentAlignment = partnerCommitmentAlignment
        self.crimeHeat = crimeHeat
        self.housingStability = housingStability
        self.consequences = consequences
        self.identityTags = identityTags
        self.socialMomentum = socialMomentum
        self.recoveryBalance = recoveryBalance
        self.riskLoad = riskLoad
    }
}

struct ActivityDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let category: ActivityCategory
    let costLine: String
    let previewTags: [String]
    let risk: ActivityRiskLevel
    let minimumAge: Int?
    let requiresPartner: Bool
    let requiresFriends: Bool
    let requiresChildren: Bool
    let effects: ActivityEffects

    init(
        id: String,
        title: String,
        category: ActivityCategory,
        costLine: String,
        previewTags: [String],
        risk: ActivityRiskLevel,
        minimumAge: Int? = nil,
        requiresPartner: Bool = false,
        requiresFriends: Bool = false,
        requiresChildren: Bool = false,
        effects: ActivityEffects
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.costLine = costLine
        self.previewTags = previewTags
        self.risk = risk
        self.minimumAge = minimumAge
        self.requiresPartner = requiresPartner
        self.requiresFriends = requiresFriends
        self.requiresChildren = requiresChildren
        self.effects = effects
    }

    func isAvailable(in state: GameState) -> Bool {
        if let minimumAge, state.player.age < minimumAge { return false }
        if requiresPartner, !state.relationships.hasPartner { return false }
        if requiresFriends, state.relationships.friends.isEmpty { return false }
        if requiresChildren, state.family.childCount == 0 { return false }
        switch id {
        case "art_collecting":
            return state.finance.cashOnHand >= 5_000
        case "high_end_racing":
            return state.finance.cashOnHand >= 15_000
        default:
            break
        }
        return true
    }
}

struct ActivityRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var age: Int
    var activityID: String
    var title: String
    var category: ActivityCategory
    var headline: String
    var detail: String
    var tone: YearlyOutcomeTone

    static func == (lhs: ActivityRecord, rhs: ActivityRecord) -> Bool {
        lhs.age == rhs.age &&
        lhs.activityID == rhs.activityID &&
        lhs.title == rhs.title &&
        lhs.category == rhs.category &&
        lhs.headline == rhs.headline &&
        lhs.detail == rhs.detail &&
        lhs.tone == rhs.tone
    }
}

struct ActivityState: Codable, Equatable {
    var currentYearAge: Int = 14
    var currentYearActivities: [ActivityRecord] = []
    var currentYearCounts: [String: Int] = [:]
    var previousYearCounts: [String: Int] = [:]
    var yearlyStreaks: [String: Int] = [:]
    var lifetimeCounts: [String: Int] = [:]
    var identityWeights: [String: Int] = [:]
    var socialMomentum: Int = 0
    var recoveryBalance: Int = 0
    var riskLoad: Int = 0

    init(currentYearAge: Int = 14) {
        self.currentYearAge = currentYearAge
    }

    var yearlyCount: Int { currentYearActivities.count }

    mutating func rolloverIfNeeded(to age: Int) {
        guard currentYearAge != age else { return }

        var nextStreaks: [String: Int] = [:]
        for (activityID, count) in currentYearCounts where count > 0 {
            let priorCount = previousYearCounts[activityID, default: 0]
            nextStreaks[activityID] = priorCount > 0 ? yearlyStreaks[activityID, default: 1] + 1 : 1
        }

        previousYearCounts = currentYearCounts
        currentYearCounts = [:]
        currentYearActivities = []
        yearlyStreaks = nextStreaks
        currentYearAge = age
    }

    func preferredEventWeights() -> [String: Int] {
        var weights: [String: Int] = [:]

        if recoveryBalance >= 6 {
            weights["health", default: 0] += 5
            weights["routine", default: 0] += 4
        }
        if socialMomentum >= 5 {
            weights["social", default: 0] += 6
            weights["romance", default: 0] += 4
            weights["family", default: 0] += 2
        }
        if riskLoad >= 8 {
            weights["risk", default: 0] += 8
            weights["money", default: 0] += 4
            weights["health", default: 0] += 4
        }
        if identityWeights["self_improvement", default: 0] >= 4 {
            weights["career", default: 0] += 4
            weights["school", default: 0] += 4
        }
        if identityWeights["domestic", default: 0] >= 4 {
            weights["housing", default: 0] += 4
            weights["family", default: 0] += 5
        }
        if identityWeights["escapist", default: 0] >= 4 {
            weights["chance", default: 0] += 4
            weights["risk", default: 0] += 5
        }

        return weights
    }
}

struct ActivityResolution: Equatable {
    var headline: String
    var detail: String
    var tone: YearlyOutcomeTone
    var pressureChanges: [String: Int]
    var historyEntry: HistoryEntry
    var record: ActivityRecord
    var majorPreview: ConsequencePreview? = nil
}

struct ActivitySystem {
    func availableActivities(for state: GameState, in category: ActivityCategory) -> [ActivityDefinition] {
        Self.catalog.filter { $0.category == category && $0.isAvailable(in: state) }
    }

    func activity(withID id: String) -> ActivityDefinition? {
        Self.catalog.first { $0.id == id }
    }

    func apply(activityID: String, to state: inout GameState) -> ActivityResolution? {
        state.activities.rolloverIfNeeded(to: state.player.age)
        guard let definition = activity(withID: activityID), definition.isAvailable(in: state) else { return nil }

        let repeatCount = state.activities.currentYearCounts[activityID, default: 0]
        let yearlyCount = state.activities.yearlyCount
        let scaled = scaledEffects(for: definition, repeatCount: repeatCount, yearlyCount: yearlyCount)
        apply(scaled, from: definition, to: &state)

        state.activities.currentYearCounts[activityID, default: 0] += 1
        state.activities.lifetimeCounts[activityID, default: 0] += 1
        
        // Hobby/Vice Extension
        if definition.category == .viceRisk {
            state.healthProfile.addiction += 8
        }
        
        for (tag, value) in scaled.identityTags {
            state.activities.identityWeights[tag, default: 0] += value
        }
        state.activities.socialMomentum = (state.activities.socialMomentum + scaled.socialMomentum).clamped(to: -20...20)
        state.activities.recoveryBalance = (state.activities.recoveryBalance + scaled.recoveryBalance).clamped(to: -20...20)
        state.activities.riskLoad = (state.activities.riskLoad + scaled.riskLoad).clamped(to: 0...40)
        for (domain, delta) in scaled.consequences {
            state.consequences.adjustPressure(domain: domain, delta: delta)
        }

        let detail = detailLine(for: definition, scaled: scaled, repeatCount: repeatCount, yearlyCount: yearlyCount)
        let tone = resolutionTone(for: definition, scaled: scaled)
        let record = ActivityRecord(
            age: state.player.age,
            activityID: definition.id,
            title: definition.title,
            category: definition.category,
            headline: headline(for: definition, scaled: scaled),
            detail: detail,
            tone: tone
        )
        state.activities.currentYearActivities.insert(record, at: 0)
        let historyEntry = HistoryEntry(
            age: state.player.age,
            title: record.headline,
            text: detail,
            tags: historyTags(for: definition)
        )
        state.history.insert(historyEntry, at: 0)

        return ActivityResolution(
            headline: record.headline,
            detail: detail,
            tone: tone,
            pressureChanges: scaled.consequences,
            historyEntry: historyEntry,
            record: record,
            majorPreview: majorPreview(for: definition, state: state)
        )
    }

    private func apply(_ effects: ActivityEffects, from definition: ActivityDefinition, to state: inout GameState) {
        state.player.happiness += effects.happiness
        state.player.smarts += effects.smarts
        state.player.looks += effects.looks
        state.player.health += effects.health

        state.finance.cashOnHand += effects.cash
        state.finance.financialStress = (state.finance.financialStress + effects.financialStress).clamped(to: 0...100)

        state.healthProfile.physicalWellness = (state.healthProfile.physicalWellness + effects.physicalWellness).clamped(to: 0...100)
        state.healthProfile.mentalWellness = (state.healthProfile.mentalWellness + effects.mentalWellness).clamped(to: 0...100)
        state.healthProfile.habits.stressManagement = (state.healthProfile.habits.stressManagement + effects.stressManagement).clamped(to: 0...100)

        state.education.schoolStanding = (state.education.schoolStanding + effects.schoolStanding).clamped(to: 0...100)
        state.education.engagement = (state.education.engagement + effects.engagement).clamped(to: 0...100)
        state.education.schoolBelonging = (state.education.schoolBelonging + effects.schoolBelonging).clamped(to: 0...100)
        state.education.activityMomentum = (state.education.activityMomentum + effects.activityMomentum).clamped(to: 0...100)

        state.career.performance = (state.career.performance + effects.careerPerformance).clamped(to: 0...100)
        state.career.burnout = (state.career.burnout + effects.careerBurnout).clamped(to: 0...100)
        state.career.jobSecurity = (state.career.jobSecurity + effects.careerJobSecurity).clamped(to: 0...100)

        if effects.friendBond != 0 {
            if state.relationships.friends.isEmpty, effects.friendBond > 0 {
                state.relationships.friends.append(
                    Relationship(
                        name: Self.generatedFriendName(seed: state.activities.lifetimeCounts[definition.id, default: 0]),
                        type: .friend,
                        bond: min(70, max(38, 36 + effects.friendBond))
                    )
                )
            } else if !state.relationships.friends.isEmpty {
                state.relationships.friends[0].bond = (state.relationships.friends[0].bond + effects.friendBond).clamped(to: 0...100)
                if state.relationships.friends[0].bond < 35 {
                    state.relationships.friends[0].status = .strained
                }
            }
        }

        if effects.partnerBond != 0, let index = state.relationships.romanticPartners.firstIndex(where: { !$0.isSecret }) {
            var partner = state.relationships.romanticPartners[index]
            partner.bond = (partner.bond + effects.partnerBond).clamped(to: 0...100)
            partner.commitmentAlignment = (partner.commitmentAlignment + effects.partnerCommitmentAlignment).clamped(to: 0...100)
            if effects.partnerBond <= -4 {
                partner.status = .strained
            } else if partner.bond >= 45 && partner.status == .strained {
                partner.status = .active
            }
            state.relationships.romanticPartners[index] = partner
        }

        state.crime.heat = (state.crime.heat + effects.crimeHeat).clamped(to: 0...100)
        state.housing.housingStability = (state.housing.housingStability + effects.housingStability).clamped(to: 0...100)

        state.player.clampStats()
        state.education.clamp()
        state.finance.financialStress = state.finance.financialStress.clamped(to: 0...100)
        state.healthProfile.clamp()
        state.career.clamp()
        state.specialCareer.clamp()
        state.crime.clamp()
        state.housing.clamp()
    }

    private func scaledEffects(for definition: ActivityDefinition, repeatCount: Int, yearlyCount: Int) -> ActivityEffects {
        func scale(_ value: Int, positiveDecay: Double, negativeEscalation: Double) -> Int {
            guard value != 0 else { return 0 }
            if value > 0 {
                let multiplier = max(0.35, 1.0 - (Double(repeatCount) * positiveDecay))
                return scaledInt(value, multiplier: multiplier)
            }
            let annualLoad = max(0, yearlyCount - 2)
            let multiplier = 1.0 + (Double(repeatCount) * negativeEscalation) + (Double(annualLoad) * 0.12)
            return scaledInt(value, multiplier: multiplier)
        }

        let risky = definition.risk == .dangerous || definition.risk == .charged
        let positiveDecay = risky ? 0.28 : 0.18
        let negativeEscalation = risky ? 0.35 : 0.18
        let base = definition.effects

        return ActivityEffects(
            happiness: scale(base.happiness, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            smarts: scale(base.smarts, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            looks: scale(base.looks, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            health: scale(base.health, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            cash: scale(base.cash, positiveDecay: 0.05, negativeEscalation: 0.22),
            financialStress: scale(base.financialStress, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            physicalWellness: scale(base.physicalWellness, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            mentalWellness: scale(base.mentalWellness, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            stressManagement: scale(base.stressManagement, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            schoolStanding: scale(base.schoolStanding, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            engagement: scale(base.engagement, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            schoolBelonging: scale(base.schoolBelonging, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            activityMomentum: scale(base.activityMomentum, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            careerPerformance: scale(base.careerPerformance, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            careerBurnout: scale(base.careerBurnout, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            careerJobSecurity: scale(base.careerJobSecurity, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            friendBond: scale(base.friendBond, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            partnerBond: scale(base.partnerBond, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            partnerCommitmentAlignment: scale(base.partnerCommitmentAlignment, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            crimeHeat: scale(base.crimeHeat, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            housingStability: scale(base.housingStability, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            consequences: base.consequences.mapValues { scale($0, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation) },
            identityTags: base.identityTags,
            socialMomentum: scale(base.socialMomentum, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            recoveryBalance: scale(base.recoveryBalance, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation),
            riskLoad: scale(base.riskLoad, positiveDecay: positiveDecay, negativeEscalation: negativeEscalation)
        )
    }

    private func scaledInt(_ value: Int, multiplier: Double) -> Int {
        let scaled = Int((Double(value) * multiplier).rounded())
        if value > 0 {
            return max(1, scaled)
        }
        return min(-1, scaled)
    }

    private func headline(for definition: ActivityDefinition, scaled: ActivityEffects) -> String {
        switch definition.id {
        case "gym_session": return "You forced your body back into the year"
        case "therapy_session": return "You stopped pretending it would sort itself out"
        case "journal_night": return "You made the noise legible for once"
        case "hang_with_friends": return "You remembered what company can soften"
        case "meet_new_people": return "You put yourself back into circulation"
        case "community_event": return "You showed up somewhere beyond your own head"
        case "gaming_binge": return "You disappeared into a smaller world for a while"
        case "read_or_class": return "You fed the future version of yourself"
        case "weekend_trip": return "You spent money to make the year feel wider"
        case "date_night": return "You made the relationship feel chosen again"
        case "look_for_date": return "You aimed yourself back at intimacy"
        case "hookup": return "You chased closeness without asking for permanence"
        case "drink_night": return "You paid for relief and called it fun"
        case "casino_trip": return "You let chance sit too close to your money"
        case "reckless_night": return "You gave impulse too much room"
        case "visit_family": return "You went back to the people who still know you"
        case "family_night_in": return "You chose steadiness over escape for a night"
        case "deep_clean_home": return "You made the place feel livable again"
        case "childcare_day": return "You spent energy where the family actually needed it"
        default:
            return scaled.happiness >= 0 ? "\(definition.title) landed" : "\(definition.title) came with a bill"
        }
    }

    private func detailLine(for definition: ActivityDefinition, scaled: ActivityEffects, repeatCount: Int, yearlyCount: Int) -> String {
        var fragments: [String] = []
        if scaled.cash != 0 {
            fragments.append(scaled.cash > 0 ? "Cash +$\(scaled.cash)" : "Cash -$\(abs(scaled.cash))")
        }
        if scaled.mentalWellness != 0 {
            fragments.append("Mental \(scaled.mentalWellness > 0 ? "+" : "")\(scaled.mentalWellness)")
        }
        if scaled.physicalWellness != 0 {
            fragments.append("Physical \(scaled.physicalWellness > 0 ? "+" : "")\(scaled.physicalWellness)")
        }
        if scaled.friendBond != 0 || scaled.partnerBond != 0 {
            let socialDelta = scaled.friendBond != 0 ? scaled.friendBond : scaled.partnerBond
            fragments.append("Bond \(socialDelta > 0 ? "+" : "")\(socialDelta)")
        }
        if fragments.isEmpty {
            fragments.append(definition.costLine)
        }
        if repeatCount > 0 {
            fragments.append("repeat payoff tapering")
        }
        if yearlyCount >= 4 {
            fragments.append("the year is starting to push back")
        }
        return fragments.joined(separator: " • ")
    }

    private func resolutionTone(for definition: ActivityDefinition, scaled: ActivityEffects) -> YearlyOutcomeTone {
        if definition.risk == .dangerous || definition.risk == .charged {
            return (scaled.mentalWellness < 0 || scaled.cash < 0 || scaled.crimeHeat > 0) ? .warning : .neutral
        }
        if scaled.mentalWellness > 0 || scaled.physicalWellness > 0 || scaled.friendBond > 0 || scaled.partnerBond > 0 {
            return .positive
        }
        return .neutral
    }

    private func majorPreview(for definition: ActivityDefinition, state: GameState) -> ConsequencePreview? {
        guard state.activities.yearlyCount >= 4 else { return nil }

        switch definition.category {
        case .viceRisk where state.activities.riskLoad >= 10:
            return ConsequencePreview(
                id: "activity-risk-\(state.player.age)-\(definition.id)",
                title: "The activity is starting to run ahead of you",
                detail: "What felt like relief is becoming a pattern the rest of the year will have to absorb.",
                domain: .activities,
                tone: .warning
            )
        case .romanceSex where state.relationships.hasPartner && state.relationships.partnerBond < 45:
            return ConsequencePreview(
                id: "activity-romance-\(state.player.age)-\(definition.id)",
                title: "Your romantic choices are starting to leave a mark",
                detail: "The relationship side of life is no longer treating this as harmless background behavior.",
                domain: .relationships,
                tone: .warning
            )
        default:
            return nil
        }
    }

    private func historyTags(for definition: ActivityDefinition) -> [HistoryDomainTag] {
        var tags: [HistoryDomainTag] = [.activities]
        switch definition.category {
        case .mindBody:
            tags.append(.health)
        case .social:
            tags.append(.relationships)
        case .leisure:
            tags.append(.progress)
        case .romanceSex:
            tags.append(contentsOf: [.relationships, .lifeEvent])
        case .viceRisk:
            tags.append(contentsOf: [.health, .finance])
        case .familyHome:
            tags.append(contentsOf: [.housing, .relationships])
        }
        return Array(Set(tags))
    }

    private static func generatedFriendName(seed: Int) -> String {
        let names = ["Maya", "Rico", "Leah", "Andre", "Naomi", "Eli", "Sasha", "Jules", "Ava", "Marcus"]
        return names[abs(seed) % names.count]
    }

    static let catalog: [ActivityDefinition] = [
        ActivityDefinition(
            id: "gym_session",
            title: "Hit The Gym",
            category: .mindBody,
            costLine: "$20 • energy • visible payoff",
            previewTags: ["Recovery", "Looks", "Discipline"],
            risk: .grounding,
            effects: ActivityEffects(happiness: 1, looks: 1, health: 1, cash: -20, physicalWellness: 4, mentalWellness: 1, stressManagement: 2, careerBurnout: -1, consequences: ["health": -2], identityTags: ["self_improvement": 1], recoveryBalance: 2)
        ),
        ActivityDefinition(
            id: "therapy_session",
            title: "Go To Therapy",
            category: .mindBody,
            costLine: "$90 • emotional labor • steadier floor",
            previewTags: ["Mental", "Stress", "Counterbalance"],
            risk: .grounding,
            minimumAge: 16,
            effects: ActivityEffects(happiness: 1, cash: -90, financialStress: 1, mentalWellness: 5, stressManagement: 4, careerBurnout: -2, consequences: ["health": -4, "relationships": -1], identityTags: ["grounded": 1], recoveryBalance: 3)
        ),
        ActivityDefinition(
            id: "journal_night",
            title: "Journal For A Night",
            category: .mindBody,
            costLine: "quiet evening • low cost • small relief",
            previewTags: ["Mental", "Cheap", "Routine"],
            risk: .easy,
            effects: ActivityEffects(happiness: 1, mentalWellness: 3, stressManagement: 2, engagement: 1, careerBurnout: -1, consequences: ["health": -1], identityTags: ["grounded": 1], recoveryBalance: 2)
        ),
        ActivityDefinition(
            id: "hang_with_friends",
            title: "Hang Out With Friends",
            category: .social,
            costLine: "$25 • time • softens isolation",
            previewTags: ["Belonging", "Bond", "Relief"],
            risk: .easy,
            requiresFriends: true,
            effects: ActivityEffects(happiness: 2, cash: -25, mentalWellness: 2, schoolBelonging: 3, careerBurnout: -1, friendBond: 4, consequences: ["relationships": -2], identityTags: ["social": 1], socialMomentum: 2)
        ),
        ActivityDefinition(
            id: "meet_new_people",
            title: "Meet New People",
            category: .social,
            costLine: "$15 • uncertain • maybe worth it",
            previewTags: ["Belonging", "Exposure", "Chance"],
            risk: .easy,
            effects: ActivityEffects(happiness: 1, looks: 1, cash: -15, schoolBelonging: 2, activityMomentum: 1, friendBond: 3, consequences: ["relationships": -1], identityTags: ["social": 1], socialMomentum: 2)
        ),
        ActivityDefinition(
            id: "community_event",
            title: "Go To A Community Event",
            category: .social,
            costLine: "$10 • low stakes • outside your bubble",
            previewTags: ["Routine", "Social", "Grounding"],
            risk: .grounding,
            effects: ActivityEffects(happiness: 1, cash: -10, mentalWellness: 2, schoolBelonging: 2, careerPerformance: 1, friendBond: 2, housingStability: 1, consequences: ["relationships": -1], identityTags: ["grounded": 1, "social": 1], socialMomentum: 1, recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "gaming_binge",
            title: "Lose A Night To Gaming",
            category: .leisure,
            costLine: "cheap • relief now • drift later",
            previewTags: ["Escape", "Cheap", "Time sink"],
            risk: .charged,
            effects: ActivityEffects(happiness: 2, smarts: 1, mentalWellness: 1, stressManagement: 1, engagement: -1, careerPerformance: -1, consequences: ["career": 1], identityTags: ["escapist": 1], recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "read_or_class",
            title: "Read Or Take A Small Class",
            category: .leisure,
            costLine: "$30 • focus • future-facing",
            previewTags: ["Smarts", "Career", "Routine"],
            risk: .grounding,
            effects: ActivityEffects(happiness: 1, smarts: 3, cash: -30, mentalWellness: 1, schoolStanding: 2, engagement: 2, careerPerformance: 2, consequences: ["career": -1], identityTags: ["self_improvement": 1], recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "weekend_trip",
            title: "Take A Weekend Trip",
            category: .leisure,
            costLine: "$180 • reset • not cheap",
            previewTags: ["Relief", "Spend", "Reset"],
            risk: .easy,
            minimumAge: 16,
            effects: ActivityEffects(happiness: 3, cash: -180, financialStress: 2, mentalWellness: 3, stressManagement: 2, careerBurnout: -2, consequences: ["finance": 2, "health": -1], identityTags: ["escapist": 1], recoveryBalance: 2)
        ),
        ActivityDefinition(
            id: "date_night",
            title: "Plan A Date Night",
            category: .romanceSex,
            costLine: "$70 • intimacy • shared attention",
            previewTags: ["Partner", "Bond", "Cost"],
            risk: .easy,
            minimumAge: 16,
            requiresPartner: true,
            effects: ActivityEffects(happiness: 2, cash: -70, mentalWellness: 1, partnerBond: 5, partnerCommitmentAlignment: 2, consequences: ["relationships": -3], identityTags: ["romantic": 1], socialMomentum: 1)
        ),
        ActivityDefinition(
            id: "look_for_date",
            title: "Put Yourself Out There",
            category: .romanceSex,
            costLine: "$40 • vulnerable • image heavy",
            previewTags: ["Looks", "Chance", "Exposure"],
            risk: .charged,
            minimumAge: 16,
            effects: ActivityEffects(happiness: 1, looks: 1, cash: -40, mentalWellness: 1, schoolBelonging: 1, consequences: ["relationships": 1], identityTags: ["romantic": 1], socialMomentum: 1, riskLoad: 1)
        ),
        ActivityDefinition(
            id: "hookup",
            title: "Go For A Hookup",
            category: .romanceSex,
            costLine: "immediate closeness • unstable aftertaste",
            previewTags: ["Desire", "Risk", "Aftermath"],
            risk: .dangerous,
            minimumAge: 18,
            effects: ActivityEffects(happiness: 2, looks: 1, mentalWellness: -1, stressManagement: -1, partnerBond: -5, consequences: ["relationships": 4, "health": 2], identityTags: ["romantic": 1, "escapist": 1], socialMomentum: 1, riskLoad: 3)
        ),
        ActivityDefinition(
            id: "drink_night",
            title: "Go Drinking",
            category: .viceRisk,
            costLine: "$45 • short relief • messy tomorrow",
            previewTags: ["Relief", "Vice", "Health bill"],
            risk: .dangerous,
            minimumAge: 21,
            effects: ActivityEffects(happiness: 2, health: -1, cash: -45, mentalWellness: 1, stressManagement: -2, careerPerformance: -1, careerBurnout: 1, crimeHeat: 1, consequences: ["health": 3, "career": 2], identityTags: ["escapist": 1, "indulgent": 1], riskLoad: 3)
        ),
        ActivityDefinition(
            id: "casino_trip",
            title: "Go To The Casino",
            category: .viceRisk,
            costLine: "cash swing • adrenaline • bad floor",
            previewTags: ["Money", "Chance", "Vice"],
            risk: .dangerous,
            minimumAge: 21,
            effects: ActivityEffects(happiness: 2, cash: -120, financialStress: 2, mentalWellness: 1, careerPerformance: -1, consequences: ["finance": 5], identityTags: ["escapist": 1, "indulgent": 1], riskLoad: 4)
        ),
        ActivityDefinition(
            id: "reckless_night",
            title: "Have A Reckless Night",
            category: .viceRisk,
            costLine: "$80 • chaos • possible fallout",
            previewTags: ["Impulse", "Heat", "Health"],
            risk: .dangerous,
            minimumAge: 18,
            effects: ActivityEffects(happiness: 3, health: -2, cash: -80, mentalWellness: -1, careerPerformance: -2, crimeHeat: 4, consequences: ["health": 4, "career": 3, "relationships": 2], identityTags: ["escapist": 1, "indulgent": 1], riskLoad: 5)
        ),
        ActivityDefinition(
            id: "visit_family",
            title: "Visit Family",
            category: .familyHome,
            costLine: "$20 • emotional weight • grounding",
            previewTags: ["Family", "History", "Support"],
            risk: .grounding,
            effects: ActivityEffects(happiness: 1, cash: -20, mentalWellness: 2, stressManagement: 2, housingStability: 1, consequences: ["relationships": -1], identityTags: ["domestic": 1], socialMomentum: 1, recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "art_collecting",
            title: "Art Collecting",
            category: .leisure,
            costLine: "$2,000 • status • long-term floor",
            previewTags: ["Status", "Mental floor", "Expensive"],
            risk: .grounding,
            minimumAge: 25,
            effects: ActivityEffects(happiness: 2, cash: -2000, mentalWellness: 4, stressManagement: 3, careerJobSecurity: 2, identityTags: ["connoisseur": 1], recoveryBalance: 2)
        ),
        ActivityDefinition(
            id: "high_end_racing",
            title: "High-End Racing",
            category: .viceRisk,
            costLine: "$8,000 • adrenaline • dangerous",
            previewTags: ["Adrenaline", "Status", "Lethal risk"],
            risk: .dangerous,
            minimumAge: 21,
            effects: ActivityEffects(happiness: 4, looks: 2, cash: -8000, mentalWellness: 1, stressManagement: -2, careerPerformance: 1, consequences: ["health": 8, "finance": 4], identityTags: ["indulgent": 1], riskLoad: 8)
        ),
        ActivityDefinition(
            id: "family_night_in",
            title: "Stay In With Family",
            category: .familyHome,
            costLine: "cheap • calming • less freedom",
            previewTags: ["Domestic", "Bond", "Routine"],
            risk: .grounding,
            minimumAge: 16,
            requiresPartner: true,
            effects: ActivityEffects(happiness: 1, mentalWellness: 2, stressManagement: 2, partnerBond: 4, consequences: ["relationships": -2, "health": -1], identityTags: ["domestic": 1], socialMomentum: 1, recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "deep_clean_home",
            title: "Deep Clean Your Place",
            category: .familyHome,
            costLine: "$10 • annoying • stabilizing",
            previewTags: ["Home", "Routine", "Control"],
            risk: .easy,
            effects: ActivityEffects(happiness: 1, cash: -10, mentalWellness: 1, stressManagement: 2, housingStability: 4, consequences: ["housing": -3], identityTags: ["domestic": 1], recoveryBalance: 1)
        ),
        ActivityDefinition(
            id: "childcare_day",
            title: "Take The Parenting Load",
            category: .familyHome,
            costLine: "energy • less freedom • more trust",
            previewTags: ["Family", "Responsibility", "Bond"],
            risk: .charged,
            requiresChildren: true,
            effects: ActivityEffects(happiness: 1, mentalWellness: -1, stressManagement: -1, careerBurnout: 1, partnerBond: 3, housingStability: 1, consequences: ["relationships": -1, "health": 1], identityTags: ["domestic": 1], socialMomentum: 1)
        )
    ]
}

struct ScheduledEventTrigger: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var eventID: String
    var yearsFromNow: Int
    var title: String? = nil
    var detail: String? = nil

    private enum CodingKeys: String, CodingKey {
        case id
        case eventID
        case yearsFromNow
        case title
        case detail
    }

    init(
        id: String = UUID().uuidString,
        eventID: String,
        yearsFromNow: Int,
        title: String? = nil,
        detail: String? = nil
    ) {
        self.id = id
        self.eventID = eventID
        self.yearsFromNow = yearsFromNow
        self.title = title
        self.detail = detail
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        eventID = try container.decode(String.self, forKey: .eventID)
        yearsFromNow = try container.decode(Int.self, forKey: .yearsFromNow)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        detail = try container.decodeIfPresent(String.self, forKey: .detail)
    }
}

enum HistoryDomainTag: String, Codable, CaseIterable, Identifiable {
    case system
    case activities
    case education
    case career
    case military
    case social
    case fame
    case crime
    case risk
    case finance
    case relationships
    case health
    case family
    case housing
    case assets
    case progress
    case lifeEvent
    case identity  // D1 self domain

    var id: String { rawValue }
}

struct HistoryEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var age: Int
    var title: String
    var text: String
    var tags: [HistoryDomainTag] = []

    private enum CodingKeys: String, CodingKey {
        case id
        case age
        case title
        case text
        case tags
    }

    init(id: UUID = UUID(), age: Int, title: String, text: String, tags: [HistoryDomainTag] = []) {
        self.id = id
        self.age = age
        self.title = title
        self.text = text
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        age = try container.decode(Int.self, forKey: .age)
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        tags = try container.decodeIfPresent([HistoryDomainTag].self, forKey: .tags) ?? []
    }

    static func == (lhs: HistoryEntry, rhs: HistoryEntry) -> Bool {
        lhs.age == rhs.age &&
        lhs.title == rhs.title &&
        lhs.text == rhs.text &&
        lhs.tags == rhs.tags
    }
}

struct DomainYearResult: Equatable {
    var notes: [DomainNote] = []
    var events: [GameEvent] = []
    var spilloverSignals: [SpilloverSignal] = []
    var coreEffects: CoreStatEffects? = nil
    var trajectoryEffects: TrajectoryEffects? = nil
    var educationEffects: EducationEffects? = nil
    var careerEffects: CareerEffects? = nil
    var specialCareerEffects: SpecialCareerEffects? = nil
    var militaryEffects: MilitaryEffects? = nil
    var crimeEffects: CrimeEffects? = nil
    var financeEffects: FinanceEffects? = nil
    var relationshipEffects: RelationshipEffects? = nil
    var healthEffects: HealthEffects? = nil
    var housingEffects: HousingEffects? = nil
    var assetEffects: AssetEffects? = nil
    var fameEffects: FameEffects? = nil   // Fame Web F1
}

struct DomainNote: Equatable {
    var title: String
    var text: String
    var tags: [HistoryDomainTag] = []
}

struct SpilloverSignal: Equatable {
    var title: String
    var detail: String
    var sourceDomain: HistoryDomainTag
    var impactedDomain: HistoryDomainTag
    var tone: YearlyOutcomeTone
    var impactScore: Int
}

enum YearlyOutcomeTone: String, Codable, Equatable {
    case positive
    case neutral
    case warning
}

struct YearlyOutcomeItem: Codable, Identifiable, Equatable {
    var title: String
    var detail: String
    var domain: HistoryDomainTag
    var tone: YearlyOutcomeTone
    var impactScore: Int

    var id: String { "\(domain.rawValue)-\(title)-\(detail)" }
}

struct YearlyOutcomeSummary: Codable, Equatable {
    var age: Int
    var headlines: [YearlyOutcomeItem] = []
    var topProblem: YearlyOutcomeItem? = nil
    var topOpportunity: YearlyOutcomeItem? = nil
    var momentum: YearlyOutcomeItem? = nil
    var spillovers: [YearlyOutcomeItem] = []
    var checkpoint: YearlyOutcomeItem? = nil
    var focusOutcome: YearlyOutcomeItem? = nil
    var mainTradeoff: YearlyOutcomeItem? = nil
    var nextYearPressure: YearlyOutcomeItem? = nil
    var yearlyStanceOutcome: YearlyOutcomeItem? = nil
}

struct ConsequencePreview: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var domain: HistoryDomainTag
    var tone: YearlyOutcomeTone
}

struct ResolutionPreview: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var actionTitle: String
}

struct CrisisChoice: Codable, Equatable, Identifiable {
    var id: String
    var text: String
    var detail: String
    var costSummary: String
    var isBuyBack: Bool // true = survive with penalty, false = accept death/failure
}

struct CrisisInteraction: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var choices: [CrisisChoice]
}

enum BusinessSector: String, Codable, CaseIterable {
    case general
    case semiconductors
    case restaurants
    case automobiles
    case gaming
}

enum AdvisorSpecialty: String, Codable, CaseIterable {
    case growth
    case strategy
    case political
}

struct BusinessAdvisor: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var specialty: AdvisorSpecialty
    var yearlyFee: Int
}

struct PitchDeckChoice: Codable, Equatable, Identifiable {
    var id: String
    var text: String
    var detail: String
    var sector: BusinessSector
}

struct PitchDeckInteraction: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var choices: [PitchDeckChoice]
}

enum InteractionCardPayload: Equatable, Identifiable {
    case forecast(YearForecastCard)
    case yearSummary(YearlyOutcomeSummary)
    case event(GameEvent)
    case reaction(YearReactionCard)
    case consequence(ConsequencePreview)
    case resolution(ResolutionPreview)
    case crisis(CrisisInteraction)
    case pitchDeck(PitchDeckInteraction)

    var id: String {
        switch self {
        case .forecast(let forecast):
            return forecast.id
        case .yearSummary(let summary):
            return "summary-\(summary.age)"
        case .event(let event):
            return "event-\(event.id)"
        case .reaction(let reaction):
            return reaction.id
        case .consequence(let preview):
            return preview.id
        case .resolution(let preview):
            return preview.id
        case .crisis(let crisis):
            return crisis.id
        case .pitchDeck(let pitch):
            return pitch.id
        }
    }
}

struct YearAdvanceOutcome: Equatable {
    var summary: YearlyOutcomeSummary? = nil
    var cards: [InteractionCardPayload] = []
}

// MARK: - Trait Domain

enum PersonalityTrait: String, Codable, CaseIterable, Identifiable {
    case disciplined
    case impulsive
    case charismatic
    case anxious
    case lucky
    
    // Mutated Traits
    case manipulative
    case coldBlooded
    case visionary
    case burnoutProne
    case workaholic
    case resilient
    case unreliable
    case ptsd

    var id: String { rawValue }
}

struct CoreStatDelta: Equatable {
    var happiness: Int = 0
    var smarts: Int = 0
    var looks: Int = 0
    var health: Int = 0
}

struct FinanceDelta: Equatable {
    var cash: Int = 0
}

struct TraitProfile: Equatable {
    var name: String
    var summary: String
    var yearlyDrift: CoreStatDelta
    var yearlyFinanceDrift: FinanceDelta
    var eventTagWeights: [String: Int]
    var eventTagOutcomes: [String: CoreStatDelta]
    var eventTagFinanceOutcomes: [String: FinanceDelta]
}

enum TraitCatalog {
    static func profile(for trait: PersonalityTrait) -> TraitProfile {
        switch trait {
        case .disciplined:
            return TraitProfile(
                name: "Disciplined",
                summary: "Steady and self-controlled, with an edge in school, work, and healthy routines.",
                yearlyDrift: CoreStatDelta(happiness: 0, smarts: 1, looks: 0, health: 1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["school": 5, "career": 6, "health": 4, "routine": 4],
                eventTagOutcomes: [
                    "school": CoreStatDelta(smarts: 2),
                    "career": CoreStatDelta(smarts: 1),
                    "health": CoreStatDelta(health: 2)
                ],
                eventTagFinanceOutcomes: [
                    "career": FinanceDelta(cash: 150)
                ]
            )
        case .impulsive:
            return TraitProfile(
                name: "Impulsive",
                summary: "Quick to act, making risky or social years feel more tempting and swingy.",
                yearlyDrift: CoreStatDelta(happiness: 1, smarts: -1, looks: 0, health: -1),
                yearlyFinanceDrift: FinanceDelta(cash: -50),
                eventTagWeights: ["risk": 7, "social": 4, "spend": 6, "romance": 3],
                eventTagOutcomes: [
                    "risk": CoreStatDelta(happiness: 2, health: -2),
                    "spend": CoreStatDelta(happiness: 1),
                    "social": CoreStatDelta(happiness: 1)
                ],
                eventTagFinanceOutcomes: [
                    "risk": FinanceDelta(cash: -100),
                    "spend": FinanceDelta(cash: -150)
                ]
            )
        case .charismatic:
            return TraitProfile(
                name: "Charismatic",
                summary: "Socially magnetic, with better momentum in relationships and public-facing opportunities.",
                yearlyDrift: CoreStatDelta(happiness: 1, smarts: 0, looks: 1, health: 0),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["social": 6, "romance": 7, "career": 3],
                eventTagOutcomes: [
                    "social": CoreStatDelta(happiness: 2),
                    "romance": CoreStatDelta(happiness: 2, looks: 1),
                    "career": CoreStatDelta()
                ],
                eventTagFinanceOutcomes: [
                    "career": FinanceDelta(cash: 100)
                ]
            )
        case .anxious:
            return TraitProfile(
                name: "Anxious",
                summary: "Cautious and tense, leaning away from risky situations and carrying more mental strain.",
                yearlyDrift: CoreStatDelta(happiness: -1, smarts: 1, looks: 0, health: -1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["risk": -8, "health": 4, "school": 3],
                eventTagOutcomes: [
                    "risk": CoreStatDelta(happiness: -2, health: -1),
                    "health": CoreStatDelta(smarts: 1),
                    "school": CoreStatDelta(smarts: 1)
                ],
                eventTagFinanceOutcomes: [:]
            )
        case .lucky:
            return TraitProfile(
                name: "Lucky",
                summary: "Things tend to break your way just often enough to nudge long-term outcomes upward.",
                yearlyDrift: CoreStatDelta(happiness: 1, smarts: 0, looks: 0, health: 0),
                yearlyFinanceDrift: FinanceDelta(cash: 75),
                eventTagWeights: ["chance": 10, "career": 2, "money": 4],
                eventTagOutcomes: [
                    "chance": CoreStatDelta(happiness: 2),
                    "money": CoreStatDelta(),
                    "career": CoreStatDelta()
                ],
                eventTagFinanceOutcomes: [
                    "chance": FinanceDelta(cash: 250),
                    "money": FinanceDelta(cash: 150),
                    "career": FinanceDelta(cash: 100)
                ]
            )
        case .manipulative:
            return TraitProfile(
                name: "Manipulative",
                summary: "You see people as leverage. Bonds are harder to form, but social capital builds faster.",
                yearlyDrift: CoreStatDelta(happiness: -1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["social": 8, "risk": 5],
                eventTagOutcomes: ["social": CoreStatDelta(smarts: 1)],
                eventTagFinanceOutcomes: [:]
            )
        case .coldBlooded:
            return TraitProfile(
                name: "Cold-Blooded",
                summary: "Volatility doesn't shake you. Immune to financial stress effects, but isolated from deep connections.",
                yearlyDrift: CoreStatDelta(happiness: -2),
                yearlyFinanceDrift: FinanceDelta(cash: 200),
                eventTagWeights: ["money": 10, "risk": 7],
                eventTagOutcomes: ["money": CoreStatDelta(smarts: 2)],
                eventTagFinanceOutcomes: ["money": FinanceDelta(cash: 500)]
            )
        case .visionary:
            return TraitProfile(
                name: "Visionary",
                summary: "You see the horizon. Massive growth in valuation and standing, but your mind is never at rest.",
                yearlyDrift: CoreStatDelta(happiness: -1, smarts: 2),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["career": 12, "routine": 5],
                eventTagOutcomes: ["career": CoreStatDelta(smarts: 3)],
                eventTagFinanceOutcomes: [:]
            )
        case .burnoutProne:
            return TraitProfile(
                name: "Burnout Prone",
                summary: "High energy but low durability. You move fast until you stop completely.",
                yearlyDrift: CoreStatDelta(health: -2),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["routine": 8, "health": 10],
                eventTagOutcomes: ["routine": CoreStatDelta(health: -3)],
                eventTagFinanceOutcomes: [:]
            )
        case .workaholic:
            return TraitProfile(
                name: "Workaholic",
                summary: "Your career is your identity. High performance and income, but personal life is a ghost town.",
                yearlyDrift: CoreStatDelta(happiness: -2),
                yearlyFinanceDrift: FinanceDelta(cash: 400),
                eventTagWeights: ["career": 15, "social": -5],
                eventTagOutcomes: ["career": CoreStatDelta(smarts: 2)],
                eventTagFinanceOutcomes: ["career": FinanceDelta(cash: 1000)]
            )
        case .resilient:
            return TraitProfile(
                name: "Resilient",
                summary: "You can take a hit. Drastically reduced impacts from stress and setbacks.",
                yearlyDrift: CoreStatDelta(health: 1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["risk": 8, "health": 5],
                eventTagOutcomes: ["risk": CoreStatDelta(happiness: 1)],
                eventTagFinanceOutcomes: [:]
            )
        case .unreliable:
            return TraitProfile(
                name: "Unreliable",
                summary: "Commitment is hard. High risk of losing stability, but life is less stressful.",
                yearlyDrift: CoreStatDelta(happiness: 1),
                yearlyFinanceDrift: FinanceDelta(cash: -200),
                eventTagWeights: ["routine": -10, "social": 5],
                eventTagOutcomes: ["career": CoreStatDelta(smarts: -1)],
                eventTagFinanceOutcomes: [:]
            )
        case .ptsd:
            return TraitProfile(
                name: "PTSD",
                summary: "The trauma stays with you. Constant drain on happiness and mental wellness.",
                yearlyDrift: CoreStatDelta(happiness: -3, health: -1),
                yearlyFinanceDrift: FinanceDelta(),
                eventTagWeights: ["risk": 15, "health": 10],
                eventTagOutcomes: ["health": CoreStatDelta(happiness: -2)],
                eventTagFinanceOutcomes: [:]
            )
        }
    }
}

struct TraitSystem {
    func processMutations(player: inout Player, state: GameState) -> [DomainNote] {
        var notes: [DomainNote] = []
        let specialCareer = state.specialCareer
        let career = state.career
        let military = state.military
        let finance = state.finance
        
        // Shadow Operative -> Manipulative
        if specialCareer.track == .shadowOperative, specialCareer.yearsActive >= 8, player.traits.contains(.charismatic), !player.traits.contains(.manipulative) {
            mutate(from: .charismatic, to: .manipulative, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "Years of leverage and secrets have changed how you see people. Your charm has hardened into something more calculated.", tags: [.progress, .lifeEvent]))
        }
        
        // Trader -> Cold-Blooded
        if specialCareer.track == .trader, specialCareer.notoriety >= 60, player.traits.contains(.anxious), !player.traits.contains(.coldBlooded) {
            mutate(from: .anxious, to: .coldBlooded, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "The market's volatility no longer shakes you. You've traded your anxiety for a clinical, cold-blooded perspective on risk.", tags: [.progress, .lifeEvent]))
        }
        
        // Founder -> Visionary
        if specialCareer.track == .founder, specialCareer.audience >= 50, player.traits.contains(.disciplined), !player.traits.contains(.visionary) {
            mutate(from: .disciplined, to: .visionary, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "Building something from nothing has expanded your horizon. You no longer just follow a routine; you see the future.", tags: [.progress, .lifeEvent]))
        }
        
        // Career -> Workaholic
        if career.burnout >= 80, career.performance >= 80, !player.traits.contains(.workaholic) {
            mutate(to: .workaholic, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "You've crossed a line. Work isn't what you do; it's who you are. You are now a Workaholic.", tags: [.progress, .lifeEvent]))
        }
        
        // Combat -> PTSD or Resilient
        if military.combatTrauma >= 50, !player.traits.contains(.ptsd) {
            mutate(to: .ptsd, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "The sounds and sights of the front lines have left a permanent mark on your mind.", tags: [.progress, .lifeEvent, .health]))
        } else if military.yearsServed >= 8, military.discipline >= 85, !player.traits.contains(.resilient) {
            mutate(to: .resilient, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "Years of service and strict discipline have forged you into someone who doesn't break under pressure.", tags: [.progress, .lifeEvent]))
        }
        
        // AWOL/Debt -> Unreliable
        if (military.isAWOL || finance.debtDelinquencyRisk >= 80), !player.traits.contains(.unreliable) {
            mutate(to: .unreliable, on: &player)
            notes.append(DomainNote(title: "Trait Mutation", text: "A pattern of running from obligations has hardened. People no longer expect you to show up when it matters.", tags: [.progress, .lifeEvent]))
        }

        return notes
    }
    
    private func mutate(from: PersonalityTrait? = nil, to: PersonalityTrait, on player: inout Player) {
        if let from = from, let index = player.traits.firstIndex(of: from) {
            player.traits[index] = to
        } else if !player.traits.contains(to) {
            if player.traits.count >= 3 {
                player.traits.removeFirst()
            }
            player.traits.append(to)
        }
    }

    func generateInitialTraits(count: Int = 3, preferredTraits: [PersonalityTrait] = []) -> [PersonalityTrait] {
        var weightedPool: [PersonalityTrait] = PersonalityTrait.allCases
        for trait in preferredTraits {
            weightedPool.append(contentsOf: Array(repeating: trait, count: 3))
        }

        var chosen: [PersonalityTrait] = []
        while chosen.count < min(count, PersonalityTrait.allCases.count), !weightedPool.isEmpty {
            guard let pick = weightedPool.randomElement() else { break }
            if !chosen.contains(pick) {
                chosen.append(pick)
            }
            weightedPool.removeAll { $0 == pick }
        }

        return chosen
    }

    func ensureInitialTraits(on player: inout Player, preferredTraits: [PersonalityTrait] = []) -> [DomainNote] {
        guard player.traits.isEmpty else { return [] }
        player.traits = generateInitialTraits(preferredTraits: preferredTraits)
        let names = player.traits.map { TraitCatalog.profile(for: $0).name }.joined(separator: ", ")
        return [DomainNote(title: "Personality", text: "Your early personality starts taking shape: \(names).")]
    }

    func applyYearlyInfluence(to player: inout Player, finance: inout FinanceState) -> DomainYearResult {
        for trait in player.traits {
            let profile = TraitCatalog.profile(for: trait)
            apply(profile.yearlyDrift, to: &player)
            apply(profile.yearlyFinanceDrift, to: &finance)
        }

        player.clampStats()
        return DomainYearResult()
    }

    func adjustedWeight(for event: GameEvent, player: Player) -> Int {
        let modifier = player.traits.reduce(0) { partial, trait in
            let profile = TraitCatalog.profile(for: trait)
            let tagBonus = event.tags.reduce(0) { $0 + (profile.eventTagWeights[$1] ?? 0) }
            return partial + tagBonus
        }

        return max(1, event.weight + modifier)
    }

    func applyEventOutcomeInfluence(for event: GameEvent, player: inout Player, finance: inout FinanceState) {
        for trait in player.traits {
            let profile = TraitCatalog.profile(for: trait)
            for tag in event.tags {
                if let delta = profile.eventTagOutcomes[tag] {
                    apply(delta, to: &player)
                }
                if let financeDelta = profile.eventTagFinanceOutcomes[tag] {
                    apply(financeDelta, to: &finance)
                }
            }
        }

        player.clampStats()
    }

    private func apply(_ delta: CoreStatDelta, to player: inout Player) {
        player.happiness += delta.happiness
        player.smarts += delta.smarts
        player.looks += delta.looks
        player.health += delta.health
    }

    private func apply(_ delta: FinanceDelta, to finance: inout FinanceState) {
        finance.cashOnHand += delta.cash
    }
}

// MARK: - Career Domain

enum CareerStatus: String, Codable, CaseIterable {
    case student
    case partTime
    case fullTime
    case military
    case unemployed
}

enum CareerProfile: String, Codable, CaseIterable {
    case stableAdmin
    case physicalLabor
    case serviceFrontline
    case creativeFreelance
    case credentialedProfessional
    case militaryService
    case medicalProfessional
    case legalProfessional
    case techSpecialist
    case financialExpert

    var shortLabel: String {
        switch self {
        case .stableAdmin: return "Stable Admin"
        case .physicalLabor: return "Physical Labor"
        case .serviceFrontline: return "Service Frontline"
        case .creativeFreelance: return "Creative Freelance"
        case .credentialedProfessional: return "Credentialed Pro"
        case .militaryService: return "Military Service"
        case .medicalProfessional: return "Medical"
        case .legalProfessional: return "Legal"
        case .techSpecialist: return "Tech"
        case .financialExpert: return "Finance"
        }
    }
}

enum SpecializedCareerTrack: String, Codable, CaseIterable {
    case medical
    case law
    case tech
    case corporateFinance
}

enum MilitaryBranch: String, Codable, CaseIterable {
    case army
    case navy
    case airForce
    case marines
    case coastGuard
    case spaceForce

    var displayName: String {
        switch self {
        case .army: return "Army"
        case .navy: return "Navy"
        case .airForce: return "Air Force"
        case .marines: return "Marines"
        case .coastGuard: return "Coast Guard"
        case .spaceForce: return "Space Force"
        }
    }
}

enum MilitaryTrack: String, Codable, CaseIterable {
    case inactive
    case enlisted
    case officer
    case reserve
}

enum DeploymentStatus: String, Codable, CaseIterable {
    case home
    case stationed
    case deployed
    case activeCombat
}

enum MilitarySpecialty: String, Codable, CaseIterable {
    case combat
    case medical
    case aviation
    case intelligence
    case logistics
    
    var displayName: String {
        switch self {
        case .combat: return "Combat Operations"
        case .medical: return "Medical Services"
        case .aviation: return "Aviation"
        case .intelligence: return "Intelligence"
        case .logistics: return "Logistics"
        }
    }
}

struct MilitaryState: Codable, Equatable {
    var track: MilitaryTrack = .inactive
    var branch: MilitaryBranch? = nil
    var specialty: MilitarySpecialty? = nil
    var rank: String = "Private"
    var rankLevel: Int = 1
    var yearsServed: Int = 0
    var contractYearsRemaining: Int = 0
    var deploymentStatus: DeploymentStatus = .home
    var fitness: Int = 60
    var discipline: Int = 80
    var heat: Int = 0 // AWOL/Trouble
    var isAWOL: Bool = false
    var medals: [String] = []
    
    // V2 additions
    var isVeteran: Bool = false
    var hasGIBill: Bool = false
    var hasPension: Bool = false
    var combatTrauma: Int = 0 // PTSD tracking

    mutating func clamp() {
        fitness = fitness.clamped(to: 0...100)
        discipline = discipline.clamped(to: 0...100)
        heat = heat.clamped(to: 0...100)
        combatTrauma = combatTrauma.clamped(to: 0...100)
    }
}

enum CareerExperienceTag: String, Codable, CaseIterable, Hashable {
    case service
    case labor
    case admin
    case technical
    case healthcare
    case sales
    case creative
    case management
    case coaching

    var shortLabel: String {
        switch self {
        case .service: return "Service"
        case .labor: return "Labor"
        case .admin: return "Admin"
        case .technical: return "Technical"
        case .healthcare: return "Healthcare"
        case .sales: return "Sales"
        case .creative: return "Creative"
        case .management: return "Management"
        case .coaching: return "Coaching"
        }
    }
}

enum WorkIdentity: String, Codable, CaseIterable {
    case unsettled
    case climber
    case caretaker
    case drifter
    case hustler
    case burnedOutProvider

    var shortLabel: String {
        switch self {
        case .unsettled: return "Unsettled"
        case .climber: return "Climber"
        case .caretaker: return "Caretaker"
        case .drifter: return "Drifter"
        case .hustler: return "Hustler"
        case .burnedOutProvider: return "Burned-Out Provider"
        }
    }
}

enum CareerOpportunityDoor: String, Codable, CaseIterable {
    case internalPromotionTrack
    case lateralEscapeRoute
    case credentialPivot
    case contractWindfall
    case unionStability
    case burnoutExit

    var shortLabel: String {
        switch self {
        case .internalPromotionTrack: return "Promotion Track"
        case .lateralEscapeRoute: return "Escape Route"
        case .credentialPivot: return "Credential Pivot"
        case .contractWindfall: return "Contract Windfall"
        case .unionStability: return "Union Stability"
        case .burnoutExit: return "Burnout Exit"
        }
    }
}

/// D3: Regular (non-special) career archetypes for mechanical parity with deep paths.
/// Different curves for performance, burnout, security, income ramp, aging resilience.
/// Set by static instant actions; used in advanceYear + UI + handoff flavor.
enum CareerArchetype: String, Codable, CaseIterable {
    case corporateClimber
    case gigFreelancer
    case skilledTrades
    case publicService
    case techEngineer
    case salesNetworker

    var displayName: String {
        switch self {
        case .corporateClimber: return "Corporate Climber"
        case .gigFreelancer: return "Gig Freelancer"
        case .skilledTrades: return "Skilled Trades"
        case .publicService: return "Public Service"
        case .techEngineer: return "Tech Engineer"
        case .salesNetworker: return "Sales Networker"
        }
    }
}

enum SpecialCareerTrack: String, Codable, CaseIterable {
    case inactive
    case entertainment
    case movieActor
    case musicProducer
    case movieProducer
    case recordLabelOwner
    case coach
    case contentCreator   // C1: New dedicated track for modern attention economy creators
    case politics         // P1: New dedicated track for political life
    case crime
    case founder
    case athlete
    case shadowOperative
    case trader
    case ventureCapitalist
    case corporateRaider
    case military
}

/// Dedicated state for the Athlete special career path.
/// This is the foundation for a real sports pipeline.
struct AthleteState: Codable, Equatable {
    var sport: AthleteSport = .general
    var peakPerformance: Int = 65          // 0-100, peaks in mid-late 20s, declines with age/injury
    var durability: Int = 60               // Resistance to injury
    var sponsorshipTier: Int = 1           // 1-5, affects income and fame
    var fanLoyalty: Int = 40               // How much fans stick with you through slumps/scandals
    var injuryRisk: Int = 25               // Current season injury chance modifier
    
    // S3a: Potential / Talent ceiling — the "gift" that determines how high you can realistically climb
    var naturalPotential: Int = 72         // 40-95. Higher = better ceiling, slower age decline, bigger doping upside
    
    // S3a: Athlete-specific fame / icon status (separate from generic specialCareer.fame)
    var personalBrand: Int = 25            // 0-100. "Pro" < 45, "Star" 45-70, "Legend" > 70. Resists audience decay, boosts endorsements.
    
    // S3a: Real accolades and legacy markers
    var accolades: [String] = []           // e.g. "League MVP", "World Champion", "Hall of Fame Inductee"
    
    // S3a: Doping / edge state (high-risk, high-reward temptation)
    var enhancementUses: Int = 0           // How many times you've crossed the line
    var enhancementHeat: Int = 0           // Lingering detection risk (decays slowly)
    var lastEnhancementAge: Int = 0        // For narrative + detection window logic
    
    var careerHighlights: [String] = []    // Memorable moments for narrative and legacy
    var retirementOptionsUnlocked: Set<AthleteRetirementPath> = []
    
    mutating func clamp() {
        peakPerformance = peakPerformance.clamped(to: 10...100)
        durability = durability.clamped(to: 10...95)
        sponsorshipTier = sponsorshipTier.clamped(to: 1...5)
        fanLoyalty = fanLoyalty.clamped(to: 0...100)
        injuryRisk = injuryRisk.clamped(to: 5...80)
        naturalPotential = naturalPotential.clamped(to: 40...95)
        personalBrand = personalBrand.clamped(to: 0...100)
        enhancementHeat = enhancementHeat.clamped(to: 0...100)
        enhancementUses = max(0, enhancementUses)
    }
}

/// Dedicated state for the Founder / CEO / Entrepreneur special career path.
/// E1 foundation: real CEO mechanics with vision, execution, team, stage, control, and mental load.
struct FounderState: Codable, Equatable {
    var vision: Int = 55                   // Big picture, storytelling, fundraising
    var execution: Int = 55                // Operational delivery and discipline
    var teamHealth: Int = 60               // Morale, retention, culture strength
    var productStage: Int = 20             // 0-100: idea → mvp → early traction → scale → mature
    var control: Int = 85                  // Founder power / influence (synergizes with equityOwned)
    var founderMentalLoad: Int = 30        // Stress, burnout risk, decision fatigue
    var companyCulture: Int = 50           // Values, identity, "how we do things"
    var keyHires: Int = 10                 // Quality and number of critical hires made
    var competitiveMoat: Int = 15          // Differentiation and defensibility
    var personalLegend: Int = 20           // Founder-specific reputation (feeds FameProfile strongly)

    mutating func clamp() {
        vision = vision.clamped(to: 15...95)
        execution = execution.clamped(to: 15...95)
        teamHealth = teamHealth.clamped(to: 10...95)
        productStage = productStage.clamped(to: 0...100)
        control = control.clamped(to: 10...100)
        founderMentalLoad = founderMentalLoad.clamped(to: 5...95)
        companyCulture = companyCulture.clamped(to: 10...95)
        keyHires = keyHires.clamped(to: 0...100)
        competitiveMoat = competitiveMoat.clamped(to: 0...100)
        personalLegend = personalLegend.clamped(to: 0...100)
    }
}

struct MovieActorState: Codable, Equatable {
    var actingSkill: Int = 35
    var screenPresence: Int = 35
    var auditionNetwork: Int = 25
    var roleCredits: Int = 0
    var boxOfficeDraw: Int = 5
    var publicImage: Int = 45
    var typecastRisk: Int = 15
    var agentQuality: Int = 20
    var lastRolePayout: Int = 0

    init(
        actingSkill: Int = 35,
        screenPresence: Int = 35,
        auditionNetwork: Int = 25,
        roleCredits: Int = 0,
        boxOfficeDraw: Int = 5,
        publicImage: Int = 45,
        typecastRisk: Int = 15,
        agentQuality: Int = 20,
        lastRolePayout: Int = 0
    ) {
        self.actingSkill = actingSkill
        self.screenPresence = screenPresence
        self.auditionNetwork = auditionNetwork
        self.roleCredits = roleCredits
        self.boxOfficeDraw = boxOfficeDraw
        self.publicImage = publicImage
        self.typecastRisk = typecastRisk
        self.agentQuality = agentQuality
        self.lastRolePayout = lastRolePayout
        clamp()
    }

    mutating func clamp() {
        actingSkill = actingSkill.clamped(to: 0...100)
        screenPresence = screenPresence.clamped(to: 0...100)
        auditionNetwork = auditionNetwork.clamped(to: 0...100)
        roleCredits = max(0, roleCredits)
        boxOfficeDraw = boxOfficeDraw.clamped(to: 0...100)
        publicImage = publicImage.clamped(to: 0...100)
        typecastRisk = typecastRisk.clamped(to: 0...100)
        agentQuality = agentQuality.clamped(to: 0...100)
        lastRolePayout = max(0, lastRolePayout)
    }
}

struct MovieProducerState: Codable, Equatable {
    var slateCount: Int = 0
    var developmentQuality: Int = 30
    var castRelationships: Int = 30
    var budgetControl: Int = 35
    var distributionLeverage: Int = 20
    var productionChaos: Int = 25
    var studioTrust: Int = 35
    var backendCatalog: Int = 5
    var prestige: Int = 15
    var lastFilmPayout: Int = 0

    init(
        slateCount: Int = 0,
        developmentQuality: Int = 30,
        castRelationships: Int = 30,
        budgetControl: Int = 35,
        distributionLeverage: Int = 20,
        productionChaos: Int = 25,
        studioTrust: Int = 35,
        backendCatalog: Int = 5,
        prestige: Int = 15,
        lastFilmPayout: Int = 0
    ) {
        self.slateCount = slateCount
        self.developmentQuality = developmentQuality
        self.castRelationships = castRelationships
        self.budgetControl = budgetControl
        self.distributionLeverage = distributionLeverage
        self.productionChaos = productionChaos
        self.studioTrust = studioTrust
        self.backendCatalog = backendCatalog
        self.prestige = prestige
        self.lastFilmPayout = lastFilmPayout
        clamp()
    }

    mutating func clamp() {
        slateCount = slateCount.clamped(to: 0...12)
        developmentQuality = developmentQuality.clamped(to: 0...100)
        castRelationships = castRelationships.clamped(to: 0...100)
        budgetControl = budgetControl.clamped(to: 0...100)
        distributionLeverage = distributionLeverage.clamped(to: 0...100)
        productionChaos = productionChaos.clamped(to: 0...100)
        studioTrust = studioTrust.clamped(to: 0...100)
        backendCatalog = backendCatalog.clamped(to: 0...100)
        prestige = prestige.clamped(to: 0...100)
        lastFilmPayout = max(0, lastFilmPayout)
    }
}

struct CoachingState: Codable, Equatable {
    var programLevel: Int = 1
    var rosterTalent: Int = 42
    var playerDevelopment: Int = 40
    var schemeFit: Int = 38
    var staffQuality: Int = 35
    var lockerRoom: Int = 50
    var recruitingReach: Int = 35
    var boosterPressure: Int = 25
    var programPrestige: Int = 20
    var seasonWins: Int = 0
    var seasonLosses: Int = 0
    var contractValue: Int = 0

    init(
        programLevel: Int = 1,
        rosterTalent: Int = 42,
        playerDevelopment: Int = 40,
        schemeFit: Int = 38,
        staffQuality: Int = 35,
        lockerRoom: Int = 50,
        recruitingReach: Int = 35,
        boosterPressure: Int = 25,
        programPrestige: Int = 20,
        seasonWins: Int = 0,
        seasonLosses: Int = 0,
        contractValue: Int = 0
    ) {
        self.programLevel = programLevel
        self.rosterTalent = rosterTalent
        self.playerDevelopment = playerDevelopment
        self.schemeFit = schemeFit
        self.staffQuality = staffQuality
        self.lockerRoom = lockerRoom
        self.recruitingReach = recruitingReach
        self.boosterPressure = boosterPressure
        self.programPrestige = programPrestige
        self.seasonWins = seasonWins
        self.seasonLosses = seasonLosses
        self.contractValue = contractValue
        clamp()
    }

    mutating func clamp() {
        programLevel = programLevel.clamped(to: 1...4)
        rosterTalent = rosterTalent.clamped(to: 0...100)
        playerDevelopment = playerDevelopment.clamped(to: 0...100)
        schemeFit = schemeFit.clamped(to: 0...100)
        staffQuality = staffQuality.clamped(to: 0...100)
        lockerRoom = lockerRoom.clamped(to: 0...100)
        recruitingReach = recruitingReach.clamped(to: 0...100)
        boosterPressure = boosterPressure.clamped(to: 0...100)
        programPrestige = programPrestige.clamped(to: 0...100)
        seasonWins = seasonWins.clamped(to: 0...16)
        seasonLosses = seasonLosses.clamped(to: 0...16)
        contractValue = max(0, contractValue)
    }
}

enum ArtistPayoutPolicy: String, Codable, CaseIterable {
    case exploitative
    case standard
    case artistFriendly
}

struct LabelArtist: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var name: String = "New Artist"
    var talent: Int = 50
    var popularity: Int = 20
    var morale: Int = 55
    var contractFairness: Int = 50
    var catalogCount: Int = 0
    var tourReadiness: Int = 30
    var yearlyEarnings: Int = 0

    init(
        id: String = UUID().uuidString,
        name: String = "New Artist",
        talent: Int = 50,
        popularity: Int = 20,
        morale: Int = 55,
        contractFairness: Int = 50,
        catalogCount: Int = 0,
        tourReadiness: Int = 30,
        yearlyEarnings: Int = 0
    ) {
        self.id = id
        self.name = name
        self.talent = talent
        self.popularity = popularity
        self.morale = morale
        self.contractFairness = contractFairness
        self.catalogCount = catalogCount
        self.tourReadiness = tourReadiness
        self.yearlyEarnings = yearlyEarnings
        clamp()
    }

    mutating func clamp() {
        talent = talent.clamped(to: 10...100)
        popularity = popularity.clamped(to: 0...100)
        morale = morale.clamped(to: 0...100)
        contractFairness = contractFairness.clamped(to: 0...100)
        catalogCount = max(0, catalogCount)
        tourReadiness = tourReadiness.clamped(to: 0...100)
        yearlyEarnings = max(0, yearlyEarnings)
    }
}

struct RecordLabelState: Codable, Equatable {
    var roster: [LabelArtist] = []
    var catalogStrength: Int = 10
    var tourMachine: Int = 10
    var artistTrust: Int = 55
    var cashflowPressure: Int = 25
    var industryHeat: Int = 10
    var labelPrestige: Int = 15
    var artistPayoutPolicy: ArtistPayoutPolicy = .standard

    init(
        roster: [LabelArtist] = [],
        catalogStrength: Int = 10,
        tourMachine: Int = 10,
        artistTrust: Int = 55,
        cashflowPressure: Int = 25,
        industryHeat: Int = 10,
        labelPrestige: Int = 15,
        artistPayoutPolicy: ArtistPayoutPolicy = .standard
    ) {
        self.roster = roster
        self.catalogStrength = catalogStrength
        self.tourMachine = tourMachine
        self.artistTrust = artistTrust
        self.cashflowPressure = cashflowPressure
        self.industryHeat = industryHeat
        self.labelPrestige = labelPrestige
        self.artistPayoutPolicy = artistPayoutPolicy
        clamp()
    }

    mutating func clamp() {
        roster = roster.map { artist in
            var copy = artist
            copy.clamp()
            return copy
        }
        if roster.count > 8 {
            roster = Array(roster.prefix(8))
        }
        catalogStrength = catalogStrength.clamped(to: 0...100)
        tourMachine = tourMachine.clamped(to: 0...100)
        artistTrust = artistTrust.clamped(to: 0...100)
        cashflowPressure = cashflowPressure.clamped(to: 0...100)
        industryHeat = industryHeat.clamped(to: 0...100)
        labelPrestige = labelPrestige.clamped(to: 0...100)
    }
}

struct MusicProducerState: Codable, Equatable {
    var credits: Int = 0
    var sonicSignature: Int = 35
    var studioQuality: Int = 30
    var network: Int = 35
    var demand: Int = 20
    var royaltyCatalog: Int = 5
    var creditDisputes: Int = 10
    var lastPlacementValue: Int = 0

    init(
        credits: Int = 0,
        sonicSignature: Int = 35,
        studioQuality: Int = 30,
        network: Int = 35,
        demand: Int = 20,
        royaltyCatalog: Int = 5,
        creditDisputes: Int = 10,
        lastPlacementValue: Int = 0
    ) {
        self.credits = credits
        self.sonicSignature = sonicSignature
        self.studioQuality = studioQuality
        self.network = network
        self.demand = demand
        self.royaltyCatalog = royaltyCatalog
        self.creditDisputes = creditDisputes
        self.lastPlacementValue = lastPlacementValue
        clamp()
    }

    mutating func clamp() {
        credits = max(0, credits)
        sonicSignature = sonicSignature.clamped(to: 0...100)
        studioQuality = studioQuality.clamped(to: 0...100)
        network = network.clamped(to: 0...100)
        demand = demand.clamped(to: 0...100)
        royaltyCatalog = royaltyCatalog.clamped(to: 0...100)
        creditDisputes = creditDisputes.clamped(to: 0...100)
        lastPlacementValue = max(0, lastPlacementValue)
    }
}

// C1: Dedicated state for the Content Creator / Influencer special career path.
enum CreatorPlatform: String, Codable, CaseIterable {
    case youtube
    case tiktokShorts
    case instagram
    case twitch
    case podcast
    case newsletter
    case generalSocial
}

struct CreatorState: Codable, Equatable {
    var platform: CreatorPlatform = .generalSocial
    var audience: Int = 25              // Followers / subscribers (core "valuation" equivalent)
    var algorithmFavor: Int = 50        // 0-100, swings with consistency, scandals, trends
    var personalBrand: Int = 40         // Authenticity vs sell-out tension (feeds FameProfile strongly)
    var contentQuality: Int = 50
    var consistency: Int = 55
    var burnout: Int = 20
    var cancellationRisk: Int = 15      // "Heat" equivalent for creators
    var brandDealValue: Int = 10        // Current sponsorship strength

    mutating func clamp() {
        audience = audience.clamped(to: 0...100)
        algorithmFavor = algorithmFavor.clamped(to: 0...100)
        personalBrand = personalBrand.clamped(to: 0...100)
        contentQuality = contentQuality.clamped(to: 10...95)
        consistency = consistency.clamped(to: 5...95)
        burnout = burnout.clamped(to: 0...95)
        cancellationRisk = cancellationRisk.clamped(to: 0...100)
        brandDealValue = brandDealValue.clamped(to: 0...100)
    }
}

// P1: Dedicated state for the Politics special career path.
struct PoliticsState: Codable, Equatable {
    var approvalRating: Int = 45           // Core "audience" equivalent — how much the public likes you
    var scandalHeat: Int = 10              // Current risk of damaging revelations (like heat/cancellation)
    var policyLegacy: Int = 20             // Long-term impact of your actual work
    var donorBase: Int = 25                // Financial power base
    var ethics: Int = 70                   // Personal integrity (affects options and reputation)
    var voterBase: Int = 30                // Strength of core supporters
    var charisma: Int = 50                 // Natural political talent
    var burnout: Int = 15                  // The grind of constant performance and scrutiny

    mutating func clamp() {
        approvalRating = approvalRating.clamped(to: 0...100)
        scandalHeat = scandalHeat.clamped(to: 0...100)
        policyLegacy = policyLegacy.clamped(to: 0...100)
        donorBase = donorBase.clamped(to: 0...100)
        ethics = ethics.clamped(to: 10...100)
        voterBase = voterBase.clamped(to: 0...100)
        charisma = charisma.clamped(to: 15...95)
        burnout = burnout.clamped(to: 0...95)
    }
}

// CE1: Dedicated state for the Crime & Enterprise paths (shadow operative, crime, trader, VC, raider)
enum CriminalEnterpriseSubtype: String, Codable, CaseIterable {
    case shadowOperative
    case streetCrime
    case grayMarketTrader
    case ventureCapitalist
    case corporateRaider
}

struct CriminalEnterpriseState: Codable, Equatable {
    var subtype: CriminalEnterpriseSubtype = .streetCrime
    var heat: Int = 20                    // Law enforcement / external scrutiny
    var notoriety: Int = 25               // Reputation in the underworld / gray economy
    var loyalty: Int = 50                 // Crew / key allies loyalty and trust
    var operationalSecurity: Int = 55     // How well you cover your tracks
    var networkStrength: Int = 30         // Quality and reach of connections
    var cleanMoneyRatio: Int = 25         // Percentage of wealth that appears legitimate (0-100)
    var riskTolerance: Int = 50           // Willingness to take bigger, riskier moves
    var crewSize: Int = 4
    var lastMajorScoreAge: Int = 0        // For narrative and cooldown logic

    mutating func clamp() {
        heat = heat.clamped(to: 0...100)
        notoriety = notoriety.clamped(to: 0...100)
        loyalty = loyalty.clamped(to: 0...100)
        operationalSecurity = operationalSecurity.clamped(to: 0...100)
        networkStrength = networkStrength.clamped(to: 0...100)
        cleanMoneyRatio = cleanMoneyRatio.clamped(to: 0...100)
        riskTolerance = riskTolerance.clamped(to: 10...90)
        crewSize = crewSize.clamped(to: 1...25)
    }
}

enum AthleteSport: String, Codable, CaseIterable {
    case general
    case basketball
    case football
    case soccer
    case tennis
    case olympic
    case combatSports
}

enum AthleteRetirementPath: String, Codable, CaseIterable {
    case coaching
    case business
    case media
    case philanthropy
    case politics
}

// MARK: - Fame Unification (Fame Web F1 foundation)

/// Unified fame / recognition profile. Every avenue that can make you "known" (athlete, entertainment,
/// crime, military, wealth, social, career peaks, events) should eventually feed this.
/// This replaces the previous total fragmentation between specialCareer.fame, athlete.personalBrand,
/// relationships.publicReputation, crime.notoriety, military medals, etc.
struct FameProfile: Codable, Equatable {
    /// Positive cultural recognition / household name status (0-100).
    /// "Pro athlete" or "local founder" sits low. "World champion / cultural icon" sits high.
    var culturalFame: Int = 0
    
    /// Dark / controversial recognition (fear, infamy, "that guy from the scandal").
    /// High notoriety creates different opportunities and much harsher downsides than culturalFame.
    var notoriety: Int = 0
    
    /// What the world associates you with. Merged from athlete accolades, career highlights,
    /// relationship knownForTags, military medals, viral moments, etc.
    var knownFor: [String] = []
    
    /// Age at which your fame peaked (for legacy narratives and "has-been" texture).
    var peakFameAge: Int? = nil
    
    /// Last age a major scandal or exposure hit (affects decay rate and "tainted" flavor).
    var lastScandalAge: Int? = nil
    
    mutating func clamp() {
        culturalFame = culturalFame.clamped(to: 0...100)
        notoriety = notoriety.clamped(to: 0...100)
        knownFor = Array(NSOrderedSet(array: knownFor.compactMap { $0.isEmpty ? nil : $0 }).array as? [String] ?? []).prefix(6).map { $0 }
        if culturalFame == 0 && notoriety == 0 {
            peakFameAge = nil
        }
    }
    
    /// Combined "how known are you?" signal used for many cross-domain rolls.
    var recognition: Int {
        max(culturalFame, notoriety)
    }
    
    var isPublicFigure: Bool { recognition >= 45 }
    var isHouseholdName: Bool { culturalFame >= 70 }
    var isInfamous: Bool { notoriety >= 65 }
}

struct CareerState: Codable, Equatable {
    var status: CareerStatus = .student
    var profile: CareerProfile = .stableAdmin
    var specializedTrack: SpecializedCareerTrack? = nil
    /// D3: Regular career archetype set by static always-instant actions (corporateClimb etc).
    /// Drives differentiated curves (perf/burnout/security/income/aging) + flavor + handoff.
    /// Nil for special-track lives (they use their deep state instead).
    var regularArchetype: CareerArchetype? = nil
    var professionalRank: String = "Entry Level"
    var workIdentity: WorkIdentity = .unsettled
    var roleID: String? = nil
    var level: Int = 0
    var annualIncome: Int = 0
    var performance: Int = 52
    var yearsWorked: Int = 0
    var unemployedYears: Int = 0
    var burnout: Int = 18
    var schedulePressure: Int = 22
    var relationshipSpillover: Int = 16
    var jobSecurity: Int = 52
    var managerFriction: Int = 34
    var scheduleControl: Int = 50
    var retrainingProgress: Int = 0
    var retrainingTargetProfile: CareerProfile? = nil
    var activeOpportunityDoor: CareerOpportunityDoor? = nil
    var opportunityDoorYearsRemaining: Int = 0
    var ambitionYears: Int = 0
    var protectiveYears: Int = 0
    var hustleYears: Int = 0
    var driftYears: Int = 0
    var careerExperience: [CareerExperienceTag: Int] = [:]

    private enum CodingKeys: String, CodingKey {
        case status
        case profile
        case specializedTrack
        case regularArchetype  // D3
        case professionalRank
        case workIdentity
        case roleID
        case level
        case annualIncome
        case performance
        case yearsWorked
        case unemployedYears
        case burnout
        case schedulePressure
        case relationshipSpillover
        case jobSecurity
        case managerFriction
        case scheduleControl
        case retrainingProgress
        case retrainingTargetProfile
        case activeOpportunityDoor
        case opportunityDoorYearsRemaining
        case ambitionYears
        case protectiveYears
        case hustleYears
        case driftYears
        case careerExperience
    }

    init() {}

    init(
        status: CareerStatus = .student,
        profile: CareerProfile = .stableAdmin,
        workIdentity: WorkIdentity = .unsettled,
        roleID: String? = nil,
        level: Int = 0,
        annualIncome: Int = 0,
        performance: Int = 52,
        yearsWorked: Int = 0,
        unemployedYears: Int = 0,
        burnout: Int = 18,
        schedulePressure: Int = 22,
        relationshipSpillover: Int = 16,
        jobSecurity: Int = 52,
        managerFriction: Int = 34,
        scheduleControl: Int = 50,
        retrainingProgress: Int = 0,
        retrainingTargetProfile: CareerProfile? = nil,
        activeOpportunityDoor: CareerOpportunityDoor? = nil,
        opportunityDoorYearsRemaining: Int = 0,
        ambitionYears: Int = 0,
        protectiveYears: Int = 0,
        hustleYears: Int = 0,
        driftYears: Int = 0,
        careerExperience: [CareerExperienceTag: Int] = [:],
        regularArchetype: CareerArchetype? = nil  // D3
    ) {
        self.status = status
        self.profile = profile
        self.workIdentity = workIdentity
        self.roleID = roleID
        self.level = level
        self.annualIncome = annualIncome
        self.performance = performance
        self.yearsWorked = yearsWorked
        self.unemployedYears = unemployedYears
        self.burnout = burnout
        self.schedulePressure = schedulePressure
        self.relationshipSpillover = relationshipSpillover
        self.jobSecurity = jobSecurity
        self.managerFriction = managerFriction
        self.scheduleControl = scheduleControl
        self.retrainingProgress = retrainingProgress
        self.retrainingTargetProfile = retrainingTargetProfile
        self.activeOpportunityDoor = activeOpportunityDoor
        self.opportunityDoorYearsRemaining = opportunityDoorYearsRemaining
        self.ambitionYears = ambitionYears
        self.protectiveYears = protectiveYears
        self.hustleYears = hustleYears
        self.driftYears = driftYears
        self.careerExperience = careerExperience
        self.regularArchetype = regularArchetype
        clamp()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(CareerStatus.self, forKey: .status) ?? .student
        profile = try container.decodeIfPresent(CareerProfile.self, forKey: .profile) ?? .stableAdmin
        specializedTrack = try container.decodeIfPresent(SpecializedCareerTrack.self, forKey: .specializedTrack)
        regularArchetype = try container.decodeIfPresent(CareerArchetype.self, forKey: .regularArchetype)
        professionalRank = try container.decodeIfPresent(String.self, forKey: .professionalRank) ?? "Entry Level"
        workIdentity = try container.decodeIfPresent(WorkIdentity.self, forKey: .workIdentity) ?? .unsettled
        roleID = try container.decodeIfPresent(String.self, forKey: .roleID)
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 0
        annualIncome = try container.decodeIfPresent(Int.self, forKey: .annualIncome) ?? 0
        performance = try container.decodeIfPresent(Int.self, forKey: .performance) ?? 52
        yearsWorked = try container.decodeIfPresent(Int.self, forKey: .yearsWorked) ?? 0
        unemployedYears = try container.decodeIfPresent(Int.self, forKey: .unemployedYears) ?? 0
        burnout = try container.decodeIfPresent(Int.self, forKey: .burnout) ?? 18
        schedulePressure = try container.decodeIfPresent(Int.self, forKey: .schedulePressure) ?? 22
        relationshipSpillover = try container.decodeIfPresent(Int.self, forKey: .relationshipSpillover) ?? 16
        jobSecurity = try container.decodeIfPresent(Int.self, forKey: .jobSecurity) ?? 52
        managerFriction = try container.decodeIfPresent(Int.self, forKey: .managerFriction) ?? 34
        scheduleControl = try container.decodeIfPresent(Int.self, forKey: .scheduleControl) ?? 50
        retrainingProgress = try container.decodeIfPresent(Int.self, forKey: .retrainingProgress) ?? 0
        retrainingTargetProfile = try container.decodeIfPresent(CareerProfile.self, forKey: .retrainingTargetProfile)
        activeOpportunityDoor = try container.decodeIfPresent(CareerOpportunityDoor.self, forKey: .activeOpportunityDoor)
        opportunityDoorYearsRemaining = try container.decodeIfPresent(Int.self, forKey: .opportunityDoorYearsRemaining) ?? 0
        ambitionYears = try container.decodeIfPresent(Int.self, forKey: .ambitionYears) ?? 0
        protectiveYears = try container.decodeIfPresent(Int.self, forKey: .protectiveYears) ?? 0
        hustleYears = try container.decodeIfPresent(Int.self, forKey: .hustleYears) ?? 0
        driftYears = try container.decodeIfPresent(Int.self, forKey: .driftYears) ?? 0
        careerExperience = try container.decodeIfPresent([CareerExperienceTag: Int].self, forKey: .careerExperience) ?? [:]
        clamp()
    }

    mutating func clamp() {
        level = max(0, level)
        annualIncome = max(0, annualIncome)
        performance = performance.clamped(to: 0...100)
        yearsWorked = max(0, yearsWorked)
        unemployedYears = max(0, unemployedYears)
        burnout = burnout.clamped(to: 0...100)
        schedulePressure = schedulePressure.clamped(to: 0...100)
        relationshipSpillover = relationshipSpillover.clamped(to: 0...100)
        jobSecurity = jobSecurity.clamped(to: 0...100)
        managerFriction = managerFriction.clamped(to: 0...100)
        scheduleControl = scheduleControl.clamped(to: 0...100)
        retrainingProgress = retrainingProgress.clamped(to: 0...3)
        opportunityDoorYearsRemaining = opportunityDoorYearsRemaining.clamped(to: 0...2)
        if opportunityDoorYearsRemaining == 0 {
            activeOpportunityDoor = nil
        }
        ambitionYears = max(0, ambitionYears)
        protectiveYears = max(0, protectiveYears)
        hustleYears = max(0, hustleYears)
        driftYears = max(0, driftYears)
        careerExperience = careerExperience.mapValues { max(0, $0) }.filter { $0.value > 0 }
    }

    func experience(for tag: CareerExperienceTag) -> Int {
        careerExperience[tag] ?? 0
    }

    var strongestExperienceTag: CareerExperienceTag? {
        careerExperience.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.rawValue < rhs.key.rawValue
            }
            return lhs.value < rhs.value
        }?.key
    }
}

struct SpecialCareerState: Codable, Equatable {
    var track: SpecialCareerTrack = .inactive
    var sector: BusinessSector = .general
    var advisors: [BusinessAdvisor] = []
    var tier: Int = 0
    var fame: Int = 0
    var audience: Int = 0
    var heat: Int = 0
    var notoriety: Int = 0
    var burnout: Int = 0
    var yearsActive: Int = 0
    var lastPayout: Int = 0
    
    // Entrepreneur/VC/Raider Extension
    var equityOwned: Double = 1.0 // 0.0 to 1.0
    var boardPressure: Int = 0 // 0-100, if 100, you are ousted
    var capitalUnderManagement: Int = 0 // For VC/Raider

    // Phase S1: Athlete dedicated state (only used when track == .athlete)
    var athlete: AthleteState = AthleteState()

    // E1: Dedicated Founder / CEO state (only used when track == .founder or related)
    var founder: FounderState = FounderState()

    // Film business: Dedicated Movie Actor state
    var movieActor: MovieActorState = MovieActorState()

    // Music business: Dedicated Music Producer state
    var musicProducer: MusicProducerState = MusicProducerState()

    // Film business: Dedicated Movie Producer state
    var movieProducer: MovieProducerState = MovieProducerState()

    // Music business: Dedicated Record Label Owner state
    var recordLabel: RecordLabelState = RecordLabelState()

    // Sports management: Dedicated Program Coach state
    var coaching: CoachingState = CoachingState()

    // C1: Dedicated Content Creator / Influencer state
    var creator: CreatorState = CreatorState()

    // P1: Dedicated Politics state
    var politics: PoliticsState = PoliticsState()

    // CE1: Dedicated Criminal Enterprise state (shadow operative, crime, trader, VC, raider)
    var enterprise: CriminalEnterpriseState = CriminalEnterpriseState()

    private enum CodingKeys: String, CodingKey {
        case track
        case tier
        case fame
        case audience
        case heat
        case notoriety
        case burnout
        case yearsActive
        case lastPayout
        case founder     // E1
        case movieActor
        case musicProducer
        case movieProducer
        case recordLabel
        case coaching
        case creator     // C1
        case politics    // P1
        case enterprise  // CE1
    }

    init() {}

    init(
        track: SpecialCareerTrack = .inactive,
        tier: Int = 0,
        fame: Int = 0,
        audience: Int = 0,
        heat: Int = 0,
        notoriety: Int = 0,
        burnout: Int = 0,
        yearsActive: Int = 0,
        lastPayout: Int = 0
    ) {
        self.track = track
        self.tier = tier
        self.fame = fame
        self.audience = audience
        self.heat = heat
        self.notoriety = notoriety
        self.burnout = burnout
        self.yearsActive = yearsActive
        self.lastPayout = lastPayout
        clamp()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        track = try container.decodeIfPresent(SpecialCareerTrack.self, forKey: .track) ?? .inactive
        tier = try container.decodeIfPresent(Int.self, forKey: .tier) ?? 0
        fame = try container.decodeIfPresent(Int.self, forKey: .fame) ?? 0
        audience = try container.decodeIfPresent(Int.self, forKey: .audience) ?? 0
        heat = try container.decodeIfPresent(Int.self, forKey: .heat) ?? 0
        notoriety = try container.decodeIfPresent(Int.self, forKey: .notoriety) ?? 0
        burnout = try container.decodeIfPresent(Int.self, forKey: .burnout) ?? 0
        yearsActive = try container.decodeIfPresent(Int.self, forKey: .yearsActive) ?? 0
        lastPayout = try container.decodeIfPresent(Int.self, forKey: .lastPayout) ?? 0
        founder = try container.decodeIfPresent(FounderState.self, forKey: .founder) ?? FounderState()
        movieActor = try container.decodeIfPresent(MovieActorState.self, forKey: .movieActor) ?? MovieActorState()
        musicProducer = try container.decodeIfPresent(MusicProducerState.self, forKey: .musicProducer) ?? MusicProducerState()
        movieProducer = try container.decodeIfPresent(MovieProducerState.self, forKey: .movieProducer) ?? MovieProducerState()
        recordLabel = try container.decodeIfPresent(RecordLabelState.self, forKey: .recordLabel) ?? RecordLabelState()
        coaching = try container.decodeIfPresent(CoachingState.self, forKey: .coaching) ?? CoachingState()
        creator = try container.decodeIfPresent(CreatorState.self, forKey: .creator) ?? CreatorState()
        politics = try container.decodeIfPresent(PoliticsState.self, forKey: .politics) ?? PoliticsState()
        enterprise = try container.decodeIfPresent(CriminalEnterpriseState.self, forKey: .enterprise) ?? CriminalEnterpriseState()
        clamp()
    }

    mutating func clamp() {
        tier = tier.clamped(to: 0...3)
        fame = fame.clamped(to: 0...100)
        audience = audience.clamped(to: 0...100)
        heat = heat.clamped(to: 0...100)
        notoriety = notoriety.clamped(to: 0...100)
        burnout = burnout.clamped(to: 0...100)
        yearsActive = max(0, yearsActive)
        lastPayout = max(0, lastPayout)
        founder.clamp()
        movieActor.clamp()
        musicProducer.clamp()
        movieProducer.clamp()
        recordLabel.clamp()
        coaching.clamp()
        creator.clamp()
        politics.clamp()
        enterprise.clamp()
    }
}

enum CrimeStatus: String, Codable, CaseIterable {
    case inactive
    case active
    case layingLow
}

struct CrimeState: Codable, Equatable {
    var status: CrimeStatus = .inactive
    var roleTier: Int = 0
    var heat: Int = 0
    var notoriety: Int = 0
    var burnout: Int = 0
    var crewID: String? = nil
    var loyalty: Int = 0
    var territoryPressure: Int = 0
    var yearsActive: Int = 0
    var lastPayout: Int = 0

    private enum CodingKeys: String, CodingKey {
        case status
        case roleTier
        case heat
        case notoriety
        case burnout
        case crewID
        case loyalty
        case territoryPressure
        case yearsActive
        case lastPayout
    }

    init() {}

    init(
        status: CrimeStatus = .inactive,
        roleTier: Int = 0,
        heat: Int = 0,
        notoriety: Int = 0,
        burnout: Int = 0,
        crewID: String? = nil,
        loyalty: Int = 0,
        territoryPressure: Int = 0,
        yearsActive: Int = 0,
        lastPayout: Int = 0
    ) {
        self.status = status
        self.roleTier = roleTier
        self.heat = heat
        self.notoriety = notoriety
        self.burnout = burnout
        self.crewID = crewID
        self.loyalty = loyalty
        self.territoryPressure = territoryPressure
        self.yearsActive = yearsActive
        self.lastPayout = lastPayout
        clamp()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(CrimeStatus.self, forKey: .status) ?? .inactive
        roleTier = try container.decodeIfPresent(Int.self, forKey: .roleTier) ?? 0
        heat = try container.decodeIfPresent(Int.self, forKey: .heat) ?? 0
        notoriety = try container.decodeIfPresent(Int.self, forKey: .notoriety) ?? 0
        burnout = try container.decodeIfPresent(Int.self, forKey: .burnout) ?? 0
        crewID = try container.decodeIfPresent(String.self, forKey: .crewID)
        loyalty = try container.decodeIfPresent(Int.self, forKey: .loyalty) ?? 0
        territoryPressure = try container.decodeIfPresent(Int.self, forKey: .territoryPressure) ?? 0
        yearsActive = try container.decodeIfPresent(Int.self, forKey: .yearsActive) ?? 0
        lastPayout = try container.decodeIfPresent(Int.self, forKey: .lastPayout) ?? 0
        clamp()
    }

    mutating func clamp() {
        roleTier = roleTier.clamped(to: 0...3)
        heat = heat.clamped(to: 0...100)
        notoriety = notoriety.clamped(to: 0...100)
        burnout = burnout.clamped(to: 0...100)
        loyalty = loyalty.clamped(to: 0...100)
        territoryPressure = territoryPressure.clamped(to: 0...100)
        yearsActive = max(0, yearsActive)
        lastPayout = max(0, lastPayout)
        if status == .inactive {
            roleTier = 0
            heat = 0
            notoriety = 0
            crewID = nil
            loyalty = 0
            territoryPressure = 0
            yearsActive = 0
            lastPayout = 0
            burnout = min(35, burnout)
        }
    }

    static func migratingFromLegacySpecialCareer(_ specialCareer: SpecialCareerState) -> CrimeState {
        CrimeState(
            status: .active,
            roleTier: specialCareer.tier,
            heat: 40,
            notoriety: 35,
            burnout: specialCareer.burnout,
            crewID: nil,
            loyalty: 30,
            territoryPressure: 20,
            yearsActive: specialCareer.yearsActive,
            lastPayout: specialCareer.lastPayout
        )
    }
}

struct CareerRoleDefinition: Equatable {
    var id: String
    var title: String
    var profile: CareerProfile
    var status: CareerStatus
    var level: Int
    var annualIncome: Int
    var minAge: Int
    var nextRoleID: String?
    var requiredCredentials: [String] = []
    var minimumYearsWorked: Int = 0
    var primaryExperienceTag: CareerExperienceTag = .admin
    var secondaryExperienceTags: [CareerExperienceTag] = []
    var bridgeTags: [CareerExperienceTag] = []
    var isManagementRole: Bool = false
}

// MARK: - Finance Domain

enum InvestmentRiskProfile: String, Codable, CaseIterable {
    case defensive
    case conservative
    case balanced
    case speculative

    var displayLabel: String {
        switch self {
        case .defensive: return "Defensive"
        case .conservative: return "Conservative"
        case .balanced: return "Balanced"
        case .speculative: return "Speculative"
        }
    }
}

enum DebtPressureBand: String, Codable, CaseIterable {
    case clear
    case manageable
    case heavy
    case crushing

    var displayLabel: String {
        switch self {
        case .clear: return "Clear"
        case .manageable: return "Manageable"
        case .heavy: return "Heavy"
        case .crushing: return "Crushing"
        }
    }
}

enum DebtPaymentStrategy: String, Codable, CaseIterable {
    case standard
    case aggressive
    case minimumOnly
    case deferStudentLoans
}

enum MarketPhase: String, Codable, CaseIterable {
    case stable
    case boom
    case correction
    case recession
}

struct EconomyState: Codable, Equatable {
    var marketCycle: MarketPhase = .stable
    var inflationRate: Double = 0.02
    var techSectorMultiplier: Double = 1.0
    var energySectorMultiplier: Double = 1.0
    var broadMarketMultiplier: Double = 1.0
}

struct StockHolding: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var tickerOrSector: String // e.g. "TECH", "ENERGY", "INDEX"
    var sharesOrValue: Double
    var entryBasis: Double
    var volatilityFactor: Double // 0.5-2.0 based on sector + current economy

    var totalValue: Int { Int(sharesOrValue) }
    var totalProfit: Int { Int(sharesOrValue - entryBasis) }
}

struct CryptoAsset: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let symbol: String
    var coins: Double
    var averageCost: Double
    var currentPrice: Double
    
    var totalValue: Int { Int(coins * currentPrice) }
}

struct RentalProperty: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var propertyValue: Int
    var mortgagePrincipal: Int
    var monthlyRent: Int
    var monthlyMaintenance: Int
    
    var equity: Int { max(0, propertyValue - mortgagePrincipal) }
    var annualNetIncome: Int { (monthlyRent - (mortgagePrincipal > 0 ? (monthlyRent/2) : 0) - monthlyMaintenance) * 12 }
}

struct InvestmentPortfolio: Codable, Equatable {
    var stocks: [StockHolding] = []
    var crypto: [CryptoAsset] = []
    var rentals: [RentalProperty] = []
    var totalMarketExposure: Double = 0 // % of net worth
    var lastVolatilityEventAge: Int? // for narrative echo
    
    var totalValue: Int {
        let stockVal = stocks.reduce(0) { $0 + $1.totalValue }
        let cryptoVal = crypto.reduce(0) { $0 + $1.totalValue }
        let rentalEquity = rentals.reduce(0) { $0 + $1.equity }
        return stockVal + cryptoVal + rentalEquity
    }
}

struct FinanceState: Codable, Equatable {
    var cashOnHand: Int = 250
    var studentDebt: Int = 0
    var creditDebt: Int = 0
    var medicalDebt: Int = 0
    var investedBalance: Int = 0
    var indexFundBalance: Int = 0
    var stockPortfolioBalance: Int = 0
    var costBasis: Int = 0
    var portfolio: InvestmentPortfolio = InvestmentPortfolio()
    var lastYearInvestmentDelta: Int = 0
    var investmentRiskProfile: InvestmentRiskProfile = .defensive
    var homeDownPaymentSavings: Int = 0
    var homeEquity: Int = 0
    var lastYearHomeValueDelta: Int = 0
    var lastYearMortgagePrincipalPaid: Int = 0
    var housingDebtBurden: Int = 0
    var annualGrossIncome: Int = 0
    var annualNetIncome: Int = 0
    var annualLivingCost: Int = 0
    var annualEducationCost: Int = 0
    var annualDependentCost: Int = 0
    var annualDiscretionaryCost: Int = 0
    var annualTotalExpenses: Int = 0
    var annualDebtPayments: Int = 0
    var effectiveTaxRate: Int = 0
    var financialStress: Int = 18
    var debtPressureBand: DebtPressureBand = .clear
    var debtDelinquencyRisk: Int = 0
    var recentDebtReliefYears: Int = 0
    var debtStrategy: DebtPaymentStrategy = .standard
    var consecutiveDeficitYears: Int = 0
    var stabilityStreakYears: Int = 0
    var wealthVelocity: Int = 0
    var lifestyleCreep: Int = 0
    var majorSetbackCount: Int = 0
    var peakWealth: Int = 250
    var compoundingYears: Int = 0
    var currentRegionPolicyID: String? = nil
    var lastYearBalanceDelta: Int = 0

    private enum CodingKeys: String, CodingKey {
        case cashOnHand
        case studentDebt
        case creditDebt
        case medicalDebt
        case investedBalance
        case indexFundBalance
        case stockPortfolioBalance
        case costBasis
        case portfolio
        case lastYearInvestmentDelta
        case investmentRiskProfile
        case homeDownPaymentSavings
        case homeEquity
        case lastYearHomeValueDelta
        case lastYearMortgagePrincipalPaid
        case housingDebtBurden
        case annualGrossIncome
        case annualNetIncome
        case annualLivingCost
        case annualEducationCost
        case annualDependentCost
        case annualDiscretionaryCost
        case annualTotalExpenses
        case annualDebtPayments
        case effectiveTaxRate
        case financialStress
        case debtPressureBand
        case debtDelinquencyRisk
        case recentDebtReliefYears
        case debtStrategy
        case consecutiveDeficitYears
        case stabilityStreakYears
        case wealthVelocity
        case lifestyleCreep
        case majorSetbackCount
        case peakWealth
        case compoundingYears
        case currentRegionPolicyID
        case lastYearBalanceDelta
    }

    init() {}

    init(
        cashOnHand: Int = 250,
        studentDebt: Int = 0,
        creditDebt: Int = 0,
        medicalDebt: Int = 0,
        investedBalance: Int = 0,
        indexFundBalance: Int = 0,
        stockPortfolioBalance: Int = 0,
        costBasis: Int = 0,
        portfolio: InvestmentPortfolio = InvestmentPortfolio(),
        lastYearInvestmentDelta: Int = 0,
        investmentRiskProfile: InvestmentRiskProfile = .defensive,
        homeDownPaymentSavings: Int = 0,
        homeEquity: Int = 0,
        lastYearHomeValueDelta: Int = 0,
        lastYearMortgagePrincipalPaid: Int = 0,
        housingDebtBurden: Int = 0,
        annualGrossIncome: Int = 0,
        annualNetIncome: Int = 0,
        annualLivingCost: Int = 0,
        annualEducationCost: Int = 0,
        annualDependentCost: Int = 0,
        annualDiscretionaryCost: Int = 0,
        annualTotalExpenses: Int = 0,
        annualDebtPayments: Int = 0,
        effectiveTaxRate: Int = 0,
        financialStress: Int = 18,
        debtPressureBand: DebtPressureBand = .clear,
        debtDelinquencyRisk: Int = 0,
        recentDebtReliefYears: Int = 0,
        debtStrategy: DebtPaymentStrategy = .standard,
        consecutiveDeficitYears: Int = 0,
        stabilityStreakYears: Int = 0,
        wealthVelocity: Int = 0,
        lifestyleCreep: Int = 0,
        majorSetbackCount: Int = 0,
        peakWealth: Int = 250,
        compoundingYears: Int = 0,
        currentRegionPolicyID: String? = nil,
        lastYearBalanceDelta: Int = 0
    ) {
        self.cashOnHand = cashOnHand
        self.studentDebt = studentDebt
        self.creditDebt = creditDebt
        self.medicalDebt = medicalDebt
        self.investedBalance = investedBalance
        self.indexFundBalance = indexFundBalance
        self.stockPortfolioBalance = stockPortfolioBalance
        self.costBasis = costBasis
        self.portfolio = portfolio
        self.lastYearInvestmentDelta = lastYearInvestmentDelta
        self.investmentRiskProfile = investmentRiskProfile
        self.homeDownPaymentSavings = homeDownPaymentSavings
        self.homeEquity = homeEquity
        self.lastYearHomeValueDelta = lastYearHomeValueDelta
        self.lastYearMortgagePrincipalPaid = lastYearMortgagePrincipalPaid
        self.housingDebtBurden = housingDebtBurden
        self.annualGrossIncome = annualGrossIncome
        self.annualNetIncome = annualNetIncome
        self.annualLivingCost = annualLivingCost
        self.annualEducationCost = annualEducationCost
        self.annualDependentCost = annualDependentCost
        self.annualDiscretionaryCost = annualDiscretionaryCost
        self.annualTotalExpenses = annualTotalExpenses
        self.annualDebtPayments = annualDebtPayments
        self.effectiveTaxRate = effectiveTaxRate
        self.financialStress = financialStress
        self.debtPressureBand = debtPressureBand
        self.debtDelinquencyRisk = debtDelinquencyRisk
        self.recentDebtReliefYears = recentDebtReliefYears
        self.debtStrategy = debtStrategy
        self.consecutiveDeficitYears = consecutiveDeficitYears
        self.stabilityStreakYears = stabilityStreakYears
        self.wealthVelocity = wealthVelocity
        self.lifestyleCreep = lifestyleCreep
        self.majorSetbackCount = majorSetbackCount
        self.peakWealth = peakWealth
        self.compoundingYears = compoundingYears
        self.currentRegionPolicyID = currentRegionPolicyID
        self.lastYearBalanceDelta = lastYearBalanceDelta
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cashOnHand = try container.decodeIfPresent(Int.self, forKey: .cashOnHand) ?? 250
        studentDebt = try container.decodeIfPresent(Int.self, forKey: .studentDebt) ?? 0
        creditDebt = try container.decodeIfPresent(Int.self, forKey: .creditDebt) ?? 0
        medicalDebt = try container.decodeIfPresent(Int.self, forKey: .medicalDebt) ?? 0
        investedBalance = try container.decodeIfPresent(Int.self, forKey: .investedBalance) ?? 0
        indexFundBalance = try container.decodeIfPresent(Int.self, forKey: .indexFundBalance) ?? 0
        stockPortfolioBalance = try container.decodeIfPresent(Int.self, forKey: .stockPortfolioBalance) ?? 0
        costBasis = try container.decodeIfPresent(Int.self, forKey: .costBasis) ?? 0
        portfolio = try container.decodeIfPresent(InvestmentPortfolio.self, forKey: .portfolio) ?? InvestmentPortfolio()
        lastYearInvestmentDelta = try container.decodeIfPresent(Int.self, forKey: .lastYearInvestmentDelta) ?? 0
        investmentRiskProfile = try container.decodeIfPresent(InvestmentRiskProfile.self, forKey: .investmentRiskProfile) ?? .defensive
        homeDownPaymentSavings = try container.decodeIfPresent(Int.self, forKey: .homeDownPaymentSavings) ?? 0
        homeEquity = try container.decodeIfPresent(Int.self, forKey: .homeEquity) ?? 0
        lastYearHomeValueDelta = try container.decodeIfPresent(Int.self, forKey: .lastYearHomeValueDelta) ?? 0
        lastYearMortgagePrincipalPaid = try container.decodeIfPresent(Int.self, forKey: .lastYearMortgagePrincipalPaid) ?? 0
        housingDebtBurden = try container.decodeIfPresent(Int.self, forKey: .housingDebtBurden) ?? 0
        annualGrossIncome = try container.decodeIfPresent(Int.self, forKey: .annualGrossIncome) ?? 0
        annualNetIncome = try container.decodeIfPresent(Int.self, forKey: .annualNetIncome) ?? 0
        annualLivingCost = try container.decodeIfPresent(Int.self, forKey: .annualLivingCost) ?? 0
        annualEducationCost = try container.decodeIfPresent(Int.self, forKey: .annualEducationCost) ?? 0
        annualDependentCost = try container.decodeIfPresent(Int.self, forKey: .annualDependentCost) ?? 0
        annualDiscretionaryCost = try container.decodeIfPresent(Int.self, forKey: .annualDiscretionaryCost) ?? 0
        annualTotalExpenses = try container.decodeIfPresent(Int.self, forKey: .annualTotalExpenses) ?? 0
        annualDebtPayments = try container.decodeIfPresent(Int.self, forKey: .annualDebtPayments) ?? 0
        effectiveTaxRate = try container.decodeIfPresent(Int.self, forKey: .effectiveTaxRate) ?? 0
        financialStress = try container.decodeIfPresent(Int.self, forKey: .financialStress) ?? 18
        debtPressureBand = try container.decodeIfPresent(DebtPressureBand.self, forKey: .debtPressureBand) ?? .clear
        debtDelinquencyRisk = try container.decodeIfPresent(Int.self, forKey: .debtDelinquencyRisk) ?? 0
        recentDebtReliefYears = try container.decodeIfPresent(Int.self, forKey: .recentDebtReliefYears) ?? 0
        debtStrategy = try container.decodeIfPresent(DebtPaymentStrategy.self, forKey: .debtStrategy) ?? .standard
        consecutiveDeficitYears = try container.decodeIfPresent(Int.self, forKey: .consecutiveDeficitYears) ?? 0
        stabilityStreakYears = try container.decodeIfPresent(Int.self, forKey: .stabilityStreakYears) ?? 0
        wealthVelocity = try container.decodeIfPresent(Int.self, forKey: .wealthVelocity) ?? 0
        lifestyleCreep = try container.decodeIfPresent(Int.self, forKey: .lifestyleCreep) ?? 0
        majorSetbackCount = try container.decodeIfPresent(Int.self, forKey: .majorSetbackCount) ?? 0
        peakWealth = try container.decodeIfPresent(Int.self, forKey: .peakWealth) ?? 250
        compoundingYears = try container.decodeIfPresent(Int.self, forKey: .compoundingYears) ?? 0
        currentRegionPolicyID = try container.decodeIfPresent(String.self, forKey: .currentRegionPolicyID)
        lastYearBalanceDelta = try container.decodeIfPresent(Int.self, forKey: .lastYearBalanceDelta) ?? 0
        normalizeInvestmentBalances()
    }

    var totalWealth: Int {
        cashOnHand + investedBalance + portfolio.totalValue + homeDownPaymentSavings + homeEquity - totalNonHousingDebt
    }

    var totalNonHousingDebt: Int {
        studentDebt + creditDebt + medicalDebt
    }

    var hasInvestments: Bool {
        investedBalance > 0 || indexFundBalance > 0 || stockPortfolioBalance > 0 || portfolio.totalValue > 0
    }

    var lastYearHousingGainLoss: Int {
        lastYearHomeValueDelta + lastYearMortgagePrincipalPaid
    }

    var hasMillionaireFoundation: Bool {
        hasMillionaireFoundation(using: .playableRealismV1)
    }

    var requiredAnnualDebtPayment: Int {
        let studentPayment = studentDebt == 0 ? 0 : max(600, Int((Double(studentDebt) * 0.06).rounded()))
        let creditPayment = creditDebt == 0 ? 0 : max(900, Int((Double(creditDebt) * 0.14).rounded()))
        let medicalPayment = medicalDebt == 0 ? 0 : max(400, Int((Double(medicalDebt) * 0.08).rounded()))
        return annualDebtPayments > 0 ? annualDebtPayments : (studentPayment + creditPayment + medicalPayment)
    }

    var debtToIncomeBurden: Int {
        guard annualGrossIncome > 0 else { return totalNonHousingDebt > 0 ? 100 : 0 }
        return Int((Double(requiredAnnualDebtPayment) / Double(annualGrossIncome) * 100.0).rounded())
    }

    var canUseDebtReset: Bool {
        debtPressureBand == .crushing && recentDebtReliefYears == 0 && (creditDebt > 0 || medicalDebt > 0)
    }

    var isBlockedFromCompounding: Bool {
        debtPressureBand == .heavy || debtPressureBand == .crushing || recentDebtReliefYears > 0
    }

    func hasMillionaireFoundation(using profile: SimulationBalanceProfile) -> Bool {
        stabilityStreakYears >= profile.wealth.millionaireFoundationStabilityYears ||
        compoundingYears >= profile.wealth.millionaireFoundationCompoundingYears
    }

    func isEligibleToCompound(
        emergencyReserve: Int = SimulationBalanceProfile.playableRealismV1.wealth.compoundingEmergencyReserve,
        profile: SimulationBalanceProfile = .playableRealismV1
    ) -> Bool {
        stabilityStreakYears >= 2 &&
        consecutiveDeficitYears == 0 &&
        cashOnHand >= emergencyReserve &&
        studentDebt <= max(profile.wealth.compoundingDebtIncomeCap, annualGrossIncome) &&
        financialStress <= 55 &&
        !isBlockedFromCompounding
    }

    mutating func resetAnnualWealthVelocity() {
        wealthVelocity = 0
    }

    mutating func accumulateWealthDelta(from previousTotalWealth: Int) {
        wealthVelocity += totalWealth - previousTotalWealth
        peakWealth = max(peakWealth, totalWealth)
    }

    mutating func normalizeInvestmentBalances() {
        indexFundBalance = max(0, indexFundBalance)
        stockPortfolioBalance = max(0, stockPortfolioBalance)
        studentDebt = max(0, studentDebt)
        creditDebt = max(0, creditDebt)
        medicalDebt = max(0, medicalDebt)
        investedBalance = max(0, indexFundBalance + stockPortfolioBalance)
        costBasis = min(max(0, costBasis), investedBalance)
        homeDownPaymentSavings = max(0, homeDownPaymentSavings)
        homeEquity = max(0, homeEquity)
        housingDebtBurden = max(0, housingDebtBurden)
        annualDebtPayments = max(0, annualDebtPayments)
        debtDelinquencyRisk = debtDelinquencyRisk.clamped(to: 0...100)
        recentDebtReliefYears = max(0, recentDebtReliefYears)
        stabilityStreakYears = max(0, stabilityStreakYears)
        lifestyleCreep = max(0, lifestyleCreep)
        majorSetbackCount = max(0, majorSetbackCount)
        peakWealth = max(0, max(peakWealth, totalWealth))
        compoundingYears = max(0, compoundingYears)
        if totalNonHousingDebt == 0, debtPressureBand != .clear {
            debtPressureBand = .clear
        }
        if !hasInvestments {
            investedBalance = 0
            indexFundBalance = 0
            stockPortfolioBalance = 0
            costBasis = 0
            if investmentRiskProfile != .defensive {
                investmentRiskProfile = .defensive
            }
        }
    }
}

struct FederalFinancePolicy: Equatable {
    var taxBands: [FinanceTaxBand]
}

struct FinanceTaxBand: Equatable {
    var minimumIncome: Int
    var ratePercent: Int
}

struct StateFinancePolicy: Equatable {
    var id: String
    var incomeTaxRateDelta: Int = 0
    var costOfLivingMultiplier: Double = 1.0
    var educationCostMultiplier: Double = 1.0
    var dependentCostMultiplier: Double = 1.0
    var healthcareCostMultiplier: Double = 1.0
    var schoolSupportLevel: Int = 0
}

struct FinancePolicySet: Equatable {
    var federal: FederalFinancePolicy
    var states: [String: StateFinancePolicy]

    static let usBaseline = FinancePolicySet(
        federal: FederalFinancePolicy(
            taxBands: [
                FinanceTaxBand(minimumIncome: 0, ratePercent: 8),
                FinanceTaxBand(minimumIncome: 10_000, ratePercent: 12),
                FinanceTaxBand(minimumIncome: 30_000, ratePercent: 18),
                FinanceTaxBand(minimumIncome: 60_000, ratePercent: 24)
            ]
        ),
        states: [
            "mountain_standard": StateFinancePolicy(id: "mountain_standard", incomeTaxRateDelta: 1, costOfLivingMultiplier: 1.0, educationCostMultiplier: 0.95, dependentCostMultiplier: 1.0, healthcareCostMultiplier: 1.0, schoolSupportLevel: 2),
            "expensive_coastal": StateFinancePolicy(id: "expensive_coastal", incomeTaxRateDelta: 4, costOfLivingMultiplier: 1.28, educationCostMultiplier: 1.15, dependentCostMultiplier: 1.12, healthcareCostMultiplier: 1.1, schoolSupportLevel: 4),
            "factory_town": StateFinancePolicy(id: "factory_town", incomeTaxRateDelta: 0, costOfLivingMultiplier: 0.88, educationCostMultiplier: 0.92, dependentCostMultiplier: 0.94, healthcareCostMultiplier: 0.97, schoolSupportLevel: -1)
        ]
    )
}

enum WealthBand: String, Codable, CaseIterable {
    case struggling
    case stable
    case comfortable
    case wealthy
    case millionaire
}

struct BalanceRunSummary: Equatable {
    var seed: Int
    var finalWealthBand: WealthBand
    var ageOfFirstStableSurplus: Int?
    var experiencedHeavyDebt: Bool
    var graduated: Bool
    var unemploymentYears: Int
    var becameHomeowner: Bool
    var achievedLongTermPartnership: Bool
    var severeHealthDecline: Bool
    var millionaireMilestone: Bool
}

struct BalanceReport: Equatable {
    var profileName: String
    var runCount: Int
    var summaries: [BalanceRunSummary]

    func rate(where predicate: (BalanceRunSummary) -> Bool) -> Double {
        guard runCount > 0 else { return 0 }
        return Double(summaries.filter(predicate).count) / Double(runCount)
    }

    var wealthBandCounts: [WealthBand: Int] {
        summaries.reduce(into: [:]) { partial, summary in
            partial[summary.finalWealthBand, default: 0] += 1
        }
    }

    var humanReadableSummary: String {
        let orderedBands = WealthBand.allCases.map { band in
            "\(band.rawValue): \(wealthBandCounts[band, default: 0])"
        }.joined(separator: ", ")
        let age30ishStability = summaries.compactMap(\.ageOfFirstStableSurplus).filter { $0 <= 30 }.count
        return [
            "Profile: \(profileName)",
            "Runs: \(runCount)",
            "Wealth bands: \(orderedBands)",
            "Stable by 30: \(age30ishStability)",
            "Heavy debt rate: \(Int((rate { $0.experiencedHeavyDebt } * 100).rounded()))%",
            "Graduation rate: \(Int((rate { $0.graduated } * 100).rounded()))%",
            "Homeownership rate: \(Int((rate { $0.becameHomeowner } * 100).rounded()))%",
            "Long-term partnership rate: \(Int((rate { $0.achievedLongTermPartnership } * 100).rounded()))%",
            "Millionaire rate: \(Int((rate { $0.millionaireMilestone } * 100).rounded()))%"
        ].joined(separator: "\n")
    }
}

struct SimulationBalanceProfile: Equatable {
    struct DebtSettings: Equatable {
        var studentInterestRatePercent: Int
        var deferredStudentInterestRatePercent: Int
        var creditInterestRatePercent: Int
        var restructuredCreditInterestRatePercent: Int
        var medicalInterestRatePercent: Int
        var restructuredMedicalInterestRatePercent: Int
        var studentMinimumPayment: Int
        var studentPaymentRatePercent: Int
        var creditMinimumPayment: Int
        var creditPaymentRatePercent: Int
        var medicalMinimumPayment: Int
        var medicalPaymentRatePercent: Int
    }

    struct WealthSettings: Equatable {
        var adultStableSurplusThreshold: Int
        var adultStableStressCeiling: Int
        var compoundingEmergencyReserve: Int
        var compoundingDebtIncomeCap: Int
        var millionaireMinimumAge: Int
        var millionaireFoundationStabilityYears: Int
        var millionaireFoundationCompoundingYears: Int
        var stableBandLowerBound: Int
        var comfortableBandLowerBound: Int
        var wealthyBandLowerBound: Int
    }

    struct HomeownershipSettings: Equatable {
        var minimumLiquidReserve: Int
        var minimumYearsWorked: Int
        var minimumPositiveBalanceDelta: Int
        var downPaymentRatePercent: Int
        var closingCostRatePercent: Int
    }

    struct CareerSettings: Equatable {
        var promotionBaseThreshold: Int
    }

    struct EconomySettings: Equatable {
        var baseInflationRate: Double
        var marketBoomMultiplier: Double
        var marketStableMultiplier: Double
        var marketCorrectionMultiplier: Double
        var marketRecessionMultiplier: Double
    }

    var debt: DebtSettings
    var wealth: WealthSettings
    var homeownership: HomeownershipSettings
    var career: CareerSettings
    var economy: EconomySettings

    func wealthBand(for totalWealth: Int) -> WealthBand {
        if totalWealth >= 1_000_000 { return .millionaire }
        if totalWealth >= wealth.wealthyBandLowerBound { return .wealthy }
        if totalWealth >= wealth.comfortableBandLowerBound { return .comfortable }
        if totalWealth >= wealth.stableBandLowerBound { return .stable }
        return .struggling
    }

    static let playableRealismV1 = SimulationBalanceProfile(
        debt: DebtSettings(
            studentInterestRatePercent: 4,
            deferredStudentInterestRatePercent: 6,
            creditInterestRatePercent: 18,
            restructuredCreditInterestRatePercent: 14,
            medicalInterestRatePercent: 7,
            restructuredMedicalInterestRatePercent: 5,
            studentMinimumPayment: 600,
            studentPaymentRatePercent: 6,
            creditMinimumPayment: 900,
            creditPaymentRatePercent: 14,
            medicalMinimumPayment: 400,
            medicalPaymentRatePercent: 8
        ),
        wealth: WealthSettings(
            adultStableSurplusThreshold: 2_500,
            adultStableStressCeiling: 48,
            compoundingEmergencyReserve: 6_000,
            compoundingDebtIncomeCap: 18_000,
            millionaireMinimumAge: 30,
            millionaireFoundationStabilityYears: 5,
            millionaireFoundationCompoundingYears: 6,
            stableBandLowerBound: 0,
            comfortableBandLowerBound: 75_000,
            wealthyBandLowerBound: 300_000
        ),
        homeownership: HomeownershipSettings(
            minimumLiquidReserve: 8_000,
            minimumYearsWorked: 2,
            minimumPositiveBalanceDelta: 0,
            downPaymentRatePercent: 12,
            closingCostRatePercent: 4
        ),
        career: CareerSettings(
            promotionBaseThreshold: 85
        ),
        economy: EconomySettings(
            baseInflationRate: 0.02,
            marketBoomMultiplier: 1.15,
            marketStableMultiplier: 1.05,
            marketCorrectionMultiplier: 0.92,
            marketRecessionMultiplier: 0.80
        )
    )
}

/// Lightweight scaling factors derived from LifeResilience.
/// Used by pressure, health, and game-over systems to reduce frustration spirals
/// while preserving the core "Life Killer" authenticity.
struct ResilienceScaling: Equatable {
    var spilloverSeverityMultiplier: Double   // 0.65 = resilient (less punishing chain reactions)
    var healthDeclineDampener: Double         // <1.0 reduces negative mental/physical shifts
    var wealthGameOverFloor: Int              // e.g. -35_000 for resilient vs -20_000 grounded
    var earlyLifeBufferYears: Int             // extra forgiveness before ~age 22
}

extension LifeResilience {
    var scaling: ResilienceScaling {
        switch self {
        case .resilient:
            return ResilienceScaling(
                spilloverSeverityMultiplier: 0.68,
                healthDeclineDampener: 0.78,
                wealthGameOverFloor: -35_000,
                earlyLifeBufferYears: 8
            )
        case .grounded:
            return ResilienceScaling(
                spilloverSeverityMultiplier: 1.0,
                healthDeclineDampener: 1.0,
                wealthGameOverFloor: -20_000,
                earlyLifeBufferYears: 0
            )
        }
    }

    /// Returns a human-friendly short label for the current run.
    var shortLabel: String {
        switch self {
        case .resilient: return "Resilient run"
        case .grounded: return "Grounded (hardcore)"
        }
    }

    /// Evolving journal texture so the chosen Life Feel stays visible over decades.
    func journalReflection(forAge age: Int) -> (title: String, text: String)? {
        switch self {
        case .resilient:
            switch age {
            case 25:
                return ("Life Feel", "Mid-twenties in a Resilient run: rough years still bend back. Recovery is part of the design.")
            case 40:
                return ("Life Feel", "Forty in a Resilient run: you've had room to correct course. The story still has slack in it.")
            case 60:
                return ("Life Feel", "Sixty in a Resilient run: scars exist, but fewer feel fatal. You outlasted more than you broke.")
            default:
                return nil
            }
        case .grounded:
            switch age {
            case 25:
                return ("Life Feel", "Mid-twenties in a Grounded run: every mistake lands heavier. Choosing care is an act of courage.")
            case 40:
                return ("Life Feel", "Forty in a Grounded run: the weight is real. Small recoveries feel like victories because they are.")
            case 60:
                return ("Life Feel", "Sixty in a Grounded run: you survived without nets. What you built cost more — and means more.")
            default:
                return nil
            }
        }
    }
}

struct FinanceYearContext: Equatable {
    var age: Int
    var isSchoolAge: Bool
    var careerStatus: CareerStatus
    var careerLevel: Int = 0
    var grossIncome: Int
    var traits: [PersonalityTrait]
    var educationPathway: EducationPathway
    var educationStage: EducationStage
    var hasScholarship: Bool
    var housingCostBand: Int
    var housingArrangement: LivingArrangement
    var activeConditionCount: Int
    var ownsHome: Bool
    var hasPrimaryCare: Bool
    var friendCount: Int
    var partnerCount: Int
    var hasSpouse: Bool
    var hasCohabitingPartner: Bool
    var isPregnant: Bool
    var pregnancyPhase: PregnancyPhase?
    var infantCount: Int
    var childCount: Int
}

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
    }
}

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

// MARK: - Health Domain

struct LifestyleHabits: Codable, Equatable {
    var exercise: Int = 50
    var nutrition: Int = 50
    var stressManagement: Int = 45

    mutating func clamp() {
        exercise = exercise.clamped(to: 0...100)
        nutrition = nutrition.clamped(to: 0...100)
        stressManagement = stressManagement.clamped(to: 0...100)
    }
}

struct HealthCondition: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var severity: Int

    mutating func clamp() {
        severity = severity.clamped(to: 1...100)
    }

    static func == (lhs: HealthCondition, rhs: HealthCondition) -> Bool {
        lhs.name == rhs.name && lhs.severity == rhs.severity
    }
}

struct HealthState: Codable, Equatable {
    var physicalWellness: Int = 60
    var mentalWellness: Int = 55
    var addiction: Int = 0
    var habits: LifestyleHabits = LifestyleHabits()
    var activeConditions: [HealthCondition] = []
    var hasPrimaryCare: Bool = false

    init(
        physicalWellness: Int = 60,
        mentalWellness: Int = 55,
        addiction: Int = 0,
        habits: LifestyleHabits = LifestyleHabits(),
        activeConditions: [HealthCondition] = [],
        hasPrimaryCare: Bool = false
    ) {
        self.physicalWellness = physicalWellness
        self.mentalWellness = mentalWellness
        self.addiction = addiction
        self.habits = habits
        self.activeConditions = activeConditions
        self.hasPrimaryCare = hasPrimaryCare
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        physicalWellness = try container.decodeIfPresent(Int.self, forKey: .physicalWellness) ?? 60
        mentalWellness = try container.decodeIfPresent(Int.self, forKey: .mentalWellness) ?? 55
        addiction = try container.decodeIfPresent(Int.self, forKey: .addiction) ?? 0
        habits = try container.decodeIfPresent(LifestyleHabits.self, forKey: .habits) ?? LifestyleHabits()
        activeConditions = try container.decodeIfPresent([HealthCondition].self, forKey: .activeConditions) ?? []
        hasPrimaryCare = try container.decodeIfPresent(Bool.self, forKey: .hasPrimaryCare) ?? false
        clamp()
    }

    mutating func clamp() {
        physicalWellness = physicalWellness.clamped(to: 0...100)
        mentalWellness = mentalWellness.clamped(to: 0...100)
        addiction = addiction.clamped(to: 0...100)
        habits.clamp()
        activeConditions.indices.forEach { activeConditions[$0].clamp() }
    }
}

// MARK: - Asset Domain

enum PrimaryResidenceStatus: String, Codable, CaseIterable {
    case current
    case delinquent
    case foreclosed
}

enum HouseUpgrade: String, Codable, CaseIterable {
    case pool
    case bioLandscape
    case sauna
    case gym
    case basketballCourt
    case tennisCourt
    case hotTub

    var cost: Int {
        switch self {
        case .pool: return 45000
        case .bioLandscape: return 12000
        case .sauna: return 8000
        case .gym: return 15000
        case .basketballCourt: return 25000
        case .tennisCourt: return 35000
        case .hotTub: return 10000
        }
    }

    var valueBoost: Int {
        switch self {
        case .pool: return 30000
        case .bioLandscape: return 15000
        case .sauna: return 5000
        case .gym: return 10000
        case .basketballCourt: return 15000
        case .tennisCourt: return 20000
        case .hotTub: return 6000
        }
    }

    var maintenanceCost: Int {
        switch self {
        case .pool: return 200
        case .bioLandscape: return 50
        case .sauna: return 30
        case .gym: return 40
        case .basketballCourt: return 20
        case .tennisCourt: return 40
        case .hotTub: return 80
        }
    }
}

struct PrimaryResidenceState: Codable, Equatable {
    var homeValue: Int
    var mortgagePrincipal: Int
    var monthlyMortgageCost: Int
    var mortgageRatePercent: Int
    var remainingMortgageYears: Int
    var equity: Int
    var downPaymentPaid: Int
    var maintenanceReserve: Int
    var status: PrimaryResidenceStatus = .current
    var yearsOwned: Int = 0
    var upgrades: [HouseUpgrade] = []

    var totalValue: Int {
        homeValue + upgrades.reduce(0) { $0 + $1.valueBoost }
    }

    var totalMonthlyMaintenance: Int {
        upgrades.reduce(0) { $0 + $1.maintenanceCost }
    }

    mutating func normalize() {
        homeValue = max(0, homeValue)
        mortgagePrincipal = max(0, mortgagePrincipal)
        monthlyMortgageCost = max(0, monthlyMortgageCost)
        mortgageRatePercent = mortgageRatePercent.clamped(to: 2...12)
        remainingMortgageYears = max(0, remainingMortgageYears)
        maintenanceReserve = max(0, maintenanceReserve)
        downPaymentPaid = max(0, downPaymentPaid)
        equity = max(0, homeValue - mortgagePrincipal)
        if mortgagePrincipal == 0 {
            monthlyMortgageCost = 0
            remainingMortgageYears = 0
            status = .current
        }
    }

    static func legacyStarterHome() -> PrimaryResidenceState {
        var home = PrimaryResidenceState(
            homeValue: 180_000,
            mortgagePrincipal: 125_000,
            monthlyMortgageCost: 980,
            mortgageRatePercent: 6,
            remainingMortgageYears: 28,
            equity: 55_000,
            downPaymentPaid: 32_000,
            maintenanceReserve: 2_000
        )
        home.normalize()
        return home
    }
}

enum FirearmType: String, Codable, CaseIterable {
    case handgun
    case shotgun
    case rifle
    case precisionRifle
}

enum WeaponUpgrade: String, Codable, CaseIterable {
    case optic
    case extendedMag
    case highCapacityDrum
    case suppressor
    case carbonFiberSuppressor
    case tacticalLight
    case matchTrigger
    case stippledGrip
    case rapidFireSwitch

    var cost: Int {
        switch self {
        case .optic: return 400
        case .extendedMag: return 150
        case .highCapacityDrum: return 450
        case .suppressor: return 800
        case .carbonFiberSuppressor: return 2200
        case .tacticalLight: return 100
        case .matchTrigger: return 300
        case .stippledGrip: return 200
        case .rapidFireSwitch: return 1500
        }
    }

    var powerBonus: Int {
        switch self {
        case .matchTrigger: return 5
        case .optic: return 2
        case .highCapacityDrum: return 12
        case .carbonFiberSuppressor: return 3
        case .rapidFireSwitch: return 25
        default: return 0
        }
    }

    var reliabilityBonus: Int {
        switch self {
        case .tacticalLight: return 5
        case .optic: return 3
        case .stippledGrip: return 8
        case .highCapacityDrum: return -5
        case .carbonFiberSuppressor: return 2
        case .rapidFireSwitch: return -15
        default: return 0
        }
    }

    var isIllicit: Bool {
        switch self {
        case .rapidFireSwitch, .highCapacityDrum, .suppressor, .carbonFiberSuppressor: return true
        default: return false
        }
    }
}

enum FirearmRarity: String, Codable, CaseIterable {
    case common
    case rare
    case exotic
    case prototype
}

struct Firearm: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: FirearmType
    var isLegal: Bool
    var basePower: Int
    var reliability: Int
    var rarity: FirearmRarity = .common
    var upgrades: [WeaponUpgrade] = []

    var totalPower: Int {
        basePower + upgrades.reduce(0) { $0 + $1.powerBonus }
    }

    var totalReliability: Int {
        reliability + upgrades.reduce(0) { $0 + $1.reliabilityBonus }
    }
    
    var isCurrentlyIllicit: Bool {
        !isLegal || upgrades.contains { $0.isIllicit }
    }
}

enum VehicleType: String, Codable, CaseIterable {
    case compact
    case sedan
    case truck
    case sportsCar
    case supercar
    case hypercar
}

enum AviationType: String, Codable, CaseIterable {
    case lightAircraft
    case privateJet
    case helicopter
    case heavyJet
}

struct AviationAsset: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: AviationType
    var cost: Int
    var resaleValue: Int
    var monthlyMaintenance: Int
}

enum MarineType: String, Codable, CaseIterable {
    case jetSki
    case speedboat
    case yacht
    case superYacht
}

struct MarineAsset: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: MarineType
    var cost: Int
    var resaleValue: Int
    var monthlyMaintenance: Int
}

// MARK: - Assets2: Signature Assets (Special Career Identity)

/// High-status, path-unique assets that reinforce a special career's identity and provide unique prestige/mechanical payoffs.
enum SignatureAssetCategory: String, Codable, CaseIterable {
    case athleteTeamStake      // Ownership or equity in a sports team/franchise
    case athleteTrainingEmpire // Personal training facilities, performance centers
    case founderStrategicStake // Equity in other companies / venture holdings
    case founderCompound       // Large private estate used for business + lifestyle
    case creatorStudio         // Production studio or content company
    case creatorBrandEstate    // Properties tied to personal brand (content houses, etc.)
    case politicsInfluenceHold // "Foundations", large donor properties, or strategic real estate
    case politicsLegacyEstate  // Grand estates used for political entertaining and legacy
    // CE3: Criminal/gray enterprise signature holdings — high prestige + real social/legal risk
    case crimeSafehouse        // Quiet, high-security properties for staying low or moving product
    case crimeOffshoreHoldings // Shell companies, foreign accounts, "investment" properties that are hard to trace
    case crimeFrontBusiness    // Legitimate-looking businesses that are actually cash flow / laundering vehicles
    case crimeLuxuryFront      // Flashy but dangerous (yachts under LLCs, penthouses bought through proxies)
}

struct SignatureAsset: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var category: SignatureAssetCategory
    var cost: Int
    var resaleValue: Int
    var monthlyMaintenance: Int
    var prestigeBonus: Int          // Extra boost to effective LifestyleScore / Fame when owned
    var associatedTrack: SpecialCareerTrack // Which special career this asset "belongs" to
}

enum VehicleUpgrade: String, Codable, CaseIterable {
    case supercharger
    case nos
    case racingSuspension
    case driftKit
    case rollCage
    case performanceTires
    case weightReduction

    var cost: Int {
        switch self {
        case .supercharger: return 4500
        case .nos: return 1200
        case .racingSuspension: return 2000
        case .driftKit: return 1500
        case .rollCage: return 800
        case .performanceTires: return 1000
        case .weightReduction: return 3000
        }
    }

    var speedBonus: Int {
        switch self {
        case .supercharger: return 20
        case .nos: return 15
        case .weightReduction: return 10
        case .performanceTires: return 5
        default: return 0
        }
    }

    var handlingBonus: Int {
        switch self {
        case .racingSuspension: return 15
        case .driftKit: return 12
        case .performanceTires: return 8
        case .rollCage: return 5
        default: return 0
        }
    }

    var safetyBonus: Int {
        switch self {
        case .rollCage: return 25
        default: return 0
        }
    }
}

struct Vehicle: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: VehicleType
    var isLegal: Bool
    var baseSpeed: Int
    var baseHandling: Int
    var upgrades: [VehicleUpgrade] = []

    var totalSpeed: Int {
        baseSpeed + upgrades.reduce(0) { $0 + $1.speedBonus }
    }

    var totalHandling: Int {
        baseHandling + upgrades.reduce(0) { $0 + $1.handlingBonus }
    }

    var totalSafety: Int {
        upgrades.reduce(0) { $0 + $1.safetyBonus }
    }
}

enum JewelryType: String, Codable, CaseIterable {
    case watch
    case chain
    case pendant
    case earrings
    case bracelet
}

struct Jewelry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: JewelryType
    var rarity: FirearmRarity = .common
    var cost: Int
    var resaleValue: Int
}

struct AssetState: Codable, Equatable {
    var homeownershipTrackActive: Bool = false
    var targetHomeValue: Int = 0
    var primaryResidence: PrimaryResidenceState? = nil
    var firearms: [Firearm] = []
    var vehicles: [Vehicle] = []
    var jewelry: [Jewelry] = []
    var aviation: [AviationAsset] = []
    var marine: [MarineAsset] = []

    // Assets2: Career-specific Signature Assets (high-status, path-unique holdings)
    var signatureAssets: [SignatureAsset] = []

    private enum CodingKeys: String, CodingKey {
        case homeownershipTrackActive
        case targetHomeValue
        case primaryResidence
        case firearms
        case vehicles
        case jewelry
        case aviation
        case marine
        case ownsHome // for legacy decoding
        case signatureAssets
    }

    init() {}

    init(homeownershipTrackActive: Bool = false, targetHomeValue: Int = 0, primaryResidence: PrimaryResidenceState? = nil) {
        self.homeownershipTrackActive = homeownershipTrackActive
        self.targetHomeValue = targetHomeValue
        self.primaryResidence = primaryResidence
        self.firearms = []
        self.vehicles = []
        self.jewelry = []
        self.aviation = []
        self.marine = []
        normalize()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        homeownershipTrackActive = try container.decodeIfPresent(Bool.self, forKey: .homeownershipTrackActive) ?? false
        targetHomeValue = try container.decodeIfPresent(Int.self, forKey: .targetHomeValue) ?? 0
        primaryResidence = try container.decodeIfPresent(PrimaryResidenceState.self, forKey: .primaryResidence)
        firearms = try container.decodeIfPresent([Firearm].self, forKey: .firearms) ?? []
        vehicles = try container.decodeIfPresent([Vehicle].self, forKey: .vehicles) ?? []
        jewelry = try container.decodeIfPresent([Jewelry].self, forKey: .jewelry) ?? []
        aviation = try container.decodeIfPresent([AviationAsset].self, forKey: .aviation) ?? []
        marine = try container.decodeIfPresent([MarineAsset].self, forKey: .marine) ?? []
        signatureAssets = try container.decodeIfPresent([SignatureAsset].self, forKey: .signatureAssets) ?? []

        let legacyOwnsHome = try container.decodeIfPresent(Bool.self, forKey: .ownsHome) ?? false
        if primaryResidence == nil, legacyOwnsHome {
            primaryResidence = .legacyStarterHome()
            homeownershipTrackActive = true
            targetHomeValue = max(targetHomeValue, primaryResidence?.homeValue ?? 180_000)
        }
        normalize()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(homeownershipTrackActive, forKey: .homeownershipTrackActive)
        try container.encode(targetHomeValue, forKey: .targetHomeValue)
        try container.encodeIfPresent(primaryResidence, forKey: .primaryResidence)
        try container.encode(firearms, forKey: .firearms)
        try container.encode(vehicles, forKey: .vehicles)
        try container.encode(jewelry, forKey: .jewelry)
        try container.encode(aviation, forKey: .aviation)
        try container.encode(marine, forKey: .marine)
        try container.encode(signatureAssets, forKey: .signatureAssets)
    }

    var ownsHome: Bool {
        get { primaryResidence?.status != .foreclosed && primaryResidence != nil }
        set {
            if newValue {
                homeownershipTrackActive = true
                if targetHomeValue == 0 {
                    targetHomeValue = 180_000
                }
                if primaryResidence == nil {
                    primaryResidence = .legacyStarterHome()
                }
            } else {
                primaryResidence = nil
            }
            normalize()
        }
    }

    var isSavingForHome: Bool {
        homeownershipTrackActive && !ownsHome
    }

    /// Aggressive QoL: Visible Lifestyle / Status score from assets.
    /// High asset ownership gives tangible prestige and can influence social/finance events.
    var lifestyleScore: Int {
        var score = 0
        
        // Housing prestige
        if let home = primaryResidence {
            score += home.totalValue / 20_000
            score += home.upgrades.count * 8
        }
        
        // Vehicles
        score += vehicles.count * 5
        score += vehicles.filter { $0.upgrades.count > 0 }.count * 3
        
        // Luxury
        score += jewelry.count * 4
        score += aviation.count * 15
        score += marine.count * 12
        score += firearms.count * 2

        // Assets2: Signature Assets give strong, career-specific prestige
        for sig in signatureAssets {
            score += sig.prestigeBonus
        }
        
        return max(0, min(100, score))
    }

    mutating func normalize() {
        targetHomeValue = max(0, targetHomeValue)
        primaryResidence?.normalize()
        if primaryResidence == nil && targetHomeValue == 0 {
            homeownershipTrackActive = false
        }
    }
}

// MARK: - Progress Domain

enum MilestoneID: String, Codable, CaseIterable, Identifiable {
    case graduate
    case firstJob
    case homeowner
    case married
    case millionaire
    case longLived
    case raisedGoodKids   // Phase 2.3: Family legacy milestone
    case culturalIcon
    case infamous
    case householdName

    var id: String { rawValue }
}

struct MilestoneUnlock: Codable, Identifiable, Equatable {
    var id: MilestoneID
    var unlockedAtAge: Int
}

enum LifePathID: String, Codable, CaseIterable, Identifiable {
    case scholar
    case striver
    case provider
    case connector
    case survivor

    var id: String { rawValue }
}

struct LifePathProfile: Equatable {
    var title: String
    var summary: String
    var symbol: String
}

enum LifePathCatalog {
    static func profile(for id: LifePathID) -> LifePathProfile {
        switch id {
        case .scholar:
            return LifePathProfile(
                title: "Scholar",
                summary: "Your life is being defined by study, credentials, and disciplined upward movement.",
                symbol: "book.closed.fill"
            )
        case .striver:
            return LifePathProfile(
                title: "Striver",
                summary: "You are pushing for traction through work, consistency, and earned advancement.",
                symbol: "briefcase.fill"
            )
        case .provider:
            return LifePathProfile(
                title: "Provider",
                summary: "Stability, money discipline, and practical security are shaping your choices.",
                symbol: "dollarsign.circle.fill"
            )
        case .connector:
            return LifePathProfile(
                title: "Connector",
                summary: "Relationships are the strongest force in your life, for warmth and for consequence.",
                symbol: "person.2.fill"
            )
        case .survivor:
            return LifePathProfile(
                title: "Survivor",
                summary: "This life is being defined by pressure, endurance, and staying upright through strain.",
                symbol: "cross.case.fill"
            )
        }
    }
}

struct LifePathUnlock: Codable, Identifiable, Equatable {
    var id: LifePathID
    var unlockedAtAge: Int
}

struct ProgressState: Codable, Equatable {
    var unlockedMilestones: [MilestoneUnlock] = []
    var unlockedLifePaths: [LifePathUnlock] = []
    var currentLifePath: LifePathID? = nil
    var finalLifePath: LifePathID? = nil
    var legacyScore: Int = 0

    init() {}

    private enum CodingKeys: String, CodingKey {
        case unlockedMilestones
        case unlockedLifePaths
        case currentLifePath
        case finalLifePath
        case legacyScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unlockedMilestones = try container.decodeIfPresent([MilestoneUnlock].self, forKey: .unlockedMilestones) ?? []
        unlockedLifePaths = try container.decodeIfPresent([LifePathUnlock].self, forKey: .unlockedLifePaths) ?? []
        currentLifePath = try container.decodeIfPresent(LifePathID.self, forKey: .currentLifePath)
        finalLifePath = try container.decodeIfPresent(LifePathID.self, forKey: .finalLifePath)
        legacyScore = try container.decodeIfPresent(Int.self, forKey: .legacyScore) ?? 0
    }
}

// MARK: - Event Data Models

enum EventCategory: String, Codable, CaseIterable {
    case general
    case education
    case career
    case finance
    case relationships
    case social
    case health
}

enum EventSeverity: String, Codable, CaseIterable {
    case routine
    case consequential
    case critical
}

struct EventPack: Codable {
    var events: [GameEvent]
}

struct GameEvent: Codable, Identifiable, Equatable {
    var id: String
    var category: EventCategory
    var tags: [String]
    var severity: EventSeverity
    var title: String
    var text: String
    var minAge: Int
    var maxAge: Int
    var weight: Int
    var cooldownYears: Int
    var triggerOnce: Bool
    var requirements: [String]
    var followUpEventIDs: [String]
    var choices: [EventChoice]

    init(
        id: String,
        category: EventCategory = .general,
        tags: [String] = [],
        severity: EventSeverity = .routine,
        title: String,
        text: String,
        minAge: Int,
        maxAge: Int,
        weight: Int,
        cooldownYears: Int,
        triggerOnce: Bool = false,
        requirements: [String],
        followUpEventIDs: [String] = [],
        choices: [EventChoice]
    ) {
        self.id = id
        self.category = category
        self.tags = tags
        self.severity = severity
        self.title = title
        self.text = text
        self.minAge = minAge
        self.maxAge = maxAge
        self.weight = weight
        self.cooldownYears = cooldownYears
        self.triggerOnce = triggerOnce
        self.requirements = requirements
        self.followUpEventIDs = followUpEventIDs
        self.choices = choices
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case tags
        case severity
        case title
        case text
        case minAge
        case maxAge
        case weight
        case cooldownYears
        case triggerOnce
        case requirements
        case followUpEventIDs
        case choices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        category = try container.decodeIfPresent(EventCategory.self, forKey: .category) ?? .general
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        severity = try container.decodeIfPresent(EventSeverity.self, forKey: .severity) ?? .routine
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        minAge = try container.decode(Int.self, forKey: .minAge)
        maxAge = try container.decode(Int.self, forKey: .maxAge)
        weight = try container.decode(Int.self, forKey: .weight)
        cooldownYears = try container.decode(Int.self, forKey: .cooldownYears)
        triggerOnce = try container.decodeIfPresent(Bool.self, forKey: .triggerOnce) ?? false
        requirements = try container.decodeIfPresent([String].self, forKey: .requirements) ?? []
        followUpEventIDs = try container.decodeIfPresent([String].self, forKey: .followUpEventIDs) ?? []
        choices = try container.decode([EventChoice].self, forKey: .choices)
    }
}

struct EventChoice: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String
    var effects: ChoiceEffects
    var microBeat: String?
    var baseFriction: ActionFrictionLevel = .none

    private enum CodingKeys: String, CodingKey {
        case text
        case effects
        case microBeat
        case baseFriction
    }

    init(text: String, effects: ChoiceEffects, microBeat: String? = nil, baseFriction: ActionFrictionLevel = .none) {
        self.text = text
        self.effects = effects
        self.microBeat = microBeat
        self.baseFriction = baseFriction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        effects = try container.decode(ChoiceEffects.self, forKey: .effects)
        microBeat = try container.decodeIfPresent(String.self, forKey: .microBeat)
        baseFriction = try container.decodeIfPresent(ActionFrictionLevel.self, forKey: .baseFriction) ?? .none
    }

    static func == (lhs: EventChoice, rhs: EventChoice) -> Bool {
        lhs.text == rhs.text && lhs.effects == rhs.effects && lhs.microBeat == rhs.microBeat && lhs.baseFriction == rhs.baseFriction
    }
}

struct AssetEffects: Codable, Equatable {
    var addFirearm: Firearm? = nil
    var removeFirearmID: UUID? = nil
    var upgradeFirearmID: UUID? = nil
    var addUpgrade: WeaponUpgrade? = nil
    
    var addVehicle: Vehicle? = nil
    var removeVehicleID: UUID? = nil
    var upgradeVehicleID: UUID? = nil
    var addVehicleUpgrade: VehicleUpgrade? = nil

    var addHouseUpgrade: HouseUpgrade? = nil

    var addJewelry: Jewelry? = nil
    var removeJewelryID: UUID? = nil

    var addAviation: AviationAsset? = nil
    var removeAviationID: UUID? = nil
    
    var addMarine: MarineAsset? = nil
    var removeMarineID: UUID? = nil
}

struct MilitaryEffects: Codable, Equatable {
    var fitness: Int? = nil
    var discipline: Int? = nil
    var heat: Int? = nil
    var rankLevel: Int? = nil
    var contractYearsRemaining: Int? = nil
    var setDeploymentStatus: DeploymentStatus? = nil
    var isAWOL: Bool? = nil
    var addMedal: String? = nil
}

struct ChoiceEffects: Codable, Equatable {
    var core: CoreStatEffects? = nil
    var education: EducationEffects? = nil
    var career: CareerEffects? = nil
    var specialCareer: SpecialCareerEffects? = nil
    var military: MilitaryEffects? = nil
    var crime: CrimeEffects? = nil
    var finance: FinanceEffects? = nil
    var relationship: RelationshipEffects? = nil
    var health: HealthEffects? = nil
    var housing: HousingEffects? = nil
    var assets: AssetEffects? = nil
    var consequence: ConsequenceEffects? = nil
    var fame: FameEffects? = nil   // Fame Web F1
}

struct CoreStatEffects: Codable, Equatable {
    var happiness: Int? = nil
    var smarts: Int? = nil
    var looks: Int? = nil
    var health: Int? = nil
}

struct TrajectoryEffects: Codable, Equatable {
    var socioeconomicPressure: Int? = nil
    var familyStability: Int? = nil
    var educationalAccess: Int? = nil
    var socialCapital: Int? = nil
    var neighborhoodSafety: Int? = nil
    var resilience: Int? = nil
    var momentum: Int? = nil
    var setbackPressure: Int? = nil
    var luckWindow: Int? = nil
    var opportunityVisibility: Int? = nil
    var setLifePhase: LifePhase? = nil
    var setDirection: TrajectoryDirection? = nil
}

struct CareerEffects: Codable, Equatable {
    var performance: Int? = nil
    var yearsWorked: Int? = nil
    var setStatus: CareerStatus? = nil
    var setProfile: CareerProfile? = nil
    var setRoleID: String? = nil
    var incomeBonus: Int? = nil
    var promote: Bool? = nil
    var loseJob: Bool? = nil
    var burnout: Int? = nil
    var schedulePressure: Int? = nil
    var relationshipSpillover: Int? = nil
    var jobSecurity: Int? = nil
    var managerFriction: Int? = nil
    var scheduleControl: Int? = nil
    var retrainingProgress: Int? = nil
    var setRetrainingTargetProfile: CareerProfile? = nil
    var setOpenDoor: CareerOpportunityDoor? = nil
    var clearOpenDoor: Bool? = nil

    init(
        performance: Int? = nil,
        yearsWorked: Int? = nil,
        setStatus: CareerStatus? = nil,
        setProfile: CareerProfile? = nil,
        setRoleID: String? = nil,
        incomeBonus: Int? = nil,
        promote: Bool? = nil,
        loseJob: Bool? = nil,
        burnout: Int? = nil,
        schedulePressure: Int? = nil,
        relationshipSpillover: Int? = nil,
        jobSecurity: Int? = nil,
        managerFriction: Int? = nil,
        scheduleControl: Int? = nil,
        retrainingProgress: Int? = nil,
        setRetrainingTargetProfile: CareerProfile? = nil,
        setOpenDoor: CareerOpportunityDoor? = nil,
        clearOpenDoor: Bool? = nil
    ) {
        self.performance = performance
        self.yearsWorked = yearsWorked
        self.setStatus = setStatus
        self.setProfile = setProfile
        self.setRoleID = setRoleID
        self.incomeBonus = incomeBonus
        self.promote = promote
        self.loseJob = loseJob
        self.burnout = burnout
        self.schedulePressure = schedulePressure
        self.relationshipSpillover = relationshipSpillover
        self.jobSecurity = jobSecurity
        self.managerFriction = managerFriction
        self.scheduleControl = scheduleControl
        self.retrainingProgress = retrainingProgress
        self.setRetrainingTargetProfile = setRetrainingTargetProfile
        self.setOpenDoor = setOpenDoor
        self.clearOpenDoor = clearOpenDoor
    }
}

struct SpecialCareerEffects: Codable, Equatable {
    var setTrack: SpecialCareerTrack? = nil
    var tier: Int? = nil
    var fame: Int? = nil
    var audience: Int? = nil
    var heat: Int? = nil
    var notoriety: Int? = nil
    var burnout: Int? = nil
    var yearsActive: Int? = nil
    var lastPayout: Int? = nil
    var exitTrack: Bool? = nil
}

// Fame Web F1: Direct effects for the unified profile (used by actions, storylets, events)
struct FameEffects: Codable, Equatable {
    var culturalFame: Int? = nil
    var notoriety: Int? = nil
    var addKnownFor: String? = nil
}

struct CrimeEffects: Codable, Equatable {
    var setStatus: CrimeStatus? = nil
    var roleTier: Int? = nil
    var heat: Int? = nil
    var notoriety: Int? = nil
    var burnout: Int? = nil
    var crewID: String? = nil
    var loyalty: Int? = nil
    var territoryPressure: Int? = nil
    var yearsActive: Int? = nil
    var lastPayout: Int? = nil
    var exitCrime: Bool? = nil
}

struct EducationEffects: Codable, Equatable {
    var schoolStanding: Int? = nil
    var engagement: Int? = nil
    var attendancePressure: Int? = nil
    var activityMomentum: Int? = nil
    var schoolBelonging: Int? = nil
    var reputationRisk: Int? = nil
    var teacherSupport: Int? = nil
    var applicationReadiness: Int? = nil
    var campusFit: Int? = nil
    var burnoutRisk: Int? = nil
    var disciplineRecord: Int? = nil
    var mentorSupport: Int? = nil
    var peerPressure: Int? = nil
    var setPathway: EducationPathway? = nil
    var setStage: EducationStage? = nil
    var setAcademicTrack: AcademicTrack? = nil
    var yearsInStage: Int? = nil
    var setStudyFocus: StudyFocus? = nil
    var addCredential: String? = nil
    var hasScholarship: Bool? = nil
}

struct FinanceEffects: Codable, Equatable {
    var cashDelta: Int? = nil
    var annualIncomeDelta: Int? = nil
    var studentDebtDelta: Int? = nil
    var creditDebtDelta: Int? = nil
    var medicalDebtDelta: Int? = nil
    var livingCostDelta: Int? = nil
    var educationCostDelta: Int? = nil
    var dependentCostDelta: Int? = nil
    var discretionaryCostDelta: Int? = nil
    var financialStressDelta: Int? = nil
    var setRegionPolicyID: String? = nil
}

struct RelationshipEffects: Codable, Equatable {
    var meetNewFriend: Bool? = nil
    var friendChange: Int? = nil
    var startDating: Bool? = nil
    var partnerChange: Int? = nil
    var setPartnerStage: RelationshipStage? = nil
    var setCohabiting: Bool? = nil
    var commitmentAlignmentChange: Int? = nil
    var loseFriend: Bool? = nil
    var breakup: Bool? = nil
    var publicReputationChange: Int? = nil
    var privateReputationChange: Int? = nil
    var rumorHeatChange: Int? = nil
    var addKnownTag: String? = nil

    init(
        meetNewFriend: Bool? = nil,
        friendChange: Int? = nil,
        startDating: Bool? = nil,
        partnerChange: Int? = nil,
        setPartnerStage: RelationshipStage? = nil,
        setCohabiting: Bool? = nil,
        commitmentAlignmentChange: Int? = nil,
        loseFriend: Bool? = nil,
        breakup: Bool? = nil,
        publicReputationChange: Int? = nil,
        privateReputationChange: Int? = nil,
        rumorHeatChange: Int? = nil,
        addKnownTag: String? = nil
    ) {
        self.meetNewFriend = meetNewFriend
        self.friendChange = friendChange
        self.startDating = startDating
        self.partnerChange = partnerChange
        self.setPartnerStage = setPartnerStage
        self.setCohabiting = setCohabiting
        self.commitmentAlignmentChange = commitmentAlignmentChange
        self.loseFriend = loseFriend
        self.breakup = breakup
        self.publicReputationChange = publicReputationChange
        self.privateReputationChange = privateReputationChange
        self.rumorHeatChange = rumorHeatChange
        self.addKnownTag = addKnownTag
    }
}

struct HealthEffects: Codable, Equatable {
    var physical: Int? = nil
    var mental: Int? = nil
    var exercise: Int? = nil
    var nutrition: Int? = nil
    var stressManagement: Int? = nil
    var addCondition: String? = nil
    var removeCondition: String? = nil
    var hasPrimaryCare: Bool? = nil
}

struct HousingEffects: Codable, Equatable {
    var costBandDelta: Int? = nil
    var stabilityDelta: Int? = nil
    var setArrangement: LivingArrangement? = nil
    var hasRoommate: Bool? = nil
}

struct PerformanceBudgets {
    static let maxRenderedHistoryItems = 3
    /// Headroom for macro/NPC autonomy notes appended in the same tick as headline inserts.
    static let maxPersistedHistoryItems = 280
    static let eventPackWarningThreshold = 250
    static let saveSizeWarningBytes = 180_000
}

struct SimulationTimingEntry: Codable, Equatable, Identifiable {
    var id: String { label }
    var label: String
    var durationMilliseconds: Double
}

struct SimulationTimingSnapshot: Codable, Equatable {
    var totalAdvanceYearMilliseconds: Double = 0
    var eventPickMilliseconds: Double = 0
    var loadMilliseconds: Double = 0
    var saveMilliseconds: Double = 0
    var persistedHistoryCount: Int = 0
    var persistedSaveBytes: Int = 0
    var loadErrorCount: Int = 0
    var persistenceRecoverySource: String? = nil
    var restoredFromBackup: Bool = false
    var entries: [SimulationTimingEntry] = []
}

// MARK: - Helpers

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Array where Element == Relationship {
    var strongestBond: Int {
        map(\.bond).max() ?? 0
    }

    var strongestName: String? {
        self.max(by: { $0.bond < $1.bond })?.name
    }
}
import SwiftUI

/// OneLife Design System
/// Based on Codex IV (The UI/UX Manifesto) and Codex VII (The Summary-to-Action Pipeline).
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        static let background = Color.black
        static let secondaryBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
        static let surface = Color(red: 0.18, green: 0.18, blue: 0.18)
        
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.45)
        
        // Semantic Colors (Codex IV: Color as Data)
        static let positive = Color(red: 0.17, green: 0.48, blue: 0.27)
        static let neutral = Color(red: 0.23, green: 0.29, blue: 0.36)
        static let warning = Color(red: 0.68, green: 0.22, blue: 0.18)
        
        // Background Gradients
        static let lightBackgroundStart = Color(red: 0.95, green: 0.94, blue: 0.90)
        static let lightBackgroundEnd = Color(red: 0.88, green: 0.90, blue: 0.87)
        
        static let accent = Color.blue // Default Accent
    }
    
    // MARK: - Spacing (Codex VII)
    struct Spacing {
        static let micro: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        
        /// Natural Thumb Zone padding
        static let screenEdge: CGFloat = 20
    }
    
    // MARK: - Corner Radius
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let capsule: CGFloat = 999
    }
    
    // MARK: - Typography (Codex IV: Readability)
    struct Typography {
        static let titleLarge = Font.largeTitle.weight(.bold)
        static let titleMain = Font.title.weight(.bold)
        static let titleSecondary = Font.title2.weight(.bold)
        static let titleTertiary = Font.title3.weight(.bold)
        
        static let headline = Font.headline
        static let subheadline = Font.subheadline.weight(.semibold)
        
        static let body = Font.body
        static let bodyBold = Font.body.weight(.bold)
        
        static let footnote = Font.footnote
        static let caption = Font.caption.weight(.semibold)
        static let captionBold = Font.caption.weight(.bold)
        static let caption2 = Font.caption2
    }
}

// MARK: - PlannerTone (Relocated from ContentView)
enum PlannerTone: Equatable {
    case positive
    case neutral
    case warning
    
    var color: Color {
        switch self {
        case .positive: return DesignSystem.Colors.positive
        case .neutral: return DesignSystem.Colors.neutral
        case .warning: return DesignSystem.Colors.warning
        }
    }
    
    var fill: Color {
        color.opacity(0.12)
    }
}

extension PlannerTone {
    init(_ tone: YearlyOutcomeTone) {
        switch tone {
        case .positive:
            self = .positive
        case .neutral:
            self = .neutral
        case .warning:
            self = .warning
        }
    }
}
