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

    static let firstAgeUpReflection = "Quick actions give instant feedback and build momentum. Age Up commits to a full year shaped by what you've been doing."

    static let lifeShapeCarryPhrase = "This will carry into your life shape and what the world offers in quieter years."
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

/// Tier A cache: household at-a-glance for People tab when family phase is active.
struct FamilyHouseholdSnapshot: Equatable {
    var atHomeCount: Int = 0
    var adultCount: Int = 0
    var pregnancyActive: Bool = false
    var strongestBondChildName: String?
    var strongestBondValue: Int = 0
    var topPressureLine: String?
    var headlineChildLine: String?
    var bannerLine: String?

    static let empty = FamilyHouseholdSnapshot()

    static func build(from family: FamilyState, bannerLine: String? = nil) -> FamilyHouseholdSnapshot {
        let atHome = family.children.filter(\.livesAtHome)
        let adults = family.children.filter { !$0.livesAtHome }
        let strongest = atHome.max(by: { $0.bondWithPlayer < $1.bondWithPlayer })

        var pressure: String?
        if family.isPregnant {
            pressure = "Pregnancy active — planning and energy both spike."
        } else if family.postpartumYearsRemaining > 0 {
            pressure = "Postpartum — extra support load on the household."
        } else if let strained = adults
            .filter({ ($0.adultProfile?.relationshipQuality ?? 55) < 35 })
            .min(by: { ($0.adultProfile?.relationshipQuality ?? 55) < ($1.adultProfile?.relationshipQuality ?? 55) }) {
            pressure = "\(strained.name) feels distant — strained adult bond."
        } else if let highLoad = atHome.filter({ $0.supportLoad >= 60 }).max(by: { $0.supportLoad < $1.supportLoad }) {
            pressure = "\(highLoad.name) needs more support this year."
        } else if !atHome.isEmpty {
            let avgLoad = atHome.map(\.supportLoad).reduce(0, +) / atHome.count
            if avgLoad >= 55 {
                pressure = "Household support load is elevated."
            }
        }

        var headline: String?
        if let youngest = atHome.min(by: { lhs, rhs in
            lhs.age != rhs.age ? lhs.age < rhs.age : lhs.bondWithPlayer < rhs.bondWithPlayer
        }) {
            headline = youngest.currentVibe
        } else if let strainedAdult = adults.min(by: {
            ($0.adultProfile?.relationshipQuality ?? 55) < ($1.adultProfile?.relationshipQuality ?? 55)
        }) {
            headline = strainedAdult.currentVibe
        }

        return FamilyHouseholdSnapshot(
            atHomeCount: atHome.count,
            adultCount: adults.count,
            pregnancyActive: family.isPregnant,
            strongestBondChildName: strongest?.name,
            strongestBondValue: strongest?.bondWithPlayer ?? 0,
            topPressureLine: pressure,
            headlineChildLine: headline,
            bannerLine: bannerLine
        )
    }

    /// Youngest at-home child, or lowest-bond at-home when ages tie — for parenting previews and feedback.
    static func focusChildForParenting(in family: FamilyState) -> ChildRecord? {
        let atHome = family.children.filter(\.livesAtHome)
        guard !atHome.isEmpty else { return nil }
        return atHome.min(by: { lhs, rhs in
            lhs.age != rhs.age ? lhs.age < rhs.age : lhs.bondWithPlayer < rhs.bondWithPlayer
        })
    }
}

/// Detects family teach moments from year-to-year diffs (birth, leave-home).
enum FamilyDiscoverabilityMoments {
    static func applyYearDiff(
        before: FamilyState,
        after: FamilyState,
        discoverability: inout DiscoverabilityState
    ) {
        if after.childCount == 1, before.childCount == 0, !discoverability.seenFirstChildBornCoach {
            discoverability.pendingFamilyHouseholdBanner = DiscoverabilityTeaching.firstChildBornLine
        }

        guard !discoverability.seenFirstLeaveHomeCoach else { return }
        for child in after.children {
            guard let previous = before.children.first(where: { $0.id == child.id }) else { continue }
            if previous.livesAtHome, !child.livesAtHome {
                let age = child.leftHomeAtAge ?? child.age
                discoverability.pendingFamilyHouseholdBanner = DiscoverabilityTeaching.firstLeaveHomeLine(
                    name: child.name,
                    age: age
                )
                break
            }
        }
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

    static let longPressFooterLine = "Hold any action to preview before you tap. This biases the year before you Age Up."

    static let firstMomentumAgeUpLine = "Your recent moves carry into this year—the bars above Age Up show where."

    static let adultChildTransitionLine = "These are the same children from earlier years. Their outcomes now carry forward independently."

    static let adultChildFocusHistoryLine = "Their arc remembers your focus history—stance and time spent still echo."

    static let firstChildBornLine = "This child will remember how you show up."

    static func firstLeaveHomeLine(name: String, age: Int) -> String {
        "\(name) left at \(age) — their adult story starts now."
    }

    static let firstParentingActionLine = "Bond and development notes stack into who they become."

    static let momentumStripDetailLine = "High momentum in a domain biases events and softens pressure in the next Age Up. Built by focused instant actions — carries forward until you shift focus."

    static let dossierStanceCoachLine = "What you were at 14 still wires how the world answers you. Stance choices compound into your life shape."

    static let longPressDiscoveryPulseDetail = "Hold any Right Now action to see what it does before you commit. Try it on your next move."

    static func momentumStripIntroLine(resilience: LifeResilience) -> String {
        switch resilience {
        case .resilient:
            return "The purple strip tracks momentum from quick moves. Repeats in one lane bias the next year's events."
        case .grounded:
            return "The purple strip tracks momentum. Repeats land harder in Grounded—watch Body, Money, and People bars."
        }
    }

    static func lifeShapeIntroLine(shape: String, resilience: LifeResilience) -> String {
        let shapeNote = shape.contains("driven")
            ? "A driven shape pushes harder years and bigger upside."
            : shape.contains("loose")
                ? "Loose edges soften pressure but drift can compound."
                : "Your recent stances are writing a life shape that echoes in quiet years."
        switch resilience {
        case .resilient:
            return "Shape: \(shape). \(shapeNote)"
        case .grounded:
            return "Shape: \(shape). \(shapeNote) Grounded runs feel this at full weight."
        }
    }

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

    static func momentumDomainMicroHint(domain: ActionDomain, value: Int) -> String {
        let label = momentumDomainLabel(domain)
        switch domain {
        case .health:
            return "Building \(label) momentum (+\(value)) → next year favors recovery chances."
        case .finance:
            return "Building \(label) momentum (+\(value)) → next year favors money openings."
        case .relationships:
            return "Building \(label) momentum (+\(value)) → next year favors social pressure relief."
        default:
            return "Building \(label) momentum (+\(value)) → biases next year's events."
        }
    }

    static func resilienceForecastLine(resilience: LifeResilience, momentumVisible: Bool, recoveryTone: Bool) -> String? {
        switch resilience {
        case .grounded:
            if recoveryTone {
                return "Your Grounded stance made this recovery feel earned."
            }
            if momentumVisible {
                return "Grounded — fighting back hits harder. Momentum still carries at full weight."
            }
            return nil
        case .resilient:
            if momentumVisible {
                return "Resilient years compound — the speed is still in your bones."
            }
            if recoveryTone {
                return "Resilient room let this year bend back without breaking."
            }
            return nil
        }
    }

    static func resilienceYearSummaryLine(resilience: LifeResilience, hadRecovery: Bool, momentumCarried: Bool) -> String? {
        if hadRecovery {
            return resilienceForecastLine(resilience: resilience, momentumVisible: momentumCarried, recoveryTone: true)
        }
        if momentumCarried {
            return resilienceForecastLine(resilience: resilience, momentumVisible: true, recoveryTone: false)
        }
        return nil
    }

    /// D4 / momentum consequence lines appended to long-press previews (1–2 when relevant).
    static func previewContextLines(choiceID: ActionChoiceID, domain: ActionDomain, state: GameState) -> [String] {
        let parentingIDs: Set<ActionChoiceID> = [
            .spendTimeWithKids, .checkInOnChild, .enforceRoutine, .encourageIndependence
        ]
        if parentingIDs.contains(choiceID) {
            return familyParentingPreviewLines(choiceID: choiceID, state: state)
        }

        let definition = ActionChoiceCatalog.definition(for: choiceID)
        let tagBlob = (definition.previewTags + [definition.subtitle, definition.identityLine])
            .joined(separator: " ")
            .lowercased()
        let careerWeight = definition.preferredEventTags["career"] ?? 0
        var lines: [String] = []

        let protectiveIDs: Set<ActionChoiceID> = [
            .rest, .protectSleep, .seeDoctor, .protectYourEnergy, .repairTension,
            .takeRealBreak, .recoveryFocus, .therapySession
        ]
        let looseIDs: Set<ActionChoiceID> = [
            .coast, .skipAndDrift, .spendForRelief, .spendToCope
        ]
        let driven = careerWeight >= 6
            || tagBlob.contains("performance")
            || tagBlob.contains("grind")
            || tagBlob.contains("overtime")
            || tagBlob.contains("compete")
            || tagBlob.contains("training")
            || tagBlob.contains("hustle")
        let protective = protectiveIDs.contains(choiceID)
            || tagBlob.contains("rest")
            || tagBlob.contains("recovery")
            || tagBlob.contains("protect")
            || tagBlob.contains("mental relief")
            || tagBlob.contains("therapy")
        let loose = looseIDs.contains(choiceID)
            || tagBlob.contains("drift")
            || tagBlob.contains("cope")
            || tagBlob.contains("relief")

        if driven {
            lines.append("This pushes your life shape toward driven current and will color quiet years.")
        } else if protective {
            if state.resilience == .grounded {
                lines.append("This leans protective — Grounded mode will make the payoff hit harder later.")
            } else {
                lines.append("This leans protective — recovery room carries into quieter years.")
            }
        } else if loose {
            lines.append("This nudges toward loose edges — quieter years will feel more drift.")
        }

        switch domain {
        case .health:
            lines.append("Builds momentum in Health that softens next year's pressure.")
        case .finance:
            lines.append("Builds momentum in Money that biases next year's financial openings.")
        case .relationships:
            lines.append("Builds momentum in People that shapes social pressure next year.")
        default:
            break
        }

        if lines.isEmpty {
            lines.append(TwoSpeedTeaching.lifeShapeCarryPhrase)
        } else if lines.count == 1, !lines[0].contains("life shape") {
            lines.append(TwoSpeedTeaching.lifeShapeCarryPhrase)
        }

        return Array(lines.prefix(2))
    }

    private static func familyParentingPreviewLines(choiceID: ActionChoiceID, state: GameState) -> [String] {
        guard let child = FamilyHouseholdSnapshot.focusChildForParenting(in: state.family) else {
            return ["Parenting actions shape who your kids become over time."]
        }
        let temp = child.temperament.shortDescription
        var lines: [String] = []
        switch choiceID {
        case .spendTimeWithKids:
            lines.append("\(child.name) is \(temp) — presence lands fast on sensitive kids.")
        case .checkInOnChild:
            lines.append("Check in with \(child.name) (\(temp)) — bond stacks into adult outcomes.")
        case .enforceRoutine:
            lines.append("Structure hits \(temp) temperaments differently — watch \(child.name)'s bond.")
        case .encourageIndependence:
            lines.append("\(child.name)'s \(temp) streak shapes how independence lands.")
        default:
            break
        }
        lines.append("Feeds development notes → who they become as adults.")
        return Array(lines.prefix(2))
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
    /// Tier 2: auto-expanded momentum strip intro (first time strip appears).
    var seenMomentumStripIntro: Bool = false
    /// Tier 2: first time life shape surfaces in the momentum strip.
    var seenLifeShapeTeach: Bool = false
    /// Tier 2: dossier + stance compounding coach (early life).
    var seenDossierStanceCoach: Bool = false
    /// First Age Up reflection in year summary (instant ↔ yearly loop).
    var seenFirstAgeUpReflection: Bool = false
    /// Family polish: first child born, first leave-home, first parenting action.
    var seenFirstChildBornCoach: Bool = false
    var seenFirstLeaveHomeCoach: Bool = false
    var seenFirstParentingActionCoach: Bool = false
    /// Auto-dismiss household strip banner (birth / leave-home / parenting teach).
    var pendingFamilyHouseholdBanner: String? = nil

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
    mutating func markMomentumStripIntroSeen() { seenMomentumStripIntro = true }
    mutating func markLifeShapeTeachSeen() { seenLifeShapeTeach = true }
    mutating func markDossierStanceCoachSeen() { seenDossierStanceCoach = true }
    mutating func markFirstAgeUpReflectionSeen() { seenFirstAgeUpReflection = true }
    mutating func markFirstChildBornCoachSeen() { seenFirstChildBornCoach = true }
    mutating func markFirstLeaveHomeCoachSeen() { seenFirstLeaveHomeCoach = true }
    mutating func markFirstParentingActionCoachSeen() { seenFirstParentingActionCoach = true }

    mutating func clearFamilyHouseholdBanner() {
        if let banner = pendingFamilyHouseholdBanner {
            if banner == DiscoverabilityTeaching.firstChildBornLine {
                seenFirstChildBornCoach = true
            } else if banner.contains("left at") {
                seenFirstLeaveHomeCoach = true
            } else if banner == DiscoverabilityTeaching.firstParentingActionLine {
                seenFirstParentingActionCoach = true
            }
        }
        pendingFamilyHouseholdBanner = nil
    }

    /// Whether to show inline teach under quick-action tray after first tap.
    func shouldShowFirstQuickActionTeach() -> Bool {
        performedFirstQuickAction && !seenFirstQuickActionTeach
    }

    /// Whether hold-to-preview badge should still appear.
    func shouldShowHoldHint() -> Bool {
        !seenFirstLongPressTeach
    }

    /// Auto-expand the momentum strip hint the first time momentum becomes visible.
    func shouldAutoExpandMomentumHint(momentumVisible: Bool) -> Bool {
        momentumVisible && !seenMomentumStripIntro
    }

    /// One contextual coach line at a time — priority: momentum → dossier → life shape.
    func pendingCoachLine(
        age: Int,
        momentumVisible: Bool,
        lifeShapeNonEmpty: Bool,
        earlyDossierActive: Bool
    ) -> String? {
        if momentumVisible, !seenMomentumStripIntro {
            return nil // handled by auto-expanded strip hint
        }
        if earlyDossierActive, age >= 14, age < 22, !seenDossierStanceCoach {
            return DiscoverabilityTeaching.dossierStanceCoachLine
        }
        if lifeShapeNonEmpty, !seenLifeShapeTeach {
            return nil // handled inline in momentum strip
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
        case .legal: return .legal
        case .family: return .family
        case .identity: return .progress
        case .play: return .progress
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

    static let empty = NowLaneSnapshot(
        headline: "",
        detail: "",
        quickActionTitle: nil,
        quickActionDomain: nil,
        quickActionChoice: nil,
        ageUpHint: "",
        tone: .neutral,
        showsQuickAction: false
    )
}

/// Smoothness Tier A: read-only momentum strip payload refreshed in `refreshDerivedState`.
struct MomentumStripSnapshot: Equatable {
    var showsStrip: Bool
    var momentum: InstantMomentumState
    var recentReactions: [String]
    var lifeShape: String
    var resilience: LifeResilience
    var seenMomentumStripIntro: Bool
    var seenLifeShapeTeach: Bool
    var shouldAutoExpandHint: Bool
    var topDomainMicroHint: String?

    static let empty = MomentumStripSnapshot(
        showsStrip: false,
        momentum: InstantMomentumState(),
        recentReactions: [],
        lifeShape: "",
        resilience: .resilient,
        seenMomentumStripIntro: false,
        seenLifeShapeTeach: false,
        shouldAutoExpandHint: false,
        topDomainMicroHint: nil
    )
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
        } else if age - startAge >= 8 {
            completed = true
        }
    }

    func isActive(at age: Int) -> Bool {
        guard let startAge, !completed else { return false }
        return age - startAge < 8
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
        hasYearStance: Bool,
        momentumVisible: Bool = false,
        lifeShapeNonEmpty: Bool = false
    ) -> String? {
        guard isActive(at: age) else { return nil }
        let step = elapsedYears(at: age)
        if !beatQuickActionDone, !performedQuickAction {
            return "Step 1: Tap a quick action below — instant feedback, no year lost."
        }
        if !beatHoldPreviewDone, !seenHoldCoach {
            return "Step 2: Hold any quick action to preview before you tap."
        }
        if !beatForecastCommitDone, !hasYearStance {
            return "Step 3: Age Up commits the year—momentum from quick moves carries forward."
        }
        if step <= 3 {
            return "Step 4: Finish the year cards, then repeat — quick moves stack momentum."
        }
        if step == 4, !momentumVisible {
            return "Step 5: Repeat quick actions in one lane — the purple momentum strip appears when a pattern builds."
        }
        if step == 5 {
            return "Step 6: Your \(lifeShapeNonEmpty ? "life shape" : "stances") quietly rewrite future years. Check the strip after Age Up."
        }
        if step == 6 {
            return "Step 7: Resilient vs Grounded changes recovery—tap the shield/triangle pill in the header to compare."
        }
        return "Step 8: You know the loop—quick moves, hold to preview, Age Up with a stance. Depth is in the pattern."
    }
}

