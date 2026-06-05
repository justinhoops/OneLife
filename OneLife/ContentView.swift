import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Premium surfaces (adapts light / dark)

private enum OLTheme {
    static func cardFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color.white.opacity(0.94)
    }

    static func cardStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
    }

    static func cardShadowOpacity(_ scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.5 : 0.08
    }

    static func subtleFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }
}

private enum HeaderOccupationCopy {
    static func specialCareer(_ track: SpecialCareerTrack) -> (title: String, symbol: String) {
        switch track {
        case .inactive:
            return ("", "briefcase.fill")
        case .entertainment:
            return ("Entertainment", "star.fill")
        case .movieActor:
            return ("Movie Actor", "theatermasks.fill")
        case .musicProducer:
            return ("Producer", "slider.horizontal.3")
        case .movieProducer:
            return ("Movie Producer", "film.fill")
        case .recordLabelOwner:
            return ("Record Label", "music.mic")
        case .coach:
            return ("Program Coach", "sportscourt.fill")
        case .crime:
            return ("Street Career", "flame.fill")
        case .founder:
            return ("Founder", "rocket.fill")
        case .athlete:
            return ("Athlete", "figure.run")
        case .shadowOperative:
            return ("Operative", "eye.fill")
        case .trader:
            return ("Trader", "chart.line.uptrend.xyaxis")
        case .ventureCapitalist:
            return ("Venture", "dollarsign.arrow.circlepath")
        case .corporateRaider:
            return ("Corporate Raider", "building.columns.fill")
        case .contentCreator:
            return ("Creator", "camera.fill")
        case .politics:
            return ("Politics", "person.3.fill")
        case .military:
            return ("Military", "shield.fill")
        default:
            return ("Career", "briefcase.fill")
        }
    }
}

struct PlannerInsight: Identifiable, Hashable {
    let title: String
    let value: String
    let tone: PlannerTone

    var id: String { title }
}

struct YearlyStanceChip: Identifiable, Hashable {
    let id: YearlyStanceID
    let title: String
    let detail: String
    let tone: PlannerTone
    let isSelected: Bool
}

struct RecommendedActionChip: Identifiable, Hashable {
    let id: String
    let domain: ActionDomain
    let choiceID: ActionChoiceID
    let title: String
    let relief: String
    let cost: String
    let tone: PlannerTone
}

struct OverviewSignal: Identifiable, Hashable {
    let symbol: String
    let title: String
    let value: String
    let tone: PlannerTone
    let insightTopic: ChangeInsightTopic?

    init(symbol: String, title: String, value: String, tone: PlannerTone, insightTopic: ChangeInsightTopic? = nil) {
        self.symbol = symbol
        self.title = title
        self.value = value
        self.tone = tone
        self.insightTopic = insightTopic
    }

    var id: String { title }
}

struct PressureSummary: Hashable {
    let symbol: String
    let title: String
    let detail: String
    let tone: PlannerTone
    let destination: PlannerDetailDestination?
}

struct RecommendedFocus: Hashable {
    let domain: ActionDomain?
    let choiceID: ActionChoiceID?
    let title: String
    let subtitle: String
    let previewTags: [String]
    let isSelected: Bool
}

struct TabOverviewModel: Hashable {
    let title: String
    let symbol: String
    let status: String
    let summary: String
    let tone: PlannerTone
    let trendLabel: String
    let detailDestination: PlannerDetailDestination?
    let topSignals: [OverviewSignal]
    let primaryPressure: PressureSummary
    let recommendedFocus: RecommendedFocus
    let stripTitle: String
    let stripItems: [String]
    var continuity: ContinuityHubModel? = nil
}

struct ContinuityHubItem: Identifiable, Hashable {
    let title: String
    let detail: String
    let tone: PlannerTone

    var id: String { "\(title)-\(detail)" }
}

struct ContinuityHubModel: Hashable {
    let status: String
    let changed: [ContinuityHubItem]
    let unresolved: [ContinuityHubItem]
    let comingBack: [String]
}

enum PlannerDetailDestination: String, Identifiable {
    case careerOverview
    case careerTrack
    case careerHistory
    case educationOverview
    case educationClimate
    case educationHistory
    case financeCashflow
    case financeInvesting
    case financePolicy
    case financeHistory
    case relationshipsConnections
    case relationshipsFamily
    case relationshipsHistory
    case healthOverview
    case healthConditions
    case healthHistory
    case lifeHousing
    case lifeLegacy
    case lifeHistory

    var id: String { rawValue }
}

enum FeedbackIntensitySetting: String, CaseIterable, Identifiable {
    case full
    case reduced
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .full: return "Full"
        case .reduced: return "Reduced"
        case .off: return "Off"
        }
    }
}

enum AutoLifePace: String, CaseIterable, Identifiable {
    case manual
    case guided
    case autopilot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual: return "Manual"
        case .guided: return "Guided"
        case .autopilot: return "Autopilot"
        }
    }
}

enum ColorEmphasisSetting: String, CaseIterable, Identifiable {
    case full
    case softened
    case muted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .full: return "Full"
        case .softened: return "Softened"
        case .muted: return "Muted"
        }
    }

    var saturation: Double {
        switch self {
        case .full: return 1.0
        case .softened: return 0.82
        case .muted: return 0.68
        }
    }
}

struct BackgroundPulseItem: Identifiable, Hashable {
    let title: String
    let detail: String
    let tone: PlannerTone

    var id: String { "\(title)-\(detail)" }
}

enum ChangeInsightTopic: String, CaseIterable, Identifiable, Hashable {
    case money
    case work
    case relationships
    case health

    var id: String { rawValue }

    var title: String {
        switch self {
        case .money: return "Money Pressure"
        case .work: return "Work Stability"
        case .relationships: return "Relationship Stability"
        case .health: return "Health"
        }
    }

    var symbol: String {
        switch self {
        case .money: return "dollarsign.circle.fill"
        case .work: return "briefcase.fill"
        case .relationships: return "person.2.fill"
        case .health: return "cross.case.fill"
        }
    }
}

struct ChangeInsightCard: Identifiable, Hashable {
    let topic: ChangeInsightTopic
    let headline: String
    let causes: [String]
    let implication: String?
    let tone: PlannerTone

    var id: String { topic.rawValue }
}

struct ActivityPulse: Equatable {
    let title: String
    let detail: String
    let tone: PlannerTone
}

/// Represents a floating delta that appears when an instant action has immediate visible impact.
/// This is core to making the frictionless system feel responsive.
struct FloatingDelta: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let tone: PlannerTone
    let domain: ActionDomain?
}

struct AgeUpRiskSignal: Identifiable, Hashable {
    let title: String
    let symbol: String
    let tone: PlannerTone

    var id: String { "\(symbol)-\(title)" }
}

struct CauseTrailItem: Identifiable, Hashable {
    let title: String
    let detail: String
    let tone: PlannerTone

    var id: String { "\(title)-\(detail)" }
}

struct PlannerReturnContext: Equatable {
    let tab: GameViewModel.Tab
    let destination: PlannerDetailDestination

    var title: String {
        switch destination {
        case .careerOverview: return "Back to Career Details"
        case .careerTrack: return "Back to Track Details"
        case .careerHistory: return "Back to Career History"
        case .educationOverview: return "Back to Education Details"
        case .educationClimate: return "Back to School Climate"
        case .educationHistory: return "Back to Education History"
        case .financeCashflow: return "Back to Cash Flow"
        case .financeInvesting: return "Back to Investing"
        case .financePolicy: return "Back to Policy And Housing"
        case .financeHistory: return "Back to Finance History"
        case .relationshipsConnections: return "Back to Connections"
        case .relationshipsFamily: return "Back to Family Planning"
        case .relationshipsHistory: return "Back to Relationship History"
        case .healthOverview: return "Back to Health Details"
        case .healthConditions: return "Back to Recovery Risks"
        case .healthHistory: return "Back to Health History"
        case .lifeHousing: return "Back to Housing Details"
        case .lifeLegacy: return "Back to Legacy Details"
        case .lifeHistory: return "Back to Life History"
        }
    }
}

private enum ContinuityLanguage {
    static func changedTitle(for showingEducation: Bool) -> String {
        showingEducation ? "School Path Shifted" : "Work And Money Shifted"
    }

    static func pressureTitle(for domain: GameViewModel.Tab, showingEducation: Bool) -> String {
        switch domain {
        case .home:
            return "Wellness & Activity Is Active"
        case .occupation:
            return showingEducation ? "School Pressure Is Active" : "Work Stability Is Active"
        case .assets:
            return "Financial Inventory Is Active"
        case .relationships:
            return "Relationship Pressure Is Active"
        case .history:
            return "Your Story Log Is Open"
        }
    }

    static func continuityStatus(changed: [ContinuityHubItem], unresolved: [ContinuityHubItem], comingBack: [String]) -> String {
        if !unresolved.isEmpty {
            return "Still active"
        }
        if !comingBack.isEmpty {
            return "Coming back later"
        }
        if !changed.isEmpty {
            return "This year moved"
        }
        return "No major carryover"
    }
}

final class GameViewModel: ObservableObject {
    private enum RuntimeOverrideKeys {
        static let testSaveDirectory = "ONELIFE_TEST_SAVE_DIR"
        static let testDefaultsSuite = "ONELIFE_TEST_DEFAULTS_SUITE"
        static let disableOpeningEvent = "ONELIFE_DISABLE_OPENING_EVENT"
    }

    private enum PreferenceKeys {
        static let hapticsSetting = "onelife.hapticsSetting"
        static let animationSetting = "onelife.animationSetting"
        static let colorEmphasisSetting = "onelife.colorEmphasisSetting"
    }

    enum Tab: String, CaseIterable, Identifiable {
        case home, occupation, assets, relationships, history

        /// Primary BitLife-style dock (journal/health live in the thumb-zone menu).
        static let dockTabs: [Tab] = [.home, .occupation, .assets, .relationships]

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home: return "Life"
            case .occupation: return "Work"
            case .assets: return "Money"
            case .relationships: return "Social"
            case .history: return "Journal"
            }
        }

        var symbol: String {
            switch self {
            case .home: return "figure.stand"
            case .occupation: return "briefcase.fill"
            case .assets: return "dollarsign.circle.fill"
            case .relationships: return "heart.fill"
            case .history: return "book.closed.fill"
            }
        }

        /// Matches `OneLifeUITests` dock button identifiers (`career-tab`, `finance-tab`, …).
        var uiTestTabIdentifier: String {
            switch self {
            case .home: return "home-tab"
            case .occupation: return "career-tab"
            case .assets: return "finance-tab"
            case .relationships: return "relationships-tab"
            case .history: return "history-tab"
            }
        }
    }

    func navShortTitle(for tab: Tab) -> String {
        switch tab {
        case .home:
            return "Life"
        case .occupation:
            return showingEducationAsPrimaryTab ? "School" : "Jobs"
        case .assets:
            return "Cash"
        case .relationships:
            return "Love"
        case .history:
            return "Log"
        }
    }

    @Published private(set) var state: GameState
    @Published var metaState: MetaState
    @Published var originPreview: GameState?
    @Published var latestYearSummary: YearlyOutcomeSummary?
    @Published var presentedCard: InteractionCardPayload?
    @Published var microBeatOverlay: String? = nil
    @Published var actionFrictionJitter: Bool = false
    /// Set immediately on popup button press (scrim/choice/continue). Causes processing/loading UI to appear
    /// (via Task.yield before heavy yearly resolve/refresh/save) so the card does not appear frozen.
    /// Mirrors the isStartingNewLife + loading pattern used for fresh game beginLifeSafely.
    @Published var isResolvingInteraction: Bool = false
    /// Optional context (e.g. event title) to show in the processing UI while isResolvingInteraction.
    @Published var resolvingInteractionContext: String? = nil
    @Published var selectedTab: Tab = .home {
        didSet {
            guard oldValue != selectedTab else { return }
            if returnPrompt?.tab != selectedTab {
                returnPrompt = nil
            }
            showingHealthConsole = false
        }
    }
    @Published var showingSettings: Bool = false
    /// Health console overlay (BitLife "Mind & Body" — not a main dock tab).
    @Published var showingHealthConsole: Bool = false
    @Published var autoLifePace: AutoLifePace = .guided
    @Published private(set) var autopilotYearsAdvanced: Int = 0
    @Published var selectedStartMode: StartMode = .quickStart
    @Published var selectedTemplate: OriginTemplateID = .stableHomeAverageMeans
    @Published var persistenceBanner: String?

    // MARK: Character Creation (Codex IX)
    @Published var charCreationStep: CharacterCreationStep = .name
    @Published var pendingCharName: String = ""
    @Published var pendingRegionID: String = "mountain_standard"
    @Published var pendingTraitOverride: PersonalityTrait? = nil
    @Published var selectedResilience: LifeResilience = .resilient   // Player-chosen "Life Feel" for replayability
    /// Recent autonomous "world reactions" from instant/quick actions. Powers the live frictionless feedback strip.
    @Published private(set) var recentInstantReactions: [String] = []
    @Published var autonomyToasts: [AutonomyToast] = []

    /// Currently visible floating deltas from instant actions (Phase 1 of UI overhaul).
    @Published private(set) var floatingDeltas: [FloatingDelta] = []

    func clearInstantReactions() {
        recentInstantReactions = []
    }

    /// Spawns floating delta visuals for instant actions (Phase 1 frictionless feedback polish).
    /// Now produces higher-quality, domain-aware deltas with better variety.
    func spawnFloatingDeltas(from result: DomainYearResult, domain: ActionDomain) {
        var newDeltas: [FloatingDelta] = []

        // Core stat deltas
        if let core = result.coreEffects {
            if let h = core.happiness, h != 0 {
                newDeltas.append(FloatingDelta(text: "\(h > 0 ? "+" : "")\(h) Happiness", tone: h > 0 ? .positive : .warning, domain: domain))
            }
            if let s = core.smarts, s != 0 {
                newDeltas.append(FloatingDelta(text: "\(s > 0 ? "+" : "")\(s) Smarts", tone: s > 0 ? .positive : .warning, domain: domain))
            }
            if let l = core.looks, l != 0 {
                newDeltas.append(FloatingDelta(text: "\(l > 0 ? "+" : "")\(l) Looks", tone: l > 0 ? .positive : .warning, domain: domain))
            }
            if let h = core.health, h != 0 {
                newDeltas.append(FloatingDelta(text: "\(h > 0 ? "+" : "")\(h) Health", tone: h > 0 ? .positive : .warning, domain: domain))
            }
        }

        // Autonomous world reaction deltas (these feel the most "alive")
        for note in result.notes where note.tags.contains(.progress) {
            let isReaction = note.title.contains("Responded") || note.title.contains("Noticed") || 
                            note.title.contains("Momentum") || note.title.contains("Body Responded") ||
                            note.title.contains("Financial System") || note.title.contains("Resourcefulness Echo")
            if isReaction {
                newDeltas.append(FloatingDelta(text: note.title, tone: .positive, domain: domain))
            }
        }

        // Health-specific autonomous boosts
        if let health = result.healthEffects {
            if let m = health.mental, m != 0 {
                newDeltas.append(FloatingDelta(text: "\(m > 0 ? "+" : "")\(m) Mental", tone: m > 0 ? .positive : .warning, domain: domain))
            }
        }

        guard !newDeltas.isEmpty else { return }

        // Limit concurrent deltas for visual cleanliness
        let maxConcurrent = 5
        if floatingDeltas.count + newDeltas.count > maxConcurrent {
            floatingDeltas.removeFirst(max(0, floatingDeltas.count + newDeltas.count - maxConcurrent))
        }

        floatingDeltas.append(contentsOf: newDeltas)

        // Staggered auto-removal for nicer feel
        let removalDelay = 2.4
        DispatchQueue.main.asyncAfter(deadline: .now() + removalDelay) { [weak self] in
            guard let self = self else { return }
            self.floatingDeltas.removeAll { delta in newDeltas.contains { $0.id == delta.id } }
        }
    }

    // P2: Universal deltas + pulses for yearly changes (parity with instant layer strength)
    func spawnYearlyDeltas(from summary: YearlyOutcomeSummary) {
        var newDeltas: [FloatingDelta] = []
        if let m = summary.momentum {
            newDeltas.append(FloatingDelta(text: "Momentum: \(m.title)", tone: .positive, domain: .career))
        }
        if let f = summary.focusOutcome {
            newDeltas.append(FloatingDelta(text: "Focus: \(f.title)", tone: .positive, domain: .career))
        }
        if let s = summary.yearlyStanceOutcome {
            newDeltas.append(FloatingDelta(text: "Stance: \(s.title)", tone: .positive, domain: .career))
        }
        if let t = summary.mainTradeoff {
            newDeltas.append(FloatingDelta(text: t.title, tone: .warning, domain: .career))
        }
        if let p = summary.nextYearPressure {
            newDeltas.append(FloatingDelta(text: p.title, tone: .warning, domain: .career))
        }
        guard !newDeltas.isEmpty else { return }
        let maxConcurrent = 5
        if floatingDeltas.count + newDeltas.count > maxConcurrent {
            floatingDeltas.removeFirst(max(0, floatingDeltas.count + newDeltas.count - maxConcurrent))
        }
        floatingDeltas.append(contentsOf: newDeltas)
        AppFeedback.impact(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            self.floatingDeltas.removeAll { delta in newDeltas.contains { $0.id == delta.id } }
        }
    }

    @Published var persistenceAlert: PersistenceAlertContext?
    @Published var showingDebugLab: Bool = false
    @Published var plannerDetail: PlannerDetailDestination?
    @Published var isStartingNewLife: Bool = false   // Prevents white screen during heavy fresh-game activation
    @Published var selectedInsight: ChangeInsightTopic?
    @Published private(set) var originTab: Tab?
    @Published private(set) var originPlannerDetail: PlannerDetailDestination?
    @Published private(set) var saveStatusBanner: String?
    @Published private(set) var returnPrompt: PlannerReturnContext?
    @Published private(set) var changeInsights: [ChangeInsightTopic: ChangeInsightCard] = [:]
    @Published var hapticsSetting: FeedbackIntensitySetting {
        didSet {
            defaults.set(hapticsSetting.rawValue, forKey: PreferenceKeys.hapticsSetting)
        }
    }
    @Published var animationSetting: FeedbackIntensitySetting {
        didSet {
            defaults.set(animationSetting.rawValue, forKey: PreferenceKeys.animationSetting)
        }
    }

    // P2: current life shape (D4, for reactive UI subtitles)
    var currentLifeShape: String {
        let recent = state.yearlyStance.recentStances
        guard !recent.isEmpty else { return "" }
        var pragmatic = 0, careful = 0, loose = 0, driven = 0
        for s in recent {
            switch s {
            case .stabilizeMoney: pragmatic += 1
            case .protectHealth: careful += 1
            case .letYearDrift: loose += 1
            case .pushCareer, .soldierStance, .studentStance: driven += 1
            default: pragmatic += 1
            }
        }
        if loose > max(pragmatic, careful, driven) { return "loose edges" }
        if careful > max(pragmatic, loose, driven) { return "careful shape" }
        if driven > max(pragmatic, careful, loose) { return "driven current" }
        return "pragmatic"
    }

    @Published var colorEmphasisSetting: ColorEmphasisSetting {
        didSet {
            defaults.set(colorEmphasisSetting.rawValue, forKey: PreferenceKeys.colorEmphasisSetting)
        }
    }
    @Published private(set) var historyDigest: HistoryDigest = .empty
    @Published private(set) var lastTimingSnapshot: SimulationTimingSnapshot?
    @Published private(set) var activityPulse: ActivityPulse?

    private let orchestrator = LifeSimulationOrchestrator()
    private let activitySystem = ActivitySystem()
    private let persistence: PersistenceCoordinator
    private let defaults: UserDefaults
    private let debugTestingCoordinator = DebugTestingCoordinator()
    private var interactionCards = InteractionCardCoordinator()
    private let feedbackCoordinator = FeedbackCoordinator()
    private var saveStatusTask: Task<Void, Never>?
    private var activityPulseTask: Task<Void, Never>?

    private static func defaultPersistence() -> PersistenceCoordinator {
        guard let directory = ProcessInfo.processInfo.environment[RuntimeOverrideKeys.testSaveDirectory] else {
            return .live
        }

        return PersistenceCoordinator(directoryProvider: {
            let url = URL(fileURLWithPath: directory, isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        })
    }

    private static func defaultDefaults() -> UserDefaults {
        guard let suiteName = ProcessInfo.processInfo.environment[RuntimeOverrideKeys.testDefaultsSuite],
              let defaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }

        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private static var shouldPresentOpeningEvent: Bool {
        ProcessInfo.processInfo.environment[RuntimeOverrideKeys.disableOpeningEvent] != "1"
    }

    init(
        persistence: PersistenceCoordinator = GameViewModel.defaultPersistence(),
        defaults: UserDefaults = GameViewModel.defaultDefaults(),
        debugConfiguration: DebugTestingConfiguration = .fromProcessInfo()
    ) {
        self.persistence = persistence
        self.defaults = defaults
        self.hapticsSetting = FeedbackIntensitySetting(rawValue: defaults.string(forKey: PreferenceKeys.hapticsSetting) ?? "") ?? .full
        self.animationSetting = FeedbackIntensitySetting(rawValue: defaults.string(forKey: PreferenceKeys.animationSetting) ?? "") ?? .full
        self.colorEmphasisSetting = ColorEmphasisSetting(rawValue: defaults.string(forKey: PreferenceKeys.colorEmphasisSetting) ?? "") ?? .full
        self.metaState = persistence.loadMeta()

        switch persistence.loadForStartup() {
        case .loaded(let result):
            self.state = result.state
            self.lastTimingSnapshot = result.timingSnapshot
            self.persistenceBanner = result.recoveryResult.userMessage
            configureStartupStateForLoadedGame()
            orchestrator.hydrateRuntimeCaches(for: result.state)
        case .noSave:
            // Fresh game: start in lightweight character creation flow immediately.
            // Defer ALL heavy setup (preview, beginLife, refresh, caches) to avoid main thread block / white screen.
            self.state = GameState()
            self.charCreationStep = .name
            // originPreview and heavy work kicked off in onAppear / beginLifeSafely
        case .failed(let primaryError, let errors, let timingSnapshot):
            self.state = GameState()
            self.charCreationStep = .name
            self.lastTimingSnapshot = timingSnapshot
            self.persistenceAlert = PersistenceAlertContext(
                title: "Couldn't Recover Saved Progress",
                message: persistenceMessage(for: primaryError, fallbacks: errors)
            )
        }
        // NO refresh or restore here in init - defer to views

        if let scenarioID = debugConfiguration.scenarioID {
            applyDebugPayload(
                debugTestingCoordinator.payload(for: scenarioID),
                scenarioID: scenarioID,
                modal: debugConfiguration.modal,
                shouldSave: true
            )
        }
    }

    func setupFreshGameIfNeeded() {
        if originPreview == nil && state.startupState != .active {
            originPreview = orchestrator.previewStart(mode: .quickStart, templateID: nil, meta: metaState)
            refreshDerivedState()
            restoreActiveChapterIfNeeded()
        }
    }

    func newLife() {
        // Reset to lightweight character creation immediately (avoid blocking launch with heavy beginLife work).
        state = GameState()
        originPreview = orchestrator.previewStart(mode: .quickStart, templateID: nil, meta: metaState, resilience: selectedResilience)
        autoLifePace = .guided
        selectedStartMode = .quickStart
        selectedTemplate = .stableHomeAverageMeans
        charCreationStep = .name
        pendingCharName = ""
        pendingRegionID = "mountain_standard"
        pendingTraitOverride = nil
        latestYearSummary = nil
        presentedCard = nil
        interactionCards.reset()
        activityPulse = nil
        isResolvingInteraction = false
        resolvingInteractionContext = nil
        selectedTab = .home
        plannerDetail = nil
        selectedInsight = nil
        originTab = nil
        originPlannerDetail = nil
        returnPrompt = nil
        persistenceBanner = nil
        isStartingNewLife = false
        clearPopupStateIfNeeded()
        // Heavy work (activatePreview, caches, etc.) will happen when user finishes creation via beginLifeSafely()
    }

    // Ensure loading flag is cleared on any full reset path
    func resetStartingLifeFlag() {
        isStartingNewLife = false
    }

    func ageUp() {
        guard !state.isGameOver else { return }
        if autoLifePace == .autopilot {
            runAutopilot()
            return
        }
        activityPulse = nil
        recentInstantReactions = []   // Clear instant reaction momentum on year turn (keeps focus on the new chapter)
        autopilotYearsAdvanced = 0
        captureReturnOrigin()
        AppFeedback.impact(.medium)
        applyGuidedPlanIfNeeded()

        let outcome = orchestrator.beginYearChapter(state: &state)
        if let summary = outcome.summary {
            latestYearSummary = summary
            surfaceFightingBackPulseIfNeeded(from: summary)
            evaluateSoftRunGoal(after: summary)
        }
        surfaceAutonomySignalsFromLedger()
        updateFirstLifeOnboarding(after: outcome)
        refreshSoftRunGoal()
        maintainDiscoverabilityAndResilienceJournal()
        present(cards: outcome.cards)
        refreshDerivedState()
        refreshSoftRunGoal()
        save()
    }

    /// Tier 1 Phase 4–5: contextual coaching flags + evolving resilience journal entries.
    func maintainDiscoverabilityAndResilienceJournal() {
        if let reflection = state.resilience.journalReflection(forAge: state.player.age),
           !state.discoverability.resilienceJournalAges.contains(state.player.age) {
            state.discoverability.resilienceJournalAges.insert(state.player.age)
            state.history.insert(
                HistoryEntry(age: state.player.age, title: reflection.title, text: reflection.text, tags: [.progress]),
                at: 0
            )
        }
    }

    func markLongPressCoachSeen() {
        guard !state.discoverability.seenLongPressCoach else { return }
        state.discoverability.markLongPressSeen()
        markMVPOnboardingHoldBeatIfNeeded()
        save()
    }

    func markMomentumCoachSeen() {
        guard !state.discoverability.seenMomentumCoach else { return }
        state.discoverability.markMomentumSeen()
        save()
    }

    func markResilienceExplainSeen() {
        guard !state.discoverability.seenResilienceExplain else { return }
        state.discoverability.markResilienceExplainSeen()
        save()
    }

    func markAdultChildrenCoachSeen() {
        guard !state.discoverability.seenAdultChildrenCoach else { return }
        state.discoverability.markAdultChildrenSeen()
        save()
    }

    func markInstantYearlyCoachSeen() {
        guard !state.discoverability.seenInstantYearlyCoach else { return }
        state.discoverability.markInstantYearlySeen()
        save()
    }

    /// Phase 5: Make "Fighting Back" land visibly when stabilizing choices pay off under pressure.
    private func surfaceFightingBackPulseIfNeeded(from summary: YearlyOutcomeSummary) {
        let fightingBack = (summary.spillovers + summary.headlines).first { $0.title == "Fighting Back" }
        guard let fightingBack else { return }
        let tone: PlannerTone = .positive
        activityPulse = ActivityPulse(
            title: fightingBack.title,
            detail: fightingBack.detail,
            tone: tone
        )
        showTransientActivityPulse()
        AppFeedback.notify(.success)
    }

    func recommendedYearlyStance() -> YearlyStanceID {
        // Side addition: dossier makes yearly focus feel like natural extension of childhood wiring (esp. in teen/early adult for immersion)
        if let d = state.childhoodDossier, state.player.age <= 22, state.education.stage != .inactive {
            if d.aptitudes.physical >= 60 {
                return .protectHealth  // body-first kids get nudged toward protecting the vehicle
            }
            if d.aptitudes.entrepreneurial >= 60 {
                return .stabilizeMoney // hustlers naturally gravitate to money focus
            }
            if d.aptitudes.social >= 60 {
                return .repairPeople
            }
            if d.aptitudes.creative >= 60 {
                return .studentStance // creative wiring makes academic focus feel more alive
            }
        }

        switch dominantFeedDomain() {
        case .finance:
            return .stabilizeMoney
        case .health:
            return .protectHealth
        case .relationships:
            return .repairPeople
        case .career, .education:
            return .pushCareer
        case .crime:
            return .protectHealth
        case .military:
            return .pushCareer
        case .family:
            return .repairPeople
        case .identity:
            return .stabilizeMoney
        }
    }

    func guidedRecommendation() -> RecommendedActionChip? {
        let pair = homeQuickActionChips().first
        guard let pair else { return nil }
        let definition = ActionChoiceCatalog.definition(for: pair.choiceID)
        let tradeoff = actionTradeoffLine(for: pair.choiceID)
        return RecommendedActionChip(
            id: "guided-\(pair.domain.rawValue)-\(pair.choiceID.rawValue)",
            domain: pair.domain,
            choiceID: pair.choiceID,
            title: definition.title,
            relief: tradeoff.relief,
            cost: whyActionMatters(pair.choiceID, domain: pair.domain),
            tone: definition.baseFriction == .warning || definition.baseFriction == .resistance ? .warning : .neutral
        )
    }

    func applyGuidedRecommendation() {
        let stance = recommendedYearlyStance()
        if state.yearlyStance.selectedStance == nil {
            setYearlyStance(stance)
        }
        if let recommendation = guidedRecommendation(),
           selectedAction(for: recommendation.domain) != recommendation.choiceID {
            setAction(recommendation.choiceID, for: recommendation.domain)
        }
    }

    func choose(_ choice: EventChoice) {
        guard case .event(let ev)? = presentedCard else { return }
        guard !isResolvingInteraction else { return }

        // Immediately signal processing so the popup UI can swap to loading/spinner (preventing "frozen on the popup" visual).
        // The actual (heavy) work is deferred via Task.yield so SwiftUI can commit the loading state first.
        isResolvingInteraction = true
        resolvingInteractionContext = ev.title
        let feedback = feedbackCoordinator.actionResponse(for: choice.baseFriction, microBeat: choice.microBeat)
        guard !feedback.shouldReturnEarly else {
            isResolvingInteraction = false
            resolvingInteractionContext = nil
            return
        }
        applyFeedback(feedback)

        Task { @MainActor in
            await Task.yield()
            if state.activeYearChapter != nil {
                let outcome = orchestrator.resolveYearChapter(choice: choice, state: &state)
                latestYearSummary = outcome.summary ?? latestYearSummary
                maintainDiscoverabilityAndResilienceJournal()
                present(cards: outcome.cards)
                refreshDerivedState()
                save()
            } else {
                orchestrator.apply(choice: choice, event: ev, state: &state)
                advancePresentedCard()
                orchestrator.syncActiveYearChapterProgress(state: &state, nextCard: presentedCard)
                refreshDerivedState()
                save()
            }
            isResolvingInteraction = false
            resolvingInteractionContext = nil
        }
    }

    private func applyGuidedPlanIfNeeded() {
        guard autoLifePace == .guided else { return }
        // Guided mode recommends the next move, but waits for the player to confirm it.
    }

    private func runAutopilot(maxYears: Int = 8) {
        guard !state.isGameOver, presentedCard == nil, state.activeYearChapter == nil else { return }
        activityPulse = nil
        autopilotYearsAdvanced = 0
        captureReturnOrigin()
        AppFeedback.impact(.medium)

        for _ in 0..<maxYears {
            let before = state
            applyAutopilotPlan()
            let outcome = orchestrator.beginYearChapter(state: &state)
            if let summary = outcome.summary {
                latestYearSummary = summary
            }
            autopilotYearsAdvanced += max(0, state.player.age - before.player.age)
            updateFirstLifeOnboarding(after: outcome)
            refreshDerivedState()

            if shouldStopAutopilot(before: before, outcome: outcome) {
                present(cards: outcome.cards)
                save()
                return
            }
        }

        activityPulse = ActivityPulse(
            title: "Autopilot Paused",
            detail: autopilotYearsAdvanced <= 1 ? "One quiet year resolved in the background." : "\(autopilotYearsAdvanced) quiet years resolved in the background.",
            tone: .neutral
        )
        showTransientActivityPulse()
        save()
    }

    private func applyAutopilotPlan() {
        let stance = recommendedYearlyStance()
        state.yearlyStance.selectedStance = stance
        if let domain = stance.domain,
           let choice = stance.preferredAction(for: state),
           actionChoices(for: domain).contains(choice) {
            state.pendingActions.removeAll { $0.domain == domain }
            state.pendingActions.append(PlayerYearAction(domain: domain, choiceID: choice))
        } else if let recommendation = guidedRecommendation() {
            state.pendingActions.removeAll { $0.domain == recommendation.domain }
            state.pendingActions.append(PlayerYearAction(domain: recommendation.domain, choiceID: recommendation.choiceID))
        }
    }

    private func shouldStopAutopilot(before: GameState, outcome: YearAdvanceOutcome) -> Bool {
        if !outcome.cards.isEmpty { return true }
        if state.isGameOver { return true }
        if state.player.health <= 35 || state.healthProfile.physicalWellness <= 35 || state.healthProfile.mentalWellness <= 30 { return true }
        if state.finance.totalWealth <= -15_000 || state.finance.cashOnHand <= -5_000 || state.finance.financialStress >= 75 { return true }
        if state.relationships.activeTensionCount > before.relationships.activeTensionCount || state.relationships.partnerStatus != before.relationships.partnerStatus { return true }
        if state.family.isPregnant != before.family.isPregnant || state.family.childCount != before.family.childCount { return true }
        if state.career.status != before.career.status || state.career.roleID != before.career.roleID { return true }
        if state.crime.status != before.crime.status || state.crime.heat >= 60 { return true }
        if state.narrativeArcs.currentMoodTone != before.narrativeArcs.currentMoodTone { return true }
        guard let summary = outcome.summary else { return false }
        let items = summary.headlines + summary.spillovers + [
            summary.topProblem,
            summary.checkpoint,
            summary.nextYearPressure,
            summary.yearlyStanceOutcome
        ].compactMap { $0 }
        return items.contains { item in
            item.tone == .warning || item.title.localizedCaseInsensitiveContains("milestone") || item.title.localizedCaseInsensitiveContains("legacy")
        }
    }

    private func updateFirstLifeOnboarding(after outcome: YearAdvanceOutcome) {
        guard state.mvpOnboarding.startAge != nil else { return }
        state.mvpOnboarding.advance(afterAge: state.player.age, hadMajorMoment: isMajorMoment(outcome))
    }

    private func isMajorMoment(_ outcome: YearAdvanceOutcome) -> Bool {
        if outcome.cards.contains(where: isMajorMomentCard) { return true }
        guard let summary = outcome.summary else { return false }
        let items = summary.headlines + summary.spillovers + [
            summary.topProblem,
            summary.checkpoint,
            summary.nextYearPressure,
            summary.yearlyStanceOutcome
        ].compactMap { $0 }
        return items.contains { $0.tone == .warning }
    }

    private func isMajorMomentCard(_ card: InteractionCardPayload) -> Bool {
        switch card {
        case .event, .reaction, .consequence, .resolution, .crisis, .pitchDeck:
            return true
        case .yearSummary, .forecast:
            return false
        }
    }

    func resolveCrisis(_ choice: CrisisChoice) {
        guard !isResolvingInteraction else { return }

        isResolvingInteraction = true
        resolvingInteractionContext = "crisis resolution"

        Task { @MainActor in
            await Task.yield()
            if choice.isBuyBack {
                state.hasUsedCrisisBuyBack = true
                // Apply Penalty logic
                if choice.id.contains("health") {
                    state.player.health = 20
                    state.healthProfile.physicalWellness = 20
                    state.healthProfile.activeConditions.append(HealthCondition(name: "Chronic Fragility", severity: 40))
                    state.relationships.socialCapital = max(0, state.relationships.socialCapital - 80)
                } else if choice.id.contains("finance") {
                    state.finance.cashOnHand = 10000
                    state.finance.financialStress = 70
                    state.assets.ownsHome = false
                    state.finance.indexFundBalance = 0
                    state.finance.stockPortfolioBalance = 0
                    state.finance.investedBalance = 0
                }
                
                AppFeedback.notify(.success)
                microBeatOverlay = "A heavy price paid for time."
            } else {
                state.isGameOver = true
                AppFeedback.notify(.warning)
            }
            
            // Core of dismiss (bypass the public guard since we manage the flag here)
            let currentCard = presentedCard
            let shouldCompleteLife = state.isGameOver && (currentCard != nil && isResolutionCard(currentCard!))
            advancePresentedCard()
            orchestrator.syncActiveYearChapterProgress(state: &state, nextCard: presentedCard)
            if presentedCard == nil {
                if shouldCompleteLife {
                    state.startupState = .inheritingLegacy
                } else {
                    restoreInteractionOriginIfNeeded()
                }
            }
            refreshDerivedState()
            save()
            clearPopupStateIfNeeded()
            isResolvingInteraction = false
            resolvingInteractionContext = nil
        }
    }

    func resolvePitch(_ choice: PitchDeckChoice) {
        guard !isResolvingInteraction else { return }

        isResolvingInteraction = true
        resolvingInteractionContext = "pitch deck"

        Task { @MainActor in
            await Task.yield()
            // Go through the system activate so dossier bias (from childhood origin) seeds the founder state.
            SpecialCareerSystem.activateSpecialCareerForPitch(track: .founder, sector: choice.sector, into: &state.specialCareer, dossier: state.childhoodDossier)
            // ensure the pitch-specific starting numbers
            state.specialCareer.equityOwned = 1.0
            state.specialCareer.audience = max(state.specialCareer.audience, 15)
            state.specialCareer.fame = max(state.specialCareer.fame, 10)
            state.specialCareer.heat = max(state.specialCareer.heat, 20)
            state.specialCareer.burnout = max(state.specialCareer.burnout, 10)
            
            AppFeedback.notify(.success)
            microBeatOverlay = "Launched: \(choice.text)"
            
            state.pendingActions.removeAll { $0.choiceID == .startCompany }
            
            // Core of dismiss (bypass guard)
            advancePresentedCard()
            orchestrator.syncActiveYearChapterProgress(state: &state, nextCard: presentedCard)
            if presentedCard == nil {
                restoreInteractionOriginIfNeeded()
            }
            refreshDerivedState()
            save()
            isResolvingInteraction = false
            resolvingInteractionContext = nil
        }
    }

    func advancePresentedCard() {
        presentedCard = interactionCards.advance()
    }

    func dismissPresentedCard() {
        guard let currentCard = presentedCard else { return }
        guard !isResolvingInteraction else { return }

        // Immediately signal processing for continue-style popups (summary, resolution, etc.).
        isResolvingInteraction = true
        resolvingInteractionContext = (currentCard as? CustomStringConvertible)?.description ?? "year outcome"

        // If we are dismissing a resolution card and the game is over, complete the life
        let shouldCompleteLife = state.isGameOver && isResolutionCard(currentCard)

        Task { @MainActor in
            await Task.yield()
            advancePresentedCard()
            orchestrator.syncActiveYearChapterProgress(state: &state, nextCard: presentedCard)

            if presentedCard == nil {
                if shouldCompleteLife {
                    state.startupState = .inheritingLegacy
                } else {
                    restoreInteractionOriginIfNeeded()
                }
            }
            refreshDerivedState()
            save()
            clearPopupStateIfNeeded()
            isResolvingInteraction = false
            resolvingInteractionContext = nil
        }
    }

    func switchToChild(_ child: ChildRecord) {
        let parentState = state
        orchestrator.completeLife(state: parentState, meta: &metaState)
        try? persistence.saveMeta(metaState)
        state = orchestrator.inheritLegacy(child: child, parentState: parentState)
        refreshDerivedState()
        save()
    }

    func finishLegacyWithoutSuccessor() {
        completeLife()
    }
    private func isResolutionCard(_ card: InteractionCardPayload) -> Bool {
        if case .resolution = card { return true }
        return false
    }

    func isChoiceCard(_ card: InteractionCardPayload) -> Bool {
        switch card {
        case .event, .crisis, .pitchDeck:
            return true
        case .forecast, .yearSummary, .reaction, .consequence, .resolution:
            return false
        }
    }

    /// Safety net called on shell changes / after heavy work to prevent stuck popups or desynced chapter/card state.
    func clearPopupStateIfNeeded() {
        if isResolvingInteraction { return } // let the resolving Task finish
        if presentedCard != nil {
            presentedCard = nil
        }
        if interactionCards.queuedCount > 0 {
            interactionCards.reset()
        }
        if state.activeYearChapter != nil && presentedCard == nil {
            // If no more cards but chapter lingered, clear it so next ageUp isn't confused.
            state.activeYearChapter = nil
        }
    }

    private func completeLife() {
        orchestrator.completeLife(state: state, meta: &metaState)
        try? persistence.saveMeta(metaState)
        newLife()
    }

    func openDetail(_ destination: PlannerDetailDestination) {
        originTab = selectedTab
        originPlannerDetail = destination
        plannerDetail = destination
    }

    func openInsight(_ topic: ChangeInsightTopic) {
        guard changeInsights[topic] != nil else { return }
        selectedInsight = topic
    }

    func reopenReturnDetail() {
        guard let prompt = returnPrompt, selectedTab == prompt.tab else { return }
        plannerDetail = prompt.destination
        returnPrompt = nil
    }

    func previewQuickStart() {
        selectedStartMode = .quickStart
        originPreview = orchestrator.previewStart(mode: .quickStart, templateID: nil, meta: metaState)
    }

    func previewTemplate(_ template: OriginTemplateID) {
        selectedStartMode = .template
        selectedTemplate = template
        originPreview = orchestrator.previewStart(mode: .template, templateID: template, meta: metaState)
    }

    func rerollOrigin() {
        switch selectedStartMode {
        case .quickStart:
            previewQuickStart()
        case .template:
            previewTemplate(selectedTemplate)
        case .custom:
            previewQuickStart() // Fallback to quickstart for custom reroll
        }
    }

    // MARK: - Character Creation Navigation (Codex IX)

    func advanceCreation() {
        let allSteps: [CharacterCreationStep] = [.name, .origin, .trait, .resilience]
        guard let current = allSteps.firstIndex(of: charCreationStep),
              current + 1 < allSteps.count else { return }
        // Auto-generate an origin preview when entering the origin step if none exists
        let next = allSteps[current + 1]
        if next == .origin && originPreview == nil {
            previewQuickStart()
        }
        charCreationStep = next
    }

    func retreatCreation() {
        let allSteps: [CharacterCreationStep] = [.name, .origin, .trait, .resilience]
        guard let current = allSteps.firstIndex(of: charCreationStep), current > 0 else { return }
        charCreationStep = allSteps[current - 1]
    }

    /// Applies a chosen trait override onto the current origin preview.
    /// Called before advancing from the trait step to preview.
    func applyPendingTraitToPreview() {
        guard var preview = originPreview, let trait = pendingTraitOverride else { return }
        var traits = preview.player.traits
        traits.removeAll { $0 == trait }
        traits.insert(trait, at: 0)
        preview.player.traits = Array(traits.prefix(3))
        // Re-gen dossier so aptitudes + visibleHints + future seeds in the rich creation preview update live.
        if let templateID = preview.originProfile?.templateID {
            let deterministic = selectedStartMode == .template
            orchestrator.regenerateDossierInPreview(&preview, templateID: templateID, deterministic: deterministic)
        }
        originPreview = preview
    }

    func beginLife() {
        guard var preview = originPreview else { return }

        // Apply character creation choices (Codex IX)
        let trimmedName = pendingCharName.trimmingCharacters(in: .whitespaces)
        preview.player.name = trimmedName.isEmpty ? randomCharacterName() : trimmedName
        preview.finance.currentRegionPolicyID = pendingRegionID
        
        // If it was a custom start, ensure the origin profile reflects that
        if selectedStartMode == .custom {
            preview.originProfile?.startMode = .custom
        }
        preview.mvpOnboarding.activate(at: preview.player.age)
        preview.discoverability = DiscoverabilityState()
        preview.softRunGoal = nil
        preview.resilience = selectedResilience
        preview.syncResilienceToPlayer()
        autoLifePace = .guided

        latestYearSummary = nil
        presentedCard = nil
        interactionCards.reset()
        activityPulse = nil
        let initialEvent = orchestrator.activatePreview(state: &preview)
        state = preview

        // Surface the player's chosen Life Feel immediately in the journal for transparency + replay reflection
        if state.history.isEmpty || state.history.first?.title != "Life Began" {
            let feelLine = state.resilience == .resilient
                ? "Chose a Resilient path — more room to recover when life gets heavy."
                : "Chose the Grounded path — full Life Killer weight, no safety nets."
            state.history.insert(
                HistoryEntry(age: state.player.age, title: "Life Began", text: feelLine, tags: [.progress]),
                at: 0
            )
        }

        // Phase 4 Discoverability: Lightweight first-time teaching of the two speeds
        if state.history.count <= 1 {
            let teachingLine = "Two speeds here: Quick actions (and some Family choices) give instant feedback and small world reactions. Age Up commits to a full year of consequences that compound."
            state.history.insert(
                HistoryEntry(age: state.player.age, title: "How This Life Works", text: teachingLine, tags: [.progress]),
                at: 0
            )
        }

        originPreview = nil
        selectedTab = .home
        plannerDetail = nil
        selectedInsight = nil
        originTab = nil
        originPlannerDetail = nil
        returnPrompt = nil
        if Self.shouldPresentOpeningEvent, let initialEvent {
            present(cards: [.event(initialEvent)])
        }
        refreshDerivedState()
        refreshSoftRunGoal()
        save()
    }

    /// Safe wrapper for fresh game confirmation.
    /// Sets loading flag *before* the heavy synchronous work so the UI can show an overlay instead of white.
    func beginLifeSafely() {
        guard !isStartingNewLife else { return }
        isStartingNewLife = true
        Task { @MainActor in
            await Task.yield()
            beginLife()
            isStartingNewLife = false
        }
    }

    func save() {
        do {
            try? persistence.saveMeta(metaState)
            let persistenceResult: PersistenceSaveResult
            #if DEBUG
            let saveStart = CFAbsoluteTimeGetCurrent()
            persistenceResult = try persistence.save(state)
            var snapshot = orchestrator.latestTimingSnapshot ?? lastTimingSnapshot ?? SimulationTimingSnapshot()
            snapshot.saveMilliseconds = ((CFAbsoluteTimeGetCurrent() - saveStart) * 1_000).rounded()
            snapshot.persistedHistoryCount = persistenceResult.timingSnapshot.persistedHistoryCount
            snapshot.persistedSaveBytes = persistenceResult.timingSnapshot.persistedSaveBytes
            snapshot.loadErrorCount = persistenceResult.timingSnapshot.loadErrorCount
            snapshot.persistenceRecoverySource = persistenceResult.timingSnapshot.persistenceRecoverySource
            snapshot.restoredFromBackup = persistenceResult.timingSnapshot.restoredFromBackup
            if !persistenceResult.timingSnapshot.entries.isEmpty {
                snapshot.entries = persistenceResult.timingSnapshot.entries
            }
            lastTimingSnapshot = snapshot
            #else
            persistenceResult = try persistence.save(state)
            #endif

            if let warning = persistenceResult.warning {
                persistenceBanner = warning.errorDescription
            } else if persistenceBanner?.contains("Couldn't save") == true {
                persistenceBanner = nil
            }
            showTransientSaveStatus()
        } catch let error as PersistenceError {
            persistenceBanner = error.errorDescription
        } catch {
            persistenceBanner = error.localizedDescription
        }
    }

    func resetSave() {
        do {
            try persistence.reset()
            newLife()
        } catch let error as PersistenceError {
            persistenceBanner = error.errorDescription
        } catch {
            persistenceBanner = "Couldn't reset saved progress. \(error.localizedDescription)"
        }
    }

    var filteredTemplates: [OriginTemplateDefinition] {
        OriginCatalog.templates.filter { template in
            switch template.id {
            case .wealthyDynasty:
                return metaState.generationFlags.contains("wealthy_dynasty")
            case .academicLegacy:
                return metaState.generationFlags.contains("academic_legend")
            default:
                return true
            }
        }
    }

    func roleTitle() -> String {
        orchestrator.roleTitle(for: state.career)
    }

    /// Header cash line: `$420` or `-$620` for negative balances.
    func formattedCashOnHand() -> String {
        let cash = state.finance.cashOnHand
        if cash >= 0 {
            return "$\(cash)"
        }
        return "-$\(abs(cash))"
    }

    /// Primary occupation / education / special-career badge for the life header.
    func headerOccupationHighlight() -> (title: String, symbol: String, tone: PlannerTone) {
        if state.military.track != .inactive {
            return (state.military.rank, "shield.fill", .positive)
        }
        if state.relationships.isMarried {
            return ("Married to \(state.relationships.partnerName ?? "Partner")", "heart.fill", .positive)
        }
        if state.specialCareer.track != .inactive {
            let pair = HeaderOccupationCopy.specialCareer(state.specialCareer.track)
            return (pair.title, pair.symbol, .warning)
        }
        if showingEducationAsPrimaryTab {
            switch state.education.stage {
            case .university:
                return ("University", "graduationcap.fill", .neutral)
            case .tradeTraining:
                return ("Trade School", "hammer.fill", .neutral)
            default:
                if state.player.age >= 18, state.education.pathway == .graduate, state.education.stage == .inactive {
                    return ("Graduate", "checkmark.seal.fill", .positive)
                }
                return ("Student", "book.closed.fill", .neutral)
            }
        }
        switch state.career.status {
        case .unemployed:
            let title = roleTitle()
            return (title.isEmpty ? "Unemployed" : title, "briefcase.circle.fill", .warning)
        default:
            return (roleTitle(), "briefcase.fill", .positive)
        }
    }

    var showingEducationAsPrimaryTab: Bool {
        state.player.age < 18 || state.education.stage != .inactive || state.education.pathway == .student || state.education.pathway == .training
    }

    var isTeenExperience: Bool {
        (14...17).contains(state.player.age)
    }

    var isStudentLifeExperience: Bool {
        (14...22).contains(state.player.age) && state.education.stage != .inactive
    }

    var investmentEmergencyReserve: Int {
        6_000
    }

    var canAccessInvesting: Bool {
        state.player.age >= 18 && (
            state.finance.hasInvestments ||
            state.finance.isEligibleToCompound(emergencyReserve: investmentEmergencyReserve)
        )
    }

    func tabTitle(for tab: Tab) -> String {
        switch tab {
        case .occupation where showingEducationAsPrimaryTab:
            return "Education"
        default:
            return tab.title
        }
    }

    func tabSymbol(for tab: Tab) -> String {
        switch tab {
        case .occupation where showingEducationAsPrimaryTab:
            return "book.closed.fill"
        default:
            return tab.symbol
        }
    }

    func summaryItems(for tab: Tab) -> [YearlyOutcomeItem] {
        guard let latestYearSummary else { return [] }

        let matchedDomains: Set<HistoryDomainTag>
        switch tab {
        case .home:
            return feedSummaryItems()
        case .occupation:
            matchedDomains = showingEducationAsPrimaryTab ? [.education, .progress] : [.career, .crime, .progress]
        case .assets:
            matchedDomains = [.finance, .housing, .progress]
        case .relationships:
            matchedDomains = [.relationships, .lifeEvent, .progress]
        case .history:
            matchedDomains = Set(HistoryDomainTag.allCases)
        }

        let items = latestYearSummary.headlines + latestYearSummary.spillovers
        return Array(items.filter { matchedDomains.contains($0.domain) }.prefix(2))
    }

    /// Year headlines for the Life Feed sheet (cross-domain glance).
    func feedSummaryItems() -> [YearlyOutcomeItem] {
        guard let latestYearSummary else { return [] }
        let matchedDomains = Set(HistoryDomainTag.allCases)
        let items = latestYearSummary.headlines + latestYearSummary.spillovers
        return Array(items.filter { matchedDomains.contains($0.domain) }.prefix(3))
    }

    func feedContinuityHub() -> ContinuityHubModel? {
        let changed = continuityChangedItems()
        let unresolved = continuityUnresolvedItems()
        let comingBack = continuityComingBackItems()

        guard !changed.isEmpty || !unresolved.isEmpty || !comingBack.isEmpty else {
            return nil
        }

        return ContinuityHubModel(
            status: ContinuityLanguage.continuityStatus(changed: changed, unresolved: unresolved, comingBack: comingBack),
            changed: changed,
            unresolved: unresolved,
            comingBack: comingBack
        )
    }

    var interactionQueueDepth: Int {
        (presentedCard == nil ? 0 : 1) + interactionCards.queuedCount
    }

    /// Mid/late life: many systems active — use collapsible console + fewer default rows.
    /// BitLife-style condensed shell: one scroll surface, compact dock, actions-first panels.
    var prefersBitLifeShell: Bool { true }

    var prefersCompactLateGameUI: Bool {
        let adultChildren = state.family.children.filter { !$0.livesAtHome }.count
        let heavyFamily = state.family.childCount >= 2 || adultChildren > 0
        let heavyCareer = state.specialCareer.track != .inactive
            || state.career.yearsWorked >= 8
            || state.military.track != .inactive
        return prefersBitLifeShell || state.player.age >= 40 || (state.player.age >= 32 && (heavyFamily || heavyCareer))
    }

    func dockLabel(for tab: Tab) -> String {
        switch tab {
        case .occupation where showingEducationAsPrimaryTab:
            return "School"
        default:
            return tab.title
        }
    }

    func dockSymbol(for tab: Tab) -> String {
        switch tab {
        case .occupation where showingEducationAsPrimaryTab:
            return "book.closed.fill"
        default:
            return tab.symbol
        }
    }

    /// One-line late-game context for the Life console ribbon.
    func lateGameContextRibbon() -> String? {
        guard prefersCompactLateGameUI else { return nil }
        var parts: [String] = []
        let adults = state.family.children.filter { !$0.livesAtHome }
        let atHome = state.family.children.filter { $0.livesAtHome }
        if !adults.isEmpty {
            parts.append("\(adults.count) adult \(adults.count == 1 ? "child" : "children")")
        }
        if !atHome.isEmpty {
            parts.append("\(atHome.count) at home")
        }
        if state.progress.legacyScore > 0 {
            parts.append("Legacy \(state.progress.legacyScore)")
        }
        if let loud = feedUrgencyItems().first(where: { $0.tone == .warning }) {
            parts.append(loud.title)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    struct AdultChildGlanceItem: Identifiable, Equatable {
        let id: String
        let name: String
        let age: Int
        let outcomeLabel: String
    }

    func adultChildrenGlanceItems(limit: Int = 3) -> [AdultChildGlanceItem] {
        state.family.children
            .filter { !$0.livesAtHome }
            .prefix(limit)
            .map { child in
                let outcome = child.adultProfile?.outcome
                let label: String
                switch outcome {
                case .thriving: label = "Thriving"
                case .stable: label = "Stable"
                case .struggling: label = "Struggling"
                case .distant: label = "Distant"
                case .none: label = "Adult"
                }
                return AdultChildGlanceItem(
                    id: child.id.uuidString,
                    name: child.name,
                    age: child.age,
                    outcomeLabel: label
                )
            }
    }

    // MARK: - Tier A: Now lane, soft goals, cast, autonomy toasts

    func nowLaneSnapshot() -> NowLaneSnapshot {
        if let presentedCard {
            return NowLaneSnapshot(
                headline: nextDecisionPrompt(),
                detail: nextDecisionDetail(),
                quickActionTitle: nil,
                quickActionDomain: nil,
                quickActionChoice: nil,
                ageUpHint: "Finish this card stack first.",
                tone: .warning,
                showsQuickAction: false
            )
        }

        if state.activeYearChapter != nil {
            return NowLaneSnapshot(
                headline: chapterStatus(),
                detail: nextDecisionDetail(),
                quickActionTitle: nil,
                quickActionDomain: nil,
                quickActionChoice: nil,
                ageUpHint: "Resolve the year beat before acting elsewhere.",
                tone: .neutral,
                showsQuickAction: false
            )
        }

        if let housingLane = housingNowLaneSnapshot() {
            return housingLane
        }

        if let script = state.mvpOnboarding.scriptedDirective(
            age: state.player.age,
            performedQuickAction: state.discoverability.performedFirstQuickAction,
            seenHoldCoach: state.discoverability.seenLongPressCoach,
            hasYearStance: state.yearlyStance.selectedStance != nil
        ) {
            let chip = homeQuickActionChips().first
            return NowLaneSnapshot(
                headline: "First life",
                detail: script,
                quickActionTitle: chip.map { ActionChoiceCatalog.definition(for: $0.choiceID).title },
                quickActionDomain: chip?.domain,
                quickActionChoice: chip?.choiceID,
                ageUpHint: "Age Up commits a full year after you set a goal on the forecast.",
                tone: .positive,
                showsQuickAction: chip != nil
            )
        }

        let chip = guidedRecommendation() ?? recommendedActionChips().first
        let fallback = homeQuickActionChips().first
        let domain = chip?.domain ?? fallback?.domain
        let choice = chip?.choiceID ?? fallback?.choiceID
        let title = chip?.title ?? fallback.map { ActionChoiceCatalog.definition(for: $0.choiceID).title }

        let headline: String
        let detail: String
        if let goal = state.softRunGoal, goal.status == .inProgress {
            headline = "Goal: \(goal.title)"
            detail = goal.progressHint
        } else if let loud = feedUrgencyItems(limit: 1).first(where: { $0.tone == .warning }) {
            headline = loud.title
            detail = loud.value
        } else {
            headline = "This year"
            detail = pendingActionSummary()
        }

        return NowLaneSnapshot(
            headline: headline,
            detail: detail,
            quickActionTitle: title,
            quickActionDomain: domain,
            quickActionChoice: choice,
            ageUpHint: state.yearlyStance.selectedStance == nil
                ? "Age Up → forecast → pick what you are protecting."
                : "Age Up when quick moves and year plan feel set.",
            tone: feedUrgencyItems().contains(where: { $0.tone == .warning }) ? .warning : .positive,
            showsQuickAction: choice != nil
        )
    }

    private func housingNowLaneSnapshot() -> NowLaneSnapshot? {
        if state.assets.primaryResidence?.status == .delinquent {
            return NowLaneSnapshot(
                headline: "Mortgage under strain",
                detail: "Catch up or refinance before the year turns this into a forced sale.",
                quickActionTitle: "Repair Reserve",
                quickActionDomain: .finance,
                quickActionChoice: .topUpHouseReserve,
                ageUpHint: "Set Refinance or Build Reserve in Year Plan, then Age Up.",
                tone: .warning,
                showsQuickAction: housingInstantReserveAmount() >= 750
            )
        }

        if !state.assets.ownsHome,
           state.player.age >= 18,
           state.finance.homeDownPaymentSavings > 0 || state.assets.homeownershipTrackActive {
            let needed = housingDownPaymentNeeded()
            let saved = state.finance.homeDownPaymentSavings
            return NowLaneSnapshot(
                headline: "House fund $\(saved) / $\(needed)",
                detail: "Target ~$\(housingTargetHomeValue()) starter home in \(housingArrangementLabel()).",
                quickActionTitle: "House Fund",
                quickActionDomain: .finance,
                quickActionChoice: .depositToHouseFund,
                ageUpHint: saved + state.finance.cashOnHand >= needed
                    ? "You may be ready to Buy Home on the year plan."
                    : "Deposit now, then commit Save For Home before Age Up.",
                tone: saved >= needed / 2 ? .positive : .neutral,
                showsQuickAction: housingInstantDepositAmount() >= 500
            )
        }

        return nil
    }

    func refreshSoftRunGoal() {
        guard state.startupState == .active, !state.isGameOver else { return }
        let stance = state.yearlyStance.selectedStance ?? recommendedYearlyStance()
        let choice = stance.preferredAction(for: state)
        let actionTitle = choice.map { ActionChoiceCatalog.definition(for: $0).title } ?? "a matching quick action"
        state.softRunGoal = SoftRunGoal(
            id: "soft-goal-\(stance.rawValue)-\(state.player.age)",
            title: stance.title,
            detail: softGoalDetail(for: stance),
            progressHint: "Now: \(actionTitle) · Year: commit on forecast",
            domain: stance.domain ?? .health,
            suggestedChoice: choice,
            setAtAge: state.player.age,
            status: .inProgress
        )
    }

    private func softGoalDetail(for stance: YearlyStanceID) -> String {
        switch stance {
        case .protectHealth:
            return "Keep recovery ahead of burnout before the next year closes."
        case .stabilizeMoney:
            return "Stop cash leaks and build one year of money stability."
        case .repairPeople:
            return "Repair one bond that is carrying into the forecast."
        case .pushCareer:
            return "Stack career momentum without letting health snap."
        case .soldierStance:
            return "Hold the line — discipline and duty before drift."
        case .studentStance:
            return "Protect school momentum while the year stays loud."
        case .letYearDrift:
            return "Survive the year with minimal damage — small stabilizing moves count."
        }
    }

    func evaluateSoftRunGoal(after summary: YearlyOutcomeSummary?) {
        guard var goal = state.softRunGoal, goal.status == .inProgress else { return }
        guard let summary else {
            goal.status = .missed
            state.softRunGoal = goal
            return
        }
        let stance = state.yearlyStance.lastCompletedStance
        let stanceOutcomePositive = summary.yearlyStanceOutcome?.tone == .positive
        let helpedDomain = summary.headlines.contains { $0.domain == historyDomain(for: goal.domain) && $0.tone == .positive }
            || summary.spillovers.contains { $0.title == "Fighting Back" }
        if stanceOutcomePositive || helpedDomain {
            goal.status = .met
        } else if summary.topProblem?.tone == .warning {
            goal.status = .missed
        } else {
            goal.status = .met
        }
        _ = stance
        state.softRunGoal = goal
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

    func castStripMembers(limit: Int = 3) -> [CastStripMember] {
        var members: [CastStripMember] = []
        if let partner = state.relationships.primaryPartner {
            members.append(
                CastStripMember(
                    id: "partner-\(partner.name)",
                    name: partner.name,
                    roleLabel: "Partner",
                    line: partner.bond < 50 ? "Bond needs attention" : "In your corner",
                    icon: "heart.fill"
                )
            )
        }
        for contact in state.relationships.ambientContacts.sorted(by: { $0.bond > $1.bond }).prefix(2) {
            let role: String
            switch contact.role {
            case .partner: role = "Partner"
            case .mentor: role = "Mentor"
            case .guardian: role = "Family"
            case .friend: role = "Friend"
            }
            members.append(
                CastStripMember(
                    id: contact.id,
                    name: contact.name,
                    roleLabel: role,
                    line: "Watching how this year lands",
                    icon: "person.wave.2.fill"
                )
            )
        }
        for child in state.family.children.filter({ !$0.livesAtHome }).prefix(1) {
            members.append(
                CastStripMember(
                    id: child.id.uuidString,
                    name: child.name,
                    roleLabel: "Adult child",
                    line: child.adultProfile?.lifeVibe.isEmpty == false ? (child.adultProfile?.lifeVibe ?? "Still your story") : "Grown — still connected",
                    icon: "figure.2.and.child.holdinghands"
                )
            )
        }
        return Array(members.prefix(limit))
    }

    func pushAutonomyToast(title: String, detail: String, tone: PlannerTone = .neutral) {
        let toast = AutonomyToast(title: title, detail: detail, tone: tone)
        autonomyToasts.insert(toast, at: 0)
        if autonomyToasts.count > 2 {
            autonomyToasts = Array(autonomyToasts.prefix(2))
        }
        let toastID = toast.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
            self?.autonomyToasts.removeAll { $0.id == toastID }
        }
    }

    func surfaceAutonomySignalsFromLedger() {
        let npc = state.correlationLedger.recentSignals(kind: .npcAutonomyPulse, minStrength: 5).first
        let world = state.correlationLedger.recentSignals(kind: .worldAutonomyPulse, minStrength: 5).first
        if let npc {
            pushAutonomyToast(
                title: "Someone noticed",
                detail: npcAutonomyPulse() ?? "People in your life reacted to how you've been living.",
                tone: .warning
            )
        } else if let world {
            pushAutonomyToast(
                title: "World shifted",
                detail: state.currentEra == .stable ? "Background systems moved while you weren't looking." : "\(state.currentEra.displayName) is bending the year.",
                tone: world.strength >= 14 ? .warning : .neutral
            )
        }
    }

    private func markMVPOnboardingQuickBeatIfNeeded() {
        guard state.mvpOnboarding.isActive(at: state.player.age) else { return }
        state.mvpOnboarding.beatQuickActionDone = true
    }

    private func markMVPOnboardingHoldBeatIfNeeded() {
        guard state.mvpOnboarding.isActive(at: state.player.age) else { return }
        state.mvpOnboarding.beatHoldPreviewDone = true
    }

    func markMVPOnboardingForecastBeatIfNeeded() {
        guard state.mvpOnboarding.isActive(at: state.player.age) else { return }
        state.mvpOnboarding.beatForecastCommitDone = true
    }

    func performNowLaneQuickAction() {
        let lane = nowLaneSnapshot()
        guard let domain = lane.quickActionDomain, let choice = lane.quickActionChoice else { return }
        performQuickAction(choice, for: domain)
    }

    func feedUrgencyItems(limit: Int? = nil) -> [PlannerInsight] {
        var items = [
            PlannerInsight(title: "Money Pressure", value: pressureStatus(domain: "finance", fallback: moneyPressureStatus()), tone: moneyPressureTone()),
            PlannerInsight(title: showingEducationAsPrimaryTab ? "School Momentum" : "Work Stability", value: pressureStatus(domain: showingEducationAsPrimaryTab ? "education" : "career", fallback: schoolOrWorkStatus()), tone: schoolOrWorkTone()),
            PlannerInsight(title: "Social Life", value: npcAutonomyPulse() ?? pressureStatus(domain: "relationships", fallback: socialLifeStatus()), tone: socialLifeTone()),
            PlannerInsight(title: "Burnout", value: pressureStatus(domain: "health", fallback: burnoutStatus()), tone: burnoutTone())
        ]
        
        if state.military.track != .inactive {
            if state.military.contractYearsRemaining <= 1 {
                items.append(PlannerInsight(title: "Military", value: "Contract Ending", tone: .warning))
            }
            if state.military.combatTrauma > 50 {
                items.append(PlannerInsight(title: "Mental Health", value: "Trauma High", tone: .warning))
            }
        }
        
        if let limit {
            return Array(items.prefix(limit))
        }
        return items
    }

    func activeEffects() -> [ActiveEffect] {
        var effects: [ActiveEffect] = []
        
        if state.military.hasGIBill {
            effects.append(ActiveEffect(title: "GI Bill", detail: "Free University Tuition", tone: .positive))
        }
        if state.military.hasPension {
            effects.append(ActiveEffect(title: "Military Pension", detail: "+$25,000 Annual Passive Income", tone: .positive))
        }
        if state.education.pathway == .rotc {
            effects.append(ActiveEffect(title: "ROTC", detail: "Stipend Active. Commission Guaranteed.", tone: .neutral))
        }
        if state.military.combatTrauma > 0 {
            effects.append(ActiveEffect(title: "Combat Trauma", detail: "-\(state.military.combatTrauma/10) Health/yr", tone: .warning))
        }
        
        return effects
    }

    func projectedNetFlow() -> Int {
        var income = state.career.annualIncome
        if state.military.hasPension { income += 25000 }
        if state.education.pathway == .rotc { income += 4000 }
        
        // Investment Income
        income += state.finance.portfolio.rentals.reduce(0) { $0 + $1.annualNetIncome }
        
        var expenses = 12000 // Base living cost
        if let home = state.assets.primaryResidence {
            expenses += home.monthlyMortgageCost * 12
        } else if state.housing.livingArrangement == .soloRenting {
            expenses += 18000
        }
        
        return income - expenses
    }

    func previewAction(_ choiceID: ActionChoiceID) -> [String] {
        let housingLines = housingPreviewLines(for: choiceID)
        if !housingLines.isEmpty {
            var previews = housingLines
            if let note = orchestrator.previewInstantAction(choiceID, domain: .finance, state: state).first {
                previews.append(note)
            }
            return previews
        }

        let result = orchestrator.previewAction(choiceID, state: state)
        
        var previews: [String] = []
        
        if let core = result.coreEffects {
            if let h = core.happiness, h != 0 { previews.append("\(h > 0 ? "+" : "")\(h) Happiness") }
            if let s = core.smarts, s != 0 { previews.append("\(s > 0 ? "+" : "")\(s) Smarts") }
            if let l = core.looks, l != 0 { previews.append("\(l > 0 ? "+" : "")\(l) Looks") }
            if let hl = core.health, hl != 0 { previews.append("\(hl > 0 ? "+" : "")\(hl) Health") }
        }
        
        if let mil = result.militaryEffects {
            if let f = mil.fitness, f != 0 { previews.append("\(f > 0 ? "+" : "")\(f) Fitness") }
            if let d = mil.discipline, d != 0 { previews.append("\(d > 0 ? "+" : "")\(d) Discipline") }
            if let h = mil.heat, h != 0 { previews.append("\(h > 0 ? "+" : "")\(h) Heat") }
        }
        
        if let career = result.careerEffects {
            // performanceDelta / burnoutDelta removed in effects refactor — previews limited to other domains for build
        }
        
        if let fin = result.financeEffects {
            // cashOnHandDelta removed in effects refactor
        }
        
        // P2-3: stronger previews with D4 shape/legacy impact
        let shape = currentLifeShape
        if !shape.isEmpty {
            previews.append("Shapes your life (\(shape)) + legacy echoes")
        }
        if result.notes.contains(where: { $0.tags.contains(.progress) || $0.title.lowercased().contains("focus") }) {
            previews.append("Carries into future focus & quiet years")
        }
        
        return previews
    }

    func backgroundPulseItems() -> [BackgroundPulseItem] {
        var items: [BackgroundPulseItem] = []

        if state.mvpOnboarding.isActive(at: state.player.age) {
            let hint: String
            switch state.mvpOnboarding.elapsedYears(at: state.player.age) {
            case 0:
                hint = "Pick one stance, then age up."
            case 1:
                hint = state.yearlyStance.lastOutcomeLine ?? "Read the pressure that carried forward."
            default:
                hint = currentIdentityPattern?.legacyLine ?? "Repeat what worked or change the year."
            }
            items.append(
                BackgroundPulseItem(
                    title: "First Life",
                    detail: hint,
                    tone: .neutral
                )
            )
        }

        if state.currentEra != .stable {
            items.append(
                BackgroundPulseItem(
                    title: "World",
                    detail: "\(state.currentEra.rawValue.capitalized) is shaping costs and opportunity.",
                    tone: state.currentEra == .bullMarket || state.currentEra == .techBoom ? .positive : .warning
                )
            )
        } else if state.player.age >= 18 {
            items.append(BackgroundPulseItem(title: "World", detail: "The broader economy stayed quiet.", tone: .neutral))
        }

        if let npcPulse = npcAutonomyPulse() {
            items.append(BackgroundPulseItem(title: "People", detail: npcPulse, tone: .warning))
        } else if !state.relationships.friends.isEmpty || state.relationships.hasPartner {
            items.append(BackgroundPulseItem(title: "People", detail: "Close bonds kept moving in the background.", tone: .neutral))
        }

        if let summary = latestYearSummary {
            if let finance = (summary.headlines + summary.spillovers).first(where: { $0.domain == .finance || $0.domain == .housing }) {
                items.append(BackgroundPulseItem(title: "Money", detail: finance.detail, tone: PlannerTone(finance.tone)))
            } else if state.finance.lastYearBalanceDelta != 0 {
                items.append(
                    BackgroundPulseItem(
                        title: "Money",
                        detail: state.finance.lastYearBalanceDelta > 0 ? "Cash flow added room." : "Cash flow tightened the year.",
                        tone: state.finance.lastYearBalanceDelta > 0 ? .positive : .warning
                    )
                )
            }

            if let health = (summary.headlines + summary.spillovers).first(where: { $0.domain == .health }) {
                items.append(BackgroundPulseItem(title: "Health", detail: health.detail, tone: PlannerTone(health.tone)))
            }
        }

        if state.career.status != .student, !showingEducationAsPrimaryTab {
            items.append(
                BackgroundPulseItem(
                    title: "Work",
                    detail: state.career.performance >= 65 ? "Work performance held its shape." : "Work stability softened in the background.",
                    tone: state.career.performance >= 65 ? .positive : .warning
                )
            )
        }

        var seen: Set<String> = []
        return items.filter { item in
            seen.insert(item.title).inserted && !item.detail.contains("%")
        }
        .prefix(3)
        .map { $0 }
    }

    var currentIdentityPattern: PlayerPattern? {
        state.currentIdentityPattern
    }

    func yearlyStanceChips() -> [YearlyStanceChip] {
        YearlyStanceID.allCases.map { stance in
            let actionTitle = stance.preferredAction(for: state).map { ActionChoiceCatalog.definition(for: $0).title } ?? "No forced action"
            let resilienceHint = stance.yearGoalHint(for: state)
            let detail = [actionTitle, resilienceHint].compactMap { $0 }.joined(separator: " · ")
            // D4: surface residue/repeat for the chosen focus
            var chipDetail = detail
            if state.yearlyStance.selectedStance == stance, let last = state.yearlyStance.lastCompletedStance, last == stance, state.yearlyStance.repeatCount >= 2 {
                chipDetail += " · repeated \(state.yearlyStance.repeatCount)x (rut forming)"
            } else if state.yearlyStance.lastCompletedStance == stance, !state.yearlyStance.recentStances.isEmpty {
                chipDetail += " · recent shape still active"
            }
            return YearlyStanceChip(
                id: stance,
                title: stance.title,
                detail: chipDetail,
                tone: state.yearlyStance.selectedStance == stance ? .positive : (harmfulPatternLabel(for: stance) == nil ? .neutral : .warning),
                isSelected: state.yearlyStance.selectedStance == stance
            )
        }
    }

    func setYearlyStance(_ stance: YearlyStanceID) {
        state.yearlyStance.selectedStance = stance
        markMVPOnboardingForecastBeatIfNeeded()
        refreshSoftRunGoal()
        if let domain = stance.domain, let action = stance.preferredAction(for: state), actionChoices(for: domain).contains(action) {
            setAction(action, for: domain)
        } else {
            activityPulse = ActivityPulse(title: "Year Goal Set", detail: "\(stance.title) will let the year resolve with less player steering.", tone: .neutral)
            showTransientActivityPulse()
            refreshDerivedState()
            save()
        }
    }

    /// Stances surfaced on the forecast commit beat (contextual, not the full home grid).
    func forecastStanceChips() -> [YearlyStanceChip] {
        var allowed: [YearlyStanceID] = [.stabilizeMoney, .protectHealth, .repairPeople, .pushCareer, .letYearDrift]
        if state.military.track != .inactive {
            allowed.insert(.soldierStance, at: 0)
        }
        if state.player.age < 22, state.education.pathway == .student {
            allowed.insert(.studentStance, at: min(1, allowed.count))
        }
        let all = yearlyStanceChips()
        return allowed.compactMap { id in all.first { $0.id == id } }
    }

    func prepareForecastCommitmentIfNeeded() {
        guard state.yearlyStance.selectedStance == nil else { return }
        setYearlyStance(recommendedYearlyStance())
    }

    func keepLastYearlyStance() {
        guard let stance = state.yearlyStance.lastCompletedStance else { return }
        setYearlyStance(stance)
    }

    func pressureContextLines(limit: Int = 3) -> [String] {
        let ranked = state.correlationLedger.pressureCauses
            .sorted { lhs, rhs in
                if lhs.age == rhs.age { return abs(lhs.delta) > abs(rhs.delta) }
                return lhs.age > rhs.age
            }
            .prefix(limit)
        return ranked.map { cause in
            "\(cause.label) -> \(pressureLabel(for: cause.domain)) -> \(spilloverLabel(for: cause.domain, delta: cause.delta))"
        }
    }

    func npcAutonomyPulse() -> String? {
        let contacts = state.relationships.friends + state.relationships.romanticPartners
        if state.relationships.activeRumorHeat >= 50 {
            return "Rumor heat is making people reactive"
        }
        if let strained = contacts.first(where: { $0.hiddenResentment >= 35 || $0.status == .strained }) {
            return "\(strained.name) is carrying unresolved tension"
        }
        if let needy = contacts.first(where: { $0.hiddenNeedLevel >= 42 }) {
            return "\(needy.name) may ask for help soon"
        }
        if let overworked = state.correlationLedger.npcImpressions.first(where: { $0.value["overworked", default: 0] >= 4 }),
           let contact = contacts.first(where: { $0.id.uuidString == overworked.key }) {
            return "\(contact.name) notices the overwork"
        }
        if let absent = state.correlationLedger.npcImpressions.first(where: { $0.value["absent", default: 0] >= 4 }),
           let contact = contacts.first(where: { $0.id.uuidString == absent.key }) {
            return "\(contact.name) has been waiting on you"
        }
        return nil
    }

    func nextDecisionPrompt() -> String {
        if let presentedCard {
            switch presentedCard {
            case .forecast(let forecast):
                return forecast.title
            case .yearSummary:
                return "Review the year before the next decision lands."
            case .event(let event):
                return event.title
            case .reaction(let reaction):
                return reaction.title
            case .consequence(let preview):
                return preview.title
            case .resolution:
                return "Continue when you are ready."
            case .crisis(let crisis):
                return crisis.title
            case .pitchDeck(let pitch):
                return pitch.title
            }
        }

        return ""
    }

    func nextDecisionDetail() -> String {
        if let presentedCard {
            switch presentedCard {
            case .forecast(let forecast):
                return forecast.anticipationDetail
            case .yearSummary(let summary):
                return summary.momentum?.detail ?? "The year moved. Review the biggest shifts first."
            case .event(let event):
                return event.displayText(echoing: state)
            case .reaction(let reaction):
                return reaction.detail
            case .consequence(let preview):
                return preview.detail
            case .resolution(let preview):
                return preview.detail
            case .crisis(let crisis):
                return crisis.detail
            case .pitchDeck(let pitch):
                return pitch.detail
            }
        }

        return pendingActionSummary()
    }

    func plannerDestination(forUrgencyItemTitle title: String) -> PlannerDetailDestination? {
        switch title {
        case "Money Pressure":
            return .financeCashflow
        case "School Momentum":
            return .educationClimate
        case "Work Stability":
            return .careerOverview
        case "Social Life":
            return .relationshipsConnections
        case "Burnout":
            return .healthOverview
        default:
            return nil
        }
    }

    func selectedAction(for domain: ActionDomain) -> ActionChoiceID? {
        if let pending = state.pendingActions.first(where: { $0.domain == domain }) {
            return pending.choiceID
        }
        return state.actionMemory.lastAction(for: domain)
    }

    func setAction(_ choiceID: ActionChoiceID, for domain: ActionDomain) {
        switch makeActionRegistry().resolutionTier(for: choiceID, domain: domain) {
        case .instant:
            performInstantAction(choiceID, for: domain)
        case .committed:
            queueCommittedAction(choiceID, for: domain)
        }
    }

    func quickActionChoices(for domain: ActionDomain) -> [ActionChoiceID] {
        makeActionRegistry().availableQuick(for: domain)
    }

    func quickActionBlockReason(_ choiceID: ActionChoiceID, domain: ActionDomain) -> String? {
        if choiceID == .depositToHouseFund {
            guard state.player.age >= 18, !state.assets.ownsHome else { return "Not in a home-buying lane right now." }
            if housingInstantDepositAmount() < 500 { return "Need more cash above your safety floor." }
        }
        if choiceID == .topUpHouseReserve {
            guard state.assets.ownsHome else { return "No owned home to fortify yet." }
            if housingInstantReserveAmount() < 750 { return "Need more cash for a reserve top-up." }
        }
        guard quickActionChoices(for: domain).contains(choiceID) else { return "Unavailable right now." }
        // Static core instant actions (BitLife-style always-click taps for domains/subdomains) can always be clicked.
        // They instantly calculate via the instant path and are exempt from the quick action memory limit.
        if makeActionRegistry().isStaticCoreInstantAction(choiceID, domain: domain) {
            return nil
        }
        var memory = state.quickActionMemory
        return memory.blockReason(for: PlayerYearAction(domain: domain, choiceID: choiceID), age: state.player.age)
    }

    func hasPerformedQuickAction(_ choiceID: ActionChoiceID, domain: ActionDomain) -> Bool {
        var memory = state.quickActionMemory
        memory.rolloverIfNeeded(age: state.player.age)
        return memory.completedThisAge.contains { $0.domain == domain && $0.choiceID == choiceID }
    }

    // Frictionless UI: Instant preview computation for any action
    func previewForAction(_ choiceID: ActionChoiceID, domain: ActionDomain) -> [String] {
        orchestrator.previewInstantAction(choiceID, domain: domain, state: state)
    }

    func performQuickAction(_ choiceID: ActionChoiceID, for domain: ActionDomain) {
        guard !state.isGameOver, presentedCard == nil, state.activeYearChapter == nil else { return }
        let action = PlayerYearAction(domain: domain, choiceID: choiceID)
        let definition = ActionChoiceCatalog.definition(for: choiceID)

        if let reason = quickActionBlockReason(choiceID, domain: domain) {
            AppFeedback.notify(.warning)
            activityPulse = ActivityPulse(title: "Quick Action Blocked", detail: reason, tone: .warning)
            showTransientActivityPulse()
            return
        }

        AppFeedback.impact(.light)
        state.quickActionMemory.record(action, age: state.player.age)
        if !state.discoverability.performedFirstQuickAction {
            state.discoverability.performedFirstQuickAction = true
            markMVPOnboardingQuickBeatIfNeeded()
        }

        // Use the frictionless path that lets autonomous systems react immediately
        let result = orchestrator.applyInstantActionWithAutonomousReaction(choiceID, domain: domain, state: &state)
        
        // Very aggressive QoL: High lifestyle gives small social boost on relationship actions
        if domain == .relationships && state.assets.lifestyleScore > 50 {
            if state.relationships.hasPartner {
                // Small invisible prestige bonus
            }
            // Boost the instant reaction strength slightly
            // (This would ideally be in the coordinator, but for demo)
        }

        activityPulse = activityPulseFromDomainResult(
            result,
            fallbackTitle: QuickActionCatalog.title(for: choiceID),
            fallbackDetail: result.notes.first?.text ?? definition.identityLine
        )

        // Make autonomous world reactions stand out in the pulse for that delicious "it computed instantly" feeling
        let worldReactionNotes = result.notes.filter { $0.tags.contains(.progress) && ($0.title.contains("Responded") || $0.title.contains("Noticed") || $0.title.contains("Momentum") || $0.title.contains("Echo") || $0.title.contains("Body Responded") || $0.title.contains("Financial System") || $0.title.contains("Resourcefulness")) }

        if !worldReactionNotes.isEmpty {
            let enhanced = activityPulse!
            activityPulse = ActivityPulse(title: "Action + World Reaction", detail: enhanced.detail, tone: enhanced.tone)
            if let first = worldReactionNotes.first {
                pushAutonomyToast(title: first.title, detail: first.text, tone: .neutral)
            }

            // Feed the persistent frictionless feedback strip
            for note in worldReactionNotes.prefix(2) {
                let short = "\(note.title): \(note.text)"
                if !recentInstantReactions.contains(short) {
                    recentInstantReactions.insert(short, at: 0)
                }
            }
            if recentInstantReactions.count > 3 {
                recentInstantReactions = Array(recentInstantReactions.prefix(3))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 18) { [weak self] in
                guard let self = self else { return }
                if !self.recentInstantReactions.isEmpty {
                    self.recentInstantReactions.removeLast()
                }
            }
        }

        // Spawn floating deltas for immediate visual feedback (Phase 1)
        spawnFloatingDeltas(from: result, domain: domain)

        showTransientActivityPulse()

        orchestrator.applyAmbientPressureSync(state: &state)
        refreshDerivedState()
        save()
    }

    private func performInstantAction(_ choiceID: ActionChoiceID, for domain: ActionDomain) {
        let definition = ActionChoiceCatalog.definition(for: choiceID)
        if definition.baseFriction == .locked {
            let feedback = feedbackCoordinator.actionResponse(for: .locked, microBeat: definition.microBeat)
            guard !feedback.shouldReturnEarly else { return }
            applyFeedback(feedback)
            return
        }

        AppFeedback.impact(.light)

        // Frictionless instant path with autonomous world reaction
        let result = orchestrator.applyInstantActionWithAutonomousReaction(choiceID, domain: domain, state: &state)

        activityPulse = activityPulseFromDomainResult(
            result,
            fallbackTitle: "Action Complete",
            fallbackDetail: result.notes.first?.text ?? definition.identityLine
        )

        // Highlight when autonomous systems reacted instantly
        if result.notes.contains(where: { $0.tags.contains(.progress) && ($0.title.contains("Responded") || $0.title.contains("Noticed") || $0.title.contains("Momentum") || $0.title.contains("Echo") || $0.title.contains("Body Responded")) }) {
            let enhanced = activityPulse!
            activityPulse = ActivityPulse(title: "Action + World Reaction", detail: enhanced.detail, tone: enhanced.tone)
        }

        // Spawn floating deltas
        spawnFloatingDeltas(from: result, domain: domain)

        showTransientActivityPulse()

        orchestrator.applyAmbientPressureSync(state: &state)

        refreshDerivedState()
        save()
    }

    private func queueCommittedAction(_ choiceID: ActionChoiceID, for domain: ActionDomain) {
        let definition = ActionChoiceCatalog.definition(for: choiceID)
        if definition.baseFriction == .locked {
            let feedback = feedbackCoordinator.actionResponse(for: .locked, microBeat: definition.microBeat)
            guard !feedback.shouldReturnEarly else { return }
            applyFeedback(feedback)
            return
        }

        AppFeedback.impact(.light)

        state.pendingActions.removeAll { $0.domain == domain }
        state.pendingActions.append(PlayerYearAction(domain: domain, choiceID: choiceID))
        while state.pendingActions.count > 8 {
            state.pendingActions.removeFirst()
        }

        activityPulse = ActivityPulse(
            title: "Year Stance Set",
            detail: "\(definition.title) will shape the next yearly pulse.",
            tone: .positive
        )
        showTransientActivityPulse()

        orchestrator.applyAmbientPressureSync(state: &state)

        refreshDerivedState()
        save()
    }

    func activityCategories() -> [ActivityCategory] {
        ActivityCategory.allCases
    }

    func activities(in category: ActivityCategory) -> [ActivityDefinition] {
        activitySystem.availableActivities(for: state, in: category)
    }

    func performActivity(_ activityID: String) {
        guard !state.isGameOver, presentedCard == nil, state.activeYearChapter == nil else { return }
        guard let resolution = activitySystem.apply(activityID: activityID, to: &state) else { return }

        AppFeedback.impact(.light)

        var detail = resolution.detail
        if let preview = resolution.majorPreview {
            detail = "\(detail)\n\n\(preview.title): \(preview.detail)"
        }
        let pressureLines = resolution.pressureChanges
            .filter { $0.value != 0 }
            .sorted(by: { $0.key < $1.key })
            .map { key, value in
                "\(key) pressure \(value > 0 ? "+" : "")\(value)"
            }
        if !pressureLines.isEmpty {
            detail = detail + "\n\n" + pressureLines.joined(separator: "\n")
        }

        activityPulse = ActivityPulse(
            title: resolution.headline,
            detail: detail,
            tone: PlannerTone(resolution.tone)
        )
        showTransientActivityPulse()
        refreshDerivedState()
        save()
    }

    func recommendedActionChips() -> [RecommendedActionChip] {
        homeQuickActionChips().prefix(6).map { pair in
            let definition = ActionChoiceCatalog.definition(for: pair.choiceID)
            let tradeoff = actionTradeoffLine(for: pair.choiceID)
            return RecommendedActionChip(
                id: "\(pair.domain.rawValue)-\(pair.choiceID.rawValue)",
                domain: pair.domain,
                choiceID: pair.choiceID,
                title: definition.title,
                relief: tradeoff.relief,
                cost: whyActionMatters(pair.choiceID, domain: pair.domain),
                tone: definition.baseFriction == .warning || definition.baseFriction == .resistance ? .warning : .neutral
            )
        }
    }

    /// Context-ranked cross-domain chips for the Home dashboard (only choices valid for the current year).
    func homeQuickActionChips() -> [(domain: ActionDomain, choiceID: ActionChoiceID)] {
        var seen: Set<ActionChoiceID> = []
        var result: [(ActionDomain, ActionChoiceID)] = []
        if let callback = makeActionRegistry().suggestedCallbackAction(),
           actionChoices(for: callback.domain).contains(callback.choiceID)
               || quickActionChoices(for: callback.domain).contains(callback.choiceID) {
            result.append((callback.domain, callback.choiceID))
            seen.insert(callback.choiceID)
        }
        let pressureRanked = dominantPressureActionPairs()
        let fallback: [(ActionDomain, ActionChoiceID)] = [
            (.education, .studyConsistently),
            (.education, .studyHard),
            (.career, .workHard),
            (.career, .jobHunt),
            (.finance, .smallHustle),
            (.health, .protectSleep),
            (.health, .rest),
            (.relationships, .reachOut),
            (.relationships, .findYourCrowd),
            (.career, .takeOvertime),
            (.finance, .cutSpending),
            (.health, .seeDoctor)
        ]
        for pair in pressureRanked + fallback {
            guard actionChoices(for: pair.0).contains(pair.1), !seen.contains(pair.1) else { continue }
            result.append((pair.0, pair.1))
            seen.insert(pair.1)
            if result.count >= 8 { break }
        }
        if result.count < 6 {
            outer: for domain in [ActionDomain.education, .career, .finance, .relationships, .health, .crime, .identity] { // D1: include self work
                for choice in actionChoices(for: domain) where !seen.contains(choice) {
                    result.append((domain, choice))
                    seen.insert(choice)
                    if result.count >= 8 { break outer }
                }
            }
        }
        return result
    }

    private func dominantPressureActionPairs() -> [(ActionDomain, ActionChoiceID)] {
        let rankedPressure = state.consequences.pressureByDomain.sorted { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key < rhs.key }
            return lhs.value > rhs.value
        }
        var pairs: [(ActionDomain, ActionChoiceID)] = []
        for (domain, _) in rankedPressure {
            switch domain {
            case "finance":
                pairs.append((.finance, state.finance.cashOnHand < 1_500 ? .smallHustle : .cutSpending))
                pairs.append((.finance, .minimumPayments))
            case "health":
                pairs.append((.health, .protectSleep))
                pairs.append((.health, .rest))
            case "relationships":
                pairs.append((.relationships, state.relationships.activeTensionCount > 0 ? .repairTension : .reachOut))
            case "career":
                pairs.append((.career, state.career.status == .unemployed ? .jobHunt : .protectYourEnergy))
            case "education":
                pairs.append((.education, .lockInRoutine))
                pairs.append((.education, .studyConsistently))
            default:
                break
            }
        }
        if state.yearlyStance.lastCompletedStance != nil {
            pairs.append((state.yearlyStance.lastCompletedStance?.domain ?? .health, state.yearlyStance.lastCompletedStance?.preferredAction(for: state) ?? .rest))
        }
        return pairs
    }

    private func actionTradeoffLine(for choiceID: ActionChoiceID) -> (relief: String, cost: String) {
        let definition = ActionChoiceCatalog.definition(for: choiceID)
        let tags = definition.previewTags.joined(separator: ", ")
        switch definition.baseFriction {
        case .warning: return ("High leverage", "real fallout")
        case .danger: return ("Critical stakes", "extreme risk")
        case .resistance: return ("Pressure relief", "energy cost")
        case .locked: return ("Not ready", "locked")
        case .none: return (tags.isEmpty ? "Small stabilizer" : tags, "low friction")
        }
    }

    func whyActionMatters(_ choiceID: ActionChoiceID, domain: ActionDomain) -> String {
        if let cause = state.correlationLedger.pressureCauseLine(for: domain.rawValue, limit: 1) {
            return cause
        }
        let pressure = state.consequences.pressureByDomain[domain.rawValue, default: 0]
        if pressure >= 30 {
            return "interrupts active pressure"
        }
        if selectedAction(for: domain) == choiceID {
            return "already shaping this year"
        }
        return actionTradeoffLine(for: choiceID).cost
    }

    private func pressureLabel(for domain: String) -> String {
        switch domain {
        case "finance": return "money pressure"
        case "health": return "health strain"
        case "relationships": return "relationship tension"
        case "career": return "work pressure"
        case "education": return "school pressure"
        case "housing": return "housing instability"
        default: return "\(domain) pressure"
        }
    }

    private func spilloverLabel(for domain: String, delta: Int) -> String {
        if delta < 0 { return "pressure easing" }
        switch domain {
        case "finance": return "health and people feel it"
        case "health": return "work and school get harder"
        case "relationships": return "support thins out"
        case "career": return "burnout risk rises"
        case "education": return "future doors narrow"
        case "housing": return "daily stability drops"
        default: return "life context shifts"
        }
    }

    private func harmfulPatternLabel(for stance: YearlyStanceID) -> String? {
        guard state.yearlyStance.lastCompletedStance == stance, state.yearlyStance.repeatCount >= 2 else { return nil }
        switch stance {
        case .stabilizeMoney where state.healthProfile.mentalWellness < 45:
            return "This is becoming overwork."
        case .letYearDrift:
            return "This is becoming avoidance."
        case .pushCareer where state.career.burnout >= 58:
            return "This is becoming overwork."
        default:
            return nil
        }
    }

    func buyFirearm(_ firearm: Firearm, cost: Int) {
        guard state.finance.cashOnHand >= cost else { return }
        
        state.finance.cashOnHand -= cost
        state.assets.firearms.append(firearm)
        
        AppFeedback.notify(.success)
        refreshDerivedState()
        save()
    }

    func upgradeFirearm(_ id: UUID, upgrade: WeaponUpgrade) {
        guard state.finance.cashOnHand >= upgrade.cost else { return }
        guard let index = state.assets.firearms.firstIndex(where: { $0.id == id }) else { return }
        
        state.finance.cashOnHand -= upgrade.cost
        state.assets.firearms[index].upgrades.append(upgrade)
        
        AppFeedback.impact(.medium)
        refreshDerivedState()
        save()
    }

    func buyVehicle(_ vehicle: Vehicle, cost: Int) {
        guard state.finance.cashOnHand >= cost else { return }
        
        state.finance.cashOnHand -= cost
        state.assets.vehicles.append(vehicle)
        
        // QoL: Richer feedback for asset acquisition (ties into our frictionless system)
        AppFeedback.impact(.medium)
        floatingDeltas.append(FloatingDelta(text: "+\(vehicle.name)", tone: .positive, domain: .finance))
        state.history.insert(
            HistoryEntry(age: state.player.age, title: "Acquired Asset", text: "Bought \(vehicle.name) for $\(cost).", tags: [.progress]),
            at: 0
        )
        refreshDerivedState()
        save()
    }

    func upgradeVehicle(_ id: UUID, upgrade: VehicleUpgrade) {
        guard state.finance.cashOnHand >= upgrade.cost else { return }
        guard let index = state.assets.vehicles.firstIndex(where: { $0.id == id }) else { return }
        
        state.finance.cashOnHand -= upgrade.cost
        state.assets.vehicles[index].upgrades.append(upgrade)
        
        AppFeedback.impact(.medium)
        refreshDerivedState()
        save()
    }

    func upgradeHouse(_ upgrade: HouseUpgrade) {
        guard state.finance.cashOnHand >= upgrade.cost else { return }
        guard state.assets.primaryResidence != nil else { return }
        
        state.finance.cashOnHand -= upgrade.cost
        state.assets.primaryResidence?.upgrades.append(upgrade)
        
        // QoL improvement: Satisfying feedback for meaningful asset upgrades
        AppFeedback.impact(.light)
        floatingDeltas.append(FloatingDelta(text: "Home Upgraded", tone: .positive, domain: .finance))
        state.history.insert(
            HistoryEntry(age: state.player.age, title: "Home Improvement", text: "Upgraded residence.", tags: [.progress]),
            at: 0
        )
        
        AppFeedback.notify(.success)
        refreshDerivedState()
        save()
    }

    func sellProperty() {
        guard let home = state.assets.primaryResidence else { return }
        
        let saleFeeRatePercent = 6
        let grossAfterFees = home.totalValue * (100 - saleFeeRatePercent) / 100
        let recoveredEquity = max(0, grossAfterFees - home.mortgagePrincipal)
        
        state.finance.cashOnHand += recoveredEquity + home.maintenanceReserve
        state.assets.primaryResidence = nil
        state.assets.homeownershipTrackActive = false
        state.assets.targetHomeValue = 0
        
        AppFeedback.notify(.success)
        refreshDerivedState()
        save()
    }

    // MARK: - Housing Hub (Tier A)

    private var homeOwnershipSystem: HomeOwnershipSystem { HomeOwnershipSystem() }

    func housingTargetHomeValue() -> Int {
        let snapshot = AssetDomainSnapshot(
            world: WorldCache(),
            player: state.player,
            military: state.military,
            career: state.career,
            finance: state.finance,
            assets: state.assets,
            housing: state.housing
        )
        if state.assets.targetHomeValue > 0 { return state.assets.targetHomeValue }
        return homeOwnershipSystem.recommendedHomeValuePublic(for: snapshot, finance: state.finance)
    }

    func housingDownPaymentNeeded() -> Int {
        homeOwnershipSystem.downPaymentNeeded(for: housingTargetHomeValue(), isVeteran: state.military.isVeteran)
    }

    func housingFundProgress() -> Double {
        let needed = max(1, housingDownPaymentNeeded())
        return min(1.0, Double(state.finance.homeDownPaymentSavings) / Double(needed))
    }

    func housingInstantDepositAmount() -> Int {
        homeOwnershipSystem.projectedInstantDepositAmount(cashOnHand: state.finance.cashOnHand)
    }

    func housingInstantReserveAmount() -> Int {
        homeOwnershipSystem.projectedInstantReserveAmount(cashOnHand: state.finance.cashOnHand)
    }

    func shouldExpandHomeYearPlan() -> Bool {
        state.assets.homeownershipTrackActive
            || state.finance.homeDownPaymentSavings > 0
            || state.assets.primaryResidence?.status == .delinquent
    }

    func housingArrangementLabel() -> String {
        switch state.housing.livingArrangement {
        case .familyHome: return "Family home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Renting solo"
        case .couchSurfing: return "Couch surfing"
        case .ownerOccupied: return "Owner occupied"
        }
    }

    private func housingPreviewLines(for choiceID: ActionChoiceID) -> [String] {
        switch choiceID {
        case .depositToHouseFund:
            let amount = housingInstantDepositAmount()
            return [
                "−$\(amount) cash",
                "+$\(amount) house fund",
                "Target home ~$\(housingTargetHomeValue())"
            ]
        case .topUpHouseReserve:
            let amount = housingInstantReserveAmount()
            return ["−$\(amount) cash", "+$\(amount) repair reserve"]
        case .saveForDownPayment:
            return ["Auto-save during the year", "Tightens flexible cash", "Fund grows toward ~$\(housingDownPaymentNeeded())"]
        case .buyStarterHome:
            return ["−~$\(housingDownPaymentNeeded()) upfront", "+ownership & stability", "Adds mortgage weight"]
        case .refinanceMortgage:
            return ["−$1,500 fees", "Lower monthly if eligible", "Needs rate ≥6% today"]
        case .buildMaintenanceReserve:
            return ["Year-end reserve build", "Less surprise repair pain", "Uses spare cash"]
        case .sellHome:
            if let home = state.assets.primaryResidence {
                return ["+equity back to cash", "−housing stability", "Value ~$\(home.totalValue)"]
            }
            return ["Turn equity into cash", "Lose owner stability"]
        default:
            return []
        }
    }

    func buyJewelry(_ item: Jewelry) {
        guard state.finance.cashOnHand >= item.cost else { return }
        
        state.finance.cashOnHand -= item.cost
        state.assets.jewelry.append(item)
        
        // QoL: Distinct feedback for luxury/collectible assets
        AppFeedback.impact(.light)
        floatingDeltas.append(FloatingDelta(text: "+\(item.name)", tone: .positive, domain: .finance))
        state.history.insert(
            HistoryEntry(age: state.player.age, title: "Luxury Purchase", text: "Acquired \(item.name).", tags: [.progress]),
            at: 0
        )
        refreshDerivedState()
        save()
    }

    func sellJewelry(_ id: UUID) {
        guard let index = state.assets.jewelry.firstIndex(where: { $0.id == id }) else { return }
        let item = state.assets.jewelry[index]
        
        state.finance.cashOnHand += item.resaleValue
        state.assets.jewelry.remove(at: index)
        
        AppFeedback.impact(.medium)
        refreshDerivedState()
        save()
    }

    func buyAviation(_ item: AviationAsset) {
        guard state.finance.cashOnHand >= item.cost else { return }
        state.finance.cashOnHand -= item.cost
        state.assets.aviation.append(item)
        AppFeedback.notify(.success)
        refreshDerivedState()
        save()
    }

    func sellAviation(_ id: UUID) {
        guard let index = state.assets.aviation.firstIndex(where: { $0.id == id }) else { return }
        let item = state.assets.aviation[index]
        state.finance.cashOnHand += item.resaleValue
        state.assets.aviation.remove(at: index)
        AppFeedback.impact(.medium)
        refreshDerivedState()
        save()
    }

    func buyMarine(_ item: MarineAsset) {
        guard state.finance.cashOnHand >= item.cost else { return }
        state.finance.cashOnHand -= item.cost
        state.assets.marine.append(item)
        AppFeedback.notify(.success)
        refreshDerivedState()
        save()
    }

    func sellMarine(_ id: UUID) {
        guard let index = state.assets.marine.firstIndex(where: { $0.id == id }) else { return }
        let item = state.assets.marine[index]
        state.finance.cashOnHand += item.resaleValue
        state.assets.marine.remove(at: index)
        
        // Aggressive QoL: Consistent rich feedback for all asset transactions
        AppFeedback.impact(.medium)
        floatingDeltas.append(FloatingDelta(text: "Sold \(item.name)", tone: .neutral, domain: .finance))
        state.history.insert(
            HistoryEntry(age: state.player.age, title: "Asset Sale", text: "Sold \(item.name) for $\(item.resaleValue).", tags: [.progress]),
            at: 0
        )
        refreshDerivedState()
        save()
    }

    // Assets2: Signature Asset support (career-specific high-status holdings)
    func buySignatureAsset(_ item: SignatureAsset) {
        guard state.finance.cashOnHand >= item.cost else { return }
        // Only allow if the player is on the matching special career track
        guard state.specialCareer.track == item.associatedTrack else { return }

        state.finance.cashOnHand -= item.cost
        state.assets.signatureAssets.append(item)

        AppFeedback.notify(.success)
        floatingDeltas.append(FloatingDelta(text: "+\(item.name)", tone: .positive, domain: .finance))
        state.history.insert(
            HistoryEntry(age: state.player.age, title: "Signature Asset Acquired", text: "Acquired \(item.name) — a major statement for your path.", tags: [.progress, .finance]),
            at: 0
        )
        refreshDerivedState()
        save()
    }

    func sellSignatureAsset(_ id: UUID) {
        guard let index = state.assets.signatureAssets.firstIndex(where: { $0.id == id }) else { return }
        let item = state.assets.signatureAssets[index]
        state.finance.cashOnHand += item.resaleValue
        state.assets.signatureAssets.remove(at: index)

        AppFeedback.impact(.medium)
        floatingDeltas.append(FloatingDelta(text: "Sold \(item.name)", tone: .neutral, domain: .finance))
        state.history.insert(
            HistoryEntry(age: state.player.age, title: "Signature Asset Sold", text: "Sold \(item.name) for $\(item.resaleValue).", tags: [.progress]),
            at: 0
        )
        refreshDerivedState()
        save()
    }
    
    // Very aggressive QoL: Bulk sell low-value items
    func sellLowValueAssets() {
        var soldValue = 0
        var soldCount = 0
        
        // Sell cheap jewelry
        state.assets.jewelry.removeAll { item in
            if item.resaleValue < 3000 {
                soldValue += item.resaleValue
                soldCount += 1
                return true
            }
            return false
        }
        
        // Sell cheap vehicles (conservative estimate)
        state.assets.vehicles.removeAll { vehicle in
            let estimatedValue = 5000 + vehicle.upgrades.count * 2000
            if estimatedValue < 8000 {
                soldValue += estimatedValue
                soldCount += 1
                return true
            }
            return false
        }
        
        if soldCount > 0 {
            state.finance.cashOnHand += soldValue
            assetTransactionFeedback(
                title: "Bulk Liquidation",
                detail: "Sold \(soldCount) low-value items for $\(soldValue).",
                deltaText: "+\(soldValue)",
                haptic: .light
            )
        }
    }
    
    // Helper for consistent high-quality asset transaction feedback (QoL)
    private func assetTransactionFeedback(title: String, detail: String, deltaText: String? = nil, haptic: AppFeedback.ImpactStyle = .medium) {
        AppFeedback.impact(haptic)
        if let delta = deltaText {
            floatingDeltas.append(FloatingDelta(text: delta, tone: .positive, domain: .finance))
        }
        state.history.insert(
            HistoryEntry(age: state.player.age, title: title, text: detail, tags: [.progress]),
            at: 0
        )
        refreshDerivedState()
        save()
    }

    func actionChoices(for domain: ActionDomain) -> [ActionChoiceID] {
        makeActionRegistry().availableCommitted(for: domain)
    }

    func actionLabel(for choiceID: ActionChoiceID) -> String {
        ActionChoiceCatalog.definition(for: choiceID).title
    }

    func actionPreview(for choiceID: ActionChoiceID) -> [String] {
        Array(ActionChoiceCatalog.definition(for: choiceID).previewTags.prefix(3))
    }

    func actionSubtitle(for choiceID: ActionChoiceID) -> String {
        ActionChoiceCatalog.definition(for: choiceID).subtitle
    }

    func actionIdentity(for choiceID: ActionChoiceID) -> String {
        ActionChoiceCatalog.definition(for: choiceID).identityLine
    }

    func educationWhyItMatters() -> [PlannerInsight] {
        [
            PlannerInsight(
                title: "Readiness",
                value: state.education.applicationReadiness >= 65 ? "doors are opening" : (state.education.applicationReadiness < 40 ? "future still fragile" : "still forming"),
                tone: state.education.applicationReadiness >= 65 ? .positive : (state.education.applicationReadiness < 40 ? .warning : .neutral)
            ),
            PlannerInsight(
                title: "Burnout",
                value: state.education.burnoutRisk >= 60 ? "running hot" : "still manageable",
                tone: state.education.burnoutRisk >= 60 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Support",
                value: state.education.mentorSupport >= 60 ? "adult cover is real" : (state.education.mentorSupport < 35 ? "thin adult cover" : "mixed"),
                tone: state.education.mentorSupport >= 60 ? .positive : (state.education.mentorSupport < 35 ? .warning : .neutral)
            )
        ]
    }

    func teenPressureSources() -> [String] {
        var sources: [(String, Int)] = []
        if state.finance.financialStress >= 32 {
            sources.append(("Money stress", state.finance.financialStress))
        }
        if state.education.engagement < 48 {
            sources.append(("Low engagement", 100 - state.education.engagement))
        }
        if state.education.reputationRisk >= 46 {
            sources.append(("Rumor pressure", state.education.reputationRisk))
        }
        if state.education.schoolBelonging < 40 {
            sources.append(("No safe circle", 100 - state.education.schoolBelonging))
        }
        if state.education.teacherSupport < 38 {
            sources.append(("Teacher friction", 100 - state.education.teacherSupport))
        }
        if state.education.burnoutRisk >= 50 {
            sources.append(("Burnout pressure", state.education.burnoutRisk))
        }
        if state.education.peerPressure >= 46 {
            sources.append(("Peer pressure", state.education.peerPressure))
        }
        if state.healthProfile.mentalWellness < 50 || state.healthProfile.habits.stressManagement < 46 {
            sources.append(("Poor sleep / mental strain", max(100 - state.healthProfile.mentalWellness, 100 - state.healthProfile.habits.stressManagement)))
        }
        if state.relationships.friends.isEmpty {
            sources.append(("Social drift", 58))
        }

        // Side addition for immersion (teen/early adulthood): childhood dossier makes certain pressures feel personal and differentiated, not generic "life is hard"
        if let d = state.childhoodDossier, (state.player.age <= 22 && state.education.stage != .inactive) {
            if d.aptitudes.entrepreneurial >= 55 && state.finance.financialStress >= 30 {
                sources.append(("Hustle pressure (your wiring turns money stress into drive)", state.finance.financialStress / 2))
            }
            if d.aptitudes.physical >= 55 && (state.healthProfile.mentalWellness < 50 || state.healthProfile.physicalWellness < 50) {
                sources.append(("Body pressure (early physical edge makes recovery feel familiar)", max(100 - state.healthProfile.mentalWellness, 100 - state.healthProfile.physicalWellness) / 2))
            }
            if d.aptitudes.social >= 55 && state.education.schoolBelonging < 45 {
                sources.append(("Social wiring pressure (belonging gaps hit different when you're naturally magnetic)", 100 - state.education.schoolBelonging))
            }
            if d.aptitudes.creative >= 55 && state.education.engagement < 50 {
                sources.append(("Creative friction (your spark makes low-engagement years feel especially flat)", 100 - state.education.engagement))
            }
        }

        return Array(sources.sorted { $0.1 > $1.1 }.prefix(3).map(\.0))
    }

    func teenSchoolClimateMetrics() -> [(String, String, PlannerTone)] {
        [
            ("Readiness", "\(state.education.applicationReadiness)", state.education.applicationReadiness >= 65 ? .positive : (state.education.applicationReadiness < 40 ? .warning : .neutral)),
            ("Mentor", "\(state.education.mentorSupport)", state.education.mentorSupport >= 60 ? .positive : (state.education.mentorSupport < 35 ? .warning : .neutral)),
            ("Burnout", "\(state.education.burnoutRisk)", state.education.burnoutRisk >= 55 ? .warning : .neutral)
        ]
    }

    func teenUnlocks() -> [String] {
        var unlocks: [String] = []
        if state.player.age < 15 {
            unlocks.append("15: independence pressure spikes")
        }
        if state.player.age < 16 {
            unlocks.append("16: work search opens")
            unlocks.append("16: stronger side-income events")
        }
        if state.player.age < 17 {
            unlocks.append("17: applications and portfolio matter")
        }
        if state.player.age < 18 {
            unlocks.append("18: graduation and path resolution")
        }
        if state.player.age < 20 {
            unlocks.append("19-20: debt and burnout test fit")
        }
        if state.player.age < 22 {
            unlocks.append("21-22: completion or redirection")
        }
        // Dossier immersion: your 14-year-old wiring is already shaping the teen/early adult lane
        for spark in teenAptitudeSparks() {
            unlocks.append(spark)
        }
        return unlocks
    }

    func teenFinanceMetrics() -> [(String, String, PlannerTone)] {
        let middleMetric: (String, String, PlannerTone)
        if state.education.stage == .university || state.finance.totalNonHousingDebt > 0 {
            middleMetric = ("Debt", "$\(state.finance.totalNonHousingDebt)", state.finance.debtPressureBand == .crushing ? .warning : (state.finance.totalNonHousingDebt > 0 ? .neutral : .positive))
        } else {
            middleMetric = ("Money Stress", "\(state.finance.financialStress)", state.finance.financialStress >= 40 ? .warning : .neutral)
        }
        return [
            ("Pocket Cash", "$\(state.finance.cashOnHand)", state.finance.cashOnHand >= 150 ? .positive : (state.finance.cashOnHand < 0 ? .warning : .neutral)),
            middleMetric,
            ("Home Stability", "\(state.housing.housingStability)", state.housing.housingStability >= 65 ? .positive : (state.housing.housingStability < 40 ? .warning : .neutral))
        ]
    }

    func teenRelationshipMetrics() -> [(String, String, PlannerTone)] {
        let belonging = min(100, (state.relationships.friends.count * 18) + max(state.relationships.friends.strongestBond, state.relationships.partnerBond) / 2)
        let support = max(state.relationships.friends.strongestBond, state.relationships.partnerBond)
        let tension = (state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count * 25
        return [
            ("Belonging", "\(belonging)", belonging >= 55 ? .positive : (belonging < 30 ? .warning : .neutral)),
            ("Support", "\(support)", support >= 60 ? .positive : (support < 30 ? .warning : .neutral)),
            ("Tension", "\(tension)", tension >= 40 ? .warning : .neutral)
        ]
    }

    func teenHealthMetrics() -> [(String, String, PlannerTone)] {
        let sleep = ((state.healthProfile.habits.stressManagement + state.healthProfile.mentalWellness) / 2).clamped(to: 0...100)
        let stress = (100 - state.healthProfile.mentalWellness).clamped(to: 0...100)
        let conditionRisk = min(100, state.healthProfile.activeConditions.count * 30 + max(0, 55 - state.player.health))
        return [
            ("Sleep", "\(sleep)", sleep >= 60 ? .positive : (sleep < 40 ? .warning : .neutral)),
            ("Stress", "\(stress)", stress >= 55 ? .warning : .neutral),
            ("Condition Risk", "\(conditionRisk)", conditionRisk >= 40 ? .warning : .neutral)
        ]
    }

    /// Dossier-driven "your wiring from 14 is showing up here" for teen/early adult immersion.
    /// Makes the school years feel like the special career seeds are already sprouting.
    func teenAptitudeSparks() -> [String] {
        guard let d = state.childhoodDossier, isTeenExperience || (state.player.age <= 22 && state.education.stage != .inactive) else { return [] }
        var sparks: [String] = []
        if d.aptitudes.physical >= 58 {
            sparks.append("Physical edge active in sports/gym — coaches see it")
        }
        if d.aptitudes.entrepreneurial >= 58 {
            sparks.append("Hustle instinct in side moves or projects")
        }
        if d.aptitudes.creative >= 58 {
            sparks.append("Creative current in clubs, writing, or performances")
        }
        if d.aptitudes.social >= 58 {
            sparks.append("Social current — rooms and groups bend toward you")
        }
        if d.aptitudes.analytical >= 58 || d.aptitudes.technical >= 58 {
            sparks.append("Sharp mind showing in the work that actually clicks")
        }
        return sparks
    }

    func chapterStatus() -> String {
        guard let chapter = state.activeYearChapter else {
            return interactionQueueDepth > 0 ? "\(interactionQueueDepth) live card\(interactionQueueDepth == 1 ? "" : "s")" : pendingActionStatus()
        }

        switch chapter.phase {
        case .forecast: return "Year beat: Forecast"
        case .event: return "Year beat: Choice"
        case .reaction: return "Year beat: Reaction"
        case .summary: return "Year beat: Summary"
        case .resolution: return "Year beat: Closeout"
        case .crisis: return "Year beat: Crisis"
        }
    }

    func comingUpItems(for tab: Tab) -> [String] {
        if let forecast = state.activeYearChapter?.forecast {
            return [forecast.anticipationTitle]
        }

        if let upcoming = state.consequences.scheduledEvents.sorted(by: { $0.dueAge < $1.dueAge }).first {
            return [upcoming.title ?? "Age \(upcoming.dueAge) callback"]
        }

        let unresolvedPressures = state.consequences.pressureByDomain
            .filter { $0.value >= 25 }
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { unresolvedPressureLabel(domain: $0.key, intensity: $0.value) }
        if !unresolvedPressures.isEmpty {
            return Array(unresolvedPressures)
        }

        var items: [String] = []
        if showingEducationAsPrimaryTab && state.player.age < 18 {
            if state.education.schoolStanding >= 72 && state.education.teacherSupport >= 60 {
                items.append("Recommendation window opening")
            } else if state.education.burnoutRisk >= 50 {
                items.append("School pressure likely to spill over")
            }
        }
        if tab == .assets || tab == .home || state.finance.financialStress >= 40 || state.finance.cashOnHand < 0 {
            items.append("Budget margin tightening")
        }
        if state.relationships.hasPartner && state.relationships.partnerBond < 55 {
            items.append("Relationship strain close to the surface")
        }
        if state.healthProfile.mentalWellness < 48 || !state.healthProfile.activeConditions.isEmpty {
            items.append("Recovery will set the pace")
        }

        switch state.player.age + 1 {
        case 15:
            items.append("Age 15 independence pressure")
        case 16:
            items.append("Age 16 work search opens")
        case 17:
            items.append("Age 17 applications matter more")
        case 18:
            items.append("Age 18 path resolution")
        default:
            break
        }

        if tab == .home {
            let feed = comingUpItemsForFeed()
            if !feed.isEmpty {
                return Array(feed.prefix(2))
            }
        }
        if tab == .history {
            return Array(state.history.prefix(4).map(\.title))
        }

        return Array(items.prefix(2))
    }

    /// Glance lines for the Life Feed sheet (includes risk and housing hints).
    func comingUpItemsForFeed() -> [String] {
        if let forecast = state.activeYearChapter?.forecast {
            return [forecast.anticipationTitle]
        }

        if let upcoming = state.consequences.scheduledEvents.sorted(by: { $0.dueAge < $1.dueAge }).first {
            return [upcoming.title ?? "Age \(upcoming.dueAge) callback"]
        }

        let unresolvedPressures = state.consequences.pressureByDomain
            .filter { $0.value >= 25 }
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { unresolvedPressureLabel(domain: $0.key, intensity: $0.value) }
        if !unresolvedPressures.isEmpty {
            return Array(unresolvedPressures)
        }

        var items: [String] = []
        if showingEducationAsPrimaryTab && state.player.age < 18 {
            if state.education.schoolStanding >= 72 && state.education.teacherSupport >= 60 {
                items.append("Recommendation window opening")
            } else if state.education.burnoutRisk >= 50 {
                items.append("School pressure likely to spill over")
            }
        }
        if state.finance.financialStress >= 40 || state.finance.cashOnHand < 0 {
            items.append("Budget margin tightening")
        }
        if state.relationships.hasPartner && state.relationships.partnerBond < 55 {
            items.append("Relationship strain close to the surface")
        }
        if state.healthProfile.mentalWellness < 48 || !state.healthProfile.activeConditions.isEmpty {
            items.append("Recovery will set the pace")
        }
        if state.crime.heat >= 50 {
            items.append("Street heat is visible")
        }
        if state.housing.housingStability < 40 {
            items.append("Housing margin is thin")
        }
        if state.crime.status == .layingLow {
            items.append("Cool-down window matters")
        }

        switch state.player.age + 1 {
        case 15:
            items.append("Age 15 independence pressure")
        case 16:
            items.append("Age 16 work search opens")
        case 17:
            items.append("Age 17 applications matter more")
        case 18:
            items.append("Age 18 path resolution")
        default:
            break
        }

        return Array(items.prefix(2))
    }

    func policyLabel() -> String {
        switch state.finance.currentRegionPolicyID {
        case "expensive_coastal": return "Expensive Coast"
        case "factory_town": return "Factory Town"
        default: return "Mountain Standard"
        }
    }

    func currentLifePathProfile() -> LifePathProfile? {
        guard let lifePath = state.progress.finalLifePath ?? state.progress.currentLifePath else { return nil }
        return LifePathCatalog.profile(for: lifePath)
    }

    #if DEBUG
    func loadDebugScenario(_ scenarioID: DebugScenarioID, modal: DebugScenarioModal = .none) {
        applyDebugPayload(
            debugTestingCoordinator.payload(for: scenarioID),
            scenarioID: scenarioID,
            modal: modal,
            shouldSave: true
        )
    }

    func clearDebugScenario() {
        newLife()
    }

    func mutateStateForTesting(_ mutation: (inout GameState) -> Void) {
        mutation(&state)
    }
    #endif

    func pendingActionSummary() -> String {
        if !state.pendingActions.isEmpty {
            let labels = state.pendingActions.map { actionLabel(for: $0.choiceID) }.joined(separator: " · ")
            return "Year stance: \(labels)"
        }
        guard let recentAction = state.actionMemory.latestAction else {
            return "No clear pattern yet"
        }

        return "\(actionDomainLabel(for: recentAction.domain)): \(actionLabel(for: recentAction.choiceID))"
    }

    func pendingActionStatus() -> String {
        if !state.pendingActions.isEmpty {
            return "Year queued"
        }
        return state.actionMemory.latestAction == nil ? "Open" : "Action taken"
    }

    func ageUpRiskPreviewSignals() -> [AgeUpRiskSignal] {
        var signals: [AgeUpRiskSignal] = []

        if let upcoming = state.consequences.scheduledEvents.sorted(by: { $0.dueAge < $1.dueAge }).first {
            signals.append(
                AgeUpRiskSignal(
                    title: upcoming.title ?? "A past choice is coming back",
                    symbol: "arrow.uturn.backward.circle.fill",
                    tone: .warning
                )
            )
        }

        if let planned = state.actionMemory.latestAction {
            let definition = ActionChoiceCatalog.definition(for: planned.choiceID)
            let frictionSignal: AgeUpRiskSignal?
            switch definition.baseFriction {
            case .warning:
                frictionSignal = AgeUpRiskSignal(title: "This action carries real fallout", symbol: "exclamationmark.triangle.fill", tone: .warning)
            case .danger:
                frictionSignal = AgeUpRiskSignal(title: "CRITICAL RISK ACTIVE", symbol: "exclamationmark.shield.fill", tone: .warning)
            case .resistance:
                frictionSignal = AgeUpRiskSignal(title: "This action will cost energy", symbol: "flame.fill", tone: .warning)
            case .locked:
                frictionSignal = AgeUpRiskSignal(title: "This action is not ready", symbol: "lock.fill", tone: .warning)
            case .none:
                frictionSignal = nil
            }
            if let frictionSignal {
                signals.append(frictionSignal)
            }
        }

        if state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 || state.finance.financialStress >= 45 {
            signals.append(AgeUpRiskSignal(title: "Money strain is active", symbol: "dollarsign.circle.fill", tone: .warning))
        }
        if state.education.burnoutRisk >= 55 || state.career.burnout >= 58 || state.healthProfile.mentalWellness < 45 {
            signals.append(AgeUpRiskSignal(title: "Burnout may spill over", symbol: "flame.fill", tone: .warning))
        }
        if state.relationships.activeTensionCount > 0 || strainedRelationshipCount() > 0 || state.relationships.activeRumorHeat >= 55 {
            signals.append(AgeUpRiskSignal(title: "Relationship strain is live", symbol: "person.2.fill", tone: .warning))
        }
        if !state.healthProfile.activeConditions.isEmpty || state.player.health < 40 {
            signals.append(AgeUpRiskSignal(title: "Recovery could set the pace", symbol: "cross.case.fill", tone: .warning))
        }
        if showingEducationAsPrimaryTab && (state.education.attendancePressure >= 55 || state.education.schoolBelonging < 40) {
            signals.append(AgeUpRiskSignal(title: "School pressure is close", symbol: "book.closed.fill", tone: .warning))
        } else if !showingEducationAsPrimaryTab && state.career.status == .unemployed {
            signals.append(AgeUpRiskSignal(title: "Work instability is exposed", symbol: "briefcase.fill", tone: .warning))
        }

        if signals.isEmpty {
            signals.append(AgeUpRiskSignal(title: "No loud pressure yet", symbol: "checkmark.seal.fill", tone: .neutral))
        }

        var seen: Set<String> = []
        return signals.compactMap { signal in
            guard seen.insert(signal.title).inserted else { return nil }
            return signal
        }
        .prefix(3)
        .map { $0 }
    }

    func causeTrailItems(for domains: Set<HistoryDomainTag>? = nil, limit: Int = 3) -> [CauseTrailItem] {
        guard let latestYearSummary else { return [] }

        let pool = (
            latestYearSummary.headlines +
            latestYearSummary.spillovers +
            [
                latestYearSummary.focusOutcome,
                latestYearSummary.mainTradeoff,
                latestYearSummary.topProblem,
                latestYearSummary.topOpportunity,
                latestYearSummary.nextYearPressure
            ].compactMap { $0 }
        )
        .filter { item in
            domains.map { $0.contains(item.domain) || item.domain == .progress } ?? true
        }
        .sorted { abs($0.impactScore) > abs($1.impactScore) }

        var seen: Set<String> = []
        return pool.compactMap { item in
            let detail = item.detail.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !detail.isEmpty, seen.insert(detail).inserted else { return nil }
            return CauseTrailItem(title: item.title, detail: detail, tone: PlannerTone(item.tone))
        }
        .prefix(limit)
        .map { $0 }
    }

    func activityThisYearStatus() -> String {
        let count = state.activities.yearlyCount
        switch count {
        case 0:
            return "Nothing booked yet"
        case 1...2:
            return "\(count) activity\(count == 1 ? "" : "ies") this year"
        case 3...5:
            return "\(count) activities • balanced"
        default:
            return "\(count) activities • pushback building"
        }
    }

    func activityPushbackSummary() -> String {
        let count = state.activities.yearlyCount
        if state.activities.riskLoad >= 10 {
            return "Risk is now outrunning the relief."
        }
        if count >= 6 {
            return "The year is starting to charge more for every extra outlet."
        }
        if count >= 3 {
            return "You are using activities like a real counterbalance, not just a panic button."
        }
        return "Activities give you fast relief, but the real cost still lands somewhere."
    }

    func activityFeedItems() -> [String] {
        var items = state.activities.currentYearActivities.prefix(2).map(\.headline)
        if state.activities.riskLoad >= 8 {
            items.append("Risk patterns are getting louder")
        } else if state.activities.recoveryBalance >= 6 {
            items.append("Recovery habits are starting to hold")
        } else if state.activities.socialMomentum >= 5 {
            items.append("Social momentum is changing the year")
        }
        return Array(items.prefix(3))
    }

    func activityTopSignals() -> [OverviewSignal] {
        [
            OverviewSignal(
                symbol: "sparkles",
                title: "Used",
                value: "\(state.activities.yearlyCount)",
                tone: state.activities.yearlyCount <= 5 ? .positive : .warning
            ),
            OverviewSignal(
                symbol: "heart.text.square.fill",
                title: "Recovery",
                value: "\(state.activities.recoveryBalance)",
                tone: state.activities.recoveryBalance >= 4 ? .positive : .neutral
            ),
            OverviewSignal(
                symbol: "flame.fill",
                title: "Risk",
                value: "\(state.activities.riskLoad)",
                tone: state.activities.riskLoad >= 8 ? .warning : .neutral
            )
        ]
    }

    private func moneyPressureStatus() -> String {
        switch state.finance.financialStress {
        case 55...:
            return "Money pressure is acute"
        case 35...:
            return "Money pressure is rising"
        default:
            return "Money pressure is stable"
        }
    }

    private func moneyPressureTone() -> PlannerTone {
        state.finance.financialStress >= 35 ? .warning : .neutral
    }

    private func pressureStatus(domain: String, fallback: String) -> String {
        guard let causeLine = state.correlationLedger.pressureCauseLine(for: domain) else {
            return fallback
        }
        return "\(fallback): \(causeLine)"
    }

    private func schoolOrWorkStatus() -> String {
        if showingEducationAsPrimaryTab {
            let score = state.education.schoolStanding + state.education.applicationReadiness - state.education.attendancePressure
            switch score {
            case ..<40:
                return "School path is sliding"
            case ..<85:
                return "School path is fragile"
            default:
                return "School path is holding"
            }
        }

        if state.career.status == .unemployed || state.career.performance < 45 {
            return "Work path is fragile"
        }
        if state.career.performance >= 72 {
            return "Work path is building"
        }
        return "Work path is holding"
    }

    private func schoolOrWorkTone() -> PlannerTone {
        if showingEducationAsPrimaryTab {
            let score = state.education.schoolStanding + state.education.applicationReadiness - state.education.attendancePressure
            return score < 85 ? .warning : .positive
        }
        return (state.career.status == .unemployed || state.career.performance < 45) ? .warning : .neutral
    }

    private func socialLifeStatus() -> String {
        let strain = (state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count
        if strain > 1 || state.relationships.partnerBond < 45 {
            return "Relationships are unstable"
        }
        if state.relationships.friends.isEmpty && !state.relationships.hasPartner {
            return "Relationships are fragile"
        }
        return "Relationships are grounded"
    }

    private func socialLifeTone() -> PlannerTone {
        socialLifeStatus() == "Grounded" ? .positive : .warning
    }

    private func burnoutStatus() -> String {
        let load = max(state.education.burnoutRisk, 100 - state.healthProfile.mentalWellness)
        switch load {
        case 60...:
            return "Recovery load is high"
        case 40...:
            return "Recovery load is building"
        default:
            return "Recovery load is low"
        }
    }

    private func burnoutTone() -> PlannerTone {
        burnoutStatus() == "Low" ? .neutral : .warning
    }

    private func present(cards: [InteractionCardPayload]) {
        presentedCard = interactionCards.load(cards)
        orchestrator.syncActiveYearChapterProgress(state: &state, nextCard: presentedCard)
    }

    private func applyFeedback(_ response: FeedbackCoordinator.Response) {
        if let duration = response.jitterDuration {
            actionFrictionJitter = true
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { self.actionFrictionJitter = false }
        }

        guard let microBeat = response.microBeat else { return }
        microBeatOverlay = microBeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.microBeatOverlay == microBeat {
                self.microBeatOverlay = nil
            }
        }
    }

    private func refreshDerivedState() {
        historyDigest = HistoryDigest(state: state)
        refreshChangeInsights()
        DomainActionRegistry.refreshSuggestedAction(in: &state, isTeenExperience: isTeenExperience)
        #if DEBUG
        lastTimingSnapshot = orchestrator.latestTimingSnapshot ?? lastTimingSnapshot
        #endif
    }

    private func applyDebugPayload(
        _ payload: DebugScenarioPayload,
        scenarioID: DebugScenarioID,
        modal: DebugScenarioModal,
        shouldSave: Bool
    ) {
        state = payload.state
        originPreview = nil
        selectedStartMode = .quickStart
        selectedTemplate = .stableHomeAverageMeans
        selectedTab = debugDefaultTab(for: scenarioID)
        latestYearSummary = nil
        presentedCard = nil
        interactionCards.reset()
        activityPulse = nil
        isResolvingInteraction = false
        resolvingInteractionContext = nil
        showingDebugLab = false
        plannerDetail = nil
        selectedInsight = nil
        originTab = nil
        originPlannerDetail = nil
        returnPrompt = nil
        clearPopupStateIfNeeded()
        persistenceBanner = nil

        switch modal {
        case .event:
            if let event = payload.event {
                present(cards: [.event(event)])
            }
        case .yearSummary:
            latestYearSummary = payload.yearSummary
            if let yearSummary = payload.yearSummary {
                spawnYearlyDeltas(from: yearSummary)
                present(cards: [.yearSummary(yearSummary)])
            }
        case .none:
            if let yearSummary = payload.yearSummary {
                latestYearSummary = yearSummary
                spawnYearlyDeltas(from: yearSummary)
                present(cards: [.yearSummary(yearSummary)])
            } else if let event = payload.event {
                present(cards: [.event(event)])
            }
        }

        refreshDerivedState()
        if shouldSave {
            save()
        }
    }

    private func debugDefaultTab(for _: DebugScenarioID) -> Tab {
        .home
    }

    private func actionDomainLabel(for domain: ActionDomain) -> String {
        switch domain {
        case .education: return "School"
        case .career: return "Work"
        case .military: return "Military"
        case .crime: return "Crime"
        case .finance: return "Money"
        case .relationships: return "Social"
        case .health: return "Health"
        case .family: return "Family"
        case .identity: return "Identity"
        }
    }

    private func coreStatDeltaLine(for core: CoreStatEffects?) -> String? {
        guard let core else { return nil }
        var parts: [String] = []
        if let d = core.happiness, d != 0 { parts.append("Happy \(d > 0 ? "+" : "")\(d)") }
        if let d = core.smarts, d != 0 { parts.append("Smart \(d > 0 ? "+" : "")\(d)") }
        if let d = core.looks, d != 0 { parts.append("Looks \(d > 0 ? "+" : "")\(d)") }
        if let d = core.health, d != 0 { parts.append("Health \(d > 0 ? "+" : "")\(d)") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func activityPulseFromDomainResult(
        _ result: DomainYearResult,
        fallbackTitle: String,
        fallbackDetail: String
    ) -> ActivityPulse {
        let title = result.notes.first?.title ?? fallbackTitle
        var segments: [String] = []
        if let first = result.notes.first {
            segments.append(first.text)
        }
        for note in result.notes.dropFirst().prefix(3) {
            segments.append("\(note.title): \(note.text)")
        }
        if let line = coreStatDeltaLine(for: result.coreEffects) {
            segments.append(line)
        }
        let merged = segments.filter { !$0.isEmpty }.joined(separator: "\n\n")
        let detail = merged.isEmpty ? fallbackDetail : merged
        let tone: PlannerTone = result.notes.contains(where: { $0.tags.contains(.progress) }) ? .positive : .neutral
        return ActivityPulse(title: title, detail: detail, tone: tone)
    }

    private func configureStartupStateForLoadedGame() {
        if state.startupState == .active {
            self.originPreview = nil
        } else {
            self.originPreview = orchestrator.previewStart(mode: .quickStart, templateID: nil, meta: metaState)
            self.selectedStartMode = .quickStart
            self.selectedTemplate = .stableHomeAverageMeans
        }
    }

    private func restoreActiveChapterIfNeeded() {
        guard state.activeYearChapter != nil else { return }
        present(cards: orchestrator.resumeActiveYearChapterCards(for: state))
    }

    private func captureReturnOrigin() {
        originTab = selectedTab
        if plannerDetail == nil {
            originPlannerDetail = nil
        }
    }

    private func restoreInteractionOriginIfNeeded() {
        guard let originTab else {
            originPlannerDetail = nil
            returnPrompt = nil
            return
        }
        selectedTab = originTab
        if let originPlannerDetail {
            returnPrompt = PlannerReturnContext(tab: originTab, destination: originPlannerDetail)
        } else {
            returnPrompt = nil
        }
    }

    private func showTransientSaveStatus() {
        saveStatusTask?.cancel()
        saveStatusBanner = "Saved this year"
        saveStatusTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.saveStatusBanner = nil
        }
    }

    private func showTransientActivityPulse() {
        activityPulseTask?.cancel()
        activityPulseTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            self?.activityPulse = nil
        }
    }

    private func refreshChangeInsights() {
        guard let summary = latestYearSummary else {
            changeInsights = [:]
            return
        }

        var insights: [ChangeInsightTopic: ChangeInsightCard] = [:]
        if let card = buildInsight(
            topic: .money,
            summary: summary,
            matching: [.finance, .housing],
            fallbackHeadline: state.finance.lastYearBalanceDelta < 0 ? "Money got tighter this year" : "Money held, but pressure is still visible",
            tone: state.finance.lastYearBalanceDelta < 0 ? .warning : .neutral
        ) {
            insights[.money] = card
        }
        if let card = buildInsight(
            topic: .work,
            summary: summary,
            matching: showingEducationAsPrimaryTab ? [.education, .progress] : [.career, .progress],
            fallbackHeadline: showingEducationAsPrimaryTab ? "School momentum shifted this year" : "Work stability shifted this year",
            tone: schoolOrWorkTone()
        ) {
            insights[.work] = card
        }
        if let card = buildInsight(
            topic: .relationships,
            summary: summary,
            matching: [.relationships, .lifeEvent],
            fallbackHeadline: "Your support system changed this year",
            tone: socialLifeTone()
        ) {
            insights[.relationships] = card
        }
        if let card = buildInsight(
            topic: .health,
            summary: summary,
            matching: [.health],
            fallbackHeadline: "Recovery carried real weight this year",
            tone: burnoutTone()
        ) {
            insights[.health] = card
        }
        changeInsights = insights
    }

    private func buildInsight(
        topic: ChangeInsightTopic,
        summary: YearlyOutcomeSummary,
        matching domains: Set<HistoryDomainTag>,
        fallbackHeadline: String,
        tone: PlannerTone
    ) -> ChangeInsightCard? {
        let pool = (
            summary.headlines +
            summary.spillovers +
            [summary.topProblem, summary.topOpportunity, summary.focusOutcome, summary.mainTradeoff]
                .compactMap { $0 }
        )
        let items = pool
            .filter { domains.contains($0.domain) }
            .sorted { abs($0.impactScore) > abs($1.impactScore) }

        let causes = Array(NSOrderedSet(array: items.map(\.detail)).array as? [String] ?? [])
            .filter { !$0.isEmpty }
            .prefix(3)

        guard !causes.isEmpty || tone == .warning else { return nil }

        let headline = items.first?.title ?? fallbackHeadline
        let implication: String?
        if let nextYearPressure = summary.nextYearPressure, domains.contains(nextYearPressure.domain) || nextYearPressure.domain == .progress {
            implication = nextYearPressure.detail
        } else {
            implication = nil
        }

        return ChangeInsightCard(
            topic: topic,
            headline: headline,
            causes: Array(causes),
            implication: implication,
            tone: tone
        )
    }

    private func persistenceMessage(for primaryError: PersistenceError, fallbacks: [PersistenceError]) -> String {
        let details = fallbacks
            .map { $0.errorDescription ?? "Unknown persistence error." }
            .joined(separator: " ")
        return [primaryError.errorDescription, details]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private func continuityChangedItems() -> [ContinuityHubItem] {
        guard let summary = latestYearSummary else { return [] }

        let candidates = [
            summary.checkpoint,
            summary.focusOutcome,
            summary.mainTradeoff,
            summary.topProblem,
            summary.topOpportunity,
            summary.momentum
        ].compactMap { $0 }

        var seen: Set<String> = []
        return candidates.compactMap { item in
            guard seen.insert(item.id).inserted else { return nil }
            return ContinuityHubItem(title: item.title, detail: item.detail, tone: PlannerTone(item.tone))
        }
        .prefix(3)
        .map { $0 }
    }

    private func continuityUnresolvedItems() -> [ContinuityHubItem] {
        var items: [ContinuityHubItem] = []

        if let nextYearPressure = latestYearSummary?.nextYearPressure {
            items.append(
                ContinuityHubItem(
                    title: "Still Active",
                    detail: nextYearPressure.detail,
                    tone: PlannerTone(nextYearPressure.tone)
                )
            )
        }

        if let strongest = state.consequences.pressureByDomain.max(by: { $0.value < $1.value }), strongest.value >= 18 {
            let label = dominantPressureLabel(for: strongest.key)
            let detail = strongest.value >= 30
                ? "\(label) is still steering next year unless you interrupt it."
                : "\(label) is still present in the background."
            items.append(ContinuityHubItem(title: label, detail: detail, tone: strongest.value >= 30 ? .warning : .neutral))
        }

        if let tension = state.relationships.strongestTension?.headline {
            items.append(
                ContinuityHubItem(
                    title: "Relationship Carryover",
                    detail: "\(tension) is still unresolved and can keep draining the next year.",
                    tone: .warning
                )
            )
        }

        var seen: Set<String> = []
        return items.compactMap { item in
            guard seen.insert(item.id).inserted else { return nil }
            return item
        }
        .prefix(3)
        .map { $0 }
    }

    private func continuityComingBackItems() -> [String] {
        var items: [String] = []

        if let callback = state.consequences.scheduledEvents.sorted(by: { $0.dueAge < $1.dueAge }).first {
            items.append(callback.title ?? "A past choice is coming back at age \(callback.dueAge)")
        }

        if let checkpoint = latestYearSummary?.checkpoint {
            items.append(checkpoint.title)
        }

        switch state.player.age + 1 {
        case 18:
            items.append("Age 18 continuity crossover")
        case 20:
            items.append("Age 20 first look back")
        default:
            break
        }

        return Array(NSOrderedSet(array: items).array as? [String] ?? []).prefix(3).map { $0 }
    }

    private func dominantPressureLabel(for key: String) -> String {
        switch key {
        case "finance":
            return "Money pressure"
        case "career", "education":
            return showingEducationAsPrimaryTab ? "School pressure" : "Work pressure"
        case "relationships":
            return "Relationship pressure"
        case "health":
            return "Recovery pressure"
        case "housing":
            return "Housing pressure"
        default:
            return "Unresolved pressure"
        }
    }
}

extension GameViewModel {
    func overview(for tab: Tab) -> TabOverviewModel {
        switch tab {
        case .home:
            return homeDashboardOverview()
        case .occupation:
            return showingEducationAsPrimaryTab ? educationOverview() : careerOverview()
        case .assets:
            return financeOverview()
        case .relationships:
            return relationshipsOverview()
        case .history:
            return journalOverview()
        }
    }

    /// Full feed header model for the Life Feed sheet and unit tests.
    func feedTabOverview() -> TabOverviewModel {
        let dominant = dominantFeedDomain()
        let pressure: PressureSummary
        switch dominant {
        case .education:
            pressure = PressureSummary(
                symbol: "book.closed.fill",
                title: ContinuityLanguage.pressureTitle(for: .occupation, showingEducation: true),
                detail: teenPressureSources().first ?? "School momentum is getting shaped by stress, belonging, and attendance pressure.",
                tone: schoolOrWorkTone(),
                destination: .educationClimate
            )
        case .career:
            pressure = PressureSummary(
                symbol: "briefcase.fill",
                title: ContinuityLanguage.pressureTitle(for: .occupation, showingEducation: false),
                detail: state.career.status == .unemployed ? "You need a steadier work lane before the next year compounds the gap." : "Performance and income are moving, but not cleanly enough to feel secure.",
                tone: schoolOrWorkTone(),
                destination: .careerOverview
            )
        case .finance:
            pressure = PressureSummary(
                symbol: "dollarsign.circle.fill",
                title: ContinuityLanguage.pressureTitle(for: .assets, showingEducation: showingEducationAsPrimaryTab),
                detail: state.finance.lastYearBalanceDelta < 0 ? "The year is leaking money, so cash flow is the first thing to stabilize." : "You are still functioning, but there is not much room for mistakes or shocks.",
                tone: moneyPressureTone(),
                destination: .financeCashflow
            )
        case .relationships:
            pressure = PressureSummary(
                symbol: "person.2.fill",
                title: ContinuityLanguage.pressureTitle(for: .relationships, showingEducation: showingEducationAsPrimaryTab),
                detail: socialLifeStatus() == "Relationships are grounded" ? "Your closest connections are helping absorb pressure elsewhere." : "Isolation or strain is making every other problem land harder.",
                tone: socialLifeTone(),
                destination: .relationshipsConnections
            )
        case .health:
            pressure = PressureSummary(
                symbol: "cross.case.fill",
                title: ContinuityLanguage.pressureTitle(for: .home, showingEducation: showingEducationAsPrimaryTab),
                detail: burnoutStatus() == "Recovery load is low" ? "Health is not the main drag right now, but your habits still set the pace." : "Stress, sleep, or active conditions are turning recovery into the bottleneck for the next year.",
                tone: burnoutTone(),
                destination: .healthOverview
            )
        case .crime:
            pressure = PressureSummary(
                symbol: "flame.fill",
                title: "Risk track is heating up",
                detail: "Crime or notoriety pressure is starting to spill into the rest of life.",
                tone: .warning,
                destination: .lifeHousing
            )
        case .military:
            pressure = PressureSummary(
                symbol: "shield.fill",
                title: "Military Duty",
                detail: "Service and discipline are the backbone of your year.",
                tone: .neutral,
                destination: .careerOverview
            )
        case .family:
            pressure = PressureSummary(
                symbol: "person.2.fill",
                title: "Family Burden",
                detail: "Parenthood and family ties are shaping your path.",
                tone: .neutral,
                destination: .relationshipsFamily
            )
        case .identity:
            pressure = PressureSummary(
                symbol: "person.fill",
                title: "Identity & Direction",
                detail: "You're figuring out who you are and what matters.",
                tone: .neutral,
                destination: .lifeHistory
            )
        }

        return TabOverviewModel(
            title: "Life Feed",
            symbol: "square.grid.2x2.fill",
            status: chapterStatus(),
            summary: nextDecisionPrompt(),
            tone: interactionQueueDepth > 0 ? .positive : .neutral,
            trendLabel: pendingActionStatus(),
            detailDestination: nil,
            topSignals: feedTopSignals(),
            primaryPressure: pressure,
            recommendedFocus: recommendedFocus(for: dominant),
            stripTitle: "Coming Up",
            stripItems: feedStripItems(),
            continuity: feedContinuityHub()
        )
    }

    /// Activities + health planner overview (formerly the standalone Activities tab); used by tests and continuity.
    func activitiesTabOverview() -> TabOverviewModel {
        activitiesOverview()
    }

    private func homeDashboardOverview() -> TabOverviewModel {
        let base = feedTabOverview()
        return TabOverviewModel(
            title: "Home",
            symbol: "house.fill",
            status: base.status,
            summary: base.summary,
            tone: base.tone,
            trendLabel: base.trendLabel,
            detailDestination: base.detailDestination,
            topSignals: base.topSignals,
            primaryPressure: base.primaryPressure,
            recommendedFocus: base.recommendedFocus,
            stripTitle: base.stripTitle,
            stripItems: base.stripItems,
            continuity: base.continuity
        )
    }

    private func journalOverview() -> TabOverviewModel {
        let recent = Array(state.history.prefix(3).map(\.title))
        return TabOverviewModel(
            title: "History",
            symbol: "scroll.fill",
            status: "\(state.history.count) entries",
            summary: state.history.last?.text ?? "Every choice and quiet year shows up here.",
            tone: .neutral,
            trendLabel: "Chronicled",
            detailDestination: nil,
            topSignals: [],
            primaryPressure: PressureSummary(
                symbol: "book.pages.fill",
                title: "Full timeline",
                detail: "Scroll through years of decisions, milestones, and carryover threads.",
                tone: .neutral,
                destination: nil
            ),
            recommendedFocus: RecommendedFocus(domain: nil, choiceID: nil, title: "Read the arc", subtitle: "Patterns explain what the next year is likely to test.", previewTags: recent, isSelected: false),
            stripTitle: "Latest beats",
            stripItems: recent.isEmpty ? ["Age up to start the story"] : recent
        )
    }

    private func educationOverview() -> TabOverviewModel {
        let tone: PlannerTone = state.education.burnoutRisk >= 55 || state.education.attendancePressure >= 55 ? .warning : .neutral
        let pressure: PressureSummary
        if state.education.burnoutRisk >= 55 || state.healthProfile.mentalWellness < 45 {
            pressure = PressureSummary(
                symbol: "bed.double.fill",
                title: "Burnout is the pressure point",
                detail: "Recovery and routine are the difference between holding the year together and sliding backward.",
                tone: .warning,
                destination: .educationClimate
            )
        } else if state.education.schoolBelonging < 40 || state.relationships.friends.isEmpty {
            pressure = PressureSummary(
                symbol: "person.2.fill",
                title: "Belonging is too thin",
                detail: "A weak support circle is making school pressure hit harder than it needs to.",
                tone: .warning,
                destination: .educationClimate
            )
        } else {
            pressure = PressureSummary(
                symbol: "book.closed.fill",
                title: "Readiness still needs stacking",
                detail: "Standing, applications, and mentor support are improving, but the next year still needs intentional focus.",
                tone: tone,
                destination: .educationOverview
            )
        }

        return TabOverviewModel(
            title: "Education",
            symbol: "book.closed.fill",
            status: state.education.stage == .university ? "University load" : (state.education.stage == .tradeTraining ? "Trade training" : "Student life"),
            summary: state.education.burnoutRisk >= 55 ? "School is still active, but recovery is becoming part of the academic problem." : (state.education.academicTrack == .honors ? "Honors track: prestige + pressure. Longevity high." : (state.education.academicTrack == .vocational ? "Trade: fast practical ramp, creds hold via practice." : "Education is the main lane right now, so school momentum decides what opens next.")),
            tone: tone,
            trendLabel: educationTrendLabel(),
            detailDestination: .educationOverview,
            topSignals: makeOverviewSignals(
                teenSchoolClimateMetrics(),
                symbols: ["graduationcap.fill", "person.crop.circle.badge.checkmark", "flame.fill"]
            ).map { OverviewSignal(symbol: $0.symbol, title: $0.title, value: $0.value, tone: $0.tone, insightTopic: .work) },
            primaryPressure: pressure,
            recommendedFocus: recommendedFocus(for: .education),
            stripTitle: "Near Term",
            stripItems: Array((comingUpItems(for: .occupation) + teenUnlocks()).prefix(3))
        )
    }

    private func careerOverview() -> TabOverviewModel {
        let tone: PlannerTone = state.career.status == .unemployed ? .warning : (state.career.performance >= 75 ? .positive : .neutral)
        let pressure: PressureSummary
        if state.career.status == .unemployed {
            pressure = PressureSummary(
                symbol: "briefcase.circle.fill",
                title: "Stable work is missing",
                detail: "Without a reliable role, the next year is more vulnerable to money and health spillover.",
                tone: .warning,
                destination: .careerOverview
            )
        } else if state.specialCareer.track == .entertainment && state.specialCareer.burnout >= 70 {
            pressure = PressureSummary(
                symbol: "sparkles",
                title: "Spotlight burnout is rising",
                detail: "Attention-based upside is real, but the grind behind it is starting to strip away stability.",
                tone: .warning,
                destination: .careerTrack
            )
        } else {
            pressure = PressureSummary(
                symbol: mainCareerPressureSymbol(),
                title: mainCareerPressureTitle(),
                detail: mainCareerPressureDetail(),
                tone: careerPressureTone(),
                destination: .careerOverview
            )
        }

        return TabOverviewModel(
            title: "Career",
            symbol: "briefcase.fill",
            status: roleTitle(),
            summary: state.specialCareer.track == .entertainment ? "Normal work and attention-based work are both shaping the year now." : careerSummaryLine(),
            tone: tone,
            trendLabel: careerTrendLabel(),
            detailDestination: .careerOverview,
            topSignals: [
                OverviewSignal(symbol: "point.topleft.down.curvedto.point.bottomright.up.fill", title: "Trajectory", value: state.trajectory.direction.rawValue.capitalized, tone: state.trajectory.direction == .rising ? .positive : (state.trajectory.direction == .sliding ? .warning : .neutral), insightTopic: .work),
                OverviewSignal(symbol: "speedometer", title: "Performance", value: "\(state.career.performance)", tone: state.career.performance >= 75 ? .positive : (state.career.performance < 40 ? .warning : .neutral), insightTopic: .work),
                OverviewSignal(symbol: "figure.walk.motion", title: "Burnout Trend", value: "\(state.career.burnout)", tone: state.career.burnout >= 58 ? .warning : (state.career.burnout <= 28 ? .positive : .neutral), insightTopic: .work),
                OverviewSignal(symbol: "door.left.hand.open", title: "Opportunity", value: activeCareerDoorLabel(), tone: state.career.activeOpportunityDoor == nil ? .neutral : .positive, insightTopic: .work)
            ],
            primaryPressure: pressure,
            recommendedFocus: recommendedFocus(for: .career),
            stripTitle: "Coming Up",
            stripItems: careerStripItems()
        )
    }

    private func financeOverview() -> TabOverviewModel {
        let tone: PlannerTone = state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 ? .warning : (state.finance.lastYearBalanceDelta > 5_000 ? .positive : .neutral)
        let pressure: PressureSummary
        if state.assets.ownsHome, state.assets.primaryResidence?.status == .delinquent {
            pressure = PressureSummary(
                symbol: "house.fill",
                title: "Ownership is under strain",
                detail: "The home is no longer just an asset. It is the main thing threatening budget stability.",
                tone: .warning,
                destination: .financePolicy
            )
        } else if state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 {
            pressure = PressureSummary(
                symbol: "arrow.down.circle.fill",
                title: "Running deficit",
                detail: "Expenses are beating income, so finance is the domain most likely to drag the next year down.",
                tone: .warning,
                destination: .financeCashflow
            )
        } else if state.housing.housingStability < 35 {
            pressure = PressureSummary(
                symbol: "building.2.crop.circle",
                title: "Housing squeeze is active",
                detail: "Even decent numbers stop feeling livable when housing stability and policy pressure slip together.",
                tone: .warning,
                destination: .financePolicy
            )
        } else {
            pressure = PressureSummary(
                symbol: "arrow.up.right.circle.fill",
                title: "Surplus is still thin",
                detail: "The budget is holding, but the margin is still small enough that one hit can erase the calm.",
                tone: .neutral,
                destination: .financeCashflow
            )
        }

        let signals: [OverviewSignal] = isTeenExperience
            ? makeOverviewSignals(
                teenFinanceMetrics(),
                symbols: ["dollarsign.circle.fill", "exclamationmark.triangle.fill", "house.fill"]
            ).map { OverviewSignal(symbol: $0.symbol, title: $0.title, value: $0.value, tone: $0.tone, insightTopic: .money) }
            : [
                OverviewSignal(symbol: "plusminus.circle.fill", title: "Net", value: "$\(state.finance.annualNetIncome)", tone: state.finance.annualNetIncome > 0 ? .positive : .warning, insightTopic: .money),
                OverviewSignal(symbol: "wallet.pass.fill", title: "Cash", value: "$\(state.finance.cashOnHand)", tone: state.finance.cashOnHand >= 0 ? .positive : .warning, insightTopic: .money),
                OverviewSignal(symbol: "creditcard.fill", title: "Debt", value: "$\(state.finance.totalNonHousingDebt)", tone: state.finance.debtPressureBand == .heavy || state.finance.debtPressureBand == .crushing ? .warning : .neutral, insightTopic: .money),
                OverviewSignal(symbol: "waveform.path.ecg", title: "Stress", value: "\(state.finance.financialStress)", tone: state.finance.financialStress >= 45 ? .warning : .neutral, insightTopic: .money)
            ]

        return TabOverviewModel(
            title: "Finance",
            symbol: "dollarsign.circle.fill",
            status: balanceStatusLabel(),
            summary: isTeenExperience ? "Money stress is already shaping what school and recovery feel like." : "Finance is where livability shows up, not just raw income.",
            tone: tone,
            trendLabel: financeTrendLabel(),
            detailDestination: .financeCashflow,
            topSignals: signals,
            primaryPressure: pressure,
            recommendedFocus: recommendedFocus(for: .finance),
            stripTitle: "Coming Up",
            stripItems: financeStripItems()
        )
    }

    private func relationshipsOverview() -> TabOverviewModel {
        let strained = strainedRelationshipCount()
        let tone: PlannerTone = strained > 0 || state.relationships.activeRumorHeat >= 55 || state.relationships.activeTensionCount > 0
            ? .warning
            : (connectionCount() > 0 ? .positive : .neutral)
        let pressure: PressureSummary
        if state.relationships.activeRumorHeat >= 55 {
            pressure = PressureSummary(
                symbol: "megaphone.fill",
                title: "Rumor is shaping the year",
                detail: "Social noise is no longer staying social. It is starting to affect how safe, trusted, and stable the rest of life feels.",
                tone: .warning,
                destination: .relationshipsConnections
            )
        } else if state.relationships.activeTensionCount > 0 {
            pressure = PressureSummary(
                symbol: "bolt.heart.fill",
                title: "Loose ends are still live",
                detail: state.relationships.strongestTension?.impactLine ?? "At least one unresolved relationship thread is still draining emotional room from the year.",
                tone: .warning,
                destination: .relationshipsConnections
            )
        } else if strained > 0 {
            pressure = PressureSummary(
                symbol: "exclamationmark.bubble.fill",
                title: "Relationship tension is active",
                detail: "At least one close bond is fraying, and that strain is close to spilling into the rest of life.",
                tone: .warning,
                destination: .relationshipsConnections
            )
        } else if state.family.isPregnant || state.family.childCount > 0 {
            pressure = PressureSummary(
                symbol: "heart.text.square.fill",
                title: "Family load is real now",
                detail: "Family decisions are no longer abstract. They are affecting money, health, and relationship stability together.",
                tone: .warning,
                destination: .relationshipsFamily
            )
        } else if connectionCount() == 0 {
            pressure = PressureSummary(
                symbol: "person.crop.circle.badge.exclamationmark",
                title: "Support system is too thin",
                detail: "A light social net makes hard years hit harder and leaves less buffer when other domains wobble.",
                tone: .warning,
                destination: .relationshipsConnections
            )
        } else {
            pressure = PressureSummary(
                symbol: "person.2.fill",
                title: "Trust is still forming",
                detail: "Your relationships are carrying some warmth, but they still need consistency before they feel like real cover.",
                tone: .neutral,
                destination: .relationshipsConnections
            )
        }

        let signals: [OverviewSignal] = isTeenExperience
            ? makeOverviewSignals(
                teenRelationshipMetrics(),
                symbols: ["person.3.fill", "hands.clap.fill", "bolt.heart.fill"]
            ).map { OverviewSignal(symbol: $0.symbol, title: $0.title, value: $0.value, tone: $0.tone, insightTopic: .relationships) }
            : [
                OverviewSignal(symbol: "person.3.fill", title: "Connections", value: "\(connectionCount())", tone: connectionCount() > 0 ? .positive : .warning, insightTopic: .relationships),
                OverviewSignal(symbol: "person.crop.circle.badge.checkmark", title: "Social Climate", value: "\(state.relationships.publicReputation)", tone: state.relationships.publicReputation >= 60 ? .positive : (state.relationships.publicReputation <= 40 ? .warning : .neutral), insightTopic: .relationships),
                OverviewSignal(symbol: "link.badge.plus", title: "Bond Strain", value: "\(strainedRelationshipCount())", tone: strainedRelationshipCount() > 0 || state.relationships.activeTensionCount > 0 ? .warning : .positive, insightTopic: .relationships),
                OverviewSignal(symbol: "megaphone.fill", title: "Rumor Heat", value: "\(state.relationships.activeRumorHeat)", tone: state.relationships.activeRumorHeat >= 55 ? .warning : .neutral, insightTopic: .relationships),
                OverviewSignal(symbol: "flag.2.crossed.fill", title: "Future Alignment", value: "\(state.relationships.futureAlignment.averageReadiness)", tone: state.relationships.futureAlignment.averageReadiness >= 60 ? .positive : (state.relationships.futureAlignment.averageReadiness <= 42 ? .warning : .neutral), insightTopic: .relationships)
            ]

        return TabOverviewModel(
            title: "Relationships",
            symbol: "person.2.fill",
            status: relationshipsStatusLabel(),
            summary: state.relationships.activeTensionCount > 0
                ? "Relationships are carrying unresolved pressure that is starting to spill elsewhere."
                : (state.family.isPregnant ? "Family pressure is now part of every other conversation." : "Relationships matter most when things go wrong somewhere else."),
            tone: tone,
            trendLabel: relationshipsTrendLabel(),
            detailDestination: .relationshipsConnections,
            topSignals: signals,
            primaryPressure: pressure,
            recommendedFocus: recommendedFocus(for: .relationships),
            stripTitle: "Coming Up",
            stripItems: relationshipsStripItems()
        )
    }

    /// Primary health pressure card; shared by the Activities tab header when wellness should lead.
    private func healthPrimaryPressureForPlanner() -> PressureSummary {
        if !state.healthProfile.activeConditions.isEmpty {
            return PressureSummary(
                symbol: "cross.case.fill",
                title: "Conditions are active",
                detail: "Health is asking for attention now. Recovery is the current bottleneck, not a background stat.",
                tone: .warning,
                destination: .healthConditions
            )
        }
        if state.healthProfile.mentalWellness < 45 {
            return PressureSummary(
                symbol: "brain.head.profile",
                title: "Stress load is rising",
                detail: "Mental strain is quietly dragging down the rest of your year even if you are still functional.",
                tone: .warning,
                destination: .healthOverview
            )
        }
        return PressureSummary(
            symbol: "heart.fill",
            title: "Recovery is the maintenance job",
            detail: "Health is stable enough to hold, but only if your habits keep doing the quiet work.",
            tone: .neutral,
            destination: .healthOverview
        )
    }

    private func healthTopOverviewSignals() -> [OverviewSignal] {
        if isTeenExperience {
            return makeOverviewSignals(
                teenHealthMetrics(),
                symbols: ["bed.double.fill", "bolt.heart.fill", "cross.vial.fill"]
            ).map { OverviewSignal(symbol: $0.symbol, title: $0.title, value: $0.value, tone: $0.tone, insightTopic: .health) }
        }
        return [
            OverviewSignal(symbol: "heart.fill", title: "Overall", value: "\(state.player.health)", tone: state.player.health >= 60 ? .positive : (state.player.health < 40 ? .warning : .neutral), insightTopic: .health),
            OverviewSignal(symbol: "figure.walk", title: "Physical", value: "\(state.healthProfile.physicalWellness)", tone: state.healthProfile.physicalWellness >= 60 ? .positive : (state.healthProfile.physicalWellness < 40 ? .warning : .neutral), insightTopic: .health),
            OverviewSignal(symbol: "brain.head.profile", title: "Mental", value: "\(state.healthProfile.mentalWellness)", tone: state.healthProfile.mentalWellness >= 60 ? .positive : (state.healthProfile.mentalWellness < 40 ? .warning : .neutral), insightTopic: .health),
            OverviewSignal(symbol: "hourglass.bottomhalf.filled", title: "Recovery Debt", value: "\(max(0, 100 - state.healthProfile.habits.stressManagement))", tone: state.healthProfile.habits.stressManagement < 45 ? .warning : .neutral, insightTopic: .health)
        ]
    }

    private func assetsOverview() -> TabOverviewModel {
        let hasIllegal = state.assets.firearms.contains { !$0.isLegal }
        let pressure = PressureSummary(
            symbol: hasIllegal ? "exclamationmark.shield.fill" : "bag.fill",
            title: hasIllegal ? "Possession is high risk" : "Armory is secure",
            detail: hasIllegal 
                ? "Illegal firearms are in your possession. Any police interaction could lead to severe consequences."
                : "You have secured defensive assets. These can be used to protect your property and interests.",
            tone: hasIllegal ? .warning : .neutral,
            destination: nil
        )
        
        return TabOverviewModel(
            title: "Assets",
            symbol: "bag.fill",
            status: state.assets.firearms.isEmpty ? "No defense assets" : "\(state.assets.firearms.count) firearms owned",
            summary: hasIllegal ? "Illicit inventory" : "Secure",
            tone: pressure.tone,
            trendLabel: hasIllegal ? "At Risk" : "Stable",
            detailDestination: nil,
            topSignals: [
                OverviewSignal(symbol: "shield.fill", title: "Defense", value: "\(state.assets.firearms.reduce(0) { $0 + $1.totalPower })", tone: .neutral),
                OverviewSignal(symbol: "exclamationmark.triangle.fill", title: "Risk", value: hasIllegal ? "High" : "Low", tone: hasIllegal ? .warning : .positive)
            ],
            primaryPressure: pressure,
            recommendedFocus: RecommendedFocus(domain: nil, choiceID: nil, title: "Asset protection", subtitle: "Manage your inventory to balance safety and legal risk.", previewTags: [], isSelected: false),
            stripTitle: "Inventory",
            stripItems: state.assets.firearms.map { "\($0.name) (\($0.totalPower))" }
        )
    }

    private func activitiesOverview() -> TabOverviewModel {
        let healthLeadsHeader = !state.healthProfile.activeConditions.isEmpty || state.healthProfile.mentalWellness < 45

        let activityPressure = PressureSummary(
            symbol: state.activities.riskLoad >= 8 ? "flame.fill" : "sparkles",
            title: state.activities.riskLoad >= 8 ? "Relief is turning into risk" : "Activities shape the emotional floor",
            detail: state.activities.riskLoad >= 8
                ? "The way you are blowing off pressure is starting to create new pressure in return."
                : "Activities resolve immediately, but the pattern behind them still changes what the next year feels like.",
            tone: state.activities.riskLoad >= 8 ? .warning : (state.activities.recoveryBalance >= 4 ? .positive : .neutral),
            destination: nil
        )

        if healthLeadsHeader {
            let pressure = healthPrimaryPressureForPlanner()
            let overviewTone: PlannerTone = !state.healthProfile.activeConditions.isEmpty || state.player.health < 40 ? .warning : .positive
            let summary = !state.healthProfile.activeConditions.isEmpty
                ? "Health has moved into the foreground, and the year will feel it."
                : "Habits are still doing more work than dramatic interventions."
            return TabOverviewModel(
                title: "Activities",
                symbol: "sparkles",
                status: healthStatusLabel(),
                summary: summary,
                tone: overviewTone,
                trendLabel: healthTrendLabel(),
                detailDestination: .healthOverview,
                topSignals: healthTopOverviewSignals(),
                primaryPressure: pressure,
                recommendedFocus: recommendedFocus(for: .health),
                stripTitle: "Coming Up",
                stripItems: healthStripItems()
            )
        }

        return TabOverviewModel(
            title: "Activities",
            symbol: "sparkles",
            status: activityThisYearStatus(),
            summary: activityPushbackSummary(),
            tone: activityPressure.tone,
            trendLabel: state.activities.recoveryBalance >= 4 ? "Counterbalancing" : (state.activities.riskLoad >= 8 ? "Spiraling" : "Open"),
            detailDestination: .healthOverview,
            topSignals: activityTopSignals(),
            primaryPressure: activityPressure,
            recommendedFocus: RecommendedFocus(domain: nil, choiceID: nil, title: "Immediate outlet", subtitle: "Use activities to trade money, energy, risk, and relief in real time.", previewTags: activityFeedItems(), isSelected: false),
            stripTitle: "Pattern",
            stripItems: activityFeedItems()
        )
    }

    private func makeOverviewSignals(_ metrics: [(String, String, PlannerTone)], symbols: [String]) -> [OverviewSignal] {
        Array(metrics.enumerated().map { index, metric in
            OverviewSignal(
                symbol: symbols.indices.contains(index) ? symbols[index] : "circle.fill",
                title: metric.0,
                value: metric.1,
                tone: metric.2,
                insightTopic: nil
            )
        }.prefix(3))
    }

    private func feedTopSignals() -> [OverviewSignal] {
        let thirdSignal: OverviewSignal
        if showingEducationAsPrimaryTab {
            thirdSignal = OverviewSignal(
                symbol: state.education.stage == .inactive && state.education.pathway == .graduate ? "checkmark.seal.fill" : "book.closed.fill",
                title: "Education",
                value: state.education.stage == .university
                    ? (state.education.hasScholarship ? "University" : "College Load")
                    : (state.education.stage == .tradeTraining
                        ? "Trade Track"
                        : (state.education.pathway == .graduate && state.education.stage == .inactive
                            ? "Graduated"
                            : (state.education.schoolStanding >= 70 ? "On Track" : (state.education.burnoutRisk >= 55 || state.education.attendancePressure >= 55 ? "At Risk" : "Holding")))),
                tone: state.education.stage == .inactive && state.education.pathway == .graduate ? .positive : (state.education.burnoutRisk >= 55 || state.education.attendancePressure >= 55 ? .warning : .neutral),
                insightTopic: .work
            )
        } else {
            thirdSignal = OverviewSignal(
                symbol: state.career.status == .unemployed ? "briefcase.circle.fill" : "briefcase.fill",
                title: "Career",
                value: roleTitle(),
                tone: state.career.status == .unemployed ? .warning : (state.career.performance >= 75 ? .positive : .neutral),
                insightTopic: .work
            )
        }

        return [
            OverviewSignal(
                symbol: state.finance.lastYearBalanceDelta < 0 ? "arrow.down.circle.fill" : "arrow.up.right.circle.fill",
                title: "Cash Flow",
                value: state.finance.lastYearBalanceDelta < 0 ? "Deficit" : (state.finance.lastYearBalanceDelta > 4_000 ? "Surplus" : "Stable"),
                tone: state.finance.lastYearBalanceDelta < 0 ? .warning : (state.finance.lastYearBalanceDelta > 4_000 ? .positive : .neutral),
                insightTopic: .money
            ),
            OverviewSignal(
                symbol: state.healthProfile.activeConditions.isEmpty ? "heart.fill" : "cross.case.fill",
                title: "Health",
                value: state.healthProfile.activeConditions.isEmpty ? "Stable" : "\(state.healthProfile.activeConditions.count) issue\(state.healthProfile.activeConditions.count == 1 ? "" : "s")",
                tone: state.healthProfile.activeConditions.isEmpty && state.player.health >= 55 ? .positive : (state.player.health < 40 ? .warning : .neutral),
                insightTopic: .health
            ),
            thirdSignal
        ]
    }

    private func recommendedFocus(for domain: ActionDomain) -> RecommendedFocus {
        let activeChoice = selectedAction(for: domain)
        let selected = activeChoice ?? suggestedChoice(for: domain) ?? actionChoices(for: domain).first
        guard let choice = selected else {
            return RecommendedFocus(domain: domain, choiceID: nil, title: "No action available", subtitle: "This domain has no active yearly choices right now.", previewTags: [], isSelected: false)
        }

        return RecommendedFocus(
            domain: domain,
            choiceID: choice,
            title: actionLabel(for: choice),
            subtitle: activeChoice == nil ? actionSubtitle(for: choice) : "Already shaped this year.",
            previewTags: actionPreview(for: choice),
            isSelected: activeChoice == choice
        )
    }

    private func dominantFeedDomain() -> ActionDomain {
        if showingEducationAsPrimaryTab && (state.education.burnoutRisk >= 55 || state.education.attendancePressure >= 55 || state.education.schoolBelonging < 40) {
            return .education
        }
        if state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 || state.finance.financialStress >= 45 {
            return .finance
        }
        if !state.healthProfile.activeConditions.isEmpty || state.healthProfile.mentalWellness < 45 {
            return .health
        }
        if strainedRelationshipCount() > 0 || connectionCount() == 0 {
            return .relationships
        }
        return showingEducationAsPrimaryTab ? .education : .career
    }

    private func suggestedChoice(for domain: ActionDomain) -> ActionChoiceID? {
        makeActionRegistry().suggestedChoice(for: domain)
    }

    private func unresolvedPressureLabel(domain: String, intensity: Int) -> String {
        let prefix: String
        switch intensity {
        case 60...:
            prefix = "Critical"
        case 40...:
            prefix = "Rising"
        default:
            prefix = "Lingering"
        }

        switch domain {
        case "career":
            return "\(prefix) work instability"
        case "finance":
            return "\(prefix) budget pressure"
        case "health":
            return "\(prefix) recovery strain"
        case "relationships":
            return "\(prefix) relationship strain"
        case "housing":
            return "\(prefix) housing squeeze"
        case "education":
            return "\(prefix) school pressure"
        default:
            return "\(prefix) unresolved pressure"
        }
    }

    private func feedStripItems() -> [String] {
        let shifts = feedSummaryItems().map(\.title)
        return Array((comingUpItemsForFeed() + shifts).prefix(3))
    }

    private func careerStripItems() -> [String] {
        var items = comingUpItems(for: .occupation)
        if let door = state.career.activeOpportunityDoor {
            items.insert("\(door.shortLabel) is open", at: 0)
        }
        items.append("Pressure: \(mainCareerPressureTitle())")
        items.append("Control: \(state.career.scheduleControl)")
        if state.specialCareer.track == .entertainment {
            items.append(state.specialCareer.burnout >= 70 ? "Audience upside is costing recovery" : "Attention lane still has upside")
        }
        return Array(items.prefix(3))
    }

    private func financeStripItems() -> [String] {
        var items = comingUpItems(for: .assets)
        if state.finance.hasInvestments {
            items.append(state.finance.lastYearInvestmentDelta >= 0 ? "Portfolio is compounding" : "Portfolio hit needs context")
        }
        if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 {
            items.append("Home fund is active")
        }
        return Array(items.prefix(3))
    }

    private func relationshipsStripItems() -> [String] {
        var items = comingUpItems(for: .relationships)
        if state.family.isPregnant {
            items.append("Family pressure is no longer hypothetical")
        } else if state.relationships.hasPartner && !state.relationships.hasCohabitingPartner {
            items.append("Commitment decisions are approaching")
        }
        return Array(items.prefix(3))
    }

    private func healthStripItems() -> [String] {
        var items = comingUpItems(for: .home)
        if !state.healthProfile.activeConditions.isEmpty {
            items.append("Conditions can spill into other domains")
        } else if state.healthProfile.mentalWellness < 45 {
            items.append("Stress is already shaping recovery")
        }
        return Array(items.prefix(3))
    }

    private func educationTrendLabel() -> String {
        if state.education.applicationReadiness >= 65 && state.education.burnoutRisk < 50 { return "Building" }
        if state.education.burnoutRisk >= 60 || state.education.attendancePressure >= 60 { return "Fragile" }
        return "Holding"
    }

    private func careerTrendLabel() -> String {
        if state.career.status == .unemployed { return "Stalled" }
        if state.career.activeOpportunityDoor != nil { return "Opening" }
        if state.career.jobSecurity < 40 || state.career.scheduleControl < 35 { return "Fragile" }
        if state.career.performance >= 75 { return "Rising" }
        if state.career.performance < 45 { return "Fragile" }
        return "Holding"
    }

    private func careerSummaryLine() -> String {
        if let door = state.career.activeOpportunityDoor {
            return "\(state.career.workIdentity.shortLabel) energy is shaping work now, and \(door.shortLabel.lowercased()) is the clearest opening."
        }
        return "Career is the main stability engine for adult life, and the way you work is now deciding which doors stay open."
    }

    private func activeCareerDoorLabel() -> String {
        state.career.activeOpportunityDoor?.shortLabel ?? "No clear door"
    }

    private func careerPressureTone() -> PlannerTone {
        if state.career.burnout >= 68 || state.career.jobSecurity < 40 || state.career.scheduleControl < 35 {
            return .warning
        }
        return .neutral
    }

    private func mainCareerPressureSymbol() -> String {
        if state.career.jobSecurity < 40 { return "exclamationmark.triangle.fill" }
        if state.career.scheduleControl < 35 { return "calendar.badge.exclamationmark" }
        if state.career.managerFriction >= 60 { return "person.2.slash.fill" }
        return "briefcase.fill"
    }

    private func mainCareerPressureTitle() -> String {
        if state.career.jobSecurity < 40 { return "Job security is thinning out" }
        if state.career.scheduleControl < 35 { return "Work owns too much of the calendar" }
        if state.career.managerFriction >= 60 { return "Politics is changing the job" }
        if state.career.performance < 55 { return "Performance needs correction" }
        return "Career momentum needs stacking"
    }

    private func mainCareerPressureDetail() -> String {
        if state.career.jobSecurity < 40 {
            return "The role no longer feels durable, so weak months are more likely to become layoffs, cuts, or forced pivots."
        }
        if state.career.scheduleControl < 35 {
            return "You have too little control over your time, and that loss of control is raising burnout and relationship spillover."
        }
        if state.career.managerFriction >= 60 {
            return "The room around the work is becoming part of the work, and your energy is paying for it."
        }
        if state.career.performance < 55 {
            return "The work lane is active, but performance is not strong enough to feel safe yet."
        }
        return "Momentum is building, but you still need another clean year to turn it into security."
    }

    private func financeTrendLabel() -> String {
        if state.finance.lastYearBalanceDelta > 0 && state.finance.consecutiveDeficitYears == 0 { return "Recovering" }
        if state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 { return "Fragile" }
        return "Stable"
    }

    private func relationshipsTrendLabel() -> String {
        if strainedRelationshipCount() > 0 { return "Fragile" }
        if max(state.relationships.friends.strongestBond, state.relationships.partnerBond) >= 70 { return "Growing" }
        return "Forming"
    }

    private func healthTrendLabel() -> String {
        if !state.healthProfile.activeConditions.isEmpty { return "Fragile" }
        if state.player.health >= 65 && state.healthProfile.mentalWellness >= 55 { return "Stable" }
        return "Managing"
    }

    private func balanceStatusLabel() -> String {
        if state.assets.ownsHome && state.assets.primaryResidence?.status == .delinquent { return "Ownership strain" }
        if state.finance.lastYearBalanceDelta < 0 { return "Budget strain" }
        if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 { return "Building toward ownership" }
        return "Cash flow holding"
    }

    private func relationshipsStatusLabel() -> String {
        if let pregnancy = state.family.pregnancy {
            return "Pregnant with \(pregnancy.otherParentName)"
        }
        if let partner = state.relationships.primaryPartner {
            switch partner.stage {
            case .married: return "Married to \(partner.name)"
            case .engaged: return "Engaged to \(partner.name)"
            case .committed: return "Committed to \(partner.name)"
            case .dating: return "With \(partner.name)"
            }
        }
        return connectionCount() == 0 ? "Support system thin" : "Connections active"
    }

    private func healthStatusLabel() -> String {
        if state.isGameOver { return "Life ended" }
        if !state.healthProfile.activeConditions.isEmpty { return "Recovery under pressure" }
        if state.player.health >= 65 { return "Body holding steady" }
        return "Recovery needs help"
    }

    // MARK: - Phase 1 Frictionless Visuals



    private func housingStatusShort() -> String {
        switch state.housing.livingArrangement {
        case .familyHome: return "Family home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Solo rent"
        case .ownerOccupied: return "Owner occupied"
        case .couchSurfing: return "Unstable"
        }
    }

    private func connectionCount() -> Int {
        state.relationships.friends.count + (state.relationships.hasPartner ? 1 : 0)
    }

    private func strainedRelationshipCount() -> Int {
        (state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count
    }

    private func strongestRelationshipTone() -> PlannerTone {
        let strongest = max(state.relationships.friends.strongestBond, state.relationships.partnerBond)
        if strongest >= 75 { return .positive }
        if strongest < 35 { return .warning }
        return .neutral
    }
}

// MARK: - Phase 1: High-Quality Floating Deltas Overlay (Frictionless Visual Polish)

private struct FloatingDeltasOverlay: View {
    let deltas: [FloatingDelta]

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(deltas.enumerated()), id: \.element.id) { index, delta in
                let baseY: CGFloat = 65
                let spacing: CGFloat = 30
                let yPos = baseY + CGFloat(index) * spacing
                let xPos = geo.size.width * 0.62 + CGFloat(index % 2) * 8  // slight stagger

                HStack(spacing: 6) {
                    if let domain = delta.domain {
                        Image(systemName: iconForDomain(domain))
                            .font(.caption2.weight(.bold))
                    }
                    Text(delta.text)
                        .font(.caption.weight(.black))
                        .foregroundStyle(delta.tone.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(delta.tone.fill)
                        .overlay(
                            Capsule()
                                .stroke(delta.tone.color.opacity(0.35), lineWidth: 1)
                        )
                )
                .shadow(color: delta.tone.color.opacity(0.25), radius: 3, y: 1)
                .offset(x: xPos, y: yPos)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.6).combined(with: .opacity).combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.7))
                ))
            }
        }
        .allowsHitTesting(false)
    }

    private func iconForDomain(_ domain: ActionDomain) -> String {
        switch domain {
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .relationships: return "person.2.fill"
        case .career: return "briefcase.fill"
        case .education: return "book.fill"
        case .crime: return "exclamationmark.triangle.fill"
        case .military: return "shield.fill"
        case .family: return "person.2.fill"
        case .identity: return "person.fill"
        }
    }
}

private struct HidePlannerNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content
        #else
        content.navigationBarHidden(true)
        #endif
    }
}

struct PersistenceAlertContext: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum AppFeedback {
    private static let hapticsKey = "onelife.hapticsSetting"

    static func impact(_ style: ImpactStyle) {
        #if canImport(UIKit)
        guard currentIntensity != .off else { return }
        let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
        generator.prepare()
        generator.impactOccurred(intensity: currentIntensity == .reduced ? 0.45 : 1.0)
        #endif
    }

    static func notify(_ type: NoticeType) {
        #if canImport(UIKit)
        guard currentIntensity != .off else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type.uiKitType)
        #endif
    }

    private static var currentIntensity: FeedbackIntensitySetting {
        FeedbackIntensitySetting(rawValue: UserDefaults.standard.string(forKey: hapticsKey) ?? "") ?? .full
    }

    enum ImpactStyle {
        case light
        case medium

        #if canImport(UIKit)
        var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: return .light
            case .medium: return .medium
            }
        }
        #endif
    }

    enum NoticeType {
        case success
        case warning
        case error

        #if canImport(UIKit)
        var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            }
        }
        #endif
    }
}

struct GameBouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

/// Primary thumb-zone control — BitLife-weighted, shows the year you are stepping into.
private struct AgeUpChromeButton: View {
    @ObservedObject var vm: GameViewModel
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var nextAge: Int { vm.state.player.age + 1 }

    private var enabledGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.28, green: 0.78, blue: 0.52),
                Color(red: 0.14, green: 0.55, blue: 0.36),
                Color(red: 0.08, green: 0.38, blue: 0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glowColor: Color {
        Color(red: 0.2, green: 0.7, blue: 0.45).opacity(colorScheme == .dark ? 0.55 : 0.35)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    if !vm.state.isGameOver {
                        Text("NEXT YEAR")
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1.1)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Text(vm.state.isGameOver ? "Life Ended" : "Age Up")
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(.white)
                    if !vm.state.isGameOver {
                        HStack(spacing: 5) {
                            Text("Age \(vm.state.player.age)")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9, weight: .black))
                            Text("\(nextAge)")
                                .font(.system(size: 13, weight: .black))
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                    } else {
                        // P5-1: Edge shine on game over button — shows final legacy (shape already in strip/summary)
                        let leg = vm.state.progress.legacyScore
                        Text(leg > 0 ? "Legacy \(leg) — The story closes." : "The story closes.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.35), .white.opacity(0.08)],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 28
                            )
                        )
                        .frame(width: 48, height: 48)
                    Circle()
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 48, height: 48)
                    Image(systemName: vm.state.isGameOver ? "xmark" : "plus")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(isEnabled ? 0.45 : 0.15), .white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: isEnabled ? glowColor : .clear, radius: 14, x: 0, y: 7)
            .shadow(color: isEnabled ? Color.black.opacity(0.12) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(GameBouncyButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
        .accessibilityIdentifier("age-up-button")
        .accessibilityLabel(vm.state.isGameOver ? "Life ended" : "Age up to \(nextAge)")
        .accessibilityHint(vm.state.isGameOver ? "View final legacy and shape of this life" : "Commit the year. Hold actions for previews.")
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if vm.state.isGameOver {
            LinearGradient(
                colors: [Color(white: 0.35), Color(white: 0.22)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if isEnabled {
            enabledGradient
        } else {
            LinearGradient(
                colors: [
                    DesignSystem.Colors.positive.opacity(0.45),
                    DesignSystem.Colors.positive.opacity(0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// BitLife-style bottom chrome: Age Up, four domain tabs, health/journal shortcuts.
private struct BitLifeGameChrome: View {
    @ObservedObject var vm: GameViewModel
    var onOpenFeed: () -> Void
    var onOpenJournal: () -> Void
    var safeAreaBottom: CGFloat

    private var canAct: Bool {
        vm.presentedCard == nil && vm.state.activeYearChapter == nil && !vm.state.isGameOver
    }

    var body: some View {
        VStack(spacing: 6) {
            if let last = vm.state.yearlyStance.lastCompletedStance,
               vm.state.yearlyStance.selectedStance == nil,
               canAct {
                Button {
                    vm.keepLastYearlyStance()
                    AppFeedback.impact(.light)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "repeat.circle.fill")
                        Text("Continue \(last.title)")
                            .font(.caption.weight(.black))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(vm.state.yearlyStance.lastOutcomeLine ?? "worked last year")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(PlannerTone.positive.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bottom-continue-stance-button")
            }

            AgeUpChromeButton(
                vm: vm,
                isEnabled: canAct && !vm.state.isGameOver && !vm.isResolvingInteraction
            ) {
                vm.ageUp()
                if vm.state.isGameOver {
                    AppFeedback.notify(.warning)
                }
            }

            HStack(spacing: 4) {
                ForEach(GameViewModel.Tab.dockTabs) { tab in
                    dockTabButton(tab)
                }
            }
            .accessibilityIdentifier("bottom-domain-strip")

            HStack(spacing: 8) {
                secondaryChromeButton(
                    title: "Health",
                    symbol: "heart.text.square.fill",
                    isActive: vm.showingHealthConsole,
                    accessibilityId: "body-tab"
                ) {
                    vm.showingHealthConsole = true
                    vm.selectedTab = .home
                }

                secondaryChromeButton(
                    title: "Journal",
                    symbol: "book.closed.fill",
                    isActive: false,
                    accessibilityId: "history-tab"
                ) {
                    onOpenJournal()
                }

                Menu {
                    Button {
                        onOpenFeed()
                    } label: {
                        Label("Life Feed", systemImage: "rectangle.stack.person.crop.fill")
                    }
                    Button {
                        vm.showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("More")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.primary)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .accessibilityIdentifier("bottom-actions-menu")
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, max(safeAreaBottom, 6))
        .background(.ultraThinMaterial)
        .accessibilityIdentifier("bottom-game-bar")
    }

    @ViewBuilder
    private func dockTabButton(_ tab: GameViewModel.Tab) -> some View {
        let selected = vm.selectedTab == tab && !vm.showingHealthConsole
        Button {
            AppFeedback.impact(.light)
            vm.showingHealthConsole = false
            vm.selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: vm.dockSymbol(for: tab))
                    .font(.system(size: 15, weight: .bold))
                Text(vm.dockLabel(for: tab))
                    .font(.system(size: 9, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .foregroundStyle(selected ? Color.white : Color.primary.opacity(0.85))
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? DesignSystem.Colors.accent : Color.primary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tab.uiTestTabIdentifier)
    }

    @ViewBuilder
    private func secondaryChromeButton(
        title: String,
        symbol: String,
        isActive: Bool,
        accessibilityId: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            AppFeedback.impact(.light)
            action()
        }) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .heavy))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(isActive ? Color.white : Color.primary.opacity(0.9))
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isActive ? DesignSystem.Colors.accent.opacity(0.92) : Color.primary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId)
    }
}

struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    @State private var isPulsing = false
    @State private var showLifeFeedSheet = false
    @State private var showLifeJournalSheet = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.clear
                        .onAppear {
                            if vm.state.startupState != .active {
                                vm.setupFreshGameIfNeeded()
                            }
                        }
                    plannerBackground
                        .ignoresSafeArea()
                        .saturation(vm.state.narrativeTone.saturation * vm.colorEmphasisSetting.saturation)
                    
                    // Visual Stress Filter: Vignette
                    if vm.state.narrativeTone.vignetteIntensity > 0 {
                        RadialGradient(
                            stops: [
                                .init(color: .clear, location: 0.6),
                                .init(color: Color.black.opacity(vm.state.narrativeTone.vignetteIntensity), location: 1.0)
                            ],
                            center: .center,
                            startRadius: 200,
                            endRadius: 500
                        )
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    }

                    if vm.state.startupState == .active {
                        LifeConsoleView(
                            vm: vm,
                            onOpenFeed: { showLifeFeedSheet = true },
                            onSettings: { vm.showingSettings = true }
                        )
                        .offset(x: vm.actionFrictionJitter ? 4 : 0)
                        .animation(vm.actionFrictionJitter ? .default.repeatCount(3, autoreverses: true) : .default, value: vm.actionFrictionJitter)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            if vm.presentedCard == nil,
                               vm.state.activeYearChapter == nil,
                               !vm.state.isGameOver {
                                BitLifeGameChrome(
                                    vm: vm,
                                    onOpenFeed: { showLifeFeedSheet = true },
                                    onOpenJournal: { showLifeJournalSheet = true },
                                    safeAreaBottom: geometry.safeAreaInsets.bottom
                                )
                                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                            }
                        }
                        .onAppear {
                            if vm.selectedTab == .history {
                                vm.selectedTab = .home
                            }
                        }

                        // Phase 1: Polished floating deltas for instant action feedback (above persistent controls)
                        FloatingDeltasOverlay(deltas: vm.floatingDeltas)
                            .allowsHitTesting(false)

                        AutonomyToastOverlay(toasts: vm.autonomyToasts)
                            .zIndex(48)

                        // Micro-beat (transient reaction text) -- suppressed during popup resolving to keep focus on the processing card/loading.
                        if !vm.isResolvingInteraction, let beat = vm.microBeatOverlay {
                            VStack {
                                Spacer()
                                Text(beat)
                                    .font(.headline.italic())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(Color.black.opacity(0.85))
                                    .clipShape(Capsule())
                                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                                    .padding(.bottom, 160)  // above BitLife chrome + any card bottom content
                            }
                            .ignoresSafeArea()
                            .zIndex(50)
                        }
                    } else if vm.state.startupState == .inheritingLegacy {
                        LegacySelectionView(vm: vm)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        CharacterCreationView(vm: vm)
                            .padding(.top, 14)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 28)
                    }

                    if let saveStatusBanner = vm.saveStatusBanner, vm.state.startupState == .active {
                        saveStatusToast(saveStatusBanner, safeAreaBottom: geometry.safeAreaInsets.bottom)
                            .zIndex(11)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Popup card / processing overlay at ROOT level (outside the startupState if/TabView branch and its .overlays).
                    // This decouples popups from the main shell (TabView vs Legacy vs Creation) so life-end resolution
                    // transitions (setting inheritingLegacy or calling newLife) don't remove the gesture/overlay that
                    // triggered them, preventing "stuck on one screen".
                    // Scrim blocks all underlying (including native tab bar + age-up controls + domain content).
                    // When isResolvingInteraction (set sync on button press, before Task.yield + heavy), we show
                    // processing UI immediately so user doesn't see frozen old popup buttons while yearly sim/refresh/save runs.
                    // (See also the two-speeds comment in LifeSimulationOrchestrator.swift around resolvePreparedYearChapter.)
                    if vm.presentedCard != nil || vm.isResolvingInteraction {
                        ZStack(alignment: .bottom) {
                            // Full dimming scrim (root level ensures it covers TabView content + bar + everything).
                            Color.black.opacity(0.55)
                                .ignoresSafeArea()
                                .allowsHitTesting(true)
                                .onTapGesture {
                                    if !vm.isResolvingInteraction, let card = vm.presentedCard, !vm.isChoiceCard(card) {
                                        AppFeedback.impact(.light)
                                        vm.dismissPresentedCard()
                                    }
                                }
                                .zIndex(1)

                            if vm.isResolvingInteraction {
                                // Processing/loading state (visible immediately after button press thanks to flag + yield).
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.2)
                                    Text(vm.resolvingInteractionContext.map { "Resolving: \($0)" } ?? "Resolving your choice...")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text("Simulating the year (this can take a moment for complex lives).")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(24)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .padding(.bottom, geometry.safeAreaInsets.bottom + 80)
                                .zIndex(2)
                            } else if let card = vm.presentedCard {
                                CompactInteractionOverlay(
                                    card: card,
                                    state: vm.state,
                                    stakes: vm.state.activeYearChapter?.stakes,
                                    stanceChips: vm.forecastStanceChips(),
                                    recommendedStance: vm.recommendedYearlyStance(),
                                    onSelectStance: { vm.setYearlyStance($0) },
                                    onPrepareForecast: { vm.prepareForecastCommitmentIfNeeded() },
                                    onAdvance: {
                                        AppFeedback.impact(.light)
                                        vm.dismissPresentedCard()
                                    },
                                    onPick: { choice in
                                        vm.choose(choice)
                                        if vm.state.isGameOver {
                                            AppFeedback.notify(.warning)
                                        }
                                    },
                                    onCrisisPick: { choice in
                                        vm.resolveCrisis(choice)
                                    },
                                    onPitchPick: { choice in
                                        vm.resolvePitch(choice)
                                    }
                                )
                                .padding(.horizontal, 16)
                                .padding(.bottom, geometry.safeAreaInsets.bottom + 58)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .zIndex(2)
                            }
                        }
                        .zIndex(150)
                    }

                    // Loading overlay during fresh game activation (prevents white screen)
                    if vm.isStartingNewLife {
                        ZStack {
                            Color.black.opacity(0.6).ignoresSafeArea()
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.2)
                                Text("Generating your life...")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                        .zIndex(200)
                        .transition(.opacity)
                    }
                }
            }
            .modifier(HidePlannerNavigationBar())
            .sheet(item: $vm.plannerDetail) { destination in
                PlannerDetailSheet(
                    destination: destination,
                    state: vm.state,
                    roleTitle: vm.roleTitle(),
                    policyLabel: vm.policyLabel(),
                    showingEducationAsPrimaryTab: vm.showingEducationAsPrimaryTab,
                    historyDigest: vm.historyDigest,
                    latestYearSummary: vm.latestYearSummary
                )
            }
            .sheet(item: $vm.selectedInsight) { topic in
                if let insight = vm.changeInsights[topic] {
                    ChangeInsightSheet(insight: insight)
                }
            }
            .sheet(isPresented: $showLifeJournalSheet) {
                NavigationStack {
                    LifeLogView(history: vm.state.history)
                        .accessibilityIdentifier("history-tab-content")
                        .navigationTitle("Journal")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showLifeJournalSheet = false }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showLifeFeedSheet) {
                NavigationStack {
                    ScrollView(showsIndicators: false) {
                        FeedHomeTab(
                            state: vm.state,
                            compactMode: vm.prefersCompactLateGameUI,
                            signals: topSignals(),
                            summaryItems: vm.feedSummaryItems(),
                            urgencyItems: vm.feedUrgencyItems(limit: vm.prefersCompactLateGameUI ? 3 : nil),
                            nextDecisionTitle: vm.nextDecisionPrompt(),
                            nextDecisionDetail: vm.nextDecisionDetail(),
                            queuedInteractionCount: vm.interactionQueueDepth,
                            nowStatus: vm.interactionQueueDepth > 0 ? "Live stack" : vm.chapterStatus(),
                            pendingActionStatus: vm.pendingActionStatus(),
                            pendingActionSummary: vm.pendingActionSummary(),
                            comingUpItems: vm.comingUpItemsForFeed(),
                            recentHistory: vm.historyDigest.all
                        )
                        .padding(.top, 10)
                    }
                    .navigationTitle("Life Feed")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showLifeFeedSheet = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.showingSettings) {
                SettingsSheet(
                    hapticsSetting: $vm.hapticsSetting,
                    animationSetting: $vm.animationSetting,
                    colorEmphasisSetting: $vm.colorEmphasisSetting,
                    startNewLife: vm.newLife,
                    resetSavedProgress: vm.resetSave,
                    openDebugLab: {
                        #if DEBUG
                        vm.showingDebugLab = true
                        #endif
                    }
                )
            }
            #if DEBUG
            .sheet(isPresented: $vm.showingDebugLab) {
                DebugScenarioLabSheet(
                    onLoadScenario: { scenarioID in
                        vm.loadDebugScenario(scenarioID)
                    },
                    onReset: {
                        vm.clearDebugScenario()
                    }
                )
            }
            #endif
            .alert(item: $vm.persistenceAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("Okay"))
                )
            }
            .animation(vm.animationSetting == .off ? nil : .easeInOut(duration: vm.animationSetting == .reduced ? 0.14 : 0.24), value: vm.saveStatusBanner)
            .animation(vm.animationSetting == .off ? nil : .easeInOut(duration: vm.animationSetting == .reduced ? 0.14 : 0.24), value: vm.activityPulse)
            .animation(vm.animationSetting == .off ? nil : .easeInOut(duration: vm.animationSetting == .reduced ? 0.14 : 0.24), value: vm.returnPrompt)
        }
    }

    private var startupExperience: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                startupHeader
                persistenceNotice

                HStack(spacing: 10) {
                    Button {
                        vm.previewQuickStart()
                    } label: {
                        startupModeCard(
                            title: "Quick Start",
                            subtitle: "Weighted random origin with immediate replay value.",
                            isSelected: vm.selectedStartMode == .quickStart
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("quick-start-button")

                    Button {
                        vm.previewTemplate(vm.selectedTemplate)
                    } label: {
                        startupModeCard(
                            title: "Build My Start",
                            subtitle: "Pick a teen origin template, then reroll the details.",
                            isSelected: vm.selectedStartMode == .template
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("template-start-button")
                }

                if vm.selectedStartMode == .template {
                    templatePicker
                }

                if let preview = vm.originPreview {
                    OriginPreviewCard(state: preview)

                    HStack(spacing: 10) {
                        Button("Randomize Details") {
                            AppFeedback.impact(.light)
                            vm.rerollOrigin()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("reroll-origin-button")

                        Button {
                            AppFeedback.notify(.success)
                            vm.beginLife()
                        } label: {
                            Label("Begin at 14", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("begin-life-button")
                    }
                }
            }
        }
        .accessibilityIdentifier("startup-screen")
    }

    private var startupHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OneLife")
                .font(.largeTitle.weight(.bold))

            Text("Start with a compressed backstory, land at age 14, and let the real shaping happen from there.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func startupModeCard(title: String, subtitle: String, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(isSelected ? Color.white.opacity(0.82) : .secondary)
                .lineLimit(3)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.black.opacity(0.82) : Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var templatePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(vm.filteredTemplates, id: \.id) { template in
                    Button {
                        vm.previewTemplate(template.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(template.title)
                                .font(.subheadline.weight(.semibold))
                            Text(template.summary)
                                .font(.caption)
                                .foregroundStyle(vm.selectedTemplate == template.id ? Color.white.opacity(0.82) : .secondary)
                                .lineLimit(3)
                        }
                        .foregroundStyle(vm.selectedTemplate == template.id ? Color.white : Color.primary)
                        .padding(14)
                        .frame(width: 190, alignment: .leading)
                        .background(vm.selectedTemplate == template.id ? Color.black.opacity(0.82) : Color.white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var persistenceNotice: some View {
        if let message = vm.persistenceBanner {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(PlannerTone.warning.color)
                    .padding(.top, 2)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Button {
                    vm.persistenceBanner = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.white.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(PlannerTone.warning.fill, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var plannerBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.08, green: 0.09, blue: 0.10),
                    Color(red: 0.13, green: 0.13, blue: 0.12)
                ]
                : [
                    Color(red: 0.96, green: 0.96, blue: 0.93),
                    Color(red: 0.90, green: 0.93, blue: 0.91)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func returnPromptBanner(_ prompt: PlannerReturnContext) -> some View {
        HStack {
            Button {
                AppFeedback.impact(.light)
                vm.reopenReturnDetail()
            } label: {
                Label(prompt.title, systemImage: "arrow.uturn.backward.circle.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("return-to-detail-button")

            Spacer()
        }
    }

    private func activityPulseBanner(_ pulse: ActivityPulse) -> some View {
        let isWorldReaction = pulse.title.contains("World Reaction") || pulse.title.contains("Action +")

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: isWorldReaction ? "globe" : (pulse.tone == .warning ? "flame.fill" : "sparkles"))
                .foregroundStyle(isWorldReaction ? Color.purple : pulse.tone.color)
                .padding(.top, 2)
                .scaleEffect(isWorldReaction ? 1.1 : 1.0)

            VStack(alignment: .leading, spacing: 4) {
                if isWorldReaction {
                    Text("WORLD REACTED")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(pulse.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isWorldReaction ? Color.primary : .primary)

                Text(pulse.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(6)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isWorldReaction ? Color.purple.opacity(0.06) : OLTheme.cardFill(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isWorldReaction ? Color.purple.opacity(0.35) : pulse.tone.fill, lineWidth: isWorldReaction ? 1.5 : 1)
        )
        .shadow(color: isWorldReaction ? Color.purple.opacity(0.15) : Color.black.opacity(OLTheme.cardShadowOpacity(colorScheme)), radius: isWorldReaction ? 16 : 12, x: 0, y: 6)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: pulse.title)
        .accessibilityIdentifier("activity-pulse-banner")
    }

    private func saveStatusToast(_ message: String, safeAreaBottom: CGFloat) -> some View {
        Text(message)
            .font(.caption.weight(.semibold))
            .foregroundStyle(PlannerTone.positive.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(PlannerTone.positive.fill, lineWidth: 1)
            )
            .padding(.bottom, safeAreaBottom + 168)
    }

    @ViewBuilder
    private func homeJumpTabButton(tab: GameViewModel.Tab, label: String, accessibilityId: String) -> some View {
        Button {
            vm.selectedTab = tab
            AppFeedback.impact(.light)
        } label: {
            Text(label)
                .font(.caption.weight(.heavy))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(vm.selectedTab == tab ? Color.white : Color.primary.opacity(0.85))
                .background(
                    Capsule()
                        .fill(vm.selectedTab == tab ? DesignSystem.Colors.accent : Color.white.opacity(0.72))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId)
    }

    @ViewBuilder
    private func homeUrgencyRow(item: PlannerInsight, showChevron: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(item.tone.color)
                .frame(width: 10, height: 10)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(item.value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.tone.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
    }

    private func homeUrgencyAccessibilityId(forTitle title: String) -> String {
        switch title {
        case "Money Pressure": return "home-urgency-money"
        case "School Momentum": return "home-urgency-school"
        case "Work Stability": return "home-urgency-work"
        case "Social Life": return "home-urgency-social"
        case "Burnout": return "home-urgency-burnout"
        default: return "home-urgency-row"
        }
    }

    @ViewBuilder
    private var activeTabContent: some View {
        switch vm.selectedTab {
        case .home:
            let compactHome = vm.prefersCompactLateGameUI
            VStack(alignment: .leading, spacing: 20) {
                if let ribbon = vm.lateGameContextRibbon() {
                    PlannerSectionCard(
                        title: "Life Chapter",
                        symbol: "clock.arrow.circlepath",
                        status: ribbon,
                        tone: .neutral
                    ) {
                        Text("Tap sections below to expand. The Life tab keeps quick actions up front.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("home-late-game-ribbon")
                }

                PlannerSectionCard(
                    title: "Auto-Life Pace",
                    symbol: "forward.end.fill",
                    status: vm.autoLifePace.title,
                    tone: vm.autoLifePace == .autopilot ? .positive : .neutral,
                    collapsible: compactHome,
                    startsCollapsed: compactHome
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Auto-Life Pace", selection: $vm.autoLifePace) {
                            ForEach(AutoLifePace.allCases) { pace in
                                Text(pace.title).tag(pace)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("auto-life-pace-picker")

                        if vm.autoLifePace != .manual, let recommendation = vm.guidedRecommendation() {
                            Button {
                                vm.applyGuidedRecommendation()
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(recommendation.tone.color)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(vm.autoLifePace == .autopilot ? "Autopilot will favor this" : "Guided pick")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                        Text(recommendation.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text(recommendation.cost)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(10)
                                .background(recommendation.tone.fill)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("guided-recommendation-button")
                        }
                    }
                }
                .accessibilityIdentifier("home-auto-life")

                PlannerSectionCard(
                    title: "Year Goal",
                    symbol: "scope",
                    status: yearGoalStatusLine(vm: vm),
                    tone: vm.state.yearlyStance.selectedStance == nil ? .neutral : .positive
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        if let selected = vm.state.yearlyStance.selectedStance {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(PlannerTone.positive.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selected.title)
                                        .font(.caption.weight(.heavy))
                                    Text("Locked in for this year. Change it on the forecast when you age up.")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(10)
                            .background(PlannerTone.positive.fill)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityIdentifier("home-year-goal-committed")
                        } else {
                            Text("Commit on the forecast when you age up — swipe the stakes, then pick what you are protecting.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("home-year-goal-hint")
                        }

                        if let last = vm.state.yearlyStance.lastCompletedStance,
                           vm.state.yearlyStance.selectedStance == nil {
                            Button {
                                vm.keepLastYearlyStance()
                            } label: {
                                HStack {
                                    Label("Keep \(last.title)", systemImage: "repeat")
                                        .font(.caption.weight(.heavy))
                                    Spacer(minLength: 0)
                                    if let line = vm.state.yearlyStance.lastOutcomeLine {
                                        Text(line)
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    // D4 residue
                                    if vm.state.yearlyStance.recentStances.count >= 2 {
                                        let echo = vm.state.yearlyStance.recentStances.prefix(2).map { $0.title }.joined(separator: " → ")
                                        Text("Recent: \(echo)")
                                            .font(.caption2.italic())
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(10)
                                .background(PlannerTone.positive.fill)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("keep-yearly-stance-button")
                        }
                    }
                }
                .accessibilityIdentifier("home-yearly-stance")

                PlannerSectionCard(
                    title: "Recommended Action",
                    symbol: "bolt.fill",
                    status: vm.pressureContextLines(limit: 1).first ?? "This year",
                    tone: vm.feedUrgencyItems().contains(where: { $0.tone == .warning }) ? .warning : .neutral
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(vm.recommendedActionChips().prefix(1))) { action in
                            Button {
                                vm.setAction(action.choiceID, for: action.domain)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "bolt.circle.fill")
                                        .foregroundStyle(action.tone.color)
                                        .padding(.top, 2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(action.title)
                                            .font(.subheadline.weight(.heavy))
                                            .foregroundStyle(Color.primary)
                                            .lineLimit(2)
                                        Text(action.relief)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(action.tone.color)
                                            .lineLimit(1)
                                        Text("Why: \(action.cost)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.white.opacity(0.72))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("action-choice-\(action.choiceID.rawValue)")
                        }
                    }
                }
                .accessibilityIdentifier("home-quick-actions")

                PlannerSectionCard(
                    title: compactHome ? "Signals" : "Top Status",
                    symbol: "exclamationmark.bubble.fill",
                    status: vm.feedUrgencyItems().first(where: { $0.tone == .warning })?.value
                        ?? vm.feedUrgencyItems().first?.value
                        ?? "Glance",
                    tone: vm.feedUrgencyItems().contains(where: { $0.tone == .warning }) ? .warning : .neutral,
                    collapsible: compactHome,
                    startsCollapsed: compactHome
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(vm.feedUrgencyItems(limit: compactHome ? 2 : nil)) { item in
                                Button {
                                    if let dest = vm.plannerDestination(forUrgencyItemTitle: item.title) {
                                        AppFeedback.impact(.light)
                                        vm.openDetail(dest)
                                    }
                                } label: {
                                    homeUrgencyRow(
                                        item: item,
                                        showChevron: vm.plannerDestination(forUrgencyItemTitle: item.title) != nil
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier(homeUrgencyAccessibilityId(forTitle: item.title))
                            }
                        }
                    }
                }
                .accessibilityIdentifier("home-opportunities")

                PlannerSectionCard(
                    title: "Background Pulse",
                    symbol: "waveform.path.ecg",
                    status: vm.backgroundPulseItems().first?.detail ?? "Quiet",
                    tone: vm.backgroundPulseItems().contains(where: { $0.tone == .warning }) ? .warning : .neutral,
                    collapsible: compactHome,
                    startsCollapsed: true
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(vm.backgroundPulseItems()) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(item.tone.color)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 5)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.caption.weight(.bold))
                                    Text(item.detail)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer(minLength: 0)
                            }
                            .accessibilityIdentifier("background-pulse-item")
                        }
                        if vm.backgroundPulseItems().isEmpty {
                            Text("No background pressure is asking for attention.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                homeJumpTabButton(tab: .occupation, label: vm.showingEducationAsPrimaryTab ? "School" : "Jobs", accessibilityId: "home-jump-career")
                                homeJumpTabButton(tab: .assets, label: "Money", accessibilityId: "home-jump-finance")
                                homeJumpTabButton(tab: .relationships, label: "People", accessibilityId: "home-jump-relationships")
                                homeJumpTabButton(tab: .history, label: "Journal", accessibilityId: "home-jump-history")
                            }
                            .padding(.horizontal, 2)
                        }
                        .accessibilityIdentifier("home-systems-strip")
                    }
                }
                .accessibilityIdentifier("home-background-pulse")

                if !vm.summaryItems(for: .home).isEmpty {
                    PlannerSectionCard(
                        title: "What Shifted",
                        symbol: "arrow.triangle.branch",
                        status: "Year \(vm.state.player.age)",
                        tone: vm.summaryItems(for: .home).contains(where: { PlannerTone($0.tone) == .warning }) ? .warning : .positive
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(vm.summaryItems(for: .home)) { item in
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .accessibilityIdentifier("home-summary-card")
                }
            }
            .padding(.horizontal, 18)
            .accessibilityIdentifier("home-tab-content")

        case .occupation:
            VStack(alignment: .leading, spacing: 20) {
                if vm.state.player.age < 18 || vm.state.education.pathway == .student {
                    EducationPlannerTab(
                        state: vm.state,
                        isTeenExperience: vm.isTeenExperience,
                        whyItMatters: vm.educationWhyItMatters(),
                        schoolClimateMetrics: vm.teenSchoolClimateMetrics(),
                        pressureSources: vm.teenPressureSources(),
                        nextUnlocks: vm.teenUnlocks(),
                        summaryItems: vm.summaryItems(for: .occupation),
                        recentHistory: vm.historyDigest.education,
                        actionChoices: vm.actionChoices(for: .education),
                        onSelectAction: { vm.setAction($0, for: .education) },
                        comingUpItems: vm.comingUpItems(for: .occupation),
                        openDetail: vm.openDetail(_:)
                    )
                } else {
                    CareerPlannerTab(
                        state: vm.state,
                        roleTitle: vm.roleTitle(),
                        summaryItems: vm.summaryItems(for: .occupation),
                        recentHistory: vm.historyDigest.all,
                        actionChoices: vm.actionChoices(for: .career),
                        onSelectAction: { vm.setAction($0, for: .career) },
                        crimeActionChoices: vm.actionChoices(for: .crime),
                        onSelectCrimeAction: { vm.setAction($0, for: .crime) },
                        comingUpItems: vm.comingUpItems(for: .occupation),
                        openDetail: vm.openDetail(_:)
                    )
                }
            }
            .padding(.horizontal, 18)

        case .assets:
            VStack(alignment: .leading, spacing: 16) {
                // QoL visual header for Assets tab
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Net Worth")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("$\(vm.state.finance.totalWealth)")
                            .font(.title3.weight(.black))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundStyle(Color.purple.opacity(0.8))
                }
                .padding(.horizontal, 4)
                
                FinancePlannerTab(
                    state: vm.state,
                    isTeenExperience: vm.isTeenExperience,
                    teenMetrics: vm.teenFinanceMetrics(),
                    policyLabel: vm.policyLabel(),
                    summaryItems: vm.summaryItems(for: .assets),
                    recentHistory: vm.historyDigest.finance,
                    actionChoices: vm.actionChoices(for: .finance),
                    onSelectAction: { vm.setAction($0, for: .finance) },
                    comingUpItems: vm.comingUpItems(for: .assets),
                    openDetail: vm.openDetail(_:)
                )

                AssetsPlannerTab(
                    state: vm.state,
                    onBuyFirearm: { vm.buyFirearm($0, cost: $1) },
                    onUpgradeFirearm: { vm.upgradeFirearm($0, upgrade: $1) },
                    onBuyVehicle: { vm.buyVehicle($0, cost: $1) },
                    onUpgradeVehicle: { vm.upgradeVehicle($0, upgrade: $1) },
                    onUpgradeHouse: { vm.upgradeHouse($0) },
                    onSellHouse: { vm.sellProperty() },
                    onBuyJewelry: { vm.buyJewelry($0) },
                    onSellJewelry: { vm.sellJewelry($0) },
                    onBuyAviation: { vm.buyAviation($0) },
                    onSellAviation: { vm.sellAviation($0) },
                    onBuyMarine: { vm.buyMarine($0) },
                    onSellMarine: { vm.sellMarine($0) },
                    // Assets2
                    onBuySignature: { vm.buySignatureAsset($0) },
                    onSellSignature: { vm.sellSignatureAsset($0) }
                )

                AssetsHousingLegacySection(state: vm.state, openDetail: vm.openDetail(_:))
            }
            .padding(.horizontal, 18)

        case .relationships:
            RelationshipsPlannerTab(
                state: vm.state,
                isTeenExperience: vm.isTeenExperience,
                teenMetrics: vm.teenRelationshipMetrics(),
                summaryItems: vm.summaryItems(for: .relationships),
                recentHistory: vm.historyDigest.relationships,
                actionChoices: vm.actionChoices(for: .relationships),
                onSelectAction: { vm.setAction($0, for: .relationships) },
                comingUpItems: vm.comingUpItems(for: .relationships),
                openDetail: vm.openDetail(_:)
            )
            .padding(.horizontal, 18)

        case .history:
            VStack(alignment: .leading, spacing: 12) {
                LifeLogView(history: vm.state.history)
            }
            .padding(.horizontal, 18)
            .accessibilityIdentifier("history-tab-content")
        }
    }

    private func topSignals() -> [SignalSummary] {
        let thirdSignal = vm.showingEducationAsPrimaryTab
            ? SignalSummary(
                symbol: vm.state.education.stage == .inactive && vm.state.education.pathway == .graduate ? "checkmark.seal.fill" : "book.closed.fill",
                title: "Education",
                value: vm.state.education.stage == .university
                    ? (vm.state.education.hasScholarship ? "University" : "College Load")
                    : (vm.state.education.stage == .tradeTraining
                        ? "Trade Track"
                        : (vm.state.education.pathway == .graduate && vm.state.education.stage == .inactive
                            ? "Graduated"
                            : (vm.state.education.schoolStanding >= 70 ? "On Track" : (vm.state.education.burnoutRisk >= 55 || vm.state.education.attendancePressure >= 55 ? "At Risk" : "Holding")))),
                tone: vm.state.education.stage == .inactive && vm.state.education.pathway == .graduate ? .positive : (vm.state.education.burnoutRisk >= 55 || vm.state.education.attendancePressure >= 55 ? .warning : .neutral)
            )
            : SignalSummary(
                symbol: vm.state.career.status == .unemployed ? "briefcase.circle.fill" : "briefcase.fill",
                title: "Career",
                value: vm.roleTitle(),
                tone: vm.state.career.status == .unemployed ? .warning : (vm.state.career.performance >= 75 ? .positive : .neutral)
            )

        return [
            SignalSummary(
                symbol: vm.state.finance.lastYearBalanceDelta < 0 ? "arrow.down.circle.fill" : "arrow.up.right.circle.fill",
                title: "Cash Flow",
                value: vm.state.finance.lastYearBalanceDelta < 0 ? "Deficit" : (vm.state.finance.lastYearBalanceDelta > 4_000 ? "Surplus" : "Stable"),
                tone: vm.state.finance.lastYearBalanceDelta < 0 ? .warning : (vm.state.finance.lastYearBalanceDelta > 4_000 ? .positive : .neutral)
            ),
            SignalSummary(
                symbol: vm.state.healthProfile.activeConditions.isEmpty ? "heart.fill" : "cross.case.fill",
                title: "Health",
                value: vm.state.healthProfile.activeConditions.isEmpty ? "Stable" : "\(vm.state.healthProfile.activeConditions.count) issue\(vm.state.healthProfile.activeConditions.count == 1 ? "" : "s")",
                tone: vm.state.healthProfile.activeConditions.isEmpty && vm.state.player.health >= 55 ? .positive : (vm.state.player.health < 40 ? .warning : .neutral)
            ),
            thirdSignal
        ]
    }
}


struct HistoryDigest {
    let all: [HistoryEntry]
    let education: [HistoryEntry]
    let finance: [HistoryEntry]
    let relationships: [HistoryEntry]
    let health: [HistoryEntry]
    let activities: [HistoryEntry]
    let life: [HistoryEntry]

    static let empty = HistoryDigest(all: [], education: [], finance: [], relationships: [], health: [], activities: [], life: [])

    init(state: GameState) {
        let budget = PerformanceBudgets.maxRenderedHistoryItems
        all = Array(state.history.prefix(budget))
        education = Self.entries(in: state.history, matching: [.education, .progress], budget: budget)
        finance = Self.entries(in: state.history, matching: [.finance, .progress], budget: budget)
        relationships = Self.entries(in: state.history, matching: [.relationships, .progress], budget: budget)
        health = Self.entries(in: state.history, matching: [.health, .progress], budget: budget)
        activities = Self.entries(in: state.history, matching: [.activities, .health, .relationships, .finance], budget: budget)
        life = Self.entries(in: state.history, matching: [.housing, .assets, .progress, .lifeEvent], budget: budget)
    }

    private init(all: [HistoryEntry], education: [HistoryEntry], finance: [HistoryEntry], relationships: [HistoryEntry], health: [HistoryEntry], activities: [HistoryEntry], life: [HistoryEntry]) {
        self.all = all
        self.education = education
        self.finance = finance
        self.relationships = relationships
        self.health = health
        self.activities = activities
        self.life = life
    }

    private static func entries(in history: [HistoryEntry], matching tags: [HistoryDomainTag], budget: Int) -> [HistoryEntry] {
        let tagSet = Set(tags)
        return Array(history.lazy.filter { !$0.tags.isEmpty && !tagSet.isDisjoint(with: $0.tags) }.prefix(budget))
    }
}

private struct SignalSummary {
    let symbol: String
    let title: String
    let value: String
    let tone: PlannerTone
    let insightTopic: ChangeInsightTopic?

    init(symbol: String, title: String, value: String, tone: PlannerTone, insightTopic: ChangeInsightTopic? = nil) {
        self.symbol = symbol
        self.title = title
        self.value = value
        self.tone = tone
        self.insightTopic = insightTopic
    }
}

private struct StatusPill: View {
    let symbol: String
    let title: String
    let value: String
    let tone: PlannerTone

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tone.color)
                .frame(width: 30, height: 30)
                .background(tone.fill)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tone.color)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tone.fill, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

private struct PlannerSectionCard<Content: View>: View {
    let title: String
    let symbol: String
    let status: String?
    let tone: PlannerTone
    let detailTitle: String?
    let detailIdentifier: String?
    let detailAction: (() -> Void)?
    let collapsible: Bool
    let startsCollapsed: Bool
    @ViewBuilder let content: () -> Content

    @State private var isExpanded = true

    init(
        title: String,
        symbol: String,
        status: String? = nil,
        tone: PlannerTone = .neutral,
        detailTitle: String? = nil,
        detailIdentifier: String? = nil,
        detailAction: (() -> Void)? = nil,
        collapsible: Bool = false,
        startsCollapsed: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.status = status
        self.tone = tone
        self.detailTitle = detailTitle
        self.detailIdentifier = detailIdentifier
        self.detailAction = detailAction
        self.collapsible = collapsible
        self.startsCollapsed = startsCollapsed
        self.content = content
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Group {
                    if collapsible {
                        Button {
                            AppFeedback.impact(.light)
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            headerLabel
                        }
                        .buttonStyle(.plain)
                    } else {
                        headerLabel
                    }
                }

                Spacer()

                if collapsible {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                }

                if let detailTitle, let detailAction {
                    Button(detailTitle, action: detailAction)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(minHeight: 44)
                        .background(OLTheme.subtleFill(colorScheme))
                        .clipShape(Capsule())
                        .accessibilityIdentifier(detailIdentifier ?? "\(title.lowercased())-detail-button")
                }
            }

            if !collapsible || isExpanded {
                content()
                    .transition(.opacity)
            }
        }
        .onAppear {
            isExpanded = collapsible ? !startsCollapsed : true
        }
        .onChange(of: startsCollapsed) { _, collapsed in
            if collapsible, collapsed {
                isExpanded = false
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(OLTheme.cardFill(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(OLTheme.cardStroke(colorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(OLTheme.cardShadowOpacity(colorScheme)), radius: 18, x: 0, y: 8)
        .accessibilityElement(children: .contain)
    }

    private var headerLabel: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(tone.color)
                .frame(width: 36, height: 36)
                .background(tone.fill)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                if let status {
                    Text(status)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tone.color)
                        .lineLimit(2)
                }
            }
        }
    }
}

private struct MetricRow: View {
    let metrics: [(String, String, PlannerTone)]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                MetricTile(label: metric.0, value: metric.1, tone: metric.2)
            }
        }
    }
}

private struct MetricTile: View {
    let label: String
    let value: String
    let tone: PlannerTone

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tone.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tone.fill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

private struct RecentLifeModule: View {
    let history: [HistoryEntry]
    let detailAction: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    init(history: [HistoryEntry], detailAction: (() -> Void)? = nil) {
        self.history = history
        self.detailAction = detailAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Life")
                    .font(.headline)
                Spacer()
                if let detailAction {
                    Button("Full History", action: detailAction)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(minHeight: 44)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Capsule())
                }
            }

            if history.isEmpty {
                Text("Your recent years will land here after your next turn.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(history.prefix(3))) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Age \(item.age) • \(item.title)")
                            .font(.subheadline.weight(.semibold))
                        Text(item.text)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large, style: .continuous)
                .fill(OLTheme.cardFill(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large, style: .continuous)
                .stroke(OLTheme.cardStroke(colorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(OLTheme.cardShadowOpacity(colorScheme)), radius: 14, x: 0, y: 6)
        .accessibilityElement(children: .contain)
    }
}

private struct TrendBadge: View {
    let title: String
    let tone: PlannerTone

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(tone.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tone.fill)
            .clipShape(Capsule())
    }
}

private struct OverviewSignalStrip: View {
    let signals: [OverviewSignal]
    let identifier: String
    let onSelectInsight: (ChangeInsightTopic) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(signals.prefix(3)) { signal in
                Group {
                    if let insightTopic = signal.insightTopic {
                        Button {
                            AppFeedback.impact(.light)
                            onSelectInsight(insightTopic)
                        } label: {
                            metricTile(for: signal)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("insight-\(insightTopic.rawValue)-button")
                    } else {
                        metricTile(for: signal)
                    }
                }
            }
        }
        .accessibilityIdentifier(identifier)
    }

    private func metricTile(for signal: OverviewSignal) -> some View {
        MetricTile(label: signal.title, value: signal.value, tone: signal.tone)
            .overlay(alignment: .topTrailing) {
                Image(systemName: signal.symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(signal.tone.color)
                    .padding(10)
            }
    }
}

private struct CompactFocusDock: View {
    let focus: RecommendedFocus
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void

    var body: some View {
        ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
    }
}

private struct CompressedPlannerTab: View {
    let identifier: String
    let overview: TabOverviewModel
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let openDetail: (PlannerDetailDestination) -> Void
    let openInsight: (ChangeInsightTopic) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PlannerSectionCard(
                title: overview.title,
                symbol: overview.symbol,
                status: overview.status,
                tone: overview.tone,
                detailTitle: overview.detailDestination == nil ? nil : "Details",
                detailIdentifier: overview.detailDestination.map { detailIdentifier(for: $0) },
                detailAction: overview.detailDestination.map { destination in { openDetail(destination) } }
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        TrendBadge(title: overview.trendLabel, tone: overview.tone)
                    }

                    if !overview.summary.isEmpty {
                        Text(overview.summary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
            }
            .accessibilityIdentifier("\(identifier)-overview-header")

            OverviewSignalStrip(signals: overview.topSignals, identifier: "\(identifier)-overview-audit", onSelectInsight: openInsight)

            if let continuity = overview.continuity {
                PlannerSectionCard(
                    title: "Continuity",
                    symbol: "timeline.selection",
                    status: continuity.status,
                    tone: continuity.unresolved.contains(where: { $0.tone == .warning }) ? .warning : .neutral
                ) {
                    ContinuityHubSection(model: continuity, identifier: "\(identifier)-continuity")
                }
                .accessibilityIdentifier("\(identifier)-continuity-card")
            }

            PlannerSectionCard(
                title: "Pressure Read",
                symbol: overview.primaryPressure.symbol,
                status: overview.primaryPressure.title,
                tone: overview.primaryPressure.tone,
                detailTitle: overview.primaryPressure.destination == nil ? nil : "Inspect",
                detailIdentifier: overview.primaryPressure.destination.map { pressureDetailIdentifier(for: $0) },
                detailAction: overview.primaryPressure.destination.map { destination in { openDetail(destination) } }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(overview.primaryPressure.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    CompactFocusDock(
                        focus: overview.recommendedFocus,
                        actionChoices: actionChoices,
                        onSelectAction: onSelectAction
                    )
                }
            }
            .accessibilityIdentifier("\(identifier)-overview-pressure")

            if !overview.stripItems.isEmpty {
                PlannerSectionCard(
                    title: overview.stripTitle,
                    symbol: "timeline.selection",
                    status: overview.stripItems.first ?? overview.trendLabel,
                    tone: .neutral
                ) {
                    ChipStrip(title: overview.stripTitle, items: overview.stripItems, tone: .neutral, identifier: "\(identifier)-overview-strip")
                }
            }
        }
        .accessibilityIdentifier("\(identifier)-tab-content")
    }

    private func detailIdentifier(for destination: PlannerDetailDestination) -> String {
        switch destination {
        case .careerOverview: return "career-overview-detail-button"
        case .educationOverview: return "education-overview-detail-button"
        case .financeCashflow: return "finance-cashflow-detail-button"
        case .relationshipsConnections: return "relationships-connections-detail-button"
        case .healthOverview: return "health-overview-detail-button"
        case .lifeHousing: return "life-housing-detail-button"
        default: return "planner-overview-detail-button"
        }
    }

    private func pressureDetailIdentifier(for destination: PlannerDetailDestination) -> String {
        switch destination {
        case .educationClimate: return "education-pressure-detail-button"
        case .careerTrack: return "career-track-detail-button"
        case .financePolicy: return "finance-policy-detail-button"
        case .relationshipsFamily: return "relationships-family-detail-button"
        case .relationshipsConnections: return "relationships-connections-detail-button"
        case .healthConditions: return "health-conditions-detail-button"
        default: return detailIdentifier(for: destination)
        }
    }
}

private struct ContinuityHubSection: View {
    let model: ContinuityHubModel
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            continuityGroup(title: "What Changed", items: model.changed)
            continuityGroup(title: "Still Active", items: model.unresolved)

            if !model.comingBack.isEmpty {
                ChipStrip(title: "Coming Back", items: model.comingBack, tone: .neutral, identifier: "\(identifier)-coming-back")
            }
        }
        .accessibilityIdentifier(identifier)
    }

    @ViewBuilder
    private func continuityGroup(title: String, items: [ContinuityHubItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(item.tone.color)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
            }
        }
    }
}

private struct AutonomyToastOverlay: View {
    let toasts: [AutonomyToast]

    var body: some View {
        VStack {
            if !toasts.isEmpty {
                VStack(spacing: 8) {
                    ForEach(toasts) { toast in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(toast.tone.color)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(toast.title)
                                    .font(.caption.weight(.black))
                                Text(toast.detail)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(toast.tone.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
                        .accessibilityIdentifier("autonomy-toast")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .allowsHitTesting(false)
        .accessibilityIdentifier("autonomy-toast-stack")
    }
}

private struct FeedHomeTab: View {
    let state: GameState
    var compactMode: Bool = false
    let signals: [SignalSummary]
    let summaryItems: [YearlyOutcomeItem]
    let urgencyItems: [PlannerInsight]

    @State private var expandedPressureMap = false
    let nextDecisionTitle: String
    let nextDecisionDetail: String
    let queuedInteractionCount: Int
    let nowStatus: String
    let pendingActionStatus: String
    let pendingActionSummary: String
    let comingUpItems: [String]
    let recentHistory: [HistoryEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            feedHero
                .accessibilityIdentifier("feed-overview-header")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(signals, id: \.title) { signal in
                        StatusPill(symbol: signal.symbol, title: signal.title, value: signal.value, tone: signal.tone)
                    }
                }
                .padding(.horizontal, 2)
                .accessibilityIdentifier("feed-overview-audit")
            }
            .accessibilityIdentifier("life-signals")

            PlannerSectionCard(
                title: "Pressure Map",
                symbol: "exclamationmark.bubble.fill",
                status: urgencyItems.first?.value ?? "Stable",
                tone: urgencyItems.contains(where: { $0.tone == .warning }) ? .warning : .neutral,
                collapsible: compactMode,
                startsCollapsed: false
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    let visible = compactMode && !expandedPressureMap
                        ? Array(urgencyItems.prefix(2))
                        : urgencyItems
                    ForEach(visible) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(item.tone.color)
                                .frame(width: 10, height: 10)
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(item.value)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(item.tone.color)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    if compactMode, urgencyItems.count > 2 {
                        Button(expandedPressureMap ? "Show fewer" : "Show all pressures") {
                            withAnimation { expandedPressureMap.toggle() }
                        }
                        .font(.caption.weight(.bold))
                        .accessibilityIdentifier("feed-pressure-expand")
                    }
                }
            }
            .accessibilityIdentifier("feed-overview-pressure")

            if !comingUpItems.isEmpty {
                PlannerSectionCard(
                    title: "Coming Up",
                    symbol: "hourglass.bottomhalf.filled",
                    status: comingUpItems.first ?? "Nothing urgent",
                    tone: .neutral
                ) {
                    ChipStrip(title: "Brace For", items: comingUpItems, tone: .neutral, identifier: "feed-coming-up")
                }
            }

            PlannerSectionCard(
                title: "Now",
                symbol: "bolt.horizontal.circle.fill",
                status: nowStatus,
                tone: queuedInteractionCount > 0 ? .positive : .warning
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(nextDecisionTitle)
                        .font(.headline)
                    Text(nextDecisionDetail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    Text(queuedInteractionCount > 0 ? "Finish the live card stack to settle the year." : pendingActionSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("feed-now-card")

            if !summaryItems.isEmpty {
                PlannerSectionCard(
                    title: "What Shifted",
                    symbol: "arrow.triangle.branch",
                    status: "Year \(state.player.age)",
                    tone: summaryItems.contains(where: { PlannerTone($0.tone) == .warning }) ? .warning : .positive,
                    collapsible: compactMode,
                    startsCollapsed: compactMode
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(summaryItems.prefix(compactMode ? 2 : summaryItems.count))) { item in
                            let tone = PlannerTone(item.tone)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(tone.color)
                                Text(item.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .accessibilityIdentifier("feed-summary-card")
            }

            RecentLifeModule(history: recentHistory)
        }
        .accessibilityIdentifier("feed-tab-content")
    }

    private var feedHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Life Feed")
                .font(.title.weight(.bold))
            Text("Pressure, timing, and momentum — read fast, tap once to drill down.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private func yearGoalStatusLine(vm: GameViewModel) -> String {
    let stance = vm.state.yearlyStance.selectedStance?.title ?? "Recommended: \(vm.recommendedYearlyStance().title)"
    // D4: surface ambient life shape from recent focus residue
    let recent = vm.state.yearlyStance.recentStances
    let shape = recent.isEmpty ? "" : (recent.filter { $0 == .letYearDrift }.count > recent.count / 2 ? " · loose shape" : (recent.filter { [.pushCareer, .soldierStance].contains($0) }.count > 1 ? " · driven current" : " · pragmatic"))
    return "\(stance) · \(vm.state.resilience.shortLabel)\(shape)"
}

private struct ForecastStakesPage: Identifiable {
    let id: String
    let label: String
    let title: String
    let detail: String
    let tone: PlannerTone
    let icon: String
}

private struct CompactInteractionOverlay: View {
    let card: InteractionCardPayload
    let state: GameState
    var stakes: TurnStakesSnapshot? = nil
    var stanceChips: [YearlyStanceChip] = []
    var recommendedStance: YearlyStanceID = .protectHealth
    var onSelectStance: ((YearlyStanceID) -> Void)? = nil
    var onPrepareForecast: (() -> Void)? = nil
    let onAdvance: () -> Void
    let onPick: (EventChoice) -> Void
    let onCrisisPick: (CrisisChoice) -> Void
    let onPitchPick: (PitchDeckChoice) -> Void

    @State private var stakesPageIndex = 0

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                Capsule()
                    .fill(Color.primary.opacity(0.16))
                    .frame(width: 42, height: 5)
                    .frame(maxWidth: .infinity)

                switch card {
                case .forecast(let forecast):
                    forecastView(forecast)
                case .yearSummary(let summary):
                    summaryView(summary)
                case .event(let event):
                    eventView(event)
                case .reaction(let reaction):
                    reactionView(reaction)
                case .consequence(let preview):
                    consequenceView(preview)
                case .resolution(let preview):
                    resolutionView(preview)
                case .crisis(let crisis):
                    crisisView(crisis)
                case .pitchDeck(let pitch):
                    pitchDeckView(pitch)
                }
            }
            .padding(18)
            .frame(maxWidth: 560, alignment: .leading)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 30, y: 14)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(sheetAccessibilityIdentifier)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var sheetAccessibilityIdentifier: String {
        switch card {
        case .forecast:
            return "forecast-sheet"
        case .yearSummary:
            return "year-summary-sheet"
        case .event:
            return "event-sheet"
        case .reaction:
            return "reaction-sheet"
        case .consequence:
            return "consequence-card"
        case .resolution:
            return "resolution-card"
        case .crisis:
            return "crisis-card"
        case .pitchDeck:
            return "pitch-deck-card"
        }
    }

    private func summaryView(_ summary: YearlyOutcomeSummary) -> some View {
        // Phase 6–7: Playable hierarchy + yearly feedback closer to instant layer
        let resilienceAccent = state.resilience == .grounded ? Color.orange.opacity(0.35) : Color.green.opacity(0.28)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Age \(summary.age)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Year In Brief")
                    .font(.headline.weight(.bold))
            }

            if let goal = state.softRunGoal {
                let goalTone: PlannerTone = goal.status == .met ? .positive : (goal.status == .missed ? .warning : .neutral)
                let statusText = goal.status == .met ? "Met" : (goal.status == .missed ? "Missed" : "In progress")
                compactItem(
                    label: "Run Goal",
                    title: "\(goal.title) — \(statusText)",
                    detail: goal.detail,
                    tone: goalTone
                )
                .accessibilityIdentifier("year-summary-soft-goal")
            }

            if let yearlyStanceOutcome = summary.yearlyStanceOutcome {
                compactItem(label: "Goal", title: yearlyStanceOutcome.title, detail: yearlyStanceOutcome.detail, tone: PlannerTone(yearlyStanceOutcome.tone))
            }

            if let focusOutcome = summary.focusOutcome {
                compactItem(label: "Pattern", title: focusOutcome.title, detail: focusOutcome.detail, tone: PlannerTone(focusOutcome.tone))
            }

            if let mainTradeoff = summary.mainTradeoff {
                compactItem(label: "Cost", title: mainTradeoff.title, detail: mainTradeoff.detail, tone: PlannerTone(mainTradeoff.tone))
            }

            if let nextYearPressure = summary.nextYearPressure {
                compactItem(label: "Carries Over", title: nextYearPressure.title, detail: nextYearPressure.detail, tone: PlannerTone(nextYearPressure.tone))
            } else if let momentum = summary.momentum {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "globe")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.purple)
                        .padding(.top, 2)
                    compactItem(label: "Momentum", title: momentum.title, detail: momentum.detail, tone: PlannerTone(momentum.tone))
                }
                .padding(8)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if let lesson = summary.actionableLesson(resilience: state.resilience, state: state) {
                compactItem(
                    label: "Try Next",
                    title: lesson.title,
                    detail: lesson.detail,
                    tone: PlannerTone(lesson.tone)
                )
                .accessibilityIdentifier("year-summary-actionable-lesson")
            }

            // P1: Yearly feedback parity overhaul - explicit stance, life shape, D4 residue + compressed impact bullets
            let recentFocus = state.yearlyStance.recentStances.prefix(2).map { $0.title }.joined(separator: " → ")
            if !recentFocus.isEmpty || state.yearlyStance.lastCompletedStance != nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stance & Shape")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    if let last = state.yearlyStance.lastCompletedStance {
                        Text("• \(last.title) focus (repeat: \(state.yearlyStance.repeatCount)x)")
                            .font(.caption2)
                    }
                    if !recentFocus.isEmpty {
                        Text("• Recent: \(recentFocus) — this is writing your life shape.")
                            .font(.caption2)
                    }
                    Text("• The automated world and quiet years are reacting to the shape you're building.")
                        .font(.caption2.italic())
                        .foregroundStyle(.tertiary)
                }
                .padding(6)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            CauseTrailStrip(
                title: "Why It Moved",
                items: causeTrailItems(from: summary),
                identifier: "year-summary-cause-trail"
            )

            // Keep the primary action large and in the natural thumb zone
            Button("Continue", action: onAdvance)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityIdentifier("year-summary-continue-button")
        }
        .padding(4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(resilienceAccent, lineWidth: 1)
        )
        .onAppear { AppFeedback.impact(.light) }
        // P2: tighter for dense cards polish
        .padding(.vertical, -2)
    }

    private func forecastView(_ forecast: YearForecastCard) -> some View {
        let resilienceAccent = state.resilience == .grounded ? Color.orange.opacity(0.35) : Color.green.opacity(0.28)
        let pages = forecastStakesPages(forecast: forecast, stakes: stakes)
        let canStart = state.yearlyStance.selectedStance != nil

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Forecast")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(state.resilience.shortLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(state.resilience == .grounded ? .orange : .green)
                }

                Text(forecast.title)
                    .font(.headline.weight(.bold))

                Text(forecast.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                if let goal = state.softRunGoal, goal.setAtAge == state.player.age || goal.status == .inProgress {
                    compactItem(
                        label: "Run Goal",
                        title: goal.title,
                        detail: goal.detail,
                        tone: .positive
                    )
                    .accessibilityIdentifier("forecast-soft-goal")
                }

                if let name = forecast.voiceName, let line = forecast.voiceLine {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "person.wave.2.fill")
                            .foregroundStyle(Color.purple)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.caption.weight(.black))
                            Text(line)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityIdentifier("forecast-voice-line")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What the year is holding")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)

                    TabView(selection: $stakesPageIndex) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: page.icon)
                                        .foregroundStyle(page.tone.color)
                                    Text(page.label)
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(page.tone.color)
                                }
                                Text(page.title)
                                    .font(.subheadline.weight(.bold))
                                Text(page.detail)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(page.tone.fill)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 148)
                    .accessibilityIdentifier("forecast-stakes-pager")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What are you protecting this year?")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)

                    Text("Recommended: \(recommendedStance.title)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(stanceChips) { stance in
                            Button {
                                AppFeedback.impact(.light)
                                onSelectStance?(stance.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(stance.title)
                                        .font(.caption.weight(.heavy))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                    Text(stance.detail)
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(stance.isSelected ? PlannerTone.positive.fill : Color.primary.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(stance.isSelected ? PlannerTone.positive.color.opacity(0.45) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("forecast-stance-\(stance.id.rawValue)")
                        }
                    }
                }
                .accessibilityIdentifier("forecast-stance-commit")

                Button("Start The Year", action: onAdvance)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .disabled(!canStart)
                    .accessibilityIdentifier("forecast-continue-button")
            }
        }
        .frame(maxHeight: 520)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(resilienceAccent, lineWidth: 1)
        )
        .onAppear {
            AppFeedback.impact(.light)
            onPrepareForecast?()
        }
    }

    private func forecastStakesPages(forecast: YearForecastCard, stakes: TurnStakesSnapshot?) -> [ForecastStakesPage] {
        if let stakes {
            var pages: [ForecastStakesPage] = [
                ForecastStakesPage(
                    id: "focus",
                    label: stakes.focus.label,
                    title: stakes.focus.title,
                    detail: stakes.focus.detail,
                    tone: PlannerTone(stakes.focus.tone),
                    icon: "scope"
                ),
                ForecastStakesPage(
                    id: "pressure",
                    label: stakes.topPressure.label,
                    title: stakes.topPressure.title,
                    detail: stakes.topPressure.detail,
                    tone: PlannerTone(stakes.topPressure.tone),
                    icon: "exclamationmark.triangle"
                ),
                ForecastStakesPage(
                    id: "opportunity",
                    label: stakes.topOpportunity.label,
                    title: stakes.topOpportunity.title,
                    detail: stakes.topOpportunity.detail,
                    tone: PlannerTone(stakes.topOpportunity.tone),
                    icon: "sparkles"
                ),
                ForecastStakesPage(
                    id: "risk",
                    label: stakes.ignoredRisk.label,
                    title: stakes.ignoredRisk.title,
                    detail: stakes.ignoredRisk.detail,
                    tone: PlannerTone(stakes.ignoredRisk.tone),
                    icon: "eye.trianglebadge.exclamationmark"
                )
            ]
            if let momentum = stakes.momentum {
                pages.append(
                    ForecastStakesPage(
                        id: "momentum",
                        label: momentum.label,
                        title: momentum.title,
                        detail: momentum.detail,
                        tone: PlannerTone(momentum.tone),
                        icon: "globe"
                    )
                )
            }
            return pages
        }

        return [
            ForecastStakesPage(id: "focus", label: "Focus", title: forecast.focusTitle, detail: forecast.focusDetail, tone: PlannerTone(forecast.tone), icon: "scope"),
            ForecastStakesPage(id: "pressure", label: "Pressure", title: forecast.pressureLabel, detail: forecast.pressureDetail, tone: PlannerTone(forecast.tone), icon: "exclamationmark.triangle"),
            ForecastStakesPage(id: "next", label: "Next", title: forecast.anticipationTitle, detail: forecast.anticipationDetail, tone: .neutral, icon: "arrow.right.circle")
        ]
    }

    private func eventView(_ event: GameEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event.category.rawValue.capitalized)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Text(event.title)
                .font(.title3.weight(.bold))

            Text(event.displayText(echoing: state))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(5)

            VStack(spacing: 10) {
                ForEach(Array(event.choices.enumerated()), id: \.element.id) { index, choice in
                    Button {
                        onPick(choice)
                    } label: {
                        Text(choice.text)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("event-choice-\(index)")
                }
            }
        }
    }

    private func reactionView(_ reaction: YearReactionCard) -> some View {
        let tone = PlannerTone(reaction.tone)
        let isWorldVoice = reaction.kicker.contains("From ") || reaction.kicker.contains("In your")
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: isWorldVoice ? "person.wave.2.fill" : (tone == .warning ? "exclamationmark.triangle.fill" : "sparkles"))
                    .foregroundStyle(isWorldVoice ? Color.purple : tone.color)
                Text(reaction.kicker)
                    .font(.caption.weight(.black))
                    .foregroundStyle(isWorldVoice ? Color.purple.opacity(0.9) : .secondary)
                Spacer()
                Text(reaction.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(tone.color)
                    .lineLimit(1)
            }

            Text(reaction.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(5)

            Button("Keep Going", action: onAdvance)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityIdentifier("reaction-continue-button")
        }
        .padding(6)
        .background(isWorldVoice ? Color.purple.opacity(0.08) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isWorldVoice ? Color.purple.opacity(0.35) : tone.color.opacity(0.2), lineWidth: 1)
        )
        .onAppear { AppFeedback.impact(.light) }
    }

    private func consequenceView(_ preview: ConsequencePreview) -> some View {
        let tone = PlannerTone(preview.tone)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Fallout")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Text(preview.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(tone.color)

            Text(preview.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(5)

            Button("Keep Going", action: onAdvance)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onAppear { AppFeedback.impact(.light) }
    }

    private func resolutionView(_ preview: ResolutionPreview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wrap")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Text(preview.title)
                .font(.title3.weight(.bold))

            Text(preview.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(5)

            // Replayability transparency: at the end of a life, gently remind the player what "Life Feel" they chose
            if preview.title.contains("Life Closed") || preview.title.contains("Life Ended") {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.caption2)
                    Text("Your Life Feel choice shaped how this story could recover")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }

            Button(preview.actionTitle, action: onAdvance)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func crisisView(_ crisis: CrisisInteraction) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.red)
                Text("Systemic Crisis")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
            }

            Text(crisis.title)
                .font(.title2.weight(.bold))

            Text(crisis.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(crisis.choices) { choice in
                    Button {
                        onCrisisPick(choice)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(choice.text)
                                    .font(.headline)
                                    .foregroundStyle(choice.isBuyBack ? .primary : .secondary)
                                Text(choice.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(choice.costSummary)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(choice.isBuyBack ? .red : .green)
                            }
                            Spacer()
                            Image(systemName: choice.isBuyBack ? "lifebuoy.fill" : "door.right.hand.open")
                                .foregroundStyle(choice.isBuyBack ? .red : .secondary)
                        }
                        .padding(14)
                        .background(choice.isBuyBack ? Color.red.opacity(0.1) : Color.black.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(choice.isBuyBack ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func pitchDeckView(_ pitch: PitchDeckInteraction) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Pitch Deck")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
            }

            Text(pitch.title)
                .font(.title2.weight(.bold))

            Text(pitch.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(pitch.choices) { choice in
                    Button {
                        onPitchPick(choice)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(choice.text)
                                    .font(.headline)
                                Text(choice.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func compactItem(label: String, title: String, detail: String, tone: PlannerTone) -> some View {
        // Phase 6: More glanceable with icon + tighter text
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconForCompactLabel(label))
                .font(.caption.weight(.bold))
                .foregroundStyle(tone.color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tone.color)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(tone.fill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func iconForCompactLabel(_ label: String) -> String {
        if label.lowercased().contains("focus") { return "target" }
        if label.lowercased().contains("pressure") { return "exclamationmark.triangle" }
        if label.lowercased().contains("next") || label.lowercased().contains("coming") { return "calendar" }
        return "circle"
    }

    private func causeTrailItems(from summary: YearlyOutcomeSummary) -> [CauseTrailItem] {
        let pool = (
            summary.headlines +
            summary.spillovers +
            [summary.focusOutcome, summary.mainTradeoff, summary.topProblem, summary.topOpportunity, summary.nextYearPressure]
                .compactMap { $0 }
        )
        .sorted { abs($0.impactScore) > abs($1.impactScore) }

        var seen: Set<String> = []
        return pool.compactMap { item in
            guard !item.detail.isEmpty, seen.insert(item.detail).inserted else { return nil }
            return CauseTrailItem(title: item.title, detail: item.detail, tone: PlannerTone(item.tone))
        }
        .prefix(3)
        .map { $0 }
    }
}

private struct PlannerDetailSheet: View {
    let destination: PlannerDetailDestination
    let state: GameState
    let roleTitle: String
    let policyLabel: String
    let showingEducationAsPrimaryTab: Bool
    let historyDigest: HistoryDigest
    let latestYearSummary: YearlyOutcomeSummary?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if !detailCauseTrail.isEmpty {
                        DetailCard(title: "Why This Moved", subtitle: "Recent causes, not exact math") {
                            CauseTrailStrip(
                                title: "Cause Trail",
                                items: detailCauseTrail,
                                identifier: "detail-cause-trail-\(destination.rawValue)"
                            )
                        }
                    }
                    detailBody
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("planner-detail-done-button")
                }
            }
            .accessibilityIdentifier("detail-sheet-\(destination.rawValue)")
        }
    }

    private var title: String {
        switch destination {
        case .careerOverview: return "Career Details"
        case .careerTrack: return "Track Details"
        case .careerHistory: return "Career History"
        case .educationOverview: return "Education Details"
        case .educationClimate: return "School Climate"
        case .educationHistory: return "Education History"
        case .financeCashflow: return "Cash Flow"
        case .financeInvesting: return "Investing"
        case .financePolicy: return "Policy And Housing"
        case .financeHistory: return "Finance History"
        case .relationshipsConnections: return "Connections"
        case .relationshipsFamily: return "Family Planning"
        case .relationshipsHistory: return "Relationship History"
        case .healthOverview: return "Health Details"
        case .healthConditions: return "Recovery Risks"
        case .healthHistory: return "Health History"
        case .lifeHousing: return "Housing Details"
        case .lifeLegacy: return "Legacy Details"
        case .lifeHistory: return "Life History"
        }
    }

    private var detailCauseTrail: [CauseTrailItem] {
        guard let latestYearSummary else { return [] }

        let domains: Set<HistoryDomainTag>
        switch destination {
        case .careerOverview, .careerTrack, .careerHistory:
            domains = showingEducationAsPrimaryTab ? [.education, .progress] : [.career, .crime, .progress]
        case .educationOverview, .educationClimate, .educationHistory:
            domains = [.education, .progress]
        case .financeCashflow, .financeInvesting, .financePolicy, .financeHistory, .lifeHousing:
            domains = [.finance, .housing, .assets, .progress]
        case .relationshipsConnections, .relationshipsFamily, .relationshipsHistory:
            domains = [.relationships, .lifeEvent, .progress]
        case .healthOverview, .healthConditions, .healthHistory:
            domains = [.health, .progress]
        case .lifeLegacy, .lifeHistory:
            domains = Set(HistoryDomainTag.allCases)
        }

        let pool = (
            latestYearSummary.headlines +
            latestYearSummary.spillovers +
            [
                latestYearSummary.focusOutcome,
                latestYearSummary.mainTradeoff,
                latestYearSummary.topProblem,
                latestYearSummary.topOpportunity,
                latestYearSummary.nextYearPressure
            ].compactMap { $0 }
        )
        .filter { domains.contains($0.domain) || $0.domain == .progress }
        .sorted { abs($0.impactScore) > abs($1.impactScore) }

        var seen: Set<String> = []
        return pool.compactMap { item in
            guard !item.detail.isEmpty, seen.insert(item.detail).inserted else { return nil }
            return CauseTrailItem(title: item.title, detail: item.detail, tone: PlannerTone(item.tone))
        }
        .prefix(3)
        .map { $0 }
    }

    @ViewBuilder
    private var detailBody: some View {
        switch destination {
        case .careerOverview:
            DetailCard(title: roleTitle, subtitle: "Current work position") {
                DetailMetricRow(items: [
                    ("Performance", "\(state.career.performance)"),
                    ("Income", "$\(state.career.annualIncome)"),
                    ("Years worked", "\(state.career.yearsWorked)")
                ])
                DetailMetricRow(items: [
                    ("Experience", state.career.strongestExperienceTag?.shortLabel ?? "Unproven"),
                    ("Qualified jobs", "\(qualifiedCareerRoles.count)"),
                    ("Special bridge", specialBridgeStatus)
                ])
                // D3: show regular archetype (when no deep special) with curve hint
                if state.specialCareer.track == .inactive, let arch = state.career.regularArchetype {
                    let curve = arch == .corporateClimber ? "Steady security, political" :
                                arch == .gigFreelancer ? "Variance + freedom, faster fade" :
                                arch == .skilledTrades ? "Durable demand, low burnout" :
                                arch == .publicService ? "Pension security, mission" :
                                arch == .techEngineer ? "Skill ceiling, intensity" : "Network variance"
                    DetailMetricRow(items: [("Archetype", arch.displayName), ("Curve", curve)])
                }
                DetailBodyText(text: "Career remains the main stability engine for adult years. When performance and income drift apart, the planner starts flagging that strain early.")
            }
            DetailCard(title: "Qualified Regular Jobs", subtitle: "Passive income options") {
                DetailBulletList(items: qualifiedCareerRoles.prefix(5).map { "\($0.title): $\($0.annualIncome)/yr" })
            }
            DetailCard(title: "Locked Regular Jobs", subtitle: "What is still missing") {
                DetailBulletList(items: lockedCareerRoles.prefix(5).map { "\($0.0.title): \($0.1)" })
            }
        case .careerTrack:
            DetailCard(title: state.specialCareer.track == .crime ? "Risk Track" : "Attention Track", subtitle: "Secondary pressure lane") {
                DetailMetricRow(items: [
                    ("Track", state.specialCareer.track.rawValue.capitalized),
                    ("Burnout", "\(state.specialCareer.burnout)"),
                    ("Payout", "$\(state.specialCareer.lastPayout)")
                ])
                DetailMetricRow(items: [
                    ("Crime status", state.crime.status.rawValue.capitalized),
                    ("Heat", "\(max(state.crime.heat, state.specialCareer.heat))"),
                    ("Audience / notoriety", "\(max(state.specialCareer.audience, state.crime.notoriety))")
                ])
                // CE2: Expose key CriminalEnterpriseState metrics when on a deep crime path
                if state.specialCareer.track == .crime || state.crime.status == .active {
                    let ent = state.specialCareer.enterprise
                    DetailMetricRow(items: [
                        ("Loyalty", "\(ent.loyalty)"),
                        ("Clean $", "\(ent.cleanMoneyRatio)%"),
                        ("Network", "\(ent.networkStrength)")
                    ])
                }
                // CE4: Subtype voice hint in the Risk Track
                if state.specialCareer.track == .crime {
                    let flavor = state.specialCareer.enterprise.subtype == .shadowOperative ? "Ghost work" :
                                 state.specialCareer.enterprise.subtype == .streetCrime ? "Street arithmetic" :
                                 state.specialCareer.enterprise.subtype == .grayMarketTrader ? "Gray ledger" :
                                 state.specialCareer.enterprise.subtype == .ventureCapitalist ? "Quiet capital" : "Hostile precision"
                    DetailMetricRow(items: [("Voice", flavor)])
                }
            }
        case .careerHistory:
            DetailHistoryList(entries: historyDigest.all)
        case .educationOverview:
            DetailCard(title: showingEducationAsPrimaryTab ? "Education is primary" : "Education context", subtitle: "School trajectory") {
                DetailMetricRow(items: [
                    ("Standing", "\(state.education.schoolStanding)"),
                    ("Readiness", "\(state.education.applicationReadiness)"),
                    ("Belonging", "\(state.education.schoolBelonging)")
                ])
                DetailMetricRow(items: [
                    ("Track", state.education.academicTrack.rawValue.capitalized),
                    ("Stage", state.education.stage.rawValue.capitalized),
                    ("Path", state.education.pathway.rawValue.capitalized)
                ])
                // D3: credential strength + decay status (trade decays slow via practice, honors lingers, standard faster fade)
                let cred = state.education.credentialStrength
                let yrs = state.education.yearsSinceCredential
                let decayNote: String = {
                    if state.education.academicTrack == .vocational { return "Trade: holds via use" }
                    if state.education.academicTrack == .honors { return "Honors: prestige lingers" }
                    if yrs > 5 { return "Fading — refresh or lose edge" }
                    return "Standard track"
                }()
                DetailMetricRow(items: [
                    ("Credential", "\(cred)"),
                    ("Age", "\(yrs)y"),
                    ("Value", decayNote)
                ])
            }
        case .educationClimate:
            DetailCard(title: "Pressure Sources", subtitle: "What is shaping the year") {
                DetailBulletList(items: educationPressureDetails)
            }
        case .educationHistory:
            DetailHistoryList(entries: historyDigest.education)
        case .financeCashflow:
            DetailCard(title: "Cash Flow", subtitle: policyLabel) {
                DetailMetricRow(items: [
                    ("Net income", "$\(state.finance.annualNetIncome)"),
                    ("Total expenses", "$\(state.finance.annualTotalExpenses)"),
                    ("Cash on hand", "$\(state.finance.cashOnHand)")
                ])
                DetailMetricRow(items: [
                    ("Stress", "\(state.finance.financialStress)"),
                    ("Tax rate", "\(state.finance.effectiveTaxRate)%"),
                    ("Balance delta", signedCurrency(state.finance.lastYearBalanceDelta))
                ])
                if state.finance.totalNonHousingDebt > 0 {
                    DetailMetricRow(items: [
                        ("Debt", "$\(state.finance.totalNonHousingDebt)"),
                        ("Debt pressure", state.finance.debtPressureBand.displayLabel),
                        ("Debt paid", "$\(state.finance.annualDebtPayments)")
                    ])
                }
                if state.assets.ownsHome || state.finance.homeDownPaymentSavings > 0 {
                    DetailMetricRow(items: [
                        ("Home fund", "$\(state.finance.homeDownPaymentSavings)"),
                        ("Equity", "$\(state.finance.homeEquity)"),
                        ("Housing burden", "$\(state.finance.housingDebtBurden)")
                    ])
                }
            }
        case .financeInvesting:
            DetailCard(title: "Investing", subtitle: state.finance.investmentRiskProfile.displayLabel) {
                DetailMetricRow(items: [
                    ("Invested", "$\(state.finance.investedBalance)"),
                    ("Index funds", "$\(state.finance.indexFundBalance)"),
                    ("Stocks", "$\(state.finance.stockPortfolioBalance)")
                ])
                DetailMetricRow(items: [
                    ("Last market year", signedCurrency(state.finance.lastYearInvestmentDelta)),
                    ("Cost basis", "$\(state.finance.costBasis)"),
                    ("Liquidity", "$\(state.finance.cashOnHand)")
                ])
                DetailBodyText(text: "Investing stays gated behind stability. This view makes the trade between liquidity and compounding explicit instead of burying it.")
            }
        case .financePolicy:
            DetailCard(title: policyLabel, subtitle: "Regional pressure") {
                DetailMetricRow(items: [
                    ("Housing setup", housingArrangementLabel(state.housing.livingArrangement)),
                    ("Housing stability", "\(state.housing.housingStability)"),
                    ("Education cost", "$\(state.finance.annualEducationCost)")
                ])
                DetailMetricRow(items: [
                    ("Living cost", "$\(state.finance.annualLivingCost)"),
                    ("Dependent cost", "$\(state.finance.annualDependentCost)"),
                    ("Stress", "\(state.finance.financialStress)")
                ])
                if state.finance.totalNonHousingDebt > 0 {
                    DetailMetricRow(items: [
                        ("Student debt", "$\(state.finance.studentDebt)"),
                        ("Credit debt", "$\(state.finance.creditDebt)"),
                        ("Medical debt", "$\(state.finance.medicalDebt)")
                    ])
                }
                if let home = state.assets.primaryResidence {
                    DetailMetricRow(items: [
                        ("Home value", "$\(home.homeValue)"),
                        ("Mortgage", "$\(home.mortgagePrincipal)"),
                        ("Status", home.status.rawValue.capitalized)
                    ])
                }
            }
        case .financeHistory:
            DetailHistoryList(entries: historyDigest.finance)
        case .relationshipsConnections:
            DetailCard(title: relationshipHeader, subtitle: "Closest social state") {
                DetailMetricRow(items: [
                    ("Friends", "\(state.relationships.friends.count)"),
                    ("Partner bond", "\(state.relationships.partnerBond)"),
                    ("Public rep", "\(state.relationships.publicReputation)")
                ])
                DetailMetricRow(items: [
                    ("Rumor heat", "\(state.relationships.activeRumorHeat)"),
                    ("Loose ends", "\(state.relationships.activeTensionCount)"),
                    ("Future align", "\(state.relationships.futureAlignment.averageReadiness)")
                ])
                DetailBulletList(items: topConnections)
                DetailBulletList(items: state.relationships.tensions.prefix(3).map { "\($0.headline) • \($0.impactLine)" }.isEmpty ? ["No loose ends are active right now."] : Array(state.relationships.tensions.prefix(3).map { "\($0.headline) • \($0.impactLine)" }))
            }
        case .relationshipsFamily:
            FamilyDetailCard(state: state)
        case .relationshipsHistory:
            DetailHistoryList(entries: historyDigest.relationships)
        case .healthOverview:
            DetailCard(title: "Body And Mind", subtitle: state.isGameOver ? "Life ended" : "Current stability") {
                DetailMetricRow(items: [
                    ("Overall", "\(state.player.health)"),
                    ("Physical", "\(state.healthProfile.physicalWellness)"),
                    ("Mental", "\(state.healthProfile.mentalWellness)")
                ])
                DetailMetricRow(items: [
                    ("Exercise", "\(state.healthProfile.habits.exercise)"),
                    ("Nutrition", "\(state.healthProfile.habits.nutrition)"),
                    ("Stress mgmt", "\(state.healthProfile.habits.stressManagement)")
                ])
            }
        case .healthConditions:
            DetailCard(title: "Recovery Risks", subtitle: state.healthProfile.activeConditions.isEmpty ? "No active conditions" : "Conditions active") {
                if state.healthProfile.activeConditions.isEmpty {
                    DetailBodyText(text: "There are no active conditions right now, but the recovery numbers above still determine whether your next years feel stable or brittle.")
                } else {
                    DetailBulletList(items: state.healthProfile.activeConditions.map { "\($0.name) • severity \($0.severity)" })
                }
            }
        case .healthHistory:
            DetailHistoryList(entries: historyDigest.health)
        case .lifeHousing:
            DetailCard(title: housingArrangementLabel(state.housing.livingArrangement), subtitle: "Housing details") {
                DetailMetricRow(items: [
                    ("Stability", "\(state.housing.housingStability)"),
                    ("Cost band", "\(state.housing.housingCostBand)"),
                    ("Owns home", state.assets.ownsHome ? "Yes" : "No")
                ])
                if let home = state.assets.primaryResidence {
                    DetailMetricRow(items: [
                        ("Home value", "$\(home.homeValue)"),
                        ("Equity", "$\(state.finance.homeEquity)"),
                        ("House reserve", "$\(home.maintenanceReserve)")
                    ])
                    DetailMetricRow(items: [
                        ("Mortgage rate", "\(home.mortgageRatePercent)%"),
                        ("Years left", "\(home.remainingMortgageYears)"),
                        ("Status", home.status.rawValue.capitalized)
                    ])
                } else if state.finance.homeDownPaymentSavings > 0 {
                    DetailMetricRow(items: [
                        ("Home fund", "$\(state.finance.homeDownPaymentSavings)"),
                        ("Target home", "$\(state.assets.targetHomeValue)"),
                        ("Status", "Saving")
                    ])
                }
                DetailBodyText(text: "Housing is the floor under the rest of the sim. When this slips, money and health usually start leaking soon after.")
            }
        case .lifeLegacy:
            DetailCard(title: legacyTitle, subtitle: "Life path and milestones") {
                DetailMetricRow(items: [
                    ("Legacy score", "\(state.progress.legacyScore)"),
                    ("Milestones", "\(state.progress.unlockedMilestones.count)"),
                    ("Paths", "\(state.progress.unlockedLifePaths.count)")
                ])
                if !state.progress.unlockedMilestones.isEmpty {
                    DetailBulletList(items: state.progress.unlockedMilestones.map { "\($0.id.rawValue.capitalized) at age \($0.unlockedAtAge)" })
                }
            }
        case .lifeHistory:
            DetailHistoryList(entries: historyDigest.life)
        }
    }

    private var educationPressureDetails: [String] {
        var items: [String] = []
        if state.education.attendancePressure >= 55 { items.append("Attendance pressure is high.") }
        if state.education.burnoutRisk >= 55 { items.append("Burnout risk is rising.") }
        if state.education.peerPressure >= 46 { items.append("Peer pressure is shaping behavior.") }
        if state.education.teacherSupport < 38 { items.append("Teacher support is thin.") }
        if items.isEmpty { items.append("School pressure is present, but there is still room to stabilize it.") }
        return items
    }

    private var relationshipHeader: String {
        if let pregnancy = state.family.pregnancy {
            return "Pregnant with \(pregnancy.otherParentName)"
        }
        if let partner = state.relationships.partnerName {
            return "Closest partner: \(partner)"
        }
        return "Social network"
    }

    private var topConnections: [String] {
        var items: [String] = []
        if let partner = state.relationships.primaryPartner {
            items.append("\(partner.name) • bond \(partner.bond) • \(partner.status.rawValue)")
        }
        items.append(contentsOf: state.relationships.friends.prefix(4).map { "\($0.name) • bond \($0.bond) • \($0.status.rawValue)" })
        if items.isEmpty { items.append("No close connections are active right now.") }
        return items
    }

    private var legacyTitle: String {
        if let finalPath = state.progress.finalLifePath {
            return LifePathCatalog.profile(for: finalPath).title
        }
        if let currentPath = state.progress.currentLifePath {
            return LifePathCatalog.profile(for: currentPath).title
        }
        return "Legacy still forming"
    }

    private func housingArrangementLabel(_ arrangement: LivingArrangement) -> String {
        switch arrangement {
        case .familyHome: return "Family Home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Solo Rent"
        case .ownerOccupied: return "Owner Occupied"
        case .couchSurfing: return "Couch Surfing"
        }
    }

    private var qualifiedCareerRoles: [CareerRoleDefinition] {
        CareerCatalog.qualifiedRoles(for: state.player, career: state.career, education: state.education, childhoodDossier: state.childhoodDossier)
            .sorted { $0.annualIncome > $1.annualIncome }
    }

    private var lockedCareerRoles: [(CareerRoleDefinition, String)] {
        CareerCatalog.lockedRoles(for: state.player, career: state.career, education: state.education, childhoodDossier: state.childhoodDossier)
            .sorted { lhs, rhs in
                if lhs.0.annualIncome == rhs.0.annualIncome {
                    return lhs.0.title < rhs.0.title
                }
                return lhs.0.annualIncome > rhs.0.annualIncome
            }
    }

    private var specialBridgeStatus: String {
        if state.specialCareer.track != .inactive {
            return state.specialCareer.track.rawValue.capitalized
        }
        if SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) == nil { return "Founder ready" }
        if SpecialCareerSystem.qualificationIssue(for: .manageFund, state: state) == nil { return "Capital ready" }
        if SpecialCareerSystem.qualificationIssue(for: .gatherIntelligence, state: state) == nil { return "Access ready" }
        return "Building proof"
    }
}

private struct ChangeInsightSheet: View {
    let insight: ChangeInsightCard

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Label(insight.topic.title, systemImage: insight.topic.symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(insight.tone.color)

                    Text(insight.headline)
                        .font(.title3.weight(.bold))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Why This Changed")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        ForEach(insight.causes, id: \.self) { cause in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(insight.tone.color)
                                    .frame(width: 7, height: 7)
                                    .padding(.top, 6)
                                Text(cause)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let implication = insight.implication {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Next Year")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(implication)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(insight.tone.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Year Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .accessibilityIdentifier("change-insight-sheet-\(insight.topic.rawValue)")
        }
    }
}

private struct SettingsSheet: View {
    @Binding var hapticsSetting: FeedbackIntensitySetting
    @Binding var animationSetting: FeedbackIntensitySetting
    @Binding var colorEmphasisSetting: ColorEmphasisSetting
    let startNewLife: () -> Void
    let resetSavedProgress: () -> Void
    let openDebugLab: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Feedback Pulse") {
                    Picker("Haptics", selection: $hapticsSetting) {
                        ForEach(FeedbackIntensitySetting.allCases) { setting in
                            Text(setting.title).tag(setting)
                        }
                    }

                    Picker("Animation", selection: $animationSetting) {
                        ForEach(FeedbackIntensitySetting.allCases) { setting in
                            Text(setting.title).tag(setting)
                        }
                    }

                    Picker("Color Emphasis", selection: $colorEmphasisSetting) {
                        ForEach(ColorEmphasisSetting.allCases) { setting in
                            Text(setting.title).tag(setting)
                        }
                    }
                }

                Section("Lifecycle") {
                    Button("Start New Life", role: .destructive) {
                        startNewLife()
                        dismiss()
                    }
                    Button("Reset Saved Progress", role: .destructive) {
                        resetSavedProgress()
                        dismiss()
                    }
                }

                #if DEBUG
                Section("QA") {
                    Button("Open QA Scenarios") {
                        openDebugLab()
                        dismiss()
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .accessibilityIdentifier("settings-sheet")
        }
    }
}

private struct TraitStrip: View {
    let traits: [PersonalityTrait]

    var body: some View {
        if traits.isEmpty {
            Text("Traits are still settling into place.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(traits) { trait in
                        Text(TraitCatalog.profile(for: trait).name)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

private struct ActionChoiceRow: View {
    let action: ActionChoiceID
    let immediate: Bool
    let colorScheme: ColorScheme
    let onSelect: () -> Void

    private var definition: ActionChoiceDefinition {
        ActionChoiceCatalog.definition(for: action)
    }

    var body: some View {
        Button {
            AppFeedback.impact(.light)
            onSelect()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: rowSymbol)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(rowTone.color)
                    .frame(width: 38, height: 38)
                    .background(rowTone.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(definition.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(definition.subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    previewTagsRow
                }

                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: immediate ? "play.fill" : "text.line.magnify")
                        .font(.system(size: 13, weight: .black))
                    Text(immediate ? "NOW" : "QUEUE")
                        .font(.system(size: 8, weight: .black))
                }
                .foregroundStyle(Color.white)
                .frame(width: 42, height: 42)
                .background(rowTone.color)
                .clipShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
            .background(OLTheme.cardFill(colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(rowTone.fill, lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(OLTheme.cardShadowOpacity(colorScheme)), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("action-choice-\(action.rawValue)")
        .accessibilityLabel(definition.title)
        .accessibilityHint(immediate ? "Applies this choice immediately." : "Queues this choice until you age up.")
    }

    private var previewTagsRow: some View {
        HStack(spacing: 6) {
            ForEach(Array(definition.previewTags.prefix(3)), id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(rowTone.fill)
                    .clipShape(Capsule())
            }
        }
        .accessibilityIdentifier("action-preview-strip")
    }

    private var rowTone: PlannerTone {
        switch definition.baseFriction {
        case .warning, .resistance, .danger, .locked:
            return .warning
        case .none:
            return .neutral
        }
    }

    private var rowSymbol: String {
        let tags = definition.previewTags.joined(separator: " ").lowercased()
        if tags.contains("money") || tags.contains("cash") || tags.contains("debt") || tags.contains("fund") {
            return "dollarsign.circle.fill"
        }
        if tags.contains("health") || tags.contains("sleep") || tags.contains("recovery") || tags.contains("stress") {
            return "heart.fill"
        }
        if tags.contains("friend") || tags.contains("bond") || tags.contains("belonging") || tags.contains("support") {
            return "person.2.fill"
        }
        if tags.contains("standing") || tags.contains("readiness") || tags.contains("school") {
            return "book.closed.fill"
        }
        if definition.baseFriction == .warning || definition.baseFriction == .resistance {
            return "exclamationmark.triangle.fill"
        }
        return "bolt.fill"
    }
}

private struct ActionSelectionModule: View {
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var instantChoices: [ActionChoiceID] {
        actionChoices.filter { ActionChoiceCatalog.resolutionTier(for: $0) == .instant }
    }

    private var committedChoices: [ActionChoiceID] {
        actionChoices.filter { ActionChoiceCatalog.resolutionTier(for: $0) == .committed }
    }

    var body: some View {
        if !actionChoices.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                if !instantChoices.isEmpty {
                    actionSection(
                        title: "Right now",
                        subtitle: "Instant — ALWAYS",
                        headerSymbol: "bolt.fill",
                        choices: instantChoices,
                        immediate: true
                    )
                }
                if !committedChoices.isEmpty {
                    actionSection(
                        title: "Year stance",
                        subtitle: "Intent",
                        headerSymbol: "calendar",
                        choices: committedChoices,
                        immediate: false
                    )
                }
            }
            .accessibilityIdentifier("action-deck-header")
        }
    }

    @ViewBuilder
    private func actionSection(title: String, subtitle: String, headerSymbol: String, choices: [ActionChoiceID], immediate: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: headerSymbol)
                    .font(.headline.weight(.bold))
                Spacer()
                Text(subtitle)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(immediate ? PlannerTone.positive.color : Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(immediate ? PlannerTone.positive.fill : Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            ForEach(choices) { action in
                ActionChoiceRow(
                    action: action,
                    immediate: immediate,
                    colorScheme: colorScheme,
                    onSelect: { onSelectAction(action) }
                )
            }
        }
    }
}

private struct InsightStrip: View {
    let title: String
    let insights: [PlannerInsight]
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text(insight.value)
                            .font(.caption.weight(.semibold))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(insight.tone.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .accessibilityIdentifier(identifier)
    }
}

private struct AuditStrip: View {
    let insights: [PlannerInsight]
    let identifier: String

    var body: some View {
        InsightStrip(title: "2-Second Audit", insights: insights, identifier: identifier)
    }
}

private struct YearlyConsequenceStrip: View {
    let items: [YearlyOutcomeItem]
    let identifier: String

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Consequences")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                ForEach(items.prefix(2)) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(PlannerTone(item.tone).color)
                            .frame(width: 8, height: 8)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.caption.weight(.bold))
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .accessibilityIdentifier(identifier)
        }
    }
}

private struct AgeUpRiskPreviewStrip: View {
    let signals: [AgeUpRiskSignal]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Risk Preview")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(signals) { signal in
                        Label(signal.title, systemImage: signal.symbol)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(signal.tone.fill)
                            .foregroundStyle(signal.tone.color)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .accessibilityIdentifier("age-up-risk-preview")
    }
}

private struct CauseTrailStrip: View {
    let title: String
    let items: [CauseTrailItem]
    let identifier: String

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                ForEach(items.prefix(3)) { item in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: item.tone == .warning ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(item.tone.color)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.caption.weight(.bold))
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .accessibilityIdentifier(identifier)
        }
    }
}

private struct ChipStrip: View {
    let title: String
    let items: [String]
    let tone: PlannerTone
    let identifier: String

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(tone.fill)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .accessibilityIdentifier(identifier)
        }
    }
}

private struct OriginPreviewCard: View {
    let state: GameState

    var body: some View {
        VStack(spacing: 14) {
            PlannerSectionCard(
                title: "Life Origin",
                symbol: "sparkles.rectangle.stack.fill",
                status: state.originProfile.map(originTitle(for:)) ?? "Teen setup ready",
                tone: previewTone
            ) {
                VStack(spacing: 10) {
                    originBlock(title: "Home", value: state.originProfile?.householdPressure ?? "Unknown", detail: state.originProfile?.homeSummary ?? "")
                    originBlock(title: "School", value: state.originProfile?.schoolStanding ?? "Unknown", detail: state.originProfile?.schoolSummary ?? "")
                    originBlock(title: "You", value: state.originProfile?.socialSupport ?? "Unknown", detail: state.originProfile?.selfSummary ?? "")
                }

                MetricRow(metrics: [
                    ("Cash", "$\(state.finance.cashOnHand)", state.finance.cashOnHand >= 500 ? .positive : (state.finance.cashOnHand <= 100 ? .warning : .neutral)),
                    ("Stress", "\(state.finance.financialStress)", state.finance.financialStress >= 28 ? .warning : .neutral),
                    ("Health", "\(state.player.health)", state.player.health < 50 ? .warning : .neutral)
                ])

                if let highlights = state.originProfile?.signalHighlights {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(highlights, id: \.self) { item in
                                Text(item)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if !state.narrativeArcs.previewTensionLabels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(state.narrativeArcs.previewTensionLabels, id: \.self) { item in
                                Text(item)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(PlannerTone.neutral.fill)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                TraitStrip(traits: state.player.traits)

                if let openingSummary = state.openingSummary {
                    Text(openingSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                }
            }
        }
    }

    private var previewTone: PlannerTone {
        if state.finance.financialStress >= 28 || state.player.health < 50 {
            return .warning
        }
        if state.finance.cashOnHand >= 500 || state.player.smarts >= 62 {
            return .positive
        }
        return .neutral
    }

    private func originBlock(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func originTitle(for profile: OriginProfile) -> String {
        switch profile.templateID {
        case .some(let templateID):
            return OriginCatalog.definition(for: templateID).title
        case .none:
            return "Quick start"
        }
    }
}

private struct EducationPlannerTab: View {
    let state: GameState
    let isTeenExperience: Bool
    let whyItMatters: [PlannerInsight]
    let schoolClimateMetrics: [(String, String, PlannerTone)]
    let pressureSources: [String]
    let nextUnlocks: [String]
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    init(
        state: GameState,
        isTeenExperience: Bool,
        whyItMatters: [PlannerInsight],
        schoolClimateMetrics: [(String, String, PlannerTone)],
        pressureSources: [String],
        nextUnlocks: [String],
        summaryItems: [YearlyOutcomeItem],
        recentHistory: [HistoryEntry],
        actionChoices: [ActionChoiceID],
        onSelectAction: @escaping (ActionChoiceID) -> Void,
        comingUpItems: [String],
        openDetail: @escaping (PlannerDetailDestination) -> Void
    ) {
        self.state = state
        self.isTeenExperience = isTeenExperience
        self.whyItMatters = whyItMatters
        self.schoolClimateMetrics = schoolClimateMetrics
        self.pressureSources = pressureSources
        self.nextUnlocks = nextUnlocks
        self.summaryItems = summaryItems
        self.recentHistory = recentHistory
        self.actionChoices = actionChoices
        self.onSelectAction = onSelectAction
        self.comingUpItems = comingUpItems
        self.openDetail = openDetail
    }

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Education",
                symbol: "book.closed.fill",
                status: educationStatus,
                tone: state.education.stage == .inactive && state.education.pathway == .graduate ? .positive : (state.education.burnoutRisk >= 55 || state.education.attendancePressure >= 55 ? .warning : .neutral),
                detailTitle: "Details",
                detailIdentifier: "education-overview-detail-button",
                detailAction: { openDetail(.educationOverview) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    MetricRow(metrics: [
                        ("Standing", "\(state.education.schoolStanding)", state.education.schoolStanding >= 70 ? .positive : (state.education.schoolStanding < 40 ? .warning : .neutral)),
                        (isTeenExperience ? "Readiness" : "Campus Fit", isTeenExperience ? "\(state.education.applicationReadiness)" : "\(state.education.campusFit)", (isTeenExperience ? state.education.applicationReadiness : state.education.campusFit) >= 60 ? .positive : ((isTeenExperience ? state.education.applicationReadiness : state.education.campusFit) < 40 ? .warning : .neutral))
                    ])
                    Text(educationSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("education-overview-header")

            AuditStrip(insights: auditInsights, identifier: "education-overview-audit")

            if !pressureSources.isEmpty || !comingUpItems.isEmpty {
                PlannerSectionCard(
                    title: "What Can Bite",
                    symbol: "exclamationmark.triangle.fill",
                    status: pressureSources.first ?? comingUpItems.first,
                    tone: pressureSources.isEmpty ? .neutral : .warning,
                    detailTitle: "Inspect",
                    detailIdentifier: "education-pressure-detail-button",
                    detailAction: { openDetail(.educationClimate) }
                ) {
                    ChipStrip(
                        title: "Live pressure",
                        items: Array((pressureSources + comingUpItems).prefix(4)),
                        tone: pressureSources.isEmpty ? .neutral : .warning,
                        identifier: "education-pressure-strip"
                    )
                }
                .accessibilityIdentifier("education-overview-pressure")
            }

            // Teen/early adult dossier immersion: your 14 wiring is already shaping the lane (sparks come through teenUnlocks)
            if (isTeenExperience || (state.player.age <= 22 && state.education.stage != .inactive)) && !nextUnlocks.filter({ $0.contains("edge") || $0.contains("instinct") || $0.contains("current") || $0.contains("mind") || $0.contains("Physical") || $0.contains("Hustle") || $0.contains("Creative") || $0.contains("Social") || $0.contains("Sharp") }).isEmpty {
                PlannerSectionCard(
                    title: "Wiring from 14",
                    symbol: "sparkles",
                    status: "Childhood shape showing up",
                    tone: .positive,
                    detailTitle: "See more",
                    detailIdentifier: "teen-wiring-detail",
                    detailAction: { openDetail(.educationOverview) }
                ) {
                    ChipStrip(
                        title: "Early edges",
                        items: Array(nextUnlocks.filter { $0.contains("edge") || $0.contains("instinct") || $0.contains("current") || $0.contains("mind") || $0.contains("Physical") || $0.contains("Hustle") || $0.contains("Creative") || $0.contains("Social") || $0.contains("Sharp") }.prefix(3)),
                        tone: .positive,
                        identifier: "teen-wiring-strip"
                    )
                }
            }

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("education-tab-content")
    }

    private var educationStatus: String {
        switch state.education.stage {
        case .secondary:
            switch state.education.pathway {
            case .graduate: return "Graduated"
            case .training: return "In training"
            case .dropout: return "Off track"
            case .student: return state.education.schoolStanding >= 70 ? "On track" : "School under pressure"
            default: return "On track"
            }
        case .university:
            return state.education.hasScholarship ? "University with aid" : "University under load"
        case .tradeTraining:
            return "Trade training"
        case .adultEd:
            return "Rebuilding path"
        case .inactive:
            if state.education.credentials.contains("Degree") {
                return "Degree earned"
            }
            if state.education.credentials.contains("Trade Certificate") {
                return "Trade certified"
            }
            return state.education.pathway == .graduate ? "Graduated" : "Inactive"
        }
    }

    private var educationSummary: String {
        if state.education.stage == .university {
            return state.education.hasScholarship
                ? "University is open, but expectations and debt pressure are now part of the equation."
                : "University is active, and the real question is whether fit, cost, and burnout can all hold."
        }
        if state.education.stage == .tradeTraining {
            return "Training is giving you a practical lane into adulthood, with less prestige and more immediate payoff. (D3: fast income handoff, credential decays slower if you stay hands-on.)"
        }
        if state.education.stage == .adultEd {
            return "This is a slower rebuilding route. It buys time, but it does not buy comfort."
        }
        if state.education.hasScholarship {
            return "Your school performance is opening doors and easing the financial burden."
        }
        if state.education.schoolBelonging < 40 || state.education.reputationRisk >= 55 || state.education.peerPressure >= 50 {
            return "School feels socially fragile right now, and your place in it is affecting everything else."
        }
        if state.education.attendancePressure >= 55 || state.education.burnoutRisk >= 55 {
            return "School is becoming fragile, and this year’s discipline could decide a lot."
        }
        return "Education is still shaping the floor under the rest of your life."
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: state.education.burnoutRisk >= 55 ? "burnout rising" : (state.education.reputationRisk >= 50 ? "social risk" : "manageable"),
                tone: state.education.burnoutRisk >= 55 || state.education.reputationRisk >= 50 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.education.hasScholarship ? "scholarship live" : (state.education.mentorSupport >= 65 ? "adult support" : "still forming"),
                tone: state.education.hasScholarship || state.education.mentorSupport >= 65 ? .positive : .neutral
            ),
            PlannerInsight(
                title: "Momentum",
                value: state.education.applicationReadiness >= 55 ? "building" : (state.education.engagement < 40 ? "slipping" : "fragile"),
                tone: state.education.applicationReadiness >= 55 ? .positive : (state.education.engagement < 40 ? .warning : .neutral)
            )
        ]
    }
}

private struct SchoolClimateModule: View {
    let metrics: [(String, String, PlannerTone)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("School Climate")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            MetricRow(metrics: metrics)
        }
        .accessibilityIdentifier("education-school-climate")
    }
}

private struct CareerPlannerTab: View {
    let state: GameState
    let roleTitle: String
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let crimeActionChoices: [ActionChoiceID]
    let onSelectCrimeAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Career",
                symbol: "briefcase.fill",
                status: roleTitle,
                tone: state.career.status == .unemployed ? .warning : (state.career.performance >= 75 ? .positive : .neutral),
                detailTitle: "Details",
                detailIdentifier: "career-overview-detail-button",
                detailAction: { openDetail(.careerOverview) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    MetricRow(metrics: [
                        ("Performance", "\(state.career.performance)", state.career.performance >= 75 ? .positive : (state.career.performance < 35 ? .warning : .neutral)),
                        ("Income", "$\(state.career.annualIncome)", state.career.annualIncome > 0 ? .positive : .warning),
                        ("Years", "\(state.career.yearsWorked)", .neutral)
                    ])
                    Text(careerSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("career-overview-header")

            AuditStrip(insights: auditInsights, identifier: "career-overview-audit")

            if let specialMetrics {
                PlannerSectionCard(
                    title: "Special Career",
                    symbol: state.specialCareer.track == .crime ? "flame.fill" : "sparkles",
                    status: state.specialCareer.track == .crime ? "High volatility" : "Spotlight pressure",
                    tone: state.specialCareer.burnout >= 70 || state.specialCareer.track == .crime ? .warning : .neutral
                ) {
                    MetricRow(metrics: specialMetrics)
                }
            }

            // Fame Web F3: Recognition card with flavor and downside hints
            let f = state.fame
            if f.recognition > 24 {
                let label = f.isInfamous ? "Infamous" : (f.isHouseholdName ? "Household Name" : (f.recognition > 55 ? "Widely Known" : "Name Travels"))
                let tone: PlannerTone = f.isInfamous ? .warning : (f.culturalFame > f.notoriety ? .positive : .neutral)
                let recognitionItems: [(String, String, PlannerTone)] = {
                    var items: [(String, String, PlannerTone)] = [
                        ("Fame", "\(f.culturalFame)", f.culturalFame >= 55 ? .positive : .neutral),
                        ("Notoriety", "\(f.notoriety)", f.notoriety >= 45 ? .warning : .neutral)
                    ]
                    if f.isInfamous {
                        items.append(("Scrutiny", "High", .warning))
                    } else if f.isHouseholdName {
                        items.append(("Expectations", "Heavy", .neutral))
                    }
                    return items
                }()
                PlannerSectionCard(title: "Recognition", symbol: "star.fill", status: label, tone: tone) {
                    MetricRow(metrics: recognitionItems)
                }
            }

            if showsCrimeCareerSection {
                PlannerSectionCard(
                    title: "Crime",
                    symbol: "flame.fill",
                    status: crimeStatus,
                    tone: crimeTone
                ) {
                    MetricRow(metrics: [
                        ("Heat", "\(state.crime.heat)", state.crime.heat >= 65 ? .warning : .neutral),
                        ("Loyalty", "\(state.crime.loyalty)", state.crime.loyalty >= 55 ? .positive : .neutral),
                        ("Pressure", "\(state.crime.territoryPressure)", state.crime.territoryPressure >= 60 ? .warning : .neutral)
                    ])

                    ActionSelectionModule(actionChoices: crimeActionChoices, onSelectAction: onSelectCrimeAction)
                }
                .accessibilityIdentifier("crime-career-section")
            }

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("career-tab-content")
    }

    private var showsCrimeCareerSection: Bool {
        state.crime.status != .inactive || !crimeActionChoices.isEmpty || state.specialCareer.track == .crime
    }

    private var crimeStatus: String {
        switch state.crime.status {
        case .inactive:
            return "Dormant"
        case .active:
            return state.crime.crewID == nil ? "Operating solo" : "Crew active"
        case .layingLow:
            return "Laying low"
        }
    }

    private var crimeTone: PlannerTone {
        if state.crime.heat >= 65 || state.crime.territoryPressure >= 60 || state.crime.burnout >= 70 {
            return .warning
        }
        if state.crime.status != .inactive && state.crime.loyalty >= 55 {
            return .positive
        }
        return .neutral
    }

    private var careerSummary: String {
        switch state.specialCareer.track {
        case .entertainment:
            if state.specialCareer.burnout >= 72 {
                return "You are still getting noticed, but the grind behind it is starting to eat through your stability."
            }
            if state.specialCareer.lastPayout >= 4_000 {
                return "The spotlight finally paid this year, but entertainment money still looks volatile rather than safe."
            }
            return "You are pursuing attention-based work where visibility matters more than comfort and consistency."
        case .movieActor:
            return "You are building a screen career. Craft, auditions, credits, public image, and typecast risk decide whether the camera becomes income or just another expensive dream."
        case .recordLabelOwner:
            return "You own the music machine now. Roster trust, catalog depth, tour upside, and cashflow pressure decide whether the label becomes a home for artists or another extractive room with better furniture."
        case .coach:
            return "Diamond Career: you manage a sports program now. Recruiting, staff, scheme, locker room trust, boosters, and season results decide whether you climb or get fired."
        case .movieProducer:
            return "Diamond Career: you manage scripts, casts, budgets, distribution, and production chaos. The upside is bigger than acting work, but unfinished projects can burn cash fast."
        case .musicProducer:
            return "You are building the sound behind the artist. Credits, studio quality, network, royalties, and credit disputes decide whether your name becomes a tag, a catalog, or a cautionary story."
        case .inactive:
            break
        case .crime:
            break
        case .founder, .shadowOperative, .trader, .ventureCapitalist, .corporateRaider:
            return "You are building something from nothing. Vision and execution are your weapons. Every dollar raised, every key hire, every board meeting is a negotiation between control, growth, and your own sanity."
        case .contentCreator:
            return "You are farming attention in the attention economy. Every post is a bet. Algorithm favor, personal brand, and burnout are your real stats. One clip can change everything — or destroy it."
        case .politics:
            return "You are playing the longest game there is. Approval is oxygen. Scandals are poison. Every decision is a calculation between what is right, what is popular, and what keeps the money flowing."
        case .athlete:
            return "Your body is the product. Peak Form is what you have today. Potential is the ceiling you were born with. Brand is what the world decides you are worth when the lights go out. Accolades are the only things that survive the decline."
        default:
            break
        }

        if state.career.status == .unemployed {
            return "Work stability is the pressure point right now, so the next year matters."
        }
        if state.career.performance >= 75 {
            return "Your work momentum is healthy and could convert into better opportunities."
        }
        return "Your career is moving, but it still needs steadier performance to feel secure."
    }

    private var specialMetrics: [(String, String, PlannerTone)]? {
        switch state.specialCareer.track {
        case .entertainment:
            return [
                ("Fame", "\(state.specialCareer.fame)", state.specialCareer.fame >= 60 ? .positive : .neutral),
                ("Audience", "\(state.specialCareer.audience)", state.specialCareer.audience >= 55 ? .positive : .neutral),
                ("Burnout", "\(state.specialCareer.burnout)", state.specialCareer.burnout >= 70 ? .warning : .neutral)
            ]
        case .movieActor:
            let actor = state.specialCareer.movieActor
            var metrics: [(String, String, PlannerTone)] = [
                ("Craft", "\(actor.actingSkill)", actor.actingSkill >= 60 ? .positive : .neutral),
                ("Credits", "\(actor.roleCredits)", actor.roleCredits >= 4 ? .positive : .neutral),
                ("Draw", "\(actor.boxOfficeDraw)", actor.boxOfficeDraw >= 45 ? .positive : .neutral),
                ("Agent", "\(actor.agentQuality)", actor.agentQuality >= 55 ? .positive : .neutral),
                ("Image", "\(actor.publicImage)", actor.publicImage < 35 ? .warning : .neutral)
            ]
            if actor.typecastRisk >= 35 {
                metrics.append(("Typecast", "\(actor.typecastRisk)", actor.typecastRisk >= 60 ? .warning : .neutral))
            }
            return metrics
        case .recordLabelOwner:
            let label = state.specialCareer.recordLabel
            var metrics: [(String, String, PlannerTone)] = [
                ("Roster", "\(label.roster.count)", label.roster.count >= 3 ? .positive : .neutral),
                ("Catalog", "\(label.catalogStrength)", label.catalogStrength >= 55 ? .positive : .neutral),
                ("Prestige", "\(label.labelPrestige)", label.labelPrestige >= 55 ? .positive : .neutral),
                ("Artist Trust", "\(label.artistTrust)", label.artistTrust < 40 ? .warning : (label.artistTrust >= 70 ? .positive : .neutral)),
                ("Cashflow", "\(label.cashflowPressure)", label.cashflowPressure >= 65 ? .warning : .neutral)
            ]
            if label.industryHeat >= 35 {
                metrics.append(("Heat", "\(label.industryHeat)", label.industryHeat >= 60 ? .warning : .neutral))
            }
            if label.tourMachine >= 45 {
                metrics.append(("Tours", "\(label.tourMachine)", .positive))
            }
            return metrics
        case .coach:
            let coach = state.specialCareer.coaching
            var metrics: [(String, String, PlannerTone)] = [
                ("Diamond", "Coach", .positive),
                ("Record", "\(coach.seasonWins)-\(coach.seasonLosses)", coach.seasonWins >= 9 ? .positive : (coach.seasonWins <= 4 && coach.seasonLosses > 0 ? .warning : .neutral)),
                ("Roster", "\(coach.rosterTalent)", coach.rosterTalent >= 60 ? .positive : .neutral),
                ("Scheme", "\(coach.schemeFit)", coach.schemeFit >= 60 ? .positive : .neutral),
                ("Locker Room", "\(coach.lockerRoom)", coach.lockerRoom < 40 ? .warning : .neutral),
                ("Prestige", "\(coach.programPrestige)", coach.programPrestige >= 60 ? .positive : .neutral)
            ]
            if coach.boosterPressure >= 35 {
                metrics.append(("Boosters", "\(coach.boosterPressure)", coach.boosterPressure >= 65 ? .warning : .neutral))
            }
            return metrics
        case .movieProducer:
            let film = state.specialCareer.movieProducer
            var metrics: [(String, String, PlannerTone)] = [
                ("Diamond", "Film", .positive),
                ("Slate", "\(film.slateCount)", film.slateCount >= 2 ? .positive : .neutral),
                ("Prestige", "\(film.prestige)", film.prestige >= 55 ? .positive : .neutral),
                ("Studio Trust", "\(film.studioTrust)", film.studioTrust < 35 ? .warning : .neutral),
                ("Backend", "\(film.backendCatalog)", film.backendCatalog >= 45 ? .positive : .neutral),
                ("Chaos", "\(film.productionChaos)", film.productionChaos >= 60 ? .warning : .neutral)
            ]
            if film.distributionLeverage >= 40 {
                metrics.append(("Distribution", "\(film.distributionLeverage)", .positive))
            }
            return metrics
        case .musicProducer:
            let producer = state.specialCareer.musicProducer
            var metrics: [(String, String, PlannerTone)] = [
                ("Credits", "\(producer.credits)", producer.credits >= 8 ? .positive : .neutral),
                ("Sound", "\(producer.sonicSignature)", producer.sonicSignature >= 60 ? .positive : .neutral),
                ("Studio", "\(producer.studioQuality)", producer.studioQuality >= 55 ? .positive : .neutral),
                ("Demand", "\(producer.demand)", producer.demand >= 55 ? .positive : .neutral),
                ("Royalties", "\(producer.royaltyCatalog)", producer.royaltyCatalog >= 45 ? .positive : .neutral)
            ]
            if producer.creditDisputes >= 30 {
                metrics.append(("Disputes", "\(producer.creditDisputes)", producer.creditDisputes >= 55 ? .warning : .neutral))
            }
            return metrics
        case .inactive:
            return nil
        case .crime:
            return nil
        case .founder, .shadowOperative, .trader, .ventureCapitalist, .corporateRaider:
            var m: [(String, String, PlannerTone)] = [
                ("Reach", "\(state.specialCareer.audience)", state.specialCareer.audience >= 55 ? .positive : .neutral),
                ("Heat", "\(state.specialCareer.heat)", state.specialCareer.heat >= 60 ? .warning : .neutral),
                ("Burnout", "\(state.specialCareer.burnout)", state.specialCareer.burnout >= 70 ? .warning : .neutral)
            ]
            // Fame Web F1
            let fame = state.fame
            if fame.recognition > 22 {
                m.append(("Recognition", "\(fame.recognition)", fame.culturalFame > fame.notoriety ? .positive : .neutral))
            }
            // E4: Dedicated founder CEO dashboard (rich, glanceable)
            if state.specialCareer.track == .founder {
                let fd = state.specialCareer.founder
                m.append(("Vision", "\(fd.vision)", fd.vision >= 70 ? .positive : .neutral))
                m.append(("Execution", "\(fd.execution)", fd.execution >= 68 ? .positive : (fd.execution < 45 ? .warning : .neutral)))
                m.append(("Team", "\(fd.teamHealth)", fd.teamHealth >= 65 ? .positive : (fd.teamHealth < 40 ? .warning : .neutral)))
                m.append(("Stage", "\(fd.productStage)", fd.productStage >= 70 ? .positive : .neutral))
                if fd.founderMentalLoad > 55 {
                    m.append(("Mental Load", "\(fd.founderMentalLoad)", .warning))
                }
                if fd.control < 60 {
                    m.append(("Control", "\(fd.control)", .warning))
                }
                if fd.personalLegend >= 50 {
                    m.append(("Legend", "\(fd.personalLegend)", .positive))
                }
            }
            // C4: Dedicated creator dashboard (rich, glanceable)
            if state.specialCareer.track == .contentCreator {
                let c = state.specialCareer.creator
                m.append(("Audience", "\(c.audience)", c.audience >= 50 ? .positive : .neutral))
                m.append(("Algorithm", "\(c.algorithmFavor)", c.algorithmFavor >= 65 ? .positive : (c.algorithmFavor < 35 ? .warning : .neutral)))
                m.append(("Brand", "\(c.personalBrand)", c.personalBrand >= 60 ? .positive : (c.personalBrand < 30 ? .warning : .neutral)))
                if c.burnout > 50 {
                    m.append(("Burnout", "\(c.burnout)", .warning))
                }
                if c.cancellationRisk > 40 {
                    m.append(("Cancel Risk", "\(c.cancellationRisk)", .warning))
                }
                if c.brandDealValue > 40 {
                    m.append(("Deals", "\(c.brandDealValue)", .positive))
                }
                // Platform flavor
                let platformLabel = c.platform == .tiktokShorts ? "Shorts" : (c.platform == .youtube ? "YT" : c.platform.rawValue.capitalized)
                m.append((platformLabel, "", .neutral))
            }
            // P4: Dedicated politics dashboard (rich, glanceable)
            if state.specialCareer.track == .politics {
                let p = state.specialCareer.politics
                m.append(("Approval", "\(p.approvalRating)", p.approvalRating >= 55 ? .positive : (p.approvalRating < 35 ? .warning : .neutral)))
                if p.scandalHeat > 35 {
                    m.append(("Scandal", "\(p.scandalHeat)", .warning))
                }
                m.append(("Ethics", "\(p.ethics)", p.ethics >= 65 ? .positive : (p.ethics < 45 ? .warning : .neutral)))
                m.append(("Donors", "\(p.donorBase)", p.donorBase >= 50 ? .positive : .neutral))
                if p.burnout > 50 {
                    m.append(("Burnout", "\(p.burnout)", .warning))
                }
                if p.policyLegacy >= 45 {
                    m.append(("Legacy", "\(p.policyLegacy)", .positive))
                }
                if p.charisma >= 65 {
                    m.append(("Charisma", "\(p.charisma)", .positive))
                }
                // Econ1: Glanceable macro context
                let eraName = state.currentEra.displayName
                m.append(("Economy", eraName, state.currentEra.tone))
            }
            return m
        case .athlete:
            let a = state.specialCareer.athlete
            var metrics: [(String, String, PlannerTone)] = [
                ("Peak Form", "\(a.peakPerformance)", a.peakPerformance >= 78 ? .positive : (a.peakPerformance < 50 ? .warning : .neutral)),
                ("Potential", "\(a.naturalPotential)", a.naturalPotential >= 82 ? .positive : (a.naturalPotential < 60 ? .warning : .neutral)),
                ("Durability", "\(a.durability)", a.durability >= 68 ? .positive : (a.durability < 42 ? .warning : .neutral)),
                ("Brand", "\(a.personalBrand)", a.personalBrand >= 65 ? .positive : (a.personalBrand < 35 ? .warning : .neutral)),
                ("Fan Loyalty", "\(a.fanLoyalty)", a.fanLoyalty >= 65 ? .positive : .neutral)
            ]
            if !a.accolades.isEmpty {
                let count = a.accolades.count
                let label = count == 1 ? "1 Accolade" : "\(count) Accolades"
                let tone: PlannerTone = count >= 3 ? .positive : .neutral
                metrics.append((label, a.accolades.last ?? "", tone))
            }
            // Show enhancement heat if active
            if a.enhancementHeat > 25 {
                metrics.append(("Edge Heat", "\(a.enhancementHeat)", a.enhancementHeat > 60 ? .warning : .neutral))
            }
            // Fame Web F1: unified recognition (the thing that actually travels outside your sport)
            let f = state.fame
            if f.recognition > 20 {
                let recLabel = f.isHouseholdName ? "Household Name" : (f.recognition > 55 ? "Widely Known" : "Rising Name")
                metrics.append((recLabel, "\(f.recognition)", f.culturalFame >= 60 ? .positive : .neutral))
            }
            // Econ1: Glanceable macro context (sponsorships & fan spending are economy-tied)
            metrics.append(("Economy", state.currentEra.displayName, state.currentEra.tone))
            return metrics
        default:
            return nil
        }
    }

    private var experienceLaneLabel: String {
        state.career.strongestExperienceTag?.shortLabel ?? "Unproven"
    }

    private var qualifiedRoleCount: Int {
        CareerCatalog.qualifiedRoles(for: state.player, career: state.career, education: state.education, childhoodDossier: state.childhoodDossier).count
    }

    private var specialCareerReadinessLabel: String {
        if state.specialCareer.track != .inactive {
            return state.specialCareer.track.rawValue.capitalized
        }
        if SpecialCareerSystem.qualificationIssue(for: .startCompany, state: state) == nil {
            return "Founder ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startMovieActor, state: state) == nil {
            return "Actor ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startMusicProducer, state: state) == nil {
            return "Producer ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startMovieProducer, state: state) == nil {
            return "Diamond ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startRecordLabel, state: state) == nil {
            return "Label ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .startCoachingCareer, state: state) == nil {
            return "Coach ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .manageFund, state: state) == nil {
            return "Capital ready"
        }
        if SpecialCareerSystem.qualificationIssue(for: .gatherIntelligence, state: state) == nil {
            return "Access ready"
        }
        if state.player.age >= 18 {
            return "Building"
        }
        return "Locked"
    }

    private var specialCareerReadinessTone: PlannerTone {
        specialCareerReadinessLabel.contains("ready") || state.specialCareer.track != .inactive ? .positive : (state.player.age >= 18 ? .neutral : .warning)
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: state.career.status == .unemployed ? "no stable work" : (state.career.performance < 40 ? "performance weak" : "holding"),
                tone: state.career.status == .unemployed || state.career.performance < 40 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.career.performance >= 78 ? "promotion range" : (state.specialCareer.track == .entertainment ? "creative upside" : "slow build"),
                tone: state.career.performance >= 78 || state.specialCareer.track == .entertainment ? .positive : .neutral
            ),
            PlannerInsight(
                title: "Momentum",
                value: state.career.burnout >= 68 ? "burnout carrying over" : (state.career.yearsWorked >= 2 ? "career stacking" : (state.career.performance < 35 ? "stalled" : "early")),
                tone: state.career.burnout >= 68 ? .warning : (state.career.yearsWorked >= 2 ? .positive : (state.career.performance < 35 ? .warning : .neutral))
            )
        ]
    }
}

private struct FinancePlannerTab: View {
    let state: GameState
    let isTeenExperience: Bool
    let teenMetrics: [(String, String, PlannerTone)]
    let policyLabel: String
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Finance",
                symbol: "dollarsign.circle.fill",
                status: balanceStatus,
                tone: state.finance.lastYearBalanceDelta < 0 ? .warning : (state.finance.lastYearBalanceDelta > 5_000 ? .positive : .neutral),
                detailTitle: "Details",
                detailIdentifier: "finance-cashflow-detail-button",
                detailAction: { openDetail(.financeCashflow) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if isTeenExperience {
                        MetricRow(metrics: teenMetrics)
                    } else {
                        MetricRow(metrics: [
                            ("Cash", "$\(state.finance.cashOnHand)", state.finance.cashOnHand >= 0 ? .positive : .warning),
                            ("Net", "$\(state.finance.annualNetIncome)", state.finance.annualNetIncome > 0 ? .positive : .warning),
                            ("Stress", "\(state.finance.financialStress)", state.finance.financialStress >= 45 ? .warning : .neutral)
                        ])
                    }
                    Text(financeSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("finance-overview-header")

            AuditStrip(insights: auditInsights, identifier: "finance-overview-audit")

            PlannerSectionCard(
                title: "Money Pressure",
                symbol: state.finance.lastYearBalanceDelta < 0 ? "arrow.down.circle.fill" : "chart.line.uptrend.xyaxis",
                status: policyLabel,
                tone: state.finance.financialStress >= 45 || state.finance.lastYearBalanceDelta < 0 ? .warning : .neutral,
                detailTitle: "Inspect",
                detailIdentifier: "finance-policy-detail-button",
                detailAction: { openDetail(.financePolicy) }
            ) {
                MetricRow(metrics: [
                    ("Housing", housingLabel, state.housing.housingStability < 40 ? .warning : .neutral),
                    ("Velocity", signedDollar(state.finance.lastYearBalanceDelta), state.finance.lastYearBalanceDelta < 0 ? .warning : (state.finance.lastYearBalanceDelta > 0 ? .positive : .neutral))
                ])
            }
            .accessibilityIdentifier("finance-overview-pressure")

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("finance-tab-content")
    }

    private var housingLabel: String {
        switch state.housing.livingArrangement {
        case .familyHome: return "Family home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Solo rent"
        case .ownerOccupied: return "Owner occupied"
        case .couchSurfing: return "Unstable"
        }
    }

    private var balanceStatus: String {
        if state.assets.ownsHome && state.assets.primaryResidence?.status == .delinquent { return "Ownership under strain" }
        if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 { return "Saving toward ownership" }
        if state.finance.lastYearBalanceDelta < 0 { return "Budget under strain" }
        if state.finance.lastYearBalanceDelta > 5_000 { return "Building surplus" }
        return "Cash flow holding"
    }

    private var financeSummary: String {
        if isTeenExperience {
            if state.finance.financialStress >= 40 {
                return "Money stress at home is already bleeding into what school and recovery feel like."
            }
            if state.finance.cashOnHand < 100 {
                return "You have a little cash, but not much margin for comfort or mistakes."
            }
            return "Early money is small, but it already changes freedom, stress, and how steady home feels."
        }
        if state.finance.financialStress >= 45 {
            return "Money pressure is actively shaping the rest of your life."
        }
        if state.assets.ownsHome {
            if state.assets.primaryResidence?.status == .delinquent {
                return "The house is no longer just stability. Debt, upkeep, and timing are all pushing back at once."
            }
            if state.finance.lastYearHousingGainLoss < 0 {
                return "Ownership is building equity slowly, but one repair-heavy year can still erase the emotional upside fast."
            }
            return "Homeownership is giving you a different kind of wealth: slower, heavier, and much less liquid."
        }
        if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 {
            return "You are trying to buy your way into stability, which means sacrificing easy cash long before the house exists."
        }
        if state.finance.hasInvestments {
            if state.finance.lastYearInvestmentDelta < 0 {
                return "You are finally compounding money, but a bad market year can still tighten the whole household mood."
            }
            if state.finance.lastYearInvestmentDelta > 0 {
                return "Your money is starting to work for you, but it is still locked behind risk and patience."
            }
            return "You have started building invested wealth, which helps long-term but does not solve short-term cash pressure."
        }
        if state.housing.housingStability < 35 {
            return "Housing instability is now part of your money problem, not separate from it."
        }
        if state.finance.lastYearBalanceDelta < 0 {
            return "Your costs are still beating your income, so stability has not landed yet."
        }
        return "This year feels financially livable, even if it is not comfortable yet."
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: state.finance.financialStress >= 45 ? "stress bleeding out" : (state.finance.lastYearBalanceDelta < 0 ? "running deficit" : "contained"),
                tone: state.finance.financialStress >= 45 || state.finance.lastYearBalanceDelta < 0 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.assets.ownsHome ? "equity building" : (state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 ? "house fund live" : (state.finance.hasInvestments ? "money compounding" : (state.finance.lastYearBalanceDelta > 0 ? "cash room" : (state.housing.livingArrangement == .familyHome ? "cheap housing" : "thin")))),
                tone: state.assets.ownsHome || state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 || state.finance.hasInvestments || state.finance.lastYearBalanceDelta > 0 ? .positive : .neutral
            ),
            PlannerInsight(
                title: "Momentum",
                value: homeownershipActive ? homeMomentum : (state.finance.hasInvestments ? portfolioMomentum : (state.finance.consecutiveDeficitYears == 0 ? "recovering" : "\(state.finance.consecutiveDeficitYears) bad year\(state.finance.consecutiveDeficitYears == 1 ? "" : "s")")),
                tone: homeownershipActive ? homeStatusTone : (state.finance.hasInvestments ? riskTone : (state.finance.consecutiveDeficitYears == 0 ? .positive : .warning))
            )
        ]
    }

    private var homeownershipActive: Bool {
        state.assets.ownsHome || state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 || state.finance.lastYearHomeValueDelta != 0
    }

    private var homeStatusLabel: String {
        if let home = state.assets.primaryResidence {
            switch home.status {
            case .current:
                return "Owned"
            case .delinquent:
                return "Delinquent"
            case .foreclosed:
                return "Lost"
            }
        }
        if state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0 {
            return "Saving"
        }
        return "None"
    }

    private var homeStatusTone: PlannerTone {
        if let home = state.assets.primaryResidence {
            return home.status == .delinquent ? .warning : .positive
        }
        return (state.assets.isSavingForHome || state.finance.homeDownPaymentSavings > 0) ? .neutral : .neutral
    }

    private var riskTone: PlannerTone {
        switch state.finance.investmentRiskProfile {
        case .defensive:
            return .neutral
        case .conservative:
            return .positive
        case .balanced:
            return .neutral
        case .speculative:
            return .warning
        }
    }

    private var portfolioMomentum: String {
        if state.finance.lastYearInvestmentDelta > 0 { return "portfolio up" }
        if state.finance.lastYearInvestmentDelta < 0 { return "portfolio hit" }
        return "just starting"
    }

    private var homeMomentum: String {
        if state.assets.ownsHome {
            if state.assets.primaryResidence?.status == .delinquent { return "mortgage slipping" }
            if state.finance.lastYearHousingGainLoss > 0 { return "equity rising" }
            if state.finance.lastYearHousingGainLoss < 0 { return "repairs hit" }
            return "ownership settling"
        }
        if state.finance.homeDownPaymentSavings > 0 { return "fund growing" }
        return "not started"
    }

    private func signedDollar(_ value: Int) -> String {
        value >= 0 ? "+$\(value)" : "-$\(abs(value))"
    }
}

private struct RelationshipsPlannerTab: View {
    let state: GameState
    let isTeenExperience: Bool
    let teenMetrics: [(String, String, PlannerTone)]
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Relationships",
                symbol: "person.2.fill",
                status: relationshipStatus,
                tone: strainedRelationshipCount > 0 ? .warning : (connectionCount > 0 ? .positive : .neutral),
                detailTitle: "Details",
                detailIdentifier: "relationships-connections-detail-button",
                detailAction: { openDetail(.relationshipsConnections) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    MetricRow(metrics: isTeenExperience ? teenMetrics : [
                        ("Connections", "\(connectionCount)", connectionCount > 0 ? .positive : .warning),
                        ("Social Climate", "\(state.relationships.publicReputation)", state.relationships.publicReputation >= 60 ? .positive : (state.relationships.publicReputation <= 40 ? .warning : .neutral))
                    ])
                    Text(relationshipSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("relationships-overview-header")

            AuditStrip(insights: auditInsights, identifier: "relationships-overview-audit")

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("relationships-tab-content")
    }

    private var connectionCount: Int {
        state.relationships.friends.count + (state.relationships.hasPartner ? 1 : 0)
    }

    private var strainedRelationshipCount: Int {
        (state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count
    }

    private var strongestBondTone: PlannerTone {
        let strongest = max(state.relationships.friends.strongestBond, state.relationships.partnerBond)
        if strongest >= 75 { return .positive }
        if strongest < 35 { return .warning }
        return .neutral
    }

    private var relationshipStatus: String {
        if let pregnancy = state.family.pregnancy {
            return "Pregnant with \(pregnancy.otherParentName)"
        }
        if let partner = state.relationships.primaryPartner {
            switch partner.stage {
            case .married:
                return "Married to \(partner.name)"
            case .engaged:
                return "Engaged to \(partner.name)"
            case .committed:
                return "Committed to \(partner.name)"
            case .dating:
                return "With \(partner.name)"
            }
        }
        if !state.relationships.friends.isEmpty {
            return "Friend network active"
        }
        return "Social life is thin"
    }

    private var relationshipSummary: String {
        if isTeenExperience {
            if state.relationships.activeRumorHeat >= 55 {
                return "Rumor is hot enough to spill into school, mood, and who feels safe to trust."
            }
            if strainedRelationshipCount > 0 {
                return "Teen social tension is spilling into the rest of your year faster than it looks."
            }
            if connectionCount == 0 {
                return "Belonging is thin right now, which makes school and stress hit harder."
            }
            return "The people around you are starting to shape who you become, not just how you feel."
        }
        if strainedRelationshipCount > 0 {
            return "At least one close connection is fraying and needs care."
        }
        if state.relationships.activeTensionCount > 0 {
            return state.relationships.strongestTension?.impactLine ?? "A loose end is still draining trust and emotional room from the year."
        }
        if state.family.isPregnant {
            return "Your relationship is now carrying physical, financial, and emotional consequence all at once."
        }
        if state.family.childCount > 0 {
            return "Family life is now shaping money, recovery, and relationship stability every year."
        }
        if connectionCount == 0 {
            return "Your support system is light right now, which makes hard years hit harder."
        }
        return "Your social life is carrying some warmth and stability."
    }

    private var familyStatusMetric: String {
        if state.family.isPregnant { return "Pregnant" }
        if state.family.childCount > 0 { return "\(state.family.childCount) kids" }
        return state.family.pregnancyIntent == .avoid ? "Avoiding" : (state.family.pregnancyIntent == .trying ? "Trying" : "Open")
    }

    private var familyStatusTone: PlannerTone {
        if state.family.isPregnant || state.family.childCount > 0 { return .warning }
        if state.relationships.hasPartner { return .neutral }
        return .neutral
    }

    private var connectionPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let partner = state.relationships.primaryPartner {
                connectionBadge(name: partner.name, status: partner.status, bond: partner.bond)
            }

            if let friend = state.relationships.friends.max(by: { $0.bond < $1.bond }) {
                connectionBadge(name: friend.name, status: friend.status, bond: friend.bond)
            }
        }
    }

    private func connectionBadge(name: String, status: RelationshipStatus, bond: Int) -> some View {
        let tone: PlannerTone = status == .strained ? .warning : .positive
        return HStack {
            Text(name)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(bond)")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tone.fill)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: state.relationships.activeRumorHeat >= 55 ? "rumor is hot" : (state.relationships.activeTensionCount > 0 ? "loose ends active" : (connectionCount == 0 ? "socially thin" : "steady")),
                tone: state.relationships.activeRumorHeat >= 55 || state.relationships.activeTensionCount > 0 || connectionCount == 0 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.relationships.futureAlignment.averageReadiness >= 60 ? "shared future" : (state.relationships.hasPartner ? "deeper commitment" : "new support"),
                tone: .positive
            ),
            PlannerInsight(
                title: "Momentum",
                value: max(state.relationships.friends.strongestBond, state.relationships.partnerBond) >= 70 ? "trust growing" : state.relationships.socialClimateLabel.lowercased(),
                tone: max(state.relationships.friends.strongestBond, state.relationships.partnerBond) >= 70 ? .positive : .neutral
            )
        ]
    }

    private var looseEnds: [String] {
        let items = state.relationships.tensions.prefix(3).map { "\($0.headline) • \($0.impactLine)" }
        return items.isEmpty ? [] : Array(items)
    }
}

private struct HealthPlannerTab: View {
    let state: GameState
    let isTeenExperience: Bool
    let teenMetrics: [(String, String, PlannerTone)]
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void
    let comingUpItems: [String]
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Health",
                symbol: "heart.fill",
                status: healthStatus,
                tone: state.player.health < 40 ? .warning : (state.player.health >= 60 ? .positive : .neutral),
                detailTitle: "Details",
                detailIdentifier: "health-overview-detail-button",
                detailAction: { openDetail(.healthOverview) }
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    if isTeenExperience {
                        MetricRow(metrics: teenMetrics)
                    } else {
                        MetricRow(metrics: [
                            ("Overall", "\(state.player.health)", state.player.health >= 60 ? .positive : (state.player.health < 40 ? .warning : .neutral)),
                            ("Physical", "\(state.healthProfile.physicalWellness)", state.healthProfile.physicalWellness >= 60 ? .positive : (state.healthProfile.physicalWellness < 40 ? .warning : .neutral)),
                            ("Mental", "\(state.healthProfile.mentalWellness)", state.healthProfile.mentalWellness >= 60 ? .positive : (state.healthProfile.mentalWellness < 40 ? .warning : .neutral))
                        ])
                    }
                    Text(healthSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .accessibilityIdentifier("health-overview-header")

            AuditStrip(insights: auditInsights, identifier: "health-overview-audit")

            ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
        }
        .accessibilityIdentifier("health-tab-content")
    }

    private var healthStatus: String {
        if state.isGameOver { return "Life ended" }
        if !state.healthProfile.activeConditions.isEmpty { return "Health under pressure" }
        if state.player.health >= 65 { return "Body holding steady" }
        return "Needs better recovery"
    }

    private var healthSummary: String {
        if isTeenExperience {
            if !state.healthProfile.activeConditions.isEmpty {
                return "Recovery is not optional anymore. Your body is already pushing back."
            }
            if state.healthProfile.mentalWellness < 45 {
                return "Stress and poor sleep are quietly making school and social life more fragile."
            }
            return "Your recovery habits are the difference between holding together and slipping."
        }
        if !state.healthProfile.activeConditions.isEmpty {
            return "Your health is asking for attention now, not later."
        }
        if state.healthProfile.mentalWellness < 45 {
            return "Stress is dragging your quality of life down even if you are still functioning."
        }
        return "Your habits are keeping life manageable, even if not effortless."
    }

    private func tone(for value: Int) -> PlannerTone {
        if value >= 60 { return .positive }
        if value < 40 { return .warning }
        return .neutral
    }

    private var auditInsights: [PlannerInsight] {
        [
            PlannerInsight(
                title: "Problem",
                value: !state.healthProfile.activeConditions.isEmpty ? "condition active" : (state.healthProfile.mentalWellness < 45 ? "stress load" : "contained"),
                tone: !state.healthProfile.activeConditions.isEmpty || state.healthProfile.mentalWellness < 45 ? .warning : .neutral
            ),
            PlannerInsight(
                title: "Opportunity",
                value: state.healthProfile.hasPrimaryCare ? "care access" : (state.healthProfile.habits.exercise >= 60 ? "habits working" : "routine needed"),
                tone: state.healthProfile.hasPrimaryCare || state.healthProfile.habits.exercise >= 60 ? .positive : .neutral
            ),
            PlannerInsight(
                title: "Momentum",
                value: state.player.health >= 65 ? "holding steady" : (state.player.health < 40 ? "slipping" : "fragile"),
                tone: state.player.health >= 65 ? .positive : (state.player.health < 40 ? .warning : .neutral)
            )
        ]
    }
}

private struct AssetsPlannerTab: View {
    let state: GameState
    let onBuyFirearm: (Firearm, Int) -> Void
    let onUpgradeFirearm: (UUID, WeaponUpgrade) -> Void
    let onBuyVehicle: (Vehicle, Int) -> Void
    let onUpgradeVehicle: (UUID, VehicleUpgrade) -> Void
    let onUpgradeHouse: (HouseUpgrade) -> Void
    let onSellHouse: () -> Void
    let onBuyJewelry: (Jewelry) -> Void
    let onSellJewelry: (UUID) -> Void
    let onBuyAviation: (AviationAsset) -> Void
    let onSellAviation: (UUID) -> Void
    let onBuyMarine: (MarineAsset) -> Void
    let onSellMarine: (UUID) -> Void

    // Assets2
    let onBuySignature: (SignatureAsset) -> Void
    let onSellSignature: (UUID) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Very aggressive QoL: Rich visual portfolio + Lifestyle Score
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LIFESTYLE")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.secondary)
                            Text("\(state.assets.lifestyleScore)")
                                .font(.title.weight(.black))
                                .foregroundStyle(state.assets.lifestyleScore > 60 ? Color.purple : .primary)
                        }
                        
                        Spacer()
                        
                        Text("Portfolio Overview")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        AssetCategoryIcon(count: state.assets.vehicles.count, label: "Vehicles", symbol: "car.fill")
                        AssetCategoryIcon(count: state.assets.jewelry.count, label: "Jewelry", symbol: "sparkles")
                        AssetCategoryIcon(count: state.assets.aviation.count, label: "Aviation", symbol: "airplane")
                        AssetCategoryIcon(count: state.assets.marine.count, label: "Marine", symbol: "sailboat.fill")
                        AssetCategoryIcon(count: state.assets.firearms.count, label: "Armory", symbol: "shield.fill")
                        if !state.assets.signatureAssets.isEmpty {
                            AssetCategoryIcon(count: state.assets.signatureAssets.count, label: "Signature", symbol: "crown.fill")
                        }
                    }
                }
                .padding(.horizontal, 4)
                
                // Very aggressive QoL: Bulk sell low-value assets (UI hint)
                if !state.assets.jewelry.isEmpty || !state.assets.vehicles.isEmpty {
                    Text("Low-value items available to liquidate")
                        .font(.caption2.italic())
                        .foregroundStyle(.secondary)
                }
                
                // REAL ESTATE SECTION
                if let home = state.assets.primaryResidence {
                    PlannerSectionCard(
                        title: "Primary Residence",
                        symbol: "house.fill",
                        status: "Value: $\(home.totalValue)",
                        tone: .neutral
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Equity: $\(home.equity)")
                                        .font(.caption)
                                    Text("Maintenance: $\(home.totalMonthlyMaintenance)/mo")
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button {
                                    onSellHouse()
                                } label: {
                                    Text("SELL PROPERTY")
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(4)
                                }
                            }

                            if !home.upgrades.isEmpty {
                                Text("Luxury Upgrades")
                                    .font(.caption.weight(.bold))
                                
                                FlowLayout(home.upgrades, spacing: 4) { upgrade in
                                    Text(upgrade.rawValue.capitalized)
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                                Divider()
                            }
                            
                            Text("Property Market")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(HouseUpgrade.allCases, id: \.self) { upgrade in
                                        if !home.upgrades.contains(upgrade) {
                                            PropertyUpgradeCard(upgrade: upgrade, onUpgrade: onUpgradeHouse)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // JEWELRY SECTION
                PlannerSectionCard(
                    title: "Boutique",
                    symbol: "sparkles",
                    status: state.assets.jewelry.isEmpty ? "No jewelry" : "\(state.assets.jewelry.count) items",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.jewelry.isEmpty {
                            ForEach(state.assets.jewelry) { item in
                                JewelryRow(item: item, onSell: { onSellJewelry(item.id) })
                            }
                            Divider()
                        }

                        Text("Fine Jewelry")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                JewelryMarketCard(name: "Steel Watch", type: .watch, cost: 2500, resale: 1800, rarity: .common, onBuy: onBuyJewelry)
                                JewelryMarketCard(name: "Gold Chain", type: .chain, cost: 5500, resale: 4800, rarity: .rare, onBuy: onBuyJewelry)
                                JewelryMarketCard(name: "Diamond Studs", type: .earrings, cost: 12000, resale: 9000, rarity: .exotic, onBuy: onBuyJewelry)
                                JewelryMarketCard(name: "Bust-down AP", type: .watch, cost: 65000, resale: 45000, rarity: .exotic, onBuy: onBuyJewelry)
                                JewelryMarketCard(name: "Royal Crown Jewel", type: .pendant, cost: 150000, resale: 120000, rarity: .prototype, onBuy: onBuyJewelry)
                            }
                        }
                    }
                }

                // AVIATION SECTION
                PlannerSectionCard(
                    title: "Hangar",
                    symbol: "airplane",
                    status: state.assets.aviation.isEmpty ? "No aircraft" : "\(state.assets.aviation.count) aircraft owned",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.aviation.isEmpty {
                            ForEach(state.assets.aviation) { item in
                                AviationRow(item: item, onSell: { onSellAviation(item.id) })
                            }
                            Divider()
                        }

                        Text("Aviation Market")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                AviationMarketCard(name: "Used Cessna", type: .lightAircraft, cost: 150000, resale: 110000, maintenance: 1500, onBuy: onBuyAviation)
                                AviationMarketCard(name: "Executive Heli", type: .helicopter, cost: 1200000, resale: 950000, maintenance: 8500, onBuy: onBuyAviation)
                                AviationMarketCard(name: "Gulfstream G650", type: .privateJet, cost: 65000000, resale: 45000000, maintenance: 45000, onBuy: onBuyAviation)
                                AviationMarketCard(name: "BBJ 737", type: .heavyJet, cost: 120000000, resale: 95000000, maintenance: 120000, onBuy: onBuyAviation)
                            }
                        }
                    }
                }

                // MARINE SECTION
                PlannerSectionCard(
                    title: "Marina",
                    symbol: "sailboat.fill",
                    status: state.assets.marine.isEmpty ? "No vessels" : "\(state.assets.marine.count) vessels owned",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.marine.isEmpty {
                            ForEach(state.assets.marine) { item in
                                MarineRow(item: item, onSell: { onSellMarine(item.id) })
                            }
                            Divider()
                        }

                        Text("Marine Market")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                MarineMarketCard(name: "Racing Jet Ski", type: .jetSki, cost: 18000, resale: 12000, maintenance: 150, onBuy: onBuyMarine)
                                MarineMarketCard(name: "Powerboat", type: .speedboat, cost: 145000, resale: 95000, maintenance: 800, onBuy: onBuyMarine)
                                MarineMarketCard(name: "Luxury Yacht", type: .yacht, cost: 4500000, resale: 3200000, maintenance: 12000, onBuy: onBuyMarine)
                                MarineMarketCard(name: "Mega Yacht", type: .superYacht, cost: 150000000, resale: 110000000, maintenance: 85000, onBuy: onBuyMarine)
                            }
                        }
                    }
                }

                // ARMORY SECTION
                PlannerSectionCard(
                    title: "Armory",
                    symbol: "shield.fill",
                    status: state.assets.firearms.isEmpty ? "No defensive assets" : "\(state.assets.firearms.count) firearms",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.firearms.isEmpty {
                            ForEach(state.assets.firearms) { firearm in
                                FirearmRow(firearm: firearm, onUpgrade: { onUpgradeFirearm(firearm.id, $0) })
                            }
                        }

                        Text("Firearm Market")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        Text("Legal Hardware")
                            .font(.caption.weight(.bold))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                MarketCard(name: "9mm Handgun", type: .handgun, cost: 600, isLegal: true, power: 15, reliability: 90, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Pump Shotgun", type: .shotgun, cost: 1200, isLegal: true, power: 25, reliability: 85, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Precision Bolt-Action", type: .precisionRifle, cost: 3500, isLegal: true, power: 40, reliability: 95, onBuy: { onBuyFirearm($0, $1) })
                            }
                        }

                        Text("Black Market")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.red)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                MarketCard(name: "G-Series Handgun", type: .handgun, cost: 850, isLegal: false, power: 18, reliability: 85, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Modified SMG", type: .handgun, cost: 2500, isLegal: false, power: 35, reliability: 65, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Sawn-off Shotgun", type: .shotgun, cost: 1800, isLegal: false, power: 30, reliability: 60, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Tactical Carbine", type: .rifle, cost: 6500, isLegal: false, power: 55, reliability: 80, onBuy: { onBuyFirearm($0, $1) })
                            }
                        }

                        Text("Exotic & Rare")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.purple)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                MarketCard(name: "Gold-Plated Deagle", type: .handgun, cost: 15000, isLegal: true, power: 45, reliability: 70, rarity: .exotic, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Experimental Railgun", type: .precisionRifle, cost: 85000, isLegal: false, power: 120, reliability: 40, rarity: .prototype, onBuy: { onBuyFirearm($0, $1) })
                                MarketCard(name: "Antique Duelling Pistol", type: .handgun, cost: 12000, isLegal: true, power: 10, reliability: 30, rarity: .rare, onBuy: { onBuyFirearm($0, $1) })
                            }
                        }
                    }
                }

                // GARAGE SECTION
                PlannerSectionCard(
                    title: "Garage",
                    symbol: "car.fill",
                    status: state.assets.vehicles.isEmpty ? "No vehicles" : "\(state.assets.vehicles.count) vehicles",
                    tone: .neutral
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !state.assets.vehicles.isEmpty {
                            ForEach(state.assets.vehicles) { vehicle in
                                VehicleRow(vehicle: vehicle, onUpgrade: { onUpgradeVehicle(vehicle.id, $0) })
                            }
                        }

                        Text("Vehicle Market")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                VehicleMarketCard(name: "Used Hatchback", type: .compact, cost: 4500, speed: 30, handling: 40, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Luxury Sedan", type: .sedan, cost: 45000, speed: 60, handling: 70, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Sport Coupe", type: .sportsCar, cost: 85000, speed: 85, handling: 80, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Hypercar", type: .supercar, cost: 250000, speed: 100, handling: 95, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Exotic Hypercar", type: .hypercar, cost: 1800000, speed: 110, handling: 100, onBuy: onBuyVehicle)
                                VehicleMarketCard(name: "Limited Track Toy", type: .hypercar, cost: 3200000, speed: 115, handling: 105, onBuy: onBuyVehicle)
                            }
                        }
                    }
                }

                // Assets2: Signature Holdings — Career-specific high-status assets
                if state.specialCareer.track == .athlete ||
                   state.specialCareer.track == .founder ||
                   state.specialCareer.track == .contentCreator ||
                   state.specialCareer.track == .politics {

                    PlannerSectionCard(
                        title: "Signature Holdings",
                        symbol: "crown.fill",
                        status: state.assets.signatureAssets.isEmpty ? "No signature assets yet" : "\(state.assets.signatureAssets.count) major holdings",
                        tone: .positive
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            if !state.assets.signatureAssets.isEmpty {
                                ForEach(state.assets.signatureAssets) { item in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.name)
                                                .font(.headline)
                                            Text("Prestige +\(item.prestigeBonus)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Button("Sell") {
                                            onSellSignature(item.id)
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(.red)
                                    }
                                    .padding(.vertical, 4)
                                }
                                Divider()
                            }

                            Text("Available for Your Path")
                                .font(.headline)

                            // Career-specific signature asset market (Assets2)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    SignatureAssetMarketCards(
                                        currentTrack: state.specialCareer.track,
                                        onBuy: onBuySignature
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
}

// Assets2 helper: Career-specific signature asset market cards
private struct SignatureAssetMarketCards: View {
    let currentTrack: SpecialCareerTrack
    let onBuy: (SignatureAsset) -> Void

    var body: some View {
        Group {
            switch currentTrack {
            case .athlete:
                SignatureMarketCard(name: "Minority Stake in Expansion Team", category: .athleteTeamStake, cost: 12_000_000, resale: 9_500_000, prestige: 22, track: .athlete, onBuy: onBuy)
                SignatureMarketCard(name: "Private Performance Institute", category: .athleteTrainingEmpire, cost: 4_800_000, resale: 3_200_000, prestige: 14, track: .athlete, onBuy: onBuy)

            case .founder:
                SignatureMarketCard(name: "Strategic Stake in AI Competitor", category: .founderStrategicStake, cost: 18_000_000, resale: 14_000_000, prestige: 25, track: .founder, onBuy: onBuy)
                SignatureMarketCard(name: "Founder Compound (Wyoming)", category: .founderCompound, cost: 9_500_000, resale: 7_800_000, prestige: 18, track: .founder, onBuy: onBuy)

            case .contentCreator:
                SignatureMarketCard(name: "Personal Production Studio", category: .creatorStudio, cost: 6_200_000, resale: 4_100_000, prestige: 19, track: .contentCreator, onBuy: onBuy)
                SignatureMarketCard(name: "Signature Content House Portfolio", category: .creatorBrandEstate, cost: 3_400_000, resale: 2_600_000, prestige: 13, track: .contentCreator, onBuy: onBuy)

            case .politics:
                SignatureMarketCard(name: "Major Donor Retreat Estate", category: .politicsInfluenceHold, cost: 7_800_000, resale: 5_900_000, prestige: 21, track: .politics, onBuy: onBuy)
                SignatureMarketCard(name: "Legacy Political Foundation HQ", category: .politicsLegacyEstate, cost: 5_100_000, resale: 3_800_000, prestige: 16, track: .politics, onBuy: onBuy)

            // CE3: Criminal/gray enterprise signature assets — prestige with teeth
            case .crime:
                SignatureMarketCard(name: "Discreet Waterfront Safehouse", category: .crimeSafehouse, cost: 4_200_000, resale: 3_100_000, prestige: 14, track: .crime, onBuy: onBuy)
                SignatureMarketCard(name: "Offshore Holdings Portfolio", category: .crimeOffshoreHoldings, cost: 11_500_000, resale: 9_800_000, prestige: 18, track: .crime, onBuy: onBuy)
                SignatureMarketCard(name: "Quietly Profitable Import Front", category: .crimeFrontBusiness, cost: 2_800_000, resale: 2_100_000, prestige: 11, track: .crime, onBuy: onBuy)
                SignatureMarketCard(name: "Proxy Luxury Penthouse", category: .crimeLuxuryFront, cost: 6_900_000, resale: 4_900_000, prestige: 17, track: .crime, onBuy: onBuy)

            default:
                EmptyView()
            }
        }
    }
}

private struct SignatureMarketCard: View {
    let name: String
    let category: SignatureAssetCategory
    let cost: Int
    let resale: Int
    let prestige: Int
    let track: SpecialCareerTrack
    let onBuy: (SignatureAsset) -> Void

    var body: some View {
        Button {
            let asset = SignatureAsset(
                name: name,
                category: category,
                cost: cost,
                resaleValue: resale,
                monthlyMaintenance: cost / 120,
                prestigeBonus: prestige,
                associatedTrack: track
            )
            onBuy(asset)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                    .lineLimit(2)
                    .frame(width: 140, alignment: .leading)

                Text("$\(cost / 1_000_000)M")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)

                Text("+ \(prestige) Prestige")
                    .font(.caption2)
                    .foregroundStyle(.purple)
            }
            .padding(8)
            .background(Color.black.opacity(0.05))
            .cornerRadius(6)
            .frame(width: 150)
        }
        .buttonStyle(.plain)
    }
}

private struct PropertyUpgradeCard: View {
    let upgrade: HouseUpgrade
    let onUpgrade: (HouseUpgrade) -> Void

    var body: some View {
        Button {
            onUpgrade(upgrade)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(upgrade.rawValue.capitalized)
                    .font(.caption.weight(.bold))
                Text("$\(upgrade.cost)")
                    .font(.caption2)
                Text("+\(upgrade.valueBoost) Value")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
            }
            .frame(width: 110, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct JewelryRow: View {
    let item: Jewelry
    let onSell: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.subheadline.weight(.bold))
                Text("\(item.type.rawValue.capitalized) • Resale: $\(item.resaleValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                onSell()
            } label: {
                Text("SELL")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

// Very aggressive QoL: Reusable visual asset category badge
private struct AssetCategoryIcon: View {
    let count: Int
    let label: String
    let symbol: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(count > 0 ? Color.purple.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(count > 0 ? Color.purple : .gray)
            }
            
            Text("\(count)")
                .font(.caption2.weight(.black))
                .foregroundStyle(count > 0 ? .primary : .secondary)
            
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct JewelryMarketCard: View {
    let name: String
    let type: JewelryType
    let cost: Int
    let resale: Int
    let rarity: FirearmRarity
    let onBuy: (Jewelry) -> Void

    var body: some View {
        Button {
            onBuy(Jewelry(name: name, type: type, rarity: rarity, cost: cost, resaleValue: resale))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                    .foregroundColor(rarityColor(rarity))
                Text("$\(cost)")
                    .font(.caption2)
                Text(rarity.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(rarityColor(rarity))
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func rarityColor(_ rarity: FirearmRarity) -> Color {
        switch rarity {
        case .rare: return .blue
        case .exotic: return .purple
        case .prototype: return .orange
        default: return .primary
        }
    }
}

private struct AviationRow: View {
    let item: AviationAsset
    let onSell: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.subheadline.weight(.bold))
                Text("\(item.type.rawValue.capitalized) • Maint: $\(item.monthlyMaintenance)/mo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                onSell()
            } label: {
                Text("SELL ($\(item.resaleValue))")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

private struct AviationMarketCard: View {
    let name: String
    let type: AviationType
    let cost: Int
    let resale: Int
    let maintenance: Int
    let onBuy: (AviationAsset) -> Void

    var body: some View {
        Button {
            onBuy(AviationAsset(name: name, type: type, cost: cost, resaleValue: resale, monthlyMaintenance: maintenance))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                Text("$\(cost)")
                    .font(.caption2)
                Text("\(type.rawValue.capitalized)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct MarineRow: View {
    let item: MarineAsset
    let onSell: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.subheadline.weight(.bold))
                Text("\(item.type.rawValue.capitalized) • Maint: $\(item.monthlyMaintenance)/mo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                onSell()
            } label: {
                Text("SELL ($\(item.resaleValue))")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

private struct MarineMarketCard: View {
    let name: String
    let type: MarineType
    let cost: Int
    let resale: Int
    let maintenance: Int
    let onBuy: (MarineAsset) -> Void

    var body: some View {
        Button {
            onBuy(MarineAsset(name: name, type: type, cost: cost, resaleValue: resale, monthlyMaintenance: maintenance))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                Text("$\(cost)")
                    .font(.caption2)
                Text("\(type.rawValue.capitalized)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct VehicleRow: View {
    let vehicle: Vehicle
    let onUpgrade: (VehicleUpgrade) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(vehicle.name)
                        .font(.subheadline.weight(.bold))
                    Text(vehicle.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Spd: \(vehicle.totalSpeed) / Hnd: \(vehicle.totalHandling)")
                        .font(.caption.monospacedDigit())
                    if vehicle.totalSafety > 0 {
                        Text("Safety: +\(vehicle.totalSafety)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }

            if !vehicle.upgrades.isEmpty {
                Text("Mods: " + vehicle.upgrades.map { $0.rawValue.capitalized }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(VehicleUpgrade.allCases, id: \.self) { upgrade in
                        if !vehicle.upgrades.contains(upgrade) {
                            Button {
                                onUpgrade(upgrade)
                            } label: {
                                Text("+ \(upgrade.rawValue.capitalized) ($\(upgrade.cost))")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

private struct VehicleMarketCard: View {
    let name: String
    let type: VehicleType
    let cost: Int
    let speed: Int
    let handling: Int
    let onBuy: (Vehicle, Int) -> Void

    var body: some View {
        Button {
            onBuy(Vehicle(name: name, type: type, isLegal: true, baseSpeed: speed, baseHandling: handling), cost)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                Text("$\(cost)")
                    .font(.caption2)
                Text("\(type.rawValue.capitalized)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct FirearmRow: View {
    let firearm: Firearm
    let onUpgrade: (WeaponUpgrade) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Text(firearm.name)
                            .font(.subheadline.weight(.bold))
                        if firearm.rarity != .common {
                            Text(firearm.rarity.rawValue.uppercased())
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(rarityColor(firearm.rarity))
                                .foregroundColor(.white)
                                .cornerRadius(2)
                        }
                    }
                    Text("\(firearm.type.rawValue.capitalized) • \(firearm.isCurrentlyIllicit ? "ILLICIT" : "Legal")")
                        .font(.caption)
                        .foregroundColor(firearm.isCurrentlyIllicit ? .red : .secondary)
                }
                Spacer()
                Text("Pwr: \(firearm.totalPower) / Rel: \(firearm.totalReliability)")
                    .font(.caption.monospacedDigit())
            }

            if !firearm.upgrades.isEmpty {
                Text("Mods: " + firearm.upgrades.map { $0.rawValue.capitalized }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WeaponUpgrade.allCases, id: \.self) { upgrade in
                        if !firearm.upgrades.contains(upgrade) {
                            Button {
                                onUpgrade(upgrade)
                            } label: {
                                HStack(spacing: 4) {
                                    Text("+ \(upgrade.rawValue.capitalized) ($\(upgrade.cost))")
                                    if upgrade.isIllicit {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 8))
                                    }
                                }
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(upgrade.isIllicit ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                                .foregroundColor(upgrade.isIllicit ? .red : .accentColor)
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private func rarityColor(_ rarity: FirearmRarity) -> Color {
        switch rarity {
        case .rare: return .blue
        case .exotic: return .purple
        case .prototype: return .orange
        default: return .gray
        }
    }
}

private struct MarketCard: View {
    let name: String
    let type: FirearmType
    let cost: Int
    let isLegal: Bool
    let power: Int
    let reliability: Int
    var rarity: FirearmRarity = .common
    let onBuy: (Firearm, Int) -> Void

    var body: some View {
        Button {
            onBuy(Firearm(name: name, type: type, isLegal: isLegal, basePower: power, reliability: reliability, rarity: rarity), cost)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.bold))
                    .foregroundColor(rarityColor(rarity))
                Text("$\(cost)")
                    .font(.caption2)
                if !isLegal {
                    Text("ILLICIT")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.red)
                } else if rarity != .common {
                    Text(rarity.rawValue.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(rarityColor(rarity))
                }
            }
            .frame(width: 120, height: 70)
            .padding(8)
            .background(isLegal ? Color.secondary.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func rarityColor(_ rarity: FirearmRarity) -> Color {
        switch rarity {
        case .rare: return .blue
        case .exotic: return .purple
        case .prototype: return .orange
        default: return .primary
        }
    }
}

private struct ActivitiesPlannerTab: View {
    let state: GameState
    let categories: [ActivityCategory]
    let activitiesForCategory: (ActivityCategory) -> [ActivityDefinition]
    let summaryItems: [YearlyOutcomeItem]
    let recentHistory: [HistoryEntry]
    let statusLine: String
    let pushbackSummary: String
    let onPerformActivity: (String) -> Void

    @State private var selectedCategory: ActivityCategory = .mindBody

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Activities",
                symbol: "sparkles",
                status: statusLine,
                tone: state.activities.riskLoad >= 8 ? .warning : (state.activities.recoveryBalance >= 4 ? .positive : .neutral)
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: category.symbol)
                                    Text(category.title)
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(selectedCategory == category ? Color.white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(selectedCategory == category ? Color.black : Color.white.opacity(0.65))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach(activitiesForCategory(selectedCategory)) { activity in
                    Button {
                        onPerformActivity(activity.id)
                    } label: {
                        ActivityRow(activity: activity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("activity-\(activity.id)")
                }
            }
        }
        .accessibilityIdentifier("activities-tab-content")
    }
}

private struct ActivityRow: View {
    let activity: ActivityDefinition

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: activity.category.symbol)
                .foregroundStyle(tone.color)
                .frame(width: 36, height: 36)
                .background(tone.fill)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(activity.costLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 10)
                    Text(activity.risk.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tone.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(tone.fill)
                        .clipShape(Capsule())
                }

                ChipStrip(title: "Effect", items: activity.previewTags, tone: tone, identifier: "activity-\(activity.id)-preview")
            }

            Image(systemName: "plus.circle.fill")
                .foregroundStyle(Color.black)
                .font(.title3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tone.fill, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var tone: PlannerTone {
        switch activity.risk {
        case .grounding:
            return .positive
        case .easy:
            return .neutral
        case .charged, .dangerous:
            return .warning
        }
    }
}

private struct AssetsHousingLegacySection: View {
    let state: GameState
    let openDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlannerSectionCard(
                title: "Housing",
                symbol: "house.fill",
                status: housingStatus,
                tone: housingTone,
                detailTitle: "Details",
                detailIdentifier: "life-housing-detail-button",
                detailAction: { openDetail(.lifeHousing) }
            ) {
                MetricRow(metrics: [
                    ("Setup", housingLabel, housingTone),
                    ("Stability", "\(state.housing.housingStability)", housingTone)
                ])
            }

            PlannerSectionCard(
                title: "Legacy",
                symbol: state.progress.finalLifePath == nil ? "sparkles" : "flag.fill",
                status: legacyStatus,
                tone: .neutral
            ) {
                MetricRow(metrics: [
                    ("Score", "\(state.progress.legacyScore)", .neutral),
                    ("Milestones", "\(state.progress.unlockedMilestones.count)", state.progress.unlockedMilestones.isEmpty ? .warning : .positive)
                ])
            }
            
            // Very aggressive QoL: Lifestyle Score from assets visible in Life tab
            if state.assets.lifestyleScore > 15 {
                PlannerSectionCard(
                    title: "Lifestyle",
                    symbol: "crown.fill",
                    status: state.assets.lifestyleScore > 60 ? "High Society" : (state.assets.lifestyleScore > 35 ? "Comfortable" : "Rising"),
                    tone: state.assets.lifestyleScore > 50 ? .positive : .neutral
                ) {
                    Text("Your assets signal \(state.assets.lifestyleScore) prestige. People notice.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("assets-housing-legacy-section")
    }

    private var housingStatus: String {
        if state.assets.primaryResidence?.status == .delinquent { return "Mortgage under strain" }
        if state.assets.ownsHome { return "Owned home" }
        if state.finance.homeDownPaymentSavings > 0 { return "Saving for a home" }
        if state.housing.livingArrangement == .couchSurfing { return "Housing unstable" }
        if state.housing.housingStability < 40 { return "Housing pressure" }
        return "Housing holding"
    }

    private var housingTone: PlannerTone {
        if state.assets.primaryResidence?.status == .delinquent { return .warning }
        if state.assets.ownsHome { return .positive }
        if state.housing.housingStability < 40 || state.housing.livingArrangement == .couchSurfing { return .warning }
        return .neutral
    }

    private var housingLabel: String {
        switch state.housing.livingArrangement {
        case .familyHome: return "Family Home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Solo Rent"
        case .ownerOccupied: return "Owner Occupied"
        case .couchSurfing: return "Couch Surfing"
        }
    }

    private var legacyStatus: String {
        if let finalPath = state.progress.finalLifePath {
            return LifePathCatalog.profile(for: finalPath).title
        }
        if let currentPath = state.progress.currentLifePath {
            return "Current path: \(LifePathCatalog.profile(for: currentPath).title)"
        }
        return "Legacy still forming"
    }
}

private struct FamilyDetailCard: View {
    let state: GameState
    @State private var showAtHomeDetails = false
    @State private var showAdultDetails = false

    private var compact: Bool {
        state.player.age >= 40 || state.family.children.filter { !$0.livesAtHome }.count > 0
    }

    var body: some View {
        DetailCard(title: "Family", subtitle: state.family.isPregnant ? "Pregnancy active" : "Household load") {
            HStack(spacing: 16) {
                Label("\(state.family.childCount) kids", systemImage: "person.2.fill")
                    .font(.caption.weight(.semibold))
                if state.family.infantCount > 0 {
                    Label("\(state.family.infantCount) infants", systemImage: "baby.fill")
                        .font(.caption.weight(.semibold))
                }
                if state.family.postpartumYearsRemaining > 0 {
                    Label("Postpartum", systemImage: "heart.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
            .foregroundStyle(.secondary)

            if state.family.children.isEmpty {
                Text("No children yet").font(.caption).foregroundStyle(.secondary)
            } else {
                let atHome = state.family.children.filter { $0.livesAtHome }
                let adults = state.family.children.filter { !$0.livesAtHome }

                if !atHome.isEmpty {
                    familyChildSection(
                        title: "At Home",
                        count: atHome.count,
                        expanded: $showAtHomeDetails,
                        compact: compact
                    ) {
                        ForEach(atHome) { child in
                            Text("• \(child.name), age \(child.age)")
                                .font(.caption)
                        }
                    }
                }

                if !adults.isEmpty {
                    familyChildSection(
                        title: "Adult Children",
                        count: adults.count,
                        expanded: $showAdultDetails,
                        compact: compact
                    ) {
                        ForEach(adults) { child in
                            let vibe = child.adultProfile?.lifeVibe
                            let outcome = child.adultProfile?.outcome
                            VStack(alignment: .leading, spacing: 2) {
                                Text("• \(child.name) (\(child.age))")
                                    .font(.caption.weight(.semibold))
                                if let outcome {
                                    Text(outcome.rawValue.capitalized + (vibe.map { " — \($0)" } ?? ""))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(compact ? 2 : 4)
                                }
                            }
                        }
                        if compact {
                            Text("Outcomes grew from how you raised them — tap stories in the journal.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func familyChildSection<Content: View>(
        title: String,
        count: Int,
        expanded: Binding<Bool>,
        compact: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if compact {
                Button {
                    withAnimation { expanded.wrappedValue.toggle() }
                } label: {
                    HStack {
                        Text(title)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                        Text("\(count)")
                            .font(.caption2.weight(.bold))
                        Spacer()
                        Image(systemName: expanded.wrappedValue ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                if expanded.wrappedValue {
                    content()
                } else {
                    Text(summaryLine(title: title, count: count))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(title).font(.caption2.weight(.black)).foregroundStyle(.secondary)
                content()
            }
        }
    }

    private func summaryLine(title: String, count: Int) -> String {
        if title == "Adult Children" {
            return "\(count) adult \(count == 1 ? "child" : "children") — expand for outcomes"
        }
        return "\(count) at home — expand for names"
    }
}

private struct DetailCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct DetailMetricRow: View {
    let items: [(String, String)]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack {
                    Text(item.0)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.1)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct DetailBulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.primary.opacity(0.7))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.footnote)
                }
            }
        }
    }
}

private struct DetailBodyText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

private struct DetailHistoryList: View {
    let entries: [HistoryEntry]

    var body: some View {
        DetailCard(title: "Recent Years", subtitle: entries.isEmpty ? "No history yet" : "\(entries.count) visible entries") {
            if entries.isEmpty {
                DetailBodyText(text: "Your history will fill out as years resolve.")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Age \(entry.age) • \(entry.title)")
                                .font(.subheadline.weight(.semibold))
                            Text(entry.text)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

private func signedCurrency(_ value: Int) -> String {
    value >= 0 ? "+$\(value)" : "-$\(abs(value))"
}

#if DEBUG
struct DebugScenarioLabSheet: View {
    let onLoadScenario: (DebugScenarioID) -> Void
    let onReset: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("QA Scenario Lab")
                        .font(.title2.weight(.bold))

                    Text("These seeded states are debug-only. They preserve the production planner layout while making hidden feature bands directly testable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(DebugScenarioID.allCases) { scenario in
                        Button {
                            onLoadScenario(scenario)
                        } label: {
                            PlannerSectionCard(
                                title: scenario.title,
                                symbol: symbol(for: scenario),
                                status: "Load Scenario",
                                tone: tone(for: scenario)
                            ) {
                                Text(scenario.summary)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("debug-scenario-\(scenario.rawValue)")
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button("Reset to Normal Start") {
                    onReset()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
                .padding()
                .background(.ultraThinMaterial)
                .accessibilityIdentifier("debug-reset-normal-start")
            }
            .navigationTitle("Testing")
            .accessibilityIdentifier("debug-scenario-lab")
        }
    }

    private func tone(for scenario: DebugScenarioID) -> PlannerTone {
        switch scenario {
        case .healthCrisis, .housingDeficitFlow, .specialCareerCrime, .pregnancyYoungFamily, .teenEducationPressure, .yearSummaryPreview:
            return .warning
        case .adultCareerFlow, .specialCareerEntertainment, .partnerCohabitationFlow, .universityTrack, .tradeTrack:
            return .positive
        case .adultEdRebuild, .eventPreview:
            return .neutral
        }
    }

    private func symbol(for scenario: DebugScenarioID) -> String {
        switch scenario {
        case .teenEducationPressure, .universityTrack, .tradeTrack, .adultEdRebuild:
            return "book.closed.fill"
        case .adultCareerFlow:
            return "briefcase.fill"
        case .specialCareerEntertainment:
            return "sparkles"
        case .specialCareerCrime:
            return "flame.fill"
        case .partnerCohabitationFlow, .pregnancyYoungFamily:
            return "person.2.fill"
        case .healthCrisis:
            return "cross.case.fill"
        case .housingDeficitFlow:
            return "house.fill"
        case .eventPreview:
            return "bolt.fill"
        case .yearSummaryPreview:
            return "doc.text.fill"
        }
    }
}
#endif

struct YearSummarySheet: View {
    let summary: YearlyOutcomeSummary?
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if let summary {
                        Text("Age \(summary.age) Review")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        Text("What Changed")
                            .font(.title2.weight(.bold))

                        if let checkpoint = summary.checkpoint {
                            summaryCard(item: checkpoint)
                        }

                        if let yearlyStanceOutcome = summary.yearlyStanceOutcome {
                            summaryCard(item: yearlyStanceOutcome, label: "Year Goal")
                        }

                        if let focusOutcome = summary.focusOutcome {
                            summaryCard(item: focusOutcome, label: "Pattern Outcome")
                        }

                        if let mainTradeoff = summary.mainTradeoff {
                            summaryCard(item: mainTradeoff, label: "Main Tradeoff")
                        }

                        if let nextYearPressure = summary.nextYearPressure {
                            summaryCard(item: nextYearPressure, label: "Still Active")
                        }

                        if let topProblem = summary.topProblem {
                            summaryCard(item: topProblem, label: "Top Problem")
                        }

                        if let topOpportunity = summary.topOpportunity {
                            summaryCard(item: topOpportunity, label: "Top Opportunity")
                        }

                        if let momentum = summary.momentum {
                            summaryCard(item: momentum, label: "Momentum")
                        }

                        if !summary.spillovers.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("What It Touched")
                                    .font(.headline)

                                ForEach(summary.spillovers) { item in
                                    summaryCard(item: item)
                                }
                            }
                        }

                        if !summary.headlines.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Coming Out Of The Year")
                                    .font(.headline)

                                ForEach(summary.headlines) { item in
                                    summaryCard(item: item)
                                }
                            }
                        }
                    } else {
                        Text("No year summary available.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: onContinue) {
                    Label("Continue to Event", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.ultraThinMaterial)
                .accessibilityIdentifier("year-summary-continue-button")
            }
            .navigationTitle("Year Review")
            .accessibilityIdentifier("year-summary-sheet")
        }
    }

    private func summaryCard(item: YearlyOutcomeItem, label: String? = nil) -> some View {
        let tone = PlannerTone(item.tone)
        return VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tone.color)
            Text(item.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EventSheet: View {
    let event: GameEvent?
    let state: GameState
    let onPick: (EventChoice) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let event {
                    Text(event.category.rawValue.capitalized)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)

                    Text(event.title)
                        .font(.title2.weight(.bold))

                    Text(event.displayText(echoing: state))
                        .foregroundStyle(.secondary)

                    Divider()

                    VStack(spacing: 10) {
                        ForEach(Array(event.choices.enumerated()), id: \.element.id) { index, choice in
                            Button {
                                onPick(choice)
                                dismiss()
                            } label: {
                                Text(choice.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("event-choice-\(index)")
                        }
                    }

                    Spacer()
                } else {
                    Text("No event")
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Year Event")
            .accessibilityIdentifier("event-sheet")
        }
    }
}

struct FlowLayout: View {
    var spacing: CGFloat = 8
    var items: [AnyView]

    init<Data: RandomAccessCollection, Content: View>(
        _ data: Data,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.spacing = spacing
        self.items = data.map { AnyView(content($0)) }
    }

    var body: some View {
        // Simplified for this environment to use a wrapping HStack in a scrollview
        // to avoid complex geometry calculations in a single replacement
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(0..<items.count, id: \.self) { index in
                    items[index]
                }
            }
        }
    }
}

// MARK: - Frictionless UI Components

struct PlayerLifeHeader: View {
    @ObservedObject var vm: GameViewModel
    var onOpenFeed: () -> Void
    var onSettings: () -> Void
    @ScaledMetric(relativeTo: .body) private var settingsHit = 44
    @Environment(\.colorScheme) private var colorScheme

    private var occupation: (title: String, symbol: String, tone: PlannerTone) {
        vm.headerOccupationHighlight()
    }

    private var occupationPillColors: (background: Color, foreground: Color) {
        switch occupation.tone {
        case .positive:
            return (DesignSystem.Colors.positive, .white)
        case .warning:
            return (DesignSystem.Colors.warning, .white)
        case .neutral:
            return (Color.accentColor, .white)
        }
    }

    var body: some View {
        let pill = occupationPillColors
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        AppFeedback.impact(.light)
                        onOpenFeed()
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(vm.state.player.name)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .minimumScaleFactor(0.75)
                        .lineLimit(2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("open-life-feed-button")
                    .accessibilityHint("Opens the life feed.")
                    HStack(spacing: 10) {
                        Text("Age \(vm.state.player.age)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            Image(systemName: occupation.symbol)
                                .font(.caption.weight(.bold))
                            Text(occupation.title)
                                .font(.caption.weight(.heavy))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(pill.foreground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(pill.background)
                        .clipShape(Capsule())
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current role")
                        .accessibilityValue(occupation.title)
                    }
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(vm.formattedCashOnHand())
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(vm.state.finance.cashOnHand >= 0 ? DesignSystem.Colors.positive : DesignSystem.Colors.warning)
                        .minimumScaleFactor(0.8)
                    Text("Cash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Button {
                    AppFeedback.impact(.light)
                    onSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: settingsHit, height: settingsHit)
                        .background(OLTheme.subtleFill(colorScheme))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open settings")
                .accessibilityHint("Shows debug tools and save management actions.")
                .accessibilityIdentifier("settings-button")
            }

            if let lifePath = vm.currentLifePathProfile() {
                Label(lifePath.title, systemImage: lifePath.symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(OLTheme.subtleFill(colorScheme))
                    .clipShape(Capsule())
                    .accessibilityLabel("Life path")
                    .accessibilityValue(lifePath.title)
            }

            HStack(spacing: 8) {
                StatMeter(icon: "face.smiling.fill", label: "Happy", value: vm.state.player.happiness, tint: Color(red: 0.95, green: 0.72, blue: 0.18))
                StatMeter(icon: "heart.fill", label: "Health", value: vm.state.player.health, tint: DesignSystem.Colors.positive)
                StatMeter(icon: "brain.head.profile", label: "Smart", value: vm.state.player.smarts, tint: Color(red: 0.28, green: 0.52, blue: 0.95))
                StatMeter(icon: "sparkles", label: "Looks", value: vm.state.player.looks, tint: Color(red: 0.92, green: 0.38, blue: 0.58))
                StatMeter(icon: "star.fill", label: "Rep", value: vm.state.relationships.publicReputation, tint: Color(red: 0.55, green: 0.42, blue: 0.95))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large, style: .continuous)
                .fill(OLTheme.cardFill(colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large, style: .continuous)
                .stroke(OLTheme.cardStroke(colorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(OLTheme.cardShadowOpacity(colorScheme)), radius: 18, x: 0, y: 10)
    }
}

struct StatMeter: View {
    let icon: String
    let label: String
    let value: Int
    let tint: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(label.uppercased())
                .font(.system(size: 7, weight: .heavy))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(tint.opacity(colorScheme == .dark ? 0.22 : 0.2))
                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: max(3, geo.size.width * CGFloat(value) / 100))
                }
            }
            .frame(height: 6)

            Text("\(value)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.92))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(value) out of 100")
    }
}

struct LifeLogView: View {
    let history: [HistoryEntry]
    @State private var searchText: String = ""
    @State private var selectedTag: HistoryDomainTag? = nil

    var filteredHistory: [HistoryEntry] {
        history.filter { entry in
            let matchesSearch = searchText.isEmpty || entry.title.localizedCaseInsensitiveContains(searchText) || entry.text.localizedCaseInsensitiveContains(searchText)
            let matchesTag = selectedTag == nil || entry.tags.contains(selectedTag!)
            return matchesSearch && matchesTag
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search your story...", text: $searchText)
                        .font(.subheadline)
                }
                .padding(10)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Tag Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "All", tag: nil)
                        filterChip(title: "Career", tag: .career)
                        filterChip(title: "Education", tag: .education)
                        filterChip(title: "Finance", tag: .finance)
                        filterChip(title: "Health", tag: .health)
                        filterChip(title: "Family", tag: .family)
                        filterChip(title: "Crime", tag: .crime)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)

            if filteredHistory.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: history.isEmpty ? "book.closed.fill" : "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundStyle(.quaternary)
                    Text(history.isEmpty ? "Your story is waiting to be written." : "No entries match your filter.")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 400)
            } else {
                ForEach(filteredHistory) { entry in
                    HStack(alignment: .top, spacing: 16) {
                        Text("\(entry.age)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(.system(size: 15, weight: .bold))
                            Text(entry.text)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    Text(tag.rawValue.capitalized)
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.primary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)

                    Divider()
                        .padding(.leading, 66)
                }
            }
        }
        .background(Color.white.opacity(0.05))
    }

    private func filterChip(title: String, tag: HistoryDomainTag?) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTag = tag
            }
        } label: {
            Text(title)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTag == tag ? Color.primary : Color.primary.opacity(0.1))
                .foregroundStyle(selectedTag == tag ? (Color.primary == .black ? .white : .black) : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
struct ActivityCategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

#if DEBUG
private struct PreviewLifeHeaderShell: View {
    let scenario: DebugScenarioID
    let scheme: ColorScheme
    @StateObject private var vm: GameViewModel

    init(scenario: DebugScenarioID, scheme: ColorScheme) {
        self.scenario = scenario
        self.scheme = scheme
        let suiteName = "onelife.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let persistence = PersistenceCoordinator(directoryProvider: { dir })
        _vm = StateObject(
            wrappedValue: GameViewModel(
                persistence: persistence,
                defaults: defaults,
                debugConfiguration: DebugTestingConfiguration(scenarioID: scenario, modal: .none)
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PlayerLifeHeader(vm: vm, onOpenFeed: {}, onSettings: {})

                FeedHomeTab(
                    state: vm.state,
                    signals: [
                        SignalSummary(symbol: "dollarsign.circle.fill", title: "Cash Flow", value: "Stable", tone: .neutral),
                        SignalSummary(symbol: "heart.fill", title: "Health", value: "Stable", tone: .positive),
                        SignalSummary(symbol: "briefcase.fill", title: "Career", value: "Full-time", tone: .neutral)
                    ],
                    summaryItems: [],
                    urgencyItems: vm.feedUrgencyItems(),
                    nextDecisionTitle: vm.nextDecisionPrompt(),
                    nextDecisionDetail: vm.nextDecisionDetail(),
                    queuedInteractionCount: vm.interactionQueueDepth,
                    nowStatus: vm.chapterStatus(),
                    pendingActionStatus: vm.pendingActionStatus(),
                    pendingActionSummary: vm.pendingActionSummary(),
                    comingUpItems: vm.comingUpItemsForFeed(),
                    recentHistory: Array(vm.historyDigest.all.prefix(3))
                )
            }
            .padding()
        }
        #if canImport(UIKit)
        .background(Color(uiColor: UIColor.secondarySystemGroupedBackground))
        #else
        .background(Color.gray.opacity(0.12))
        #endif
        .preferredColorScheme(scheme)
    }
}

struct LegacySelectionView: View {
    @ObservedObject var vm: GameViewModel

    private var summary: LifeSummarySnapshot {
        LifeSummarySystem().build(from: vm.state)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(summary.headline)
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .multilineTextAlignment(.center)
                    Text("Age \(vm.state.player.age)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    Text(summary.closingLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 14) {
                    Text("The Life")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)

                    Text(summary.relationshipLine)
                    Text(summary.reputationLine)
                        .foregroundStyle(.secondary)

                    HStack {
                        legacyMetric("Path", summary.lifePathTitle)
                        Spacer()
                        legacyMetric("Legacy", "\(summary.legacyScore)")
                        Spacer()
                        legacyMetric("Next Life", "+\(summary.legacyPointsEarned)")
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                legacyList(title: "What Lasted", items: summary.achievements, symbol: "sparkles", color: .green)
                legacyList(title: "What Stayed Unfinished", items: summary.regrets, symbol: "ellipsis.circle.fill", color: .orange)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Estate & Heritage")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Wealth")
                                .font(.caption.bold())
                            Text("$\(vm.state.finance.totalWealth)")
                                .font(.title3.bold())
                        }
                        Spacer()
                        if vm.state.assets.ownsHome {
                            VStack(alignment: .trailing) {
                                Text("Property")
                                    .font(.caption.bold())
                                Text(vm.state.assets.primaryResidence?.homeValue ?? 0 > 0 ? "Bequeathed" : "None")
                                    .font(.title3.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(vm.state.family.children.isEmpty ? "What Comes Next" : "Choose Your Successor")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    
                    ForEach(vm.state.family.children) { child in
                        Button {
                            withAnimation {
                                vm.switchToChild(child)
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(child.name)
                                        .font(.headline.bold())
                                    Text("Age \(child.age) · \(child.temperament.rawValue.capitalized)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        vm.finishLegacyWithoutSuccessor()
                    } label: {
                        Text(vm.state.family.children.isEmpty ? "Begin Another Life" : "Start a New Family")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            vm.clearPopupStateIfNeeded()
        }
    }

    private func legacyMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
        }
    }

    private func legacyList(title: String, items: [String], symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Label(item, systemImage: symbol)
                    .font(.subheadline)
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

#Preview("Life Shell · Light") {
    PreviewLifeHeaderShell(scenario: .adultCareerFlow, scheme: .light)
}

#Preview("Life Shell · Dark") {
    PreviewLifeHeaderShell(scenario: .adultCareerFlow, scheme: .dark)
}

#Preview("Life Shell · Teen School") {
    PreviewLifeHeaderShell(scenario: .teenEducationPressure, scheme: .light)
}
#endif
