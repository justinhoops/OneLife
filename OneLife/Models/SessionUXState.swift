import Foundation

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

/// D4 life-shape tally from recent yearly stances (+ optional activity heat).
enum LifeShape: String, Codable, CaseIterable, Equatable {
    case pragmatic
    case carefulShape = "careful shape"
    case looseEdges = "loose edges"
    case drivenCurrent = "driven current"

    var label: String { rawValue }
}

enum LifeShapeResolver {
    static func resolve(recentStances: [YearlyStanceID], activityHeat: Int = 0) -> LifeShape? {
        guard !recentStances.isEmpty else { return nil }

        var pragmatic = 0, careful = 0, loose = 0, driven = 0
        for stance in recentStances {
            switch stance {
            case .stabilizeMoney: pragmatic += 1
            case .protectHealth: careful += 1
            case .letYearDrift: loose += 1
            case .pushCareer, .soldierStance, .studentStance: driven += 1
            default: pragmatic += 1
            }
        }
        if activityHeat >= 50 { driven += 1 }
        if loose > max(pragmatic, careful, driven) { return .looseEdges }
        if careful > max(pragmatic, loose, driven) { return .carefulShape }
        if driven > max(pragmatic, careful, loose) { return .drivenCurrent }
        return .pragmatic
    }

    static func resolve(from state: GameState, includeActivityHeat: Bool = false) -> LifeShape? {
        let heat = includeActivityHeat ? state.correlationLedger.recentActivityLevel : 0
        return resolve(recentStances: state.yearlyStance.recentStances, activityHeat: heat)
    }

    static func label(from state: GameState, includeActivityHeat: Bool = false) -> String {
        resolve(from: state, includeActivityHeat: includeActivityHeat)?.label ?? ""
    }

    static func resolveOrPragmatic(from state: GameState, includeActivityHeat: Bool = false) -> LifeShape {
        resolve(from: state, includeActivityHeat: includeActivityHeat) ?? .pragmatic
    }

    /// Newest-first consecutive stance streak (e.g. three pushCareer years in a row).
    static func stanceStreak(in state: GameState, minimum: Int = 3) -> YearlyStanceID? {
        let recent = state.yearlyStance.recentStances
        guard recent.count >= minimum else { return nil }
        let head = recent[0]
        guard recent.prefix(minimum).allSatisfy({ $0 == head }) else { return nil }
        return head
    }
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

/// Blunt first-session copy for the two-speed mental model (journal, coach banner, MVP steps).
enum TwoSpeedTeaching {
    static let line = "Tap Right Now to move the world a little — you get feedback immediately. Age Up commits a full year and lets bigger things compound. Use both."
}

/// Snapshot of instant momentum captured at Age Up — powers year-summary "From Your Moves" teach.
struct InstantMomentumCarrySnapshot: Codable, Equatable {
    var healthMomentum: Int = 0
    var financeMomentum: Int = 0
    var relationshipMomentum: Int = 0
    var overallStrength: Int = 0
    var capturedAtAge: Int = 0

    init(from momentum: InstantMomentumState, age: Int) {
        healthMomentum = momentum.healthMomentum
        financeMomentum = momentum.financeMomentum
        relationshipMomentum = momentum.relationshipMomentum
        overallStrength = momentum.overallStrength
        capturedAtAge = age
    }

    init() {}

    var rankedDomains: [(domain: ActionDomain, value: Int)] {
        [
            (.health, healthMomentum),
            (.finance, financeMomentum),
            (.relationships, relationshipMomentum)
        ]
        .filter { $0.value > 0 }
        .sorted { $0.value > $1.value }
    }
}

/// Inline teach copy for Slice A discoverability (decision-point micro-hints).
enum DiscoverabilityTeaching {
    static func firstQuickActionLine(resilience: LifeResilience) -> String {
        switch resilience {
        case .resilient:
            return "Repeats in one lane build momentum—the next Age Up forecast reads your pattern."
        case .grounded:
            return "Each repeat lands harder—momentum still shows on the forecast, but recovery is thinner."
        }
    }

    static let longPressFooterLine = "This biases the year before you Age Up."

    static let firstMomentumAgeUpLine = "Your recent moves carry into this year."

    static let adultChildFocusHistoryLine = "Their arc remembers your focus history—stance and time spent still echo."

    static func instantMomentumCarryLine(snapshot: InstantMomentumCarrySnapshot, resilience: LifeResilience) -> String {
        let parts = snapshot.rankedDomains.map { entry in
            "\(momentumDomainLabel(entry.domain)) +\(entry.value)"
        }
        let joined = parts.isEmpty ? "recent quick moves" : parts.joined(separator: " and ")
        switch resilience {
        case .resilient:
            return "\(joined) from quick actions shaped this year's opening pressure."
        case .grounded:
            return "\(joined) from quick actions hit the year at full weight—thin margins ahead."
        }
    }

    static func harshYearConsoleSubtitle(resilience: LifeResilience) -> String {
        switch resilience {
        case .grounded:
            return "Thin margins—stabilizing choices matter more before the next Age Up."
        case .resilient:
            return "You have recovery room—repeats and stance can still bend this year."
        }
    }

    private static func momentumDomainLabel(_ domain: ActionDomain) -> String {
        switch domain {
        case .health: return "Body"
        case .finance: return "Money"
        case .relationships: return "People"
        default: return domain.rawValue.capitalized
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
    var seenDiamondCoach: Bool = false // CT4-3 onboarding for first Diamond unlock
    /// Ages at which we already added a resilience reflection to the journal.
    var resilienceJournalAges: Set<Int> = []
    /// Slice A: inline decision-point teaches (once per life).
    var seenFirstQuickActionTeach: Bool = false
    var seenFirstLongPressTeach: Bool = false
    var seenFirstMomentumAgeUpTeach: Bool = false
    var seenInstantMomentumYearSummary: Bool = false

    mutating func markLongPressSeen() {
        seenLongPressCoach = true
        seenFirstLongPressTeach = true
    }

    mutating func markMomentumSeen() {
        seenMomentumCoach = true
        seenFirstMomentumAgeUpTeach = true
    }

    mutating func markResilienceExplainSeen() { seenResilienceExplain = true }
    mutating func markAdultChildrenSeen() { seenAdultChildrenCoach = true }
    mutating func markInstantYearlySeen() {
        seenInstantYearlyCoach = true
        seenFirstMomentumAgeUpTeach = true
    }

    mutating func markDiamondCoachSeen() { seenDiamondCoach = true }
    mutating func markFirstQuickActionTeachSeen() { seenFirstQuickActionTeach = true }
    mutating func markFirstLongPressTeachSeen() { markLongPressSeen() }
    mutating func markFirstMomentumAgeUpTeachSeen() { markMomentumSeen() }
    mutating func markInstantMomentumYearSummarySeen() { seenInstantMomentumYearSummary = true }

    /// Whether to show inline teach under quick-action tray after first tap.
    func shouldShowFirstQuickActionTeach() -> Bool {
        performedFirstQuickAction && !seenFirstQuickActionTeach
    }

    /// Whether hold-to-preview badge should still appear.
    func shouldShowHoldHint() -> Bool {
        !seenFirstLongPressTeach
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
        case .legal: return .legal
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
            return "Step 1: Tap a quick action below — instant feedback, no year lost."
        }
        if !beatHoldPreviewDone, !seenHoldCoach {
            return "Step 2: Hold any quick action to preview before you tap."
        }
        if !beatForecastCommitDone, !hasYearStance {
            return "Step 3: Age Up commits the year—momentum from quick moves carries forward."
        }
        return "Step 4: Finish the year cards, then repeat — quick moves stack momentum."
    }
}

