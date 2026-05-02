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
}

enum StartMode: String, Codable, CaseIterable, Identifiable {
    case quickStart
    case template

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

enum ActionDomain: String, Codable, CaseIterable, Identifiable {
    case education
    case career
    case crime
    case finance
    case relationships
    case health

    var id: String { rawValue }
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
    case workHard
    case protectYourEnergy
    case network
    case retrain
    case takeOvertime
    case coast
    case jobHunt
    case chaseSpotlight
    case intenseTraining
    case compete
    case gatherIntelligence
    case exploitLeverage
    case dayTrade
    case analyzeMarkets
    case runScheme
    case buildCrew
    case cleanMoney
    case stepAway
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
    case buyStarterHome
    case refinanceMortgage
    case buildMaintenanceReserve
    case sellHome
    case findYourCrowd
    case dateCarefully
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

    var id: String { rawValue }

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

enum ActionFrictionLevel: String, Codable, Equatable {
    case none
    case resistance // Harder to press, visual jitter
    case warning // Red pulse, heavy haptics
    case locked // Cannot be selected due to state
}

struct ActionChoiceDefinition: Equatable {
    var choiceID: ActionChoiceID
    var title: String
    var subtitle: String
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
        case .runScheme:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Chase Fast Money", subtitle: "Speed over safety.", identityLine: "You decide the clean route is too slow for the pressure you are under.", previewTags: ["Fast cash", "Heat", "Stability loss"], preferredEventTags: ["money": 5, "risk": 8], microBeat: "You check over your shoulder.", baseFriction: .warning)
        case .buildCrew:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Build A Circle That Owes You", subtitle: "Power through people.", identityLine: "You choose influence and loyalty, knowing it will add pressure of its own.", previewTags: ["Loyalty", "Reach", "Pressure"], preferredEventTags: ["social": 5, "risk": 6], microBeat: "Making them an offer.", baseFriction: .warning)
        case .cleanMoney:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Make The Money Look Legit", subtitle: "Reduce heat at a cost.", identityLine: "You decide survival now depends on making your mess look stable.", previewTags: ["Heat down", "Cash cost", "Safety"], preferredEventTags: ["money": 4, "routine": 3], microBeat: "Scrubbing the trail.", baseFriction: .none)
        case .stepAway:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Back Away Before It Owns You", subtitle: "Choose air over pace.", identityLine: "You decide the year needs breathing room more than momentum.", previewTags: ["Exit risk", "Breathing room"], preferredEventTags: ["health": 5, "relationships": 2], microBeat: "Letting it go.", baseFriction: .none)
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
        case .buyStarterHome:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Make The Jump Into Ownership", subtitle: "Control with real weight attached.", identityLine: "You decide the next chapter should belong to you, even if the cost lingers.", previewTags: ["Equity", "Housing control", "Liquidity loss"], preferredEventTags: ["housing": 8, "money": 4], microBeat: "Signing the life away.", baseFriction: .resistance)
        case .refinanceMortgage:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Renegotiate The Weight", subtitle: "Buy breathing room.", identityLine: "You decide the year needs room to breathe more than pride about the original deal.", previewTags: ["Monthly cost down", "Breathing room", "Fees"], preferredEventTags: ["housing": 5, "money": 5], microBeat: "Changing the deal.", baseFriction: .none)
        case .buildMaintenanceReserve:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Prepare For The House To Ask Again", subtitle: "Plan for the next hit.", identityLine: "You decide stability means getting ahead of future problems before they arrive.", previewTags: ["Housing resilience", "Liquid cash down", "Surprise risk down"], preferredEventTags: ["housing": 7, "money": 4], microBeat: "Fortifying the walls.", baseFriction: .none)
        case .sellHome:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Cash Out And Reset", subtitle: "Trade permanence for flexibility.", identityLine: "You decide the year needs margin more than it needs roots.", previewTags: ["Cash", "Housing stability loss", "Flexibility"], preferredEventTags: ["housing": 6, "money": 5], microBeat: "Handing over the keys.", baseFriction: .none)
        case .findYourCrowd:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Find Your People", subtitle: "Belonging on purpose.", identityLine: "You decide this year should feel less lonely, even if it gets messy.", previewTags: ["Belonging", "School", "Support"], preferredEventTags: ["social": 8, "school": 3], microBeat: "Finally, someone laughs.", baseFriction: .none)
        case .dateCarefully:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Let Someone In Carefully", subtitle: "Connection with caution.", identityLine: "You open the door to closeness without pretending it cannot complicate the year.", previewTags: ["Bond", "Belonging", "Risk"], preferredEventTags: ["romance": 8, "social": 3], microBeat: "A tentative text.", baseFriction: .none)
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
        case .intenseTraining:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Push Your Physical Limits", subtitle: "Build the machine.", identityLine: "You decide your body is the only asset that matters this year.", previewTags: ["Peak up", "Burnout", "Injury risk"], preferredEventTags: ["health": 8, "routine": 5], microBeat: "The iron is heavy.", baseFriction: .resistance)
        case .compete:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Enter The Arena", subtitle: "Visibility through performance.", identityLine: "You step onto the stage where the only thing that matters is the result.", previewTags: ["Fame", "Fan base", "Injury risk"], preferredEventTags: ["career": 6, "social": 5, "risk": 4], microBeat: "Heartbeat in your ears.", baseFriction: .warning)
        case .gatherIntelligence:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Infiltrate The Circle", subtitle: "Trade trust for leverage.", identityLine: "You decide that knowing what others are hiding is the fastest way up.", previewTags: ["Leverage", "Exposure", "Suspicion"], preferredEventTags: ["social": 5, "risk": 7], microBeat: "Watching. Listening.", baseFriction: .warning)
        case .exploitLeverage:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Play Your Hand", subtitle: "Trade secrets for gain.", identityLine: "You decide it's time to cash in the favors and fears you've collected.", previewTags: ["Promotion shot", "Cash", "Exposure"], preferredEventTags: ["career": 7, "money": 5, "risk": 6], microBeat: "Checkmate.", baseFriction: .warning)
        case .dayTrade:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Trade The Volatility", subtitle: "Short-term focus.", identityLine: "You decide to chase the noise of the market instead of its signal.", previewTags: ["Cash", "Stress", "Market risk"], preferredEventTags: ["money": 8, "risk": 6], microBeat: "The tape is moving fast today.", baseFriction: .warning)
        case .analyzeMarkets:
            return ActionChoiceDefinition(choiceID: choiceID, title: "Study The Cycles", subtitle: "Trade activity for edge.", identityLine: "You decide patience and perspective are more profitable than adrenaline.", previewTags: ["Insight", "Capital access", "Patience"], preferredEventTags: ["money": 6, "routine": 5], microBeat: "The pattern emerges.", baseFriction: .none)
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
    var eventID: String? = nil
    var selectedChoiceText: String? = nil
    var reactionCards: [YearReactionCard] = []
    var currentReactionIndex: Int = 0
    var pendingSummary: YearlyOutcomeSummary? = nil
    var pendingConsequencePreview: ConsequencePreview? = nil
    var dominantUnresolvedConsequence: ConsequencePreview? = nil
    var pendingResolution: ResolutionPreview? = nil
    var pendingCrisis: CrisisInteraction? = nil
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

enum ArcDomain: String, Codable, CaseIterable, Identifiable {
    case education
    case career
    case finance
    case relationships
    case health
    case housing
    case family
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
}

struct GameState: Codable, Equatable {
    var player: Player = Player()
    var trajectory: TrajectoryState = TrajectoryState()
    var education: EducationState = EducationState()
    var career: CareerState = CareerState()
    var specialCareer: SpecialCareerState = SpecialCareerState()
    var crime: CrimeState = CrimeState()
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
    
    // Macro Autonomy
    var currentEra: WorldEra = .stable
    var eraYearsRemaining: Int = 10

    var activeYearChapter: ActiveYearChapter? = nil
    var pendingActions: [PlayerYearAction] = []
    var history: [HistoryEntry] = []
    var lastEventYearById: [String: Int] = [:]
    var startupState: StartupState = .choosingOrigin
    var originProfile: OriginProfile? = nil
    var openingSummary: String? = nil
    var isGameOver: Bool = false
    var hasUsedCrisisBuyBack: Bool = false // One-time safety net
    /// Procedural childhood backstory + career aptitude DNA. Set by ChildhoodGenerationEngine at character creation.
    var childhoodDossier: ChildhoodDossier? = nil

    private enum CodingKeys: String, CodingKey {
        case player
        case trajectory
        case education
        case career
        case specialCareer
        case crime
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
        case currentEra
        case eraYearsRemaining
        case activeYearChapter
        case pendingActions
        case history
        case lastEventYearById
        case startupState
        case originProfile
        case openingSummary
        case isGameOver
        case hasUsedCrisisBuyBack
        case childhoodDossier
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

        currentEra = try container.decodeIfPresent(WorldEra.self, forKey: .currentEra) ?? .stable
        eraYearsRemaining = try container.decodeIfPresent(Int.self, forKey: .eraYearsRemaining) ?? 10

        activeYearChapter = try container.decodeIfPresent(ActiveYearChapter.self, forKey: .activeYearChapter)
        pendingActions = try container.decodeIfPresent([PlayerYearAction].self, forKey: .pendingActions) ?? []
        history = try container.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? []
        lastEventYearById = try container.decodeIfPresent([String: Int].self, forKey: .lastEventYearById) ?? [:]
        startupState = try container.decodeIfPresent(StartupState.self, forKey: .startupState) ?? (player.traits.isEmpty ? .choosingOrigin : .active)
        originProfile = try container.decodeIfPresent(OriginProfile.self, forKey: .originProfile)
        openingSummary = try container.decodeIfPresent(String.self, forKey: .openingSummary)
        isGameOver = try container.decodeIfPresent(Bool.self, forKey: .isGameOver) ?? false
        hasUsedCrisisBuyBack = try container.decodeIfPresent(Bool.self, forKey: .hasUsedCrisisBuyBack) ?? false
        childhoodDossier = try container.decodeIfPresent(ChildhoodDossier.self, forKey: .childhoodDossier)
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

        if effects.partnerBond != 0, var partner = state.relationships.romanticPartner {
            partner.bond = (partner.bond + effects.partnerBond).clamped(to: 0...100)
            partner.commitmentAlignment = (partner.commitmentAlignment + effects.partnerCommitmentAlignment).clamped(to: 0...100)
            if effects.partnerBond <= -4 {
                partner.status = .strained
            } else if partner.bond >= 45 && partner.status == .strained {
                partner.status = .active
            }
            state.relationships.romanticPartner = partner
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
    case crime
    case risk
    case finance
    case relationships
    case health
    case housing
    case assets
    case progress
    case lifeEvent

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
    var spilloverSignals: [SpilloverSignal] = []
    var coreEffects: CoreStatEffects? = nil
    var trajectoryEffects: TrajectoryEffects? = nil
    var educationEffects: EducationEffects? = nil
    var careerEffects: CareerEffects? = nil
    var specialCareerEffects: SpecialCareerEffects? = nil
    var crimeEffects: CrimeEffects? = nil
    var financeEffects: FinanceEffects? = nil
    var relationshipEffects: RelationshipEffects? = nil
    var healthEffects: HealthEffects? = nil
    var housingEffects: HousingEffects? = nil
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
        }
    }
}

struct TraitSystem {
    func processMutations(player: inout Player, specialCareer: SpecialCareerState) -> [DomainNote] {
        var notes: [DomainNote] = []
        
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

        return notes
    }
    
    private func mutate(from: PersonalityTrait, to: PersonalityTrait, on player: inout Player) {
        if let index = player.traits.firstIndex(of: from) {
            player.traits[index] = to
        } else if player.traits.count < 3 {
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
    case unemployed
}

enum CareerProfile: String, Codable, CaseIterable {
    case stableAdmin
    case physicalLabor
    case serviceFrontline
    case creativeFreelance
    case credentialedProfessional

    var shortLabel: String {
        switch self {
        case .stableAdmin: return "Stable Admin"
        case .physicalLabor: return "Physical Labor"
        case .serviceFrontline: return "Service Frontline"
        case .creativeFreelance: return "Creative Freelance"
        case .credentialedProfessional: return "Credentialed Pro"
        }
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

enum SpecialCareerTrack: String, Codable, CaseIterable {
    case inactive
    case entertainment
    case crime
    case founder
    case athlete
    case shadowOperative
    case trader
    case ventureCapitalist
    case corporateRaider
}

struct CareerState: Codable, Equatable {
    var status: CareerStatus = .student
    var profile: CareerProfile = .stableAdmin
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
        careerExperience: [CareerExperienceTag: Int] = [:]
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
        clamp()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(CareerStatus.self, forKey: .status) ?? .student
        profile = try container.decodeIfPresent(CareerProfile.self, forKey: .profile) ?? .stableAdmin
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

struct FinanceState: Codable, Equatable {
    var cashOnHand: Int = 250
    var studentDebt: Int = 0
    var creditDebt: Int = 0
    var medicalDebt: Int = 0
    var investedBalance: Int = 0
    var indexFundBalance: Int = 0
    var stockPortfolioBalance: Int = 0
    var costBasis: Int = 0
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
        cashOnHand + investedBalance + homeDownPaymentSavings + homeEquity - totalNonHousingDebt
    }

    var totalNonHousingDebt: Int {
        studentDebt + creditDebt + medicalDebt
    }

    var hasInvestments: Bool {
        investedBalance > 0 || indexFundBalance > 0 || stockPortfolioBalance > 0
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

    var debt: DebtSettings
    var wealth: WealthSettings
    var homeownership: HomeownershipSettings
    var career: CareerSettings

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
        )
    )
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
    
    // Social Capital & Autonomy
    var influence: Int = 10 
    var profession: String? = nil
    var personality: NPCPersonality = .loyal
    var hiddenNeedLevel: Int = 0 // 0-100, triggers autonomous asks
    var hiddenResentment: Int = 0 // 0-100, triggers shifts or breakups

    static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        lhs.name == rhs.name &&
        lhs.type == rhs.type &&
        lhs.status == rhs.status &&
        lhs.bond == rhs.bond &&
        lhs.yearsKnown == rhs.yearsKnown &&
        lhs.stage == rhs.stage &&
        lhs.isCohabiting == rhs.isCohabiting &&
        lhs.commitmentAlignment == rhs.commitmentAlignment
    }
}

struct RelationshipState: Codable, Equatable {
    var friends: [Relationship] = []
    var romanticPartner: Relationship? = nil
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
        case romanticPartner
        case romanticPartners
        case ambientContacts
        case spouseName
        case publicReputation
        case privateReputation
        case activeRumorHeat
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
        if let romanticPartner = try container.decodeIfPresent(Relationship.self, forKey: .romanticPartner) {
            self.romanticPartner = romanticPartner
        } else if let legacyPartner = try container.decodeIfPresent([Relationship].self, forKey: .romanticPartners)?.first {
            var migratedPartner = legacyPartner
            let legacySpouseName = try container.decodeIfPresent(String.self, forKey: .spouseName)
            if legacySpouseName == migratedPartner.name {
                migratedPartner.stage = .married
            }
            self.romanticPartner = migratedPartner
        } else {
            self.romanticPartner = nil
        }
        ambientContacts = try container.decodeIfPresent([AmbientContact].self, forKey: .ambientContacts) ?? []
        publicReputation = try container.decodeIfPresent(Int.self, forKey: .publicReputation) ?? 50
        privateReputation = try container.decodeIfPresent(Int.self, forKey: .privateReputation) ?? 50
        activeRumorHeat = try container.decodeIfPresent(Int.self, forKey: .activeRumorHeat) ?? 10
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
        try container.encodeIfPresent(romanticPartner, forKey: .romanticPartner)
        try container.encode(ambientContacts, forKey: .ambientContacts)
        try container.encode(publicReputation, forKey: .publicReputation)
        try container.encode(privateReputation, forKey: .privateReputation)
        try container.encode(activeRumorHeat, forKey: .activeRumorHeat)
        try container.encode(knownForTags, forKey: .knownForTags)
        try container.encodeIfPresent(recentSocialHit, forKey: .recentSocialHit)
        try container.encodeIfPresent(recentSocialLift, forKey: .recentSocialLift)
        try container.encode(tensions, forKey: .tensions)
        try container.encode(futureAlignment, forKey: .futureAlignment)
    }

    var partnerName: String? { romanticPartner?.name }
    var hasPartner: Bool { romanticPartner != nil }
    var hasSpouse: Bool { romanticPartner?.stage == .married }
    var spouseName: String? {
        get { romanticPartner?.stage == .married ? romanticPartner?.name : nil }
        set {
            guard var romanticPartner else { return }
            if newValue == nil {
                if romanticPartner.stage == .married {
                    romanticPartner.stage = .committed
                }
            } else {
                romanticPartner.stage = .married
            }
            self.romanticPartner = romanticPartner
        }
    }
    var partnerStatus: RelationshipStatus? { romanticPartner?.status }
    var partnerBond: Int { romanticPartner?.bond ?? 0 }
    var partnerStage: RelationshipStage? { romanticPartner?.stage }
    var hasCohabitingPartner: Bool { romanticPartner?.isCohabiting == true }

    var romanticPartners: [Relationship] {
        get { romanticPartner.map { [$0] } ?? [] }
        set { romanticPartner = newValue.first }
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

    static func == (lhs: ChildRecord, rhs: ChildRecord) -> Bool {
        lhs.name == rhs.name &&
        lhs.age == rhs.age &&
        lhs.livesAtHome == rhs.livesAtHome &&
        lhs.otherParentName == rhs.otherParentName &&
        lhs.supportLoad == rhs.supportLoad
    }
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

struct AssetState: Codable, Equatable {
    var homeownershipTrackActive: Bool = false
    var targetHomeValue: Int = 0
    var primaryResidence: PrimaryResidenceState? = nil

    private enum CodingKeys: String, CodingKey {
        case homeownershipTrackActive
        case targetHomeValue
        case primaryResidence
        case ownsHome
    }

    init() {}

    init(homeownershipTrackActive: Bool = false, targetHomeValue: Int = 0, primaryResidence: PrimaryResidenceState? = nil) {
        self.homeownershipTrackActive = homeownershipTrackActive
        self.targetHomeValue = targetHomeValue
        self.primaryResidence = primaryResidence
        normalize()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        homeownershipTrackActive = try container.decodeIfPresent(Bool.self, forKey: .homeownershipTrackActive) ?? false
        targetHomeValue = try container.decodeIfPresent(Int.self, forKey: .targetHomeValue) ?? 0
        primaryResidence = try container.decodeIfPresent(PrimaryResidenceState.self, forKey: .primaryResidence)

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

struct ChoiceEffects: Codable, Equatable {
    var core: CoreStatEffects? = nil
    var education: EducationEffects? = nil
    var career: CareerEffects? = nil
    var specialCareer: SpecialCareerEffects? = nil
    var crime: CrimeEffects? = nil
    var finance: FinanceEffects? = nil
    var relationship: RelationshipEffects? = nil
    var health: HealthEffects? = nil
    var housing: HousingEffects? = nil
    var consequence: ConsequenceEffects? = nil
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
    static let maxPersistedHistoryItems = 240
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
