import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

final class GameViewModel: ObservableObject {
    private enum RuntimeOverrideKeys {
        static let testSaveDirectory = "ONELIFE_TEST_SAVE_DIR"
        static let testDefaultsSuite = "ONELIFE_TEST_DEFAULTS_SUITE"
        static let disableOpeningEvent = "ONELIFE_DISABLE_OPENING_EVENT"
        static let syncPersistenceLoad = "ONELIFE_SYNC_PERSISTENCE_LOAD"
        static let syncPersistenceSave = "ONELIFE_SYNC_PERSISTENCE_SAVE"
    }

    private enum PreferenceKeys {
        static let hapticsSetting = "onelife.hapticsSetting"
        static let animationSetting = "onelife.animationSetting"
        static let colorEmphasisSetting = "onelife.colorEmphasisSetting"
        static let domainShortcutPins = "onelife.domainShortcutPins"
    }

    static let maxDomainShortcutPins = 4

    enum Tab: String, CaseIterable, Identifiable {
        case home, occupation, assets, relationships, activities, history

        /// Primary BitLife-style dock — domain glance tabs + instant Activities hub.
        static let dockTabs: [Tab] = [.home, .occupation, .assets, .relationships, .activities]

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home: return "Life"
            case .occupation: return "Work"
            case .assets: return "Money"
            case .relationships: return "Social"
            case .activities: return "Play"
            case .history: return "Journal"
            }
        }

        var symbol: String {
            switch self {
            case .home: return "figure.stand"
            case .occupation: return "briefcase.fill"
            case .assets: return "dollarsign.circle.fill"
            case .relationships: return "heart.fill"
            case .activities: return "sparkles"
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
            case .activities: return "activities-tab"
            case .history: return "history-tab"
            }
        }
    }

    struct InstantHubItem: Identifiable, Equatable {
        enum Kind: Equatable {
            case activity(String)
            case quickAction(domain: ActionDomain, choiceID: ActionChoiceID)
        }

        let id: String
        let title: String
        let subtitle: String
        let icon: String
        let tone: PlannerTone
        let kind: Kind
        let isLuxury: Bool
    }

    struct InstantHubSection: Identifiable, Equatable {
        let id: String
        let title: String
        let symbol: String
        let items: [InstantHubItem]
        let isLuxury: Bool
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
        case .activities:
            return "Play"
        case .history:
            return "Log"
        }
    }

    @Published private(set) var state: GameState
    @Published var metaState: MetaState
    @Published var originPreview: GameState?
    @Published var latestYearSummary: YearlyOutcomeSummary?
    @Published var presentedCard: InteractionCardPayload?
    /// Isolated overlay/toast state — observe via `chrome` in views to limit SwiftUI invalidation.
    let chrome = GameSessionChromeState()
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
    @Published var showingDomainShortcutEditor: Bool = false
    @Published var domainShortcutPins: [DomainShortcutPin] = []
    /// Domain sub-navigation (Assets sub-tabs, Careers sub-tabs, etc.)
    @Published var consoleNavigation = ConsoleNavigationState()
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

    func clearInstantReactions() {
        recentInstantReactions = []
        momentumStripSnapshot = buildMomentumStripSnapshot()
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

        chrome.appendFloatingDeltas(newDeltas)

        // Staggered auto-removal for nicer feel
        let removalDelay = 2.4
        let deltaIDs = Set(newDeltas.map(\.id))
        DispatchQueue.main.asyncAfter(deadline: .now() + removalDelay) { [weak self] in
            self?.chrome.removeFloatingDeltas(withIDs: deltaIDs)
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
        chrome.appendFloatingDeltas(newDeltas)
        AppFeedback.impact(.medium)
        let deltaIDs = Set(newDeltas.map(\.id))
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.chrome.removeFloatingDeltas(withIDs: deltaIDs)
        }
    }

    @Published var persistenceAlert: PersistenceAlertContext?
    @Published var showingDebugLab: Bool = false
    @Published var plannerDetail: PlannerDetailDestination?
    @Published var selectedInsight: ChangeInsightTopic?
    @Published private(set) var originTab: Tab?
    @Published private(set) var originPlannerDetail: PlannerDetailDestination?
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
        LifeShapeResolver.label(from: state)
    }

    @Published var colorEmphasisSetting: ColorEmphasisSetting {
        didSet {
            defaults.set(colorEmphasisSetting.rawValue, forKey: PreferenceKeys.colorEmphasisSetting)
        }
    }
    @Published private(set) var historyDigest: HistoryDigest = .empty
    @Published private(set) var lastTimingSnapshot: SimulationTimingSnapshot?
    @Published private(set) var consoleSnapshot: LifeConsoleSnapshot = .empty
    @Published private(set) var momentumStripSnapshot: MomentumStripSnapshot = .empty
    @Published private(set) var nowLaneSnapshotCache: NowLaneSnapshot = .empty
    @Published private(set) var cachedAdultChildrenGlance: [FamilyChildGlanceItem] = []
    @Published private(set) var cachedFamilyHouseholdSnapshot: FamilyHouseholdSnapshot = .empty
    @Published private(set) var cachedAtHomeChildrenGlance: [FamilyAtHomeGlanceItem] = []
    @Published private(set) var cachedConsolePresentation: ConsolePresentationSnapshot = .empty
    private let orchestrator = LifeSimulationOrchestrator()
    private let activitySystem = ActivitySystem()
    private let persistence: PersistenceCoordinator
    private let defaults: UserDefaults
    private let debugTestingCoordinator = DebugTestingCoordinator()
    private var interactionCards = InteractionCardCoordinator()
    private let feedbackCoordinator = FeedbackCoordinator()
    private var saveStatusTask: Task<Void, Never>?
    private var activityPulseTask: Task<Void, Never>?
    private var didHydrateRuntimeCaches = false
    private var persistenceLoadTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var saveDebounceTask: Task<Void, Never>?
    private var pendingSaveState: GameState?
    private var pendingSaveMeta: MetaState?
    private static let quickActionSaveDebounceNanoseconds: UInt64 = 400_000_000
    private var lastChangeInsightSummaryAge: Int?
    private var lastDerivedStateFingerprint: UInt64 = 0
    private var lastPresentationFingerprint: UInt64 = 0
    private var deferredHeavyConsoleRefreshPending = false

    private static var shouldLoadPersistenceSynchronously: Bool {
        ProcessInfo.processInfo.environment[RuntimeOverrideKeys.testSaveDirectory] != nil
            || ProcessInfo.processInfo.environment[RuntimeOverrideKeys.syncPersistenceLoad] == "1"
    }

    private static var shouldSavePersistenceSynchronously: Bool {
        shouldLoadPersistenceSynchronously
            || ProcessInfo.processInfo.environment[RuntimeOverrideKeys.syncPersistenceSave] == "1"
    }

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
        let initStart = CFAbsoluteTimeGetCurrent()
        self.persistence = persistence
        self.defaults = defaults
        self.hapticsSetting = FeedbackIntensitySetting(rawValue: defaults.string(forKey: PreferenceKeys.hapticsSetting) ?? "") ?? .full
        self.animationSetting = FeedbackIntensitySetting(rawValue: defaults.string(forKey: PreferenceKeys.animationSetting) ?? "") ?? .full
        self.colorEmphasisSetting = ColorEmphasisSetting(rawValue: defaults.string(forKey: PreferenceKeys.colorEmphasisSetting) ?? "") ?? .full
        self.domainShortcutPins = Self.loadDomainShortcutPins(from: defaults)
        self.metaState = MetaState()
        self.state = GameState()

        if let scenarioID = debugConfiguration.scenarioID {
            self.metaState = persistence.loadMeta()
            applyDebugPayload(
                debugTestingCoordinator.payload(for: scenarioID),
                scenarioID: scenarioID,
                modal: debugConfiguration.modal,
                shouldSave: true
            )
        } else if persistence.prefersSynchronousStartupLoad || Self.shouldLoadPersistenceSynchronously {
            self.metaState = persistence.loadMeta()
            applyPersistenceStartupResult(persistence.loadForStartup())
        } else if persistence.hasPersistedSave() {
            beginAsyncPersistenceStartup()
        } else {
            self.metaState = persistence.loadMeta()
            charCreationStep = .name
        }

        RuntimePerformanceMonitor.shared.record(
            .viewModelInit,
            durationMilliseconds: ((CFAbsoluteTimeGetCurrent() - initStart) * 1_000).rounded()
        )
    }

    deinit {
        persistenceLoadTask?.cancel()
        saveDebounceTask?.cancel()
        saveTask?.cancel()
    }

    /// Test hook: waits for debounced + in-flight async saves to finish.
    func flushPendingSave() async {
        cancelSaveDebounce()
        if pendingSaveState != nil {
            beginSaveTaskIfNeeded()
        }
        while saveTask != nil {
            await Task.yield()
        }
    }

    #if DEBUG
    var isSaveDebounceActive: Bool { saveDebounceTask != nil }
    #endif

    func handleMemoryPressure() {
        orchestrator.dropTransientCachesForMemoryPressure()
        chrome.removeFloatingDeltas(withIDs: Set(chrome.floatingDeltas.map(\.id)))
        chrome.autonomyToasts.removeAll()
        recentInstantReactions.removeAll()
    }

    /// Path 2C: decode save off the main thread; paint loading shell first when a save exists.
    private func beginAsyncPersistenceStartup() {
        if persistence.hasPersistedSave() {
            chrome.setLoadingPersistedGame(true)
            let coordinator = persistence
            persistenceLoadTask = Task { @MainActor in
                let payload = await Task.detached(priority: .userInitiated) {
                    let startup = coordinator.loadForStartup()
                    let meta = coordinator.loadMeta()
                    return (startup, meta)
                }.value
                guard !Task.isCancelled else { return }
                metaState = payload.1
                chrome.setLoadingPersistedGame(false)
                applyPersistenceStartupResult(payload.0)
            }
        } else {
            charCreationStep = .name
        }
    }

    private func applyPersistenceStartupResult(_ startup: PersistenceStartupResult) {
        switch startup {
        case .loaded(let result):
            state = result.state
            lastTimingSnapshot = result.timingSnapshot
            RuntimePerformanceMonitor.shared.record(
                .persistenceLoad,
                durationMilliseconds: result.timingSnapshot.loadMilliseconds,
                detail: result.recoveryResult.rawValue
            )
            persistenceBanner = result.recoveryResult.userMessage
            configureStartupStateForLoadedGame()
            if state.startupState == .active {
                hydrateRuntimeCachesIfNeeded()
            }
            refreshDerivedState()
        case .noSave:
            charCreationStep = .name
        case .failed(let primaryError, let errors, let timingSnapshot):
            charCreationStep = .name
            lastTimingSnapshot = timingSnapshot
            persistenceAlert = PersistenceAlertContext(
                title: "Couldn't Recover Saved Progress",
                message: persistenceMessage(for: primaryError, fallbacks: errors)
            )
        }
    }

    func setupFreshGameIfNeeded() {
        // Creation uses CharacterCreationViewModel draft only until explicit commit.
    }

    /// Path 2: Defer domain-cache hydration until after first frame (loaded saves).
    func hydrateRuntimeCachesIfNeeded() {
        guard !didHydrateRuntimeCaches, state.startupState == .active else { return }
        didHydrateRuntimeCaches = true
        orchestrator.hydrateRuntimeCaches(for: state)
    }

    func newLife() {
        // Reset to lightweight character creation immediately (avoid blocking launch with heavy beginLife work).
        didHydrateRuntimeCaches = false
        state = GameState()
        originPreview = nil
        autoLifePace = .guided
        selectedStartMode = .quickStart
        selectedTemplate = .stableHomeAverageMeans
        charCreationStep = .name
        pendingCharName = ""
        pendingRegionID = "mountain_standard"
        pendingTraitOverride = nil
        selectedResilience = .resilient
        latestYearSummary = nil
        presentedCard = nil
        interactionCards.reset()
        chrome.setActivityPulse(nil)
        chrome.isResolvingInteraction = false
        chrome.resolvingInteractionContext = nil
        selectedTab = .home
        plannerDetail = nil
        selectedInsight = nil
        originTab = nil
        originPlannerDetail = nil
        returnPrompt = nil
        persistenceBanner = nil
        chrome.isStartingNewLife = false
        clearPopupStateIfNeeded()
        // Heavy work (activatePreview, caches, etc.) will happen when user finishes creation via beginLifeSafely()
    }

    // Ensure loading flag is cleared on any full reset path
    func resetStartingLifeFlag() {
        chrome.isStartingNewLife = false
    }

    func ageUp() {
        guard !state.isGameOver else { return }
        hydrateRuntimeCachesIfNeeded()
        if autoLifePace == .autopilot {
            runAutopilot()
            return
        }
        chrome.setActivityPulse(nil)
        autopilotYearsAdvanced = 0
        captureReturnOrigin()
        AppFeedback.impact(.medium)
        applyGuidedPlanIfNeeded()

        if state.discoverability.shouldShowFirstQuickActionTeach() {
            markFirstQuickActionTeachSeen()
        }

        let hadVisibleMomentum = state.instantMomentum.isVisible
        if hadVisibleMomentum {
            state.lastYearInstantMomentumCarry = InstantMomentumCarrySnapshot(from: state.instantMomentum, age: state.player.age)
        }

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
        refreshDerivedStateAfterCardTransition()
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
        markFirstLongPressTeachSeen()
    }

    func markFirstLongPressTeachSeen() {
        guard !state.discoverability.seenFirstLongPressTeach else { return }
        state.discoverability.markFirstLongPressTeachSeen()
        markMVPOnboardingHoldBeatIfNeeded()
        chrome.setActivityPulse(ActivityPulse(
            title: "Preview Unlocked",
            detail: DiscoverabilityTeaching.longPressDiscoveryPulseDetail,
            tone: .positive
        ))
        showTransientActivityPulse()
        save()
    }

    func markFirstQuickActionTeachSeen() {
        guard !state.discoverability.seenFirstQuickActionTeach else { return }
        state.discoverability.markFirstQuickActionTeachSeen()
        save()
    }

    func markMomentumCoachSeen() {
        markFirstMomentumAgeUpTeachSeen()
    }

    func markFirstMomentumAgeUpTeachSeen() {
        guard !state.discoverability.seenFirstMomentumAgeUpTeach else { return }
        state.discoverability.markFirstMomentumAgeUpTeachSeen()
        save()
    }

    func markInstantMomentumYearSummarySeen() {
        guard !state.discoverability.seenInstantMomentumYearSummary else { return }
        state.discoverability.markInstantMomentumYearSummarySeen()
        state.lastYearInstantMomentumCarry = nil
        save()
    }

    func shouldAutoExpandMomentumHint() -> Bool {
        state.discoverability.shouldAutoExpandMomentumHint(momentumVisible: state.instantMomentum.isVisible)
    }

    func markMomentumStripIntroSeen() {
        guard !state.discoverability.seenMomentumStripIntro else { return }
        state.discoverability.markMomentumStripIntroSeen()
        momentumStripSnapshot = buildMomentumStripSnapshot()
        lastDerivedStateFingerprint = derivedStateFingerprint()
        save()
    }

    func markLifeShapeTeachSeen() {
        guard !state.discoverability.seenLifeShapeTeach else { return }
        state.discoverability.markLifeShapeTeachSeen()
        momentumStripSnapshot = buildMomentumStripSnapshot()
        lastDerivedStateFingerprint = derivedStateFingerprint()
        save()
    }

    func markDossierStanceCoachSeen() {
        guard !state.discoverability.seenDossierStanceCoach else { return }
        state.discoverability.markDossierStanceCoachSeen()
        save()
    }

    func markFirstAgeUpReflectionSeen() {
        guard !state.discoverability.seenFirstAgeUpReflection else { return }
        state.discoverability.markFirstAgeUpReflectionSeen()
        save()
    }

    func pendingDiscoverabilityCoachLine() -> String? {
        state.discoverability.pendingCoachLine(
            age: state.player.age,
            momentumVisible: state.instantMomentum.isVisible,
            lifeShapeNonEmpty: !currentLifeShape.isEmpty,
            earlyDossierActive: state.childhoodDossier != nil
        )
    }

    func firstQuickActionTeachLine() -> String? {
        guard state.discoverability.shouldShowFirstQuickActionTeach() else { return nil }
        return DiscoverabilityTeaching.firstQuickActionLine(resilience: state.resilience)
    }

    func shouldShowMomentumAgeUpTeach() -> Bool {
        state.instantMomentum.isVisible && !state.discoverability.seenFirstMomentumAgeUpTeach
    }

    func instantMomentumCarrySummaryLine() -> String? {
        guard !state.discoverability.seenInstantMomentumYearSummary,
              let carry = state.lastYearInstantMomentumCarry,
              carry.overallStrength >= 12 else { return nil }
        return DiscoverabilityTeaching.instantMomentumCarryLine(snapshot: carry, resilience: state.resilience)
    }

    var hasHarshConsolePressure: Bool {
        lifeConsoleSnapshot().topPressures.contains(where: { $0.tone == .warning })
            || feedUrgencyItems(limit: 4).contains(where: { $0.tone == .warning })
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

    func markFamilyHouseholdBannerSeen() {
        guard state.discoverability.pendingFamilyHouseholdBanner != nil else { return }
        state.discoverability.clearFamilyHouseholdBanner()
        refreshDerivedState()
        save()
    }

    func markFirstParentingActionCoachSeen() {
        guard !state.discoverability.seenFirstParentingActionCoach else { return }
        state.discoverability.markFirstParentingActionCoachSeen()
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
        chrome.setActivityPulse(ActivityPulse(
            title: fightingBack.title,
            detail: fightingBack.detail,
            tone: tone
        ))
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
        case .legal:
            return .protectHealth
        case .military:
            return .pushCareer
        case .family:
            return .repairPeople
        case .identity:
            return .stabilizeMoney
        case .play:
            return .protectHealth
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
        guard !chrome.isResolvingInteraction else { return }

        // Immediately signal processing so the popup UI can swap to loading/spinner (preventing "frozen on the popup" visual).
        // The actual (heavy) work is deferred via Task.yield so SwiftUI can commit the loading state first.
        chrome.isResolvingInteraction = true
        chrome.resolvingInteractionContext = ev.title
        let feedback = feedbackCoordinator.actionResponse(for: choice.baseFriction, microBeat: choice.microBeat)
        guard !feedback.shouldReturnEarly else {
            chrome.isResolvingInteraction = false
            chrome.resolvingInteractionContext = nil
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
                refreshDerivedStateAfterCardTransition()
                save()
            } else {
                orchestrator.apply(choice: choice, event: ev, state: &state)
                advancePresentedCard()
                orchestrator.syncActiveYearChapterProgress(state: &state, nextCard: presentedCard)
                refreshDerivedStateAfterCardTransition()
                save()
            }
            chrome.isResolvingInteraction = false
            chrome.resolvingInteractionContext = nil
        }
    }

    private func applyGuidedPlanIfNeeded() {
        guard autoLifePace == .guided else { return }
        // Guided mode recommends the next move, but waits for the player to confirm it.
    }

    private func runAutopilot(maxYears: Int = 8) {
        guard !state.isGameOver, presentedCard == nil, state.activeYearChapter == nil else { return }
        chrome.setActivityPulse(nil)
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
            refreshDerivedState(deferHeavyPanels: true)

            if shouldStopAutopilot(before: before, outcome: outcome) {
                present(cards: outcome.cards)
                refreshDerivedStateAfterCardTransition()
                save()
                return
            }
        }

        refreshDerivedState()
        chrome.setActivityPulse(ActivityPulse(
            title: "Autopilot Paused",
            detail: autopilotYearsAdvanced <= 1 ? "One quiet year resolved in the background." : "\(autopilotYearsAdvanced) quiet years resolved in the background.",
            tone: .neutral
        ))
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
        case .event, .reaction, .combatFight, .legalCase, .consequence, .resolution, .crisis, .pitchDeck:
            return true
        case .yearSummary, .forecast:
            return false
        }
    }

    func resolveCrisis(_ choice: CrisisChoice) {
        guard !chrome.isResolvingInteraction else { return }

        chrome.isResolvingInteraction = true
        chrome.resolvingInteractionContext = "crisis resolution"

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
                chrome.microBeatOverlay = "A heavy price paid for time."
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
            refreshDerivedStateAfterCardTransition()
            save()
            clearPopupStateIfNeeded()
            chrome.isResolvingInteraction = false
            chrome.resolvingInteractionContext = nil
        }
    }

    func resolvePitch(_ choice: PitchDeckChoice) {
        guard !chrome.isResolvingInteraction else { return }

        chrome.isResolvingInteraction = true
        chrome.resolvingInteractionContext = "pitch deck"

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
            chrome.microBeatOverlay = "Launched: \(choice.text)"
            
            state.pendingActions.removeAll { $0.choiceID == .startCompany }
            
            // Core of dismiss (bypass guard)
            advancePresentedCard()
            orchestrator.syncActiveYearChapterProgress(state: &state, nextCard: presentedCard)
            if presentedCard == nil {
                restoreInteractionOriginIfNeeded()
            }
            refreshDerivedStateAfterCardTransition()
            save()
            chrome.isResolvingInteraction = false
            chrome.resolvingInteractionContext = nil
        }
    }

    func advancePresentedCard() {
        presentedCard = interactionCards.advance()
        if case .yearSummary = presentedCard {
            recentInstantReactions = []
        }
    }

    func dismissPresentedCard() {
        guard let currentCard = presentedCard else { return }
        guard !chrome.isResolvingInteraction else { return }

        // Immediately signal processing for continue-style popups (summary, resolution, etc.).
        chrome.isResolvingInteraction = true
        chrome.resolvingInteractionContext = (currentCard as? CustomStringConvertible)?.description ?? "year outcome"

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
            refreshDerivedStateAfterCardTransition()
            save()
            clearPopupStateIfNeeded()
            chrome.isResolvingInteraction = false
            chrome.resolvingInteractionContext = nil
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
        case .forecast, .yearSummary, .reaction, .combatFight, .legalCase, .consequence, .resolution:
            return false
        }
    }

    /// Safety net called on shell changes / after heavy work to prevent stuck popups or desynced chapter/card state.
    func clearPopupStateIfNeeded() {
        if chrome.isResolvingInteraction { return } // let the resolving Task finish
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
        chrome.setActivityPulse(nil)
        let initialEvent = orchestrator.activatePreview(state: &preview)
        state = preview
        didHydrateRuntimeCaches = true

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
            let teachingLine = TwoSpeedTeaching.line
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
        guard !chrome.isStartingNewLife else { return }
        chrome.isStartingNewLife = true
        Task { @MainActor in
            await Task.yield()
            beginLife()
            chrome.isStartingNewLife = false
        }
    }

    func beginLifeSafely(from creationDraft: CharacterCreationDraft) {
        guard !chrome.isStartingNewLife else { return }
        chrome.isStartingNewLife = true
        Task { @MainActor in
            await Task.yield()
            commitCharacterCreation(from: creationDraft)
            chrome.isStartingNewLife = false
        }
    }

    func makeCreationPreviewCard(for draft: CharacterCreationDraft) async -> CreationPreviewCard? {
        await Task.yield()
        let preview = buildPreviewState(from: draft)
        return CreationPreviewCard.from(state: preview, draftName: draft.pendingName)
    }

    private func buildPreviewState(from draft: CharacterCreationDraft) -> GameState {
        let templateID = draft.selectedStartMode == .template ? draft.selectedTemplate : nil
        var preview = orchestrator.previewStart(
            mode: draft.selectedStartMode,
            templateID: templateID,
            meta: metaState,
            resilience: draft.selectedResilience
        )

        if draft.selectedStartMode == .custom {
            preview.finance.currentRegionPolicyID = draft.pendingRegionID
        }

        if let trait = draft.pendingTrait {
            var traits = preview.player.traits
            traits.removeAll { $0 == trait }
            traits.insert(trait, at: 0)
            preview.player.traits = Array(traits.prefix(3))
            if let templateID = preview.originProfile?.templateID {
                orchestrator.regenerateDossierInPreview(
                    &preview,
                    templateID: templateID,
                    deterministic: draft.selectedStartMode == .template
                )
            }
        }

        return preview
    }

    func commitCharacterCreation(from draft: CharacterCreationDraft) {
        selectedStartMode = draft.selectedStartMode
        selectedTemplate = draft.selectedTemplate
        selectedResilience = draft.selectedResilience
        pendingCharName = draft.pendingName
        pendingRegionID = draft.pendingRegionID
        pendingTraitOverride = draft.pendingTrait
        charCreationStep = draft.step

        var preview = buildPreviewState(from: draft)

        // Phase 2: Wire starter assets based on background (from overhaul)
        if let bg = draft.selectedBackground {
            applyStarterAssets(to: &preview, for: bg)
        }

        let trimmedName = draft.pendingName.trimmingCharacters(in: .whitespaces)
        preview.player.name = trimmedName.isEmpty ? randomCharacterName() : trimmedName
        preview.finance.currentRegionPolicyID = draft.pendingRegionID

        if draft.selectedStartMode == .custom {
            preview.originProfile?.startMode = .custom
        }
        preview.mvpOnboarding.activate(at: preview.player.age)
        preview.discoverability = DiscoverabilityState()
        preview.softRunGoal = nil
        preview.resilience = draft.selectedResilience
        preview.syncResilienceToPlayer()
        autoLifePace = .guided

        latestYearSummary = nil
        presentedCard = nil
        interactionCards.reset()
        chrome.setActivityPulse(nil)
        let initialEvent = orchestrator.activatePreview(state: &preview)
        state = preview
        didHydrateRuntimeCaches = true
        originPreview = nil

        if state.history.isEmpty || state.history.first?.title != "Life Began" {
            let feelLine = state.resilience == .resilient
                ? "Chose a Resilient path — more room to recover when life gets heavy."
                : "Chose the Grounded path — full Life Killer weight, no safety nets."
            state.history.insert(
                HistoryEntry(age: state.player.age, title: "Life Began", text: feelLine, tags: [.progress]),
                at: 0
            )
        }

        if state.history.count <= 1 {
            let teachingLine = TwoSpeedTeaching.line
            state.history.insert(
                HistoryEntry(age: state.player.age, title: "How This Life Works", text: teachingLine, tags: [.progress]),
                at: 0
            )
        }

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

    // Phase 2: Apply starter assets from background (ties creation to assets per overhaul plan)
    private func applyStarterAssets(to preview: inout GameState, for bg: Background) {
        let starters = CharacterCreationViewModel().generateStarterAssets(for: bg)
        for type in starters {
            switch type {
            case "used_car", "old_bike", "reliable_truck", "beat_up_car", "work_truck":
                let vehicle = Vehicle(
                    name: type.replacingOccurrences(of: "_", with: " ").capitalized,
                    type: .sedan,
                    isLegal: true,
                    baseSpeed: 60,
                    baseHandling: 50
                )
                preview.assets.vehicles.append(vehicle)
            case "small_investment_portfolio", "family_savings", "basic_savings":
                preview.finance.cashOnHand += 2000
            case "laptop", "books_collection", "family_heirloom", "military_memento", "street_gear", "tools_set":
                let jewelry = Jewelry(
                    name: type.replacingOccurrences(of: "_", with: " ").capitalized,
                    type: .pendant,
                    rarity: .common,
                    cost: 500,
                    resaleValue: 300
                )
                preview.assets.jewelry.append(jewelry)
            default:
                preview.finance.cashOnHand += 500
            }
        }
        if !starters.isEmpty {
            preview.history.insert(
                HistoryEntry(age: preview.player.age, title: "Starter Assets", text: "Received from background: \(starters.joined(separator: ", ")). Maintain them to preserve value.", tags: [.finance]),
                at: 0
            )
        }
    }

    func save() {
        cancelSaveDebounce()
        stageSaveSnapshot()
        beginSaveTaskIfNeeded()
    }

    /// Tier C: Coalesce disk writes during rapid instant/quick-action chains.
    /// UI caches still refresh immediately via `refreshDerivedState()`.
    func scheduleDebouncedSave() {
        if Self.shouldSavePersistenceSynchronously {
            save()
            return
        }
        stageSaveSnapshot()
        saveDebounceTask?.cancel()
        saveDebounceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                if !Task.isCancelled {
                    self.saveDebounceTask = nil
                }
            }
            do {
                try await Task.sleep(nanoseconds: Self.quickActionSaveDebounceNanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self.beginSaveTaskIfNeeded()
        }
    }

    private func cancelSaveDebounce() {
        saveDebounceTask?.cancel()
        saveDebounceTask = nil
    }

    private func stageSaveSnapshot() {
        pendingSaveState = state
        pendingSaveMeta = metaState
    }

    private func beginSaveTaskIfNeeded() {
        guard saveTask == nil else { return }
        saveTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.saveTask = nil }
            while self.pendingSaveState != nil {
                await self.performSaveNow()
            }
        }
    }

    private func shouldSaveSynchronously() -> Bool {
        Self.shouldSavePersistenceSynchronously || persistence.prefersSynchronousStartupLoad
    }

    private func performSaveNow() async {
        guard let snapshot = pendingSaveState else { return }
        let metaSnapshot = pendingSaveMeta ?? metaState
        pendingSaveState = nil
        pendingSaveMeta = nil
        let coordinator = persistence
        let saveStart = CFAbsoluteTimeGetCurrent()

        do {
            let persistenceResult: PersistenceSaveResult
            if shouldSaveSynchronously() {
                try? coordinator.saveMeta(metaSnapshot)
                persistenceResult = try coordinator.save(snapshot)
            } else {
                persistenceResult = try await Task.detached(priority: .utility) {
                    try? coordinator.saveMeta(metaSnapshot)
                    return try coordinator.save(snapshot)
                }.value
            }

            let saveMilliseconds = ((CFAbsoluteTimeGetCurrent() - saveStart) * 1_000).rounded()
            RuntimePerformanceMonitor.shared.record(.persistenceSave, durationMilliseconds: saveMilliseconds)
            #if DEBUG
            var timing = orchestrator.latestTimingSnapshot ?? lastTimingSnapshot ?? SimulationTimingSnapshot()
            timing.saveMilliseconds = saveMilliseconds
            timing.persistedHistoryCount = persistenceResult.timingSnapshot.persistedHistoryCount
            timing.persistedSaveBytes = persistenceResult.timingSnapshot.persistedSaveBytes
            timing.loadErrorCount = persistenceResult.timingSnapshot.loadErrorCount
            timing.persistenceRecoverySource = persistenceResult.timingSnapshot.persistenceRecoverySource
            timing.restoredFromBackup = persistenceResult.timingSnapshot.restoredFromBackup
            if !persistenceResult.timingSnapshot.entries.isEmpty {
                timing.entries = persistenceResult.timingSnapshot.entries
            }
            lastTimingSnapshot = timing
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
            let diamondTracks: Set<SpecialCareerTrack> = [.movieProducer, .recordLabelOwner, .sportsOwner, .shadowOperative, .trader, .ventureCapitalist, .corporateRaider, .fightEmpire]
            let isDiamond = diamondTracks.contains(state.specialCareer.track)
            return (pair.title, pair.symbol, isDiamond ? .positive : .warning)  // CT1-2 + criminal-diamond: Diamond (incl. enterprise) gets prestige tone
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
        case .activities:
            matchedDomains = [.health, .finance, .progress]
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
        let heavyFame = state.fame.culturalFame >= 55 || state.fame.notoriety >= 50
        let heavyLuxury = state.assets.lifestyleScore >= 60 || state.finance.totalWealth >= 5_000_000
        return prefersBitLifeShell
            || state.player.age >= 40
            || (state.player.age >= 32 && (heavyFamily || heavyCareer || heavyFame || heavyLuxury))
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
        if state.fame.culturalFame >= 45 {
            parts.append("Fame \(state.fame.culturalFame)")
        }
        if state.assets.lifestyleScore >= 55 {
            parts.append("Lifestyle \(state.assets.lifestyleScore)")
        }
        if let loud = feedUrgencyItems(limit: 3).first(where: { $0.tone == .warning }) {
            parts.append(loud.title)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    func recognitionGlanceItem() -> RecognitionGlanceItem? {
        let publicIdentity = PublicIdentitySystem().snapshot(for: state)
        let fame = state.fame
        guard publicIdentity.score >= 40 || fame.recognition >= 40 || fame.culturalFame >= 45 || fame.notoriety >= 45 else { return nil }

        let subtitle = fame.knownFor.first ?? publicIdentity.consequences.first ?? publicIdentity.detail

        return RecognitionGlanceItem(
            label: publicIdentity.label,
            score: publicIdentity.score,
            subtitle: subtitle,
            tone: publicIdentity.tone,
            destination: .lifeLegacy
        )
    }

    func collectionGlanceItem() -> CollectionGlanceItem? {
        guard let identity = AssetCatalog.collectionIdentity(from: state.assets) else { return nil }

        let tone: PlannerTone
        if identity.completedSets.count >= 2 {
            tone = .positive
        } else if identity.lifestyleScore >= 60 {
            tone = .positive
        } else {
            tone = .neutral
        }

        return CollectionGlanceItem(
            label: identity.label,
            score: identity.lifestyleScore,
            subtitle: identity.subtitle,
            tone: tone,
            completedSetCount: identity.completedSets.count
        )
    }

    func openAssetsPlanner(subTab: AssetsSubTab = .overview) {
        consoleNavigation.assetsSubTab = subTab
        selectedTab = .assets
    }

    func openCareersPlanner(subTab: CareersSubTab = .overview) {
        consoleNavigation.careersSubTab = subTab
        selectedTab = .occupation
    }

    /// Life escape hatch + dock selection. Re-tapping Life resets sub-navigation.
    func selectDockTab(_ tab: Tab) {
        if tab == .home {
            if selectedTab == .home {
                consoleNavigation.resetToRoot()
                AppFeedback.impact(.medium)
            } else {
                consoleNavigation.resetToRoot()
                AppFeedback.impact(.light)
            }
        } else {
            AppFeedback.impact(.light)
        }
        showingHealthConsole = false
        selectedTab = tab
    }

    /// Console/debug navigation commands. See Docs/NAVIGATION-AND-TAB-PATTERN.md
    @discardableResult
    func handleConsoleNavigationCommand(_ raw: String) -> String? {
        guard var command = ConsoleNavigationCoordinator.parse(command: raw) else { return nil }
        command.apply(to: &consoleNavigation)
        if let targetTab = command.targetTab {
            selectedTab = targetTab
            showingHealthConsole = false
        }
        return command.message
    }

    func compactPressureItems(limit: Int = 3) -> [PlannerInsight] {
        Array(feedUrgencyItems().prefix(limit))
    }

    func secondaryPressureItems(after: Int = 3, limit: Int? = nil) -> [PlannerInsight] {
        let items = Array(feedUrgencyItems().dropFirst(after))
        if let limit {
            return Array(items.prefix(limit))
        }
        return items
    }

    /// Top pressures/states for the 2-second audit — warnings first, icon-ready.
    func glanceAuditChips(limit: Int = 3) -> [GlanceAuditChip] {
        var chips = feedUrgencyItems()
            .map { item in
                GlanceAuditChip(
                    id: item.title,
                    icon: glanceIcon(forPressureTitle: item.title),
                    title: item.title,
                    value: item.value,
                    tone: item.tone
                )
            }

        let recognition = recognitionGlanceItem()
        if recognition == nil,
           state.fame.culturalFame >= 50,
           !chips.contains(where: { $0.id == "Fame" }) {
            chips.append(GlanceAuditChip(
                id: "Fame",
                icon: "star.fill",
                title: "Fame",
                value: "\(state.fame.culturalFame)",
                tone: state.fame.notoriety >= 60 ? .warning : .positive
            ))
        }
        if state.assets.lifestyleScore >= 55,
           collectionGlanceItem() == nil,
           !chips.contains(where: { $0.id == "Lifestyle" }) {
            chips.append(GlanceAuditChip(
                id: "Lifestyle",
                icon: "crown.fill",
                title: "Lifestyle",
                value: "\(state.assets.effectiveLifestyleScore)",
                tone: .positive
            ))
        }

        let ranked = chips.sorted { lhs, rhs in
            let lw = lhs.tone == .warning ? 0 : (lhs.tone == .positive ? 2 : 1)
            let rw = rhs.tone == .warning ? 0 : (rhs.tone == .positive ? 2 : 1)
            return lw < rw
        }
        return Array(ranked.prefix(limit))
    }

    func glanceIcon(forPressureTitle title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("money") || lower.contains("finance") { return "dollarsign.circle.fill" }
        if lower.contains("work") || lower.contains("school") || lower.contains("career") { return "briefcase.fill" }
        if lower.contains("social") || lower.contains("relationship") { return "person.2.fill" }
        if lower.contains("burnout") || lower.contains("health") || lower.contains("mental") { return "heart.fill" }
        if lower.contains("military") { return "shield.fill" }
        if lower.contains("fame") { return "star.fill" }
        if lower.contains("lifestyle") { return "crown.fill" }
        return "exclamationmark.triangle.fill"
    }

    func adultChildrenGlanceItems(limit: Int = 3) -> [FamilyChildGlanceItem] {
        Array(cachedAdultChildrenGlance.prefix(limit))
    }

    func adultChildrenCompactSummary(limit: Int = 3) -> AdultChildrenCompactSummary {
        let preview = Array(cachedAdultChildrenGlance.prefix(limit))
        let overflow = max(0, cachedAdultChildrenGlance.count - preview.count)
        let summary: String?
        if cachedAdultChildrenGlance.isEmpty {
            summary = nil
        } else if overflow > 0 {
            summary = "\(cachedAdultChildrenGlance.count) grown · \(overflow) more"
        } else {
            summary = "\(cachedAdultChildrenGlance.count) grown"
        }
        return AdultChildrenCompactSummary(
            previewItems: preview,
            overflowCount: overflow,
            summaryLine: summary
        )
    }

    func atHomeChildrenGlanceItems(limit: Int = 2) -> [FamilyAtHomeGlanceItem] {
        Array(cachedAtHomeChildrenGlance.prefix(limit))
    }

    func atHomeChildrenGlanceOverflow(beyond limit: Int = 2) -> Int {
        max(0, state.family.children.filter(\.livesAtHome).count - limit)
    }

    func shouldShowFamilyTraySubtitle() -> Bool {
        guard state.family.childCount > 0 else { return false }
        if !state.discoverability.seenFirstParentingActionCoach { return true }
        let youngestAtHome = state.family.children.filter(\.livesAtHome).map(\.age).min() ?? 99
        return youngestAtHome < 12
    }

    private func rebuildAdultChildrenGlanceCache(limit: Int = 8) {
        cachedAdultChildrenGlance = state.family.children
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
                let profile = child.adultProfile
                let story = profile?.keyStories.last ?? profile?.lifeVibe ?? ""
                let sinceAge = child.leftHomeAtAge.map { "since age \($0)" } ?? "since childhood"
                let continuity = "\(child.temperament.shortDescription.capitalized) \(sinceAge)"
                return FamilyChildGlanceItem(
                    id: child.id.uuidString,
                    name: child.name,
                    age: child.age,
                    outcomeLabel: label,
                    temperament: child.temperament.shortDescription,
                    bond: child.bondWithPlayer,
                    continuityHint: continuity,
                    storyTease: story,
                    relationshipQuality: profile?.relationshipQuality ?? child.bondWithPlayer
                )
            }
    }

    private func rebuildAtHomeChildrenGlanceCache(limit: Int = 4) {
        cachedAtHomeChildrenGlance = state.family.children
            .filter(\.livesAtHome)
            .sorted { $0.age < $1.age }
            .prefix(limit)
            .map { child in
                FamilyAtHomeGlanceItem(
                    id: child.id.uuidString,
                    name: child.name,
                    age: child.age,
                    temperament: child.temperament.shortDescription,
                    bond: child.bondWithPlayer,
                    vibeLine: child.currentVibe
                )
            }
    }

    func adultChildrenFocusChip(for domain: ConsoleDomain) -> String? {
        guard domain == .people, !state.discoverability.seenAdultChildrenCoach else { return nil }
        let adults = state.family.children.filter { !$0.livesAtHome }
        guard !adults.isEmpty else { return nil }
        return DiscoverabilityTeaching.adultChildTransitionLine
    }

    private func rebuildConsolePresentationCache() {
        var panels: [ConsoleDomain: DomainPanelModel] = [:]
        for domain in ConsoleDomain.allCases {
            panels[domain] = buildDomainPanel(for: domain)
        }
        let atHomeCount = state.family.children.filter(\.livesAtHome).count
        cachedConsolePresentation = ConsolePresentationSnapshot(
            panels: panels,
            familyGlance: ConsoleFamilyGlancePresentation(
                household: cachedFamilyHouseholdSnapshot,
                atHomeItems: Array(cachedAtHomeChildrenGlance.prefix(2)),
                atHomeOverflow: max(0, atHomeCount - 2),
                adultChildrenFull: cachedAdultChildrenGlance,
                adultChildrenCompact: adultChildrenCompactSummary(limit: 3),
                showFamilyTraySubtitle: shouldShowFamilyTraySubtitle(),
                showHouseholdStrip: state.family.childCount > 0
            ),
            teach: ConsoleTeachSnapshot(
                showHoldHint: state.discoverability.shouldShowHoldHint(),
                seenFirstLongPressTeach: state.discoverability.seenFirstLongPressTeach,
                firstQuickActionTeachLine: firstQuickActionTeachLine(),
                adultChildrenFocusChip: adultChildrenFocusChip(for: .people)
            ),
            auditRibbon: ConsoleAuditRibbonSnapshot(
                chips: glanceAuditChips(limit: 3),
                momentumVisible: state.instantMomentum.isVisible,
                momentumStrength: state.instantMomentum.overallStrength,
                showCulturalFame: false,
                culturalFame: state.fame.culturalFame
            ),
            recognitionGlance: recognitionGlanceItem(),
            collectionGlance: collectionGlanceItem()
        )
    }

    private func rebuildFamilyHouseholdSnapshotCache() {
        cachedFamilyHouseholdSnapshot = FamilyHouseholdSnapshot.build(
            from: state.family,
            bannerLine: state.discoverability.pendingFamilyHouseholdBanner
        )
    }

    // MARK: - Tier A: Now lane, soft goals, cast, autonomy toasts

    func nowLaneSnapshot() -> NowLaneSnapshot {
        if presentedCard != nil {
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
            seenHoldCoach: state.discoverability.seenFirstLongPressTeach,
            hasYearStance: state.yearlyStance.selectedStance != nil,
            momentumVisible: state.instantMomentum.isVisible,
            lifeShapeNonEmpty: !currentLifeShape.isEmpty
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

        if let coach = pendingDiscoverabilityCoachLine() {
            let chip = homeQuickActionChips().first
            return NowLaneSnapshot(
                headline: "Coach",
                detail: coach,
                quickActionTitle: chip.map { ActionChoiceCatalog.definition(for: $0.choiceID).title },
                quickActionDomain: chip?.domain,
                quickActionChoice: chip?.choiceID,
                ageUpHint: "Tap Got it on the momentum strip, or keep playing.",
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
        case .legal: return .legal
        case .family: return .family
        case .identity: return .progress
        case .play: return .progress
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
        chrome.autonomyToasts.insert(toast, at: 0)
        if chrome.autonomyToasts.count > 2 {
            chrome.autonomyToasts = Array(chrome.autonomyToasts.prefix(2))
        }
        let toastID = toast.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
            self?.chrome.autonomyToasts.removeAll { $0.id == toastID }
        }
    }

    func surfaceAutonomySignalsFromLedger() {
        let npc = state.correlationLedger.recentSignals(kind: .npcAutonomyPulse, minStrength: 5).first
        let world = state.correlationLedger.recentSignals(kind: .worldAutonomyPulse, minStrength: 5).first
        if npc != nil {
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

        if state.legal.stage != .inactive {
            let value: String
            switch state.legal.stage {
            case .investigation: value = "Investigation open"
            case .charged, .awaitingResolution: value = "Case awaiting resolution"
            case .custody: value = "\(state.legal.yearsRemaining) years remaining"
            case .supervision: value = "\(state.legal.supervisionYearsRemaining) years supervision"
            case .released: value = state.legal.recordPressure > 0 ? "Record pressure \(state.legal.recordPressure)" : "Released"
            case .inactive: value = "Clear"
            }
            items.append(PlannerInsight(title: "Legal Status", value: value, tone: state.legal.stage == .released ? .neutral : .warning))
        }
        
        if state.military.track != .inactive {
            if state.military.contractYearsRemaining <= 1 {
                items.append(PlannerInsight(title: "Military", value: "Contract Ending", tone: .warning))
            }
            if state.military.combatTrauma > 50 {
                items.append(PlannerInsight(title: "Mental Health", value: "Trauma High", tone: .warning))
            }
        }

        if state.relationships.careLoad.isActive {
            items.append(PlannerInsight(
                title: "Care Load",
                value: state.relationships.careLoad.topLine,
                tone: state.relationships.careLoad.totalIntensity >= 45 ? .warning : .neutral
            ))
        }

        if state.healthProfile.bodyLoad.totalLoad >= 35 {
            items.append(PlannerInsight(
                title: "Body Load",
                value: state.healthProfile.bodyLoad.summaryLine,
                tone: state.healthProfile.bodyLoad.totalLoad >= 65 ? .warning : .neutral
            ))
        }
        
        let ranked = items.sorted { lhs, rhs in
            let lw = lhs.tone == .warning ? 0 : (lhs.tone == .positive ? 2 : 1)
            let rw = rhs.tone == .warning ? 0 : (rhs.tone == .positive ? 2 : 1)
            if lw != rw { return lw < rw }
            return lhs.title < rhs.title
        }
        if let limit {
            return Array(ranked.prefix(limit))
        }
        return ranked
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
        
        // P2-3: D4 / momentum context in previews (discoverability micro-pass)
        let domain = inferredPreviewDomain(for: choiceID)
        let contextLines = DiscoverabilityTeaching.previewContextLines(
            choiceID: choiceID,
            domain: domain,
            state: state
        )
        for line in contextLines where !previews.contains(line) {
            previews.append(line)
        }

        // CT1-3: Diamond tier preview callout for activation actions
        if [.startMovieProducer, .startRecordLabel, .startSportsOwnership].contains(choiceID) {
            previews.append("Diamond Tier: Requires peak Special performance + significant capital + strong dossier fit. This is empire building, not a job.")
        }
        if choiceID == .startCoachingCareer {
            previews.append("Special Tier: Peak athlete or college coaching cred + program capital. Build a legacy on the sideline.")
        }

        if choiceID == .flexLuxuryAsset, let line = AssetCatalog.flexPreviewLine(for: state.assets) {
            previews.append(line)
        }
        
        return previews
    }

    private func inferredPreviewDomain(for choiceID: ActionChoiceID) -> ActionDomain {
        let tags = ActionChoiceCatalog.definition(for: choiceID).preferredEventTags
        let top = tags.max { $0.value < $1.value }
        switch top?.key {
        case "health": return .health
        case "money", "finance": return .finance
        case "social", "family", "relationships": return .relationships
        case "school", "education": return .education
        case "crime", "risk": return .crime
        default: return .career
        }
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
            chrome.setActivityPulse(ActivityPulse(title: "Year Goal Set", detail: "\(stance.title) will let the year resolve with less player steering.", tone: .neutral))
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
            case .combatFight(let summary):
                return "\(summary.result) by \(summary.method)"
            case .legalCase(let summary):
                return summary.title
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
            case .combatFight(let summary):
                return "\(summary.record) · \(summary.rankingText) · Purse $\(summary.purse)"
            case .legalCase(let summary):
                return "\(summary.disposition) · \(summary.consequence)"
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
        case "Care Load":
            return .relationshipsFamily
        case "Body Load":
            return .healthOverview
        case "Legal Status":
            return .lifeLegacy
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
        performQuickAction(choiceID, for: domain)
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
        var lines = orchestrator.previewInstantAction(choiceID, domain: domain, state: state)
        for line in DiscoverabilityTeaching.previewContextLines(choiceID: choiceID, domain: domain, state: state)
            where !lines.contains(line) {
            lines.append(line)
        }
        return lines
    }

    private static let parentingChoiceIDs: Set<ActionChoiceID> = [
        .spendTimeWithKids, .checkInOnChild, .enforceRoutine, .encourageIndependence
    ]

    // Phase 2: Make random spawn fully functional end-to-end in console/debug
    func createRandomCharacter() {
        let character = Character.generateRandom()
        print("Random character created: \(character.name) from \(character.background.displayName) with assets \(character.startingAssets)")

        var draft = CharacterCreationDraft()
        draft.pendingName = character.name
        draft.selectedBackground = character.background
        draft.isRandomSpawn = true
        draft.selectedStartMode = .quickStart

        commitCharacterCreation(from: draft)

        // Ensure starters
        if !character.startingAssets.isEmpty {
            applyStarterAssets(to: &state, for: character.background)
        }

        let _ = orchestrator.activatePreview(state: &state)
        refreshDerivedState()
        save()
        print("Random spawn complete, state set with name \(state.player.name)")
    }

    func performQuickAction(_ choiceID: ActionChoiceID, for domain: ActionDomain) {
        guard !state.isGameOver, presentedCard == nil, state.activeYearChapter == nil else { return }
        let action = PlayerYearAction(domain: domain, choiceID: choiceID)
        let definition = ActionChoiceCatalog.definition(for: choiceID)

        if let reason = quickActionBlockReason(choiceID, domain: domain) {
            AppFeedback.notify(.warning)
            chrome.setActivityPulse(ActivityPulse(title: "Quick Action Blocked", detail: reason, tone: .warning))
            showTransientActivityPulse()
            return
        }

        state.quickActionMemory.record(action, age: state.player.age)
        if !state.discoverability.performedFirstQuickAction {
            state.discoverability.performedFirstQuickAction = true
            markMVPOnboardingQuickBeatIfNeeded()
        }

        var focusChildID: UUID?
        var bondBefore = 0
        var devNotesBefore = 0
        if Self.parentingChoiceIDs.contains(choiceID),
           let child = FamilyHouseholdSnapshot.focusChildForParenting(in: state.family) {
            focusChildID = child.id
            bondBefore = child.bondWithPlayer
            devNotesBefore = child.developmentNotes.count
        }

        let result = orchestrator.applyInstantActionWithAutonomousReaction(choiceID, domain: domain, state: &state)
        surfaceInstantActionFeedback(
            result: result,
            domain: domain,
            fallbackTitle: QuickActionCatalog.title(for: choiceID),
            fallbackDetail: result.notes.first?.text ?? definition.identityLine
        )

        if Self.parentingChoiceIDs.contains(choiceID) {
            surfaceParentingActionFeedback(
                focusChildID: focusChildID,
                bondBefore: bondBefore,
                devNotesBefore: devNotesBefore
            )
            if !state.discoverability.seenFirstParentingActionCoach {
                state.discoverability.pendingFamilyHouseholdBanner = DiscoverabilityTeaching.firstParentingActionLine
            }
        }

        orchestrator.applyAmbientPressureSync(state: &state)
        refreshDerivedState()
        scheduleDebouncedSave()
    }

    private func surfaceParentingActionFeedback(
        focusChildID: UUID?,
        bondBefore: Int,
        devNotesBefore: Int
    ) {
        guard let focusChildID,
              let index = state.family.children.firstIndex(where: { $0.id == focusChildID }) else { return }
        let child = state.family.children[index]
        let delta = child.bondWithPlayer - bondBefore
        if delta != 0 {
            let tempNote = child.temperament == .sensitive || child.temperament == .intense
                ? "\(child.temperament.shortDescription) kids feel presence fast"
                : "bond carries into their adult story"
            pushAutonomyToast(
                title: "\(child.name)'s bond \(delta > 0 ? "+" : "")\(delta)",
                detail: tempNote,
                tone: delta > 0 ? .positive : .warning
            )
        }
        if child.developmentNotes.count > devNotesBefore, let note = child.developmentNotes.last {
            pushAutonomyToast(title: "\(child.name)", detail: note, tone: .neutral)
        }
    }

    private func performInstantAction(_ choiceID: ActionChoiceID, for domain: ActionDomain) {
        let definition = ActionChoiceCatalog.definition(for: choiceID)
        if definition.baseFriction == .locked {
            let feedback = feedbackCoordinator.actionResponse(for: .locked, microBeat: definition.microBeat)
            guard !feedback.shouldReturnEarly else { return }
            applyFeedback(feedback)
            return
        }

        let result = orchestrator.applyInstantActionWithAutonomousReaction(choiceID, domain: domain, state: &state)
        surfaceInstantActionFeedback(
            result: result,
            domain: domain,
            fallbackTitle: "Action Complete",
            fallbackDetail: result.notes.first?.text ?? definition.identityLine
        )

        orchestrator.applyAmbientPressureSync(state: &state)

        refreshDerivedState()
        scheduleDebouncedSave()
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

        chrome.setActivityPulse(ActivityPulse(
            title: "Year Stance Set",
            detail: "\(definition.title) will shape the next yearly pulse.",
            tone: .positive
        ))
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

        chrome.setActivityPulse(ActivityPulse(
            title: resolution.headline,
            detail: detail,
            tone: PlannerTone(resolution.tone)
        ))
        showTransientActivityPulse()
        refreshDerivedState()
        scheduleDebouncedSave()
    }

    /// BitLife-style instant hub: all flex/quick actions grouped for the Play tab.
    func instantHubSections() -> [InstantHubSection] {
        var sections: [InstantHubSection] = []
        let luxuryIDs: Set<ActionChoiceID> = [
            .hostLuxuryEvent, .acquireLuxuryAsset, .indulgeInExcess, .displayWealth, .maintainLuxuryCollection,
            .flexLuxuryAsset, .liquidateLuxury, .upgradeCollection, .hostAtSignatureEstate
        ]

        if showsLuxurySuite {
            let luxuryItems = luxurySuiteActions().map { action in
                InstantHubItem(
                    id: "luxury-\(action.choiceID.rawValue)",
                    title: action.title,
                    subtitle: "Elite flex",
                    icon: action.icon,
                    tone: .positive,
                    kind: .quickAction(domain: .finance, choiceID: action.choiceID),
                    isLuxury: true
                )
            }
            if !luxuryItems.isEmpty {
                sections.append(InstantHubSection(id: "luxury", title: "Luxury Suite", symbol: "crown.fill", items: luxuryItems, isLuxury: true))
            }
        }

        var selfCare: [InstantHubItem] = []
        for category in activityCategories() {
            for activity in activities(in: category) {
                selfCare.append(InstantHubItem(
                    id: "activity-\(activity.id)",
                    title: activity.title,
                    subtitle: activity.costLine,
                    icon: category.symbol,
                    tone: activity.risk == .grounding ? .positive : (activity.risk == .dangerous ? .warning : .neutral),
                    kind: .activity(activity.id),
                    isLuxury: false
                ))
            }
        }
        if !selfCare.isEmpty {
            sections.append(InstantHubSection(id: "self-care", title: "Self-Care", symbol: "leaf.fill", items: selfCare, isLuxury: false))
        }

        let domainLanes: [(ActionDomain, String, String)] = [
            (.play, "Play", "sparkles"),
            (.identity, "Self", "person.fill"),
            (.health, "Body", "heart.fill"),
            (.relationships, "Love", "person.2.fill"),
            (.finance, "Money", "dollarsign.circle.fill"),
            (.career, "Work", "briefcase.fill"),
            (.education, "School", "book.closed.fill"),
            (.family, "Family", "figure.2.and.child.holdinghands"),
            (.military, "Duty", "shield.fill"),
            (.crime, "Risk", "exclamationmark.shield.fill")
        ]

        for (domain, title, symbol) in domainLanes {
            let choices = quickActionChoices(for: domain).filter { !luxuryIDs.contains($0) }
            guard !choices.isEmpty else { continue }
            let items = choices.map { choiceID in
                let definition = ActionChoiceCatalog.definition(for: choiceID)
                return InstantHubItem(
                    id: "\(domain.rawValue)-\(choiceID.rawValue)",
                    title: QuickActionCatalog.title(for: choiceID),
                    subtitle: definition.subtitle,
                    icon: instantHubIcon(for: choiceID, domain: domain),
                    tone: definition.baseFriction == .warning ? .warning : .neutral,
                    kind: .quickAction(domain: domain, choiceID: choiceID),
                    isLuxury: false
                )
            }
            sections.append(InstantHubSection(id: domain.rawValue, title: title, symbol: symbol, items: items, isLuxury: false))
        }

        return sections
    }

    func performInstantHubItem(_ item: InstantHubItem) {
        switch item.kind {
        case .activity(let id):
            performActivity(id)
        case .quickAction(let domain, let choiceID):
            performQuickAction(choiceID, for: domain)
        }
    }

    private func instantHubIcon(for choiceID: ActionChoiceID, domain: ActionDomain) -> String {
        switch domain {
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .relationships: return "person.2.fill"
        case .career: return "briefcase.fill"
        case .education: return "book.closed.fill"
        case .family: return "figure.2.and.child.holdinghands"
        case .military: return "shield.fill"
        case .crime: return "exclamationmark.triangle.fill"
        case .legal: return "building.columns.fill"
        case .identity: return "person.fill"
        case .play: return "sparkles"
        }
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
        chrome.appendFloatingDeltas([FloatingDelta(text: "+\(vehicle.name)", tone: .positive, domain: .finance)])
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
        chrome.appendFloatingDeltas([FloatingDelta(text: "Home Upgraded", tone: .positive, domain: .finance)])
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

    // MARK: - Domain bar shortcuts

    private static func loadDomainShortcutPins(from defaults: UserDefaults) -> [DomainShortcutPin] {
        guard let data = defaults.data(forKey: PreferenceKeys.domainShortcutPins),
              let decoded = try? JSONDecoder().decode([DomainShortcutPin].self, from: data) else {
            return []
        }
        return decoded
    }

    private func persistDomainShortcutPins() {
        guard let data = try? JSONEncoder().encode(domainShortcutPins) else { return }
        defaults.set(data, forKey: PreferenceKeys.domainShortcutPins)
    }

    func addDomainShortcut(_ pin: DomainShortcutPin) {
        guard domainShortcutPins.count < Self.maxDomainShortcutPins else { return }
        guard !domainShortcutPins.contains(where: { $0.target == pin.target }) else { return }
        domainShortcutPins.append(pin)
        persistDomainShortcutPins()
    }

    func removeDomainShortcut(id: String) {
        domainShortcutPins.removeAll { $0.id == id }
        persistDomainShortcutPins()
    }

    func canAddDomainShortcut(_ pin: DomainShortcutPin) -> Bool {
        domainShortcutPins.count < Self.maxDomainShortcutPins
            && !domainShortcutPins.contains(where: { $0.target == pin.target })
    }

    func executeDomainShortcut(_ pin: DomainShortcutPin, onOpenJournal: () -> Void) {
        AppFeedback.impact(.light)
        switch pin.target {
        case .tab(let raw):
            showingHealthConsole = false
            if let tab = Tab(rawValue: raw) {
                selectedTab = tab
            }
        case .special(let id):
            switch id {
            case "health":
                showingHealthConsole = false
                selectedTab = .activities
            case "housing":
                showingHealthConsole = false
                selectedTab = .assets
            case "journal":
                onOpenJournal()
            default:
                break
            }
        case .quickAction(let domainRaw, let choiceIDRaw):
            guard let domain = ActionDomain(rawValue: domainRaw),
                  let choiceID = ActionChoiceID(rawValue: choiceIDRaw) else { return }
            performQuickAction(choiceID, for: domain)
        }
    }

    func domainShortcutCandidates() -> [DomainShortcutPin] {
        var candidates: [DomainShortcutPin] = []

        func appendUnique(_ pin: DomainShortcutPin) {
            guard canAddDomainShortcut(pin) else { return }
            guard !candidates.contains(where: { $0.target == pin.target }) else { return }
            candidates.append(pin)
        }

        appendUnique(DomainShortcutPin(id: DomainShortcutPin.stableID(for: .special(id: "health")), title: "Play", symbol: "sparkles", target: .special(id: "health")))
        appendUnique(DomainShortcutPin(id: DomainShortcutPin.stableID(for: .special(id: "housing")), title: "Housing", symbol: "house.fill", target: .special(id: "housing")))
        appendUnique(DomainShortcutPin(id: DomainShortcutPin.stableID(for: .special(id: "journal")), title: "Journal", symbol: "book.closed.fill", target: .special(id: "journal")))

        for tab in Tab.dockTabs {
            let target = DomainShortcutPin.Target.tab(raw: tab.rawValue)
            appendUnique(DomainShortcutPin(
                id: DomainShortcutPin.stableID(for: target),
                title: dockLabel(for: tab),
                symbol: dockSymbol(for: tab),
                target: target
            ))
        }

        let domainOrder: [ActionDomain] = [.finance, .career, .education, .relationships, .health, .family, .military, .crime, .identity]
        for domain in domainOrder {
            for choiceID in quickActionChoices(for: domain) {
                let target = DomainShortcutPin.Target.quickAction(domainRaw: domain.rawValue, choiceIDRaw: choiceID.rawValue)
                appendUnique(DomainShortcutPin(
                    id: DomainShortcutPin.stableID(for: target),
                    title: QuickActionCatalog.title(for: choiceID),
                    symbol: shortcutSymbol(for: domain, choiceID: choiceID),
                    target: target
                ))
            }
        }

        return candidates
    }

    private func shortcutSymbol(for domain: ActionDomain, choiceID: ActionChoiceID) -> String {
        switch choiceID {
        case .depositToHouseFund, .saveForDownPayment, .buyStarterHome: return "house.fill"
        case .topUpHouseReserve, .buildMaintenanceReserve: return "wrench.and.screwdriver.fill"
        case .workHard, .takeSideWork, .takeOvertime: return "briefcase.fill"
        case .studyConsistently, .joinClub: return "book.closed.fill"
        case .rest, .protectSleep, .seeDoctor: return "heart.fill"
        case .reachOut, .strengthenBond, .repairTension: return "person.2.fill"
        default:
            break
        }
        switch domain {
        case .finance: return "dollarsign.circle.fill"
        case .career, .education: return "briefcase.fill"
        case .relationships, .family: return "person.2.fill"
        case .health: return "heart.fill"
        case .military: return "shield.fill"
        case .crime: return "exclamationmark.triangle.fill"
        case .legal: return "building.columns.fill"
        case .identity: return "person.fill"
        case .play: return "sparkles"
        }
    }

    func buyJewelry(_ item: Jewelry) {
        guard state.finance.cashOnHand >= item.cost else { return }
        
        state.finance.cashOnHand -= item.cost
        state.assets.jewelry.append(item)
        
        // QoL: Distinct feedback for luxury/collectible assets
        AppFeedback.impact(.light)
        chrome.appendFloatingDeltas([FloatingDelta(text: "+\(item.name)", tone: .positive, domain: .finance)])
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
        chrome.appendFloatingDeltas([FloatingDelta(text: "Sold \(item.name)", tone: .neutral, domain: .finance)])
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
        chrome.appendFloatingDeltas([FloatingDelta(text: "+\(item.name)", tone: .positive, domain: .finance)])
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
        chrome.appendFloatingDeltas([FloatingDelta(text: "Sold \(item.name)", tone: .neutral, domain: .finance)])
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
            chrome.appendFloatingDeltas([FloatingDelta(text: delta, tone: .positive, domain: .finance)])
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

    func highSchoolShapeMetrics() -> [(String, String, PlannerTone)] {
        let profile = state.education.highSchoolProfile
        return [
            ("Future", profile.futureSeed.displayLabel, profile.futureSeed == .undecided ? .neutral : .positive),
            ("Belonging", profile.socialShape.displayLabel, highSchoolBelongingTone(profile.socialShape)),
            ("Pressure", profile.pressureShape.displayLabel, highSchoolPressureTone(profile.pressureShape))
        ]
    }

    func highSchoolIdentityForcePreview(limit: Int = 3) -> [(String, String, PlannerTone)] {
        state.education.highSchoolIdentityForces
            .prefix(limit)
            .map { force in
                (force.role.displayLabel, force.name, highSchoolIdentityTone(force.tone))
            }
    }

    func seniorLaunchSummaryItems() -> [String] {
        guard state.education.seniorYearOutcome != .unresolved else { return [] }
        return [
            state.education.seniorYearOutcome.displayLabel,
            state.education.highSchoolProfile.futureSeed.displayLabel,
            state.education.highSchoolProfile.pressureShape.displayLabel
        ]
    }

    private func highSchoolBelongingTone(_ shape: HighSchoolSocialShape) -> PlannerTone {
        switch shape {
        case .connected, .respected: return .positive
        case .isolated, .volatile: return .warning
        case .invisible: return .neutral
        }
    }

    private func highSchoolPressureTone(_ shape: HighSchoolPressureShape) -> PlannerTone {
        switch shape {
        case .balanced: return .positive
        case .burnedOut, .survivalMode, .reckless: return .warning
        }
    }

    private func highSchoolIdentityTone(_ tone: HighSchoolIdentityForceTone) -> PlannerTone {
        switch tone {
        case .supportive: return .positive
        case .tense, .volatile, .demanding: return .warning
        case .neutral: return .neutral
        }
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

    #if DEBUG
    var isHeavyConsoleCacheRefreshDeferred: Bool { deferredHeavyConsoleRefreshPending }
    #endif

    func refreshDerivedStateForTesting() {
        refreshDerivedState()
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
        if case .yearSummary = presentedCard {
            recentInstantReactions = []
        }
        orchestrator.syncActiveYearChapterProgress(state: &state, nextCard: presentedCard)
    }

    private func applyFeedback(_ response: FeedbackCoordinator.Response) {
        if let duration = response.jitterDuration {
            chrome.actionFrictionJitter = true
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { self.chrome.actionFrictionJitter = false }
        }

        guard let microBeat = response.microBeat else { return }
        chrome.microBeatOverlay = microBeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.chrome.microBeatOverlay == microBeat {
                self.chrome.microBeatOverlay = nil
            }
        }
    }

    private func refreshDerivedState(forceInsights: Bool = false, deferHeavyPanels: Bool = false) {
        let fingerprint = derivedStateFingerprint()
        let stateChanged = fingerprint != lastDerivedStateFingerprint
        let shouldDeferHeavy = deferHeavyPanels
            || ((presentedCard != nil || state.activeYearChapter != nil) && !forceInsights)

        if stateChanged {
            lastDerivedStateFingerprint = fingerprint
            if shouldDeferHeavy {
                rebuildEssentialConsoleCaches()
                deferredHeavyConsoleRefreshPending = true
            } else {
                rebuildConsoleDerivedCaches()
            }
        } else if deferredHeavyConsoleRefreshPending && !shouldDeferHeavy {
            rebuildDeferredConsoleCaches()
        }

        let presentationChanged = presentationStateFingerprint() != lastPresentationFingerprint
        if presentationChanged {
            refreshPresentationCaches()
        } else if stateChanged && !shouldDeferHeavy {
            lastPresentationFingerprint = presentationStateFingerprint()
        }

        if forceInsights || stateChanged || latestYearSummary?.age != lastChangeInsightSummaryAge {
            lastChangeInsightSummaryAge = latestYearSummary?.age
            refreshChangeInsights()
        }
        if stateChanged {
            DomainActionRegistry.refreshSuggestedAction(in: &state, isTeenExperience: isTeenExperience)
        }
        #if DEBUG
        lastTimingSnapshot = orchestrator.latestTimingSnapshot ?? lastTimingSnapshot
        #endif
    }

    private func refreshDerivedStateAfterCardTransition() {
        if presentedCard == nil {
            refreshDerivedState()
        } else {
            refreshDerivedState(deferHeavyPanels: true)
        }
    }

    private func refreshPresentationCaches() {
        lastPresentationFingerprint = presentationStateFingerprint()
        nowLaneSnapshotCache = nowLaneSnapshot()
    }

    private func rebuildEssentialConsoleCaches() {
        consoleSnapshot = lifeConsoleSnapshot()
        momentumStripSnapshot = buildMomentumStripSnapshot()
        nowLaneSnapshotCache = nowLaneSnapshot()
        lastPresentationFingerprint = presentationStateFingerprint()
    }

    private func rebuildDeferredConsoleCaches() {
        historyDigest = HistoryDigest(state: state)
        rebuildFamilyHouseholdSnapshotCache()
        rebuildAtHomeChildrenGlanceCache()
        rebuildAdultChildrenGlanceCache()
        rebuildConsolePresentationCache()
        deferredHeavyConsoleRefreshPending = false
    }

    private func rebuildConsoleDerivedCaches() {
        rebuildEssentialConsoleCaches()
        rebuildDeferredConsoleCaches()
    }

    private func buildMomentumStripSnapshot() -> MomentumStripSnapshot {
        let momentum = state.instantMomentum
        let top = momentum.rankedDomainMomentum.first
        let microHint: String? = {
            guard let top, top.value >= 8 else { return nil }
            return DiscoverabilityTeaching.momentumDomainMicroHint(domain: top.domain, value: top.value)
        }()
        return MomentumStripSnapshot(
            showsStrip: !recentInstantReactions.isEmpty || momentum.isVisible,
            momentum: momentum,
            recentReactions: Array(recentInstantReactions.prefix(3)),
            lifeShape: currentLifeShape,
            resilience: state.resilience,
            seenMomentumStripIntro: state.discoverability.seenMomentumStripIntro,
            seenLifeShapeTeach: state.discoverability.seenLifeShapeTeach,
            shouldAutoExpandHint: shouldAutoExpandMomentumHint(),
            topDomainMicroHint: microHint
        )
    }

    private func derivedStateFingerprint() -> UInt64 {
        var hasher = Hasher()
        hasher.combine(state.player.age)
        hasher.combine(state.player.name)
        hasher.combine(state.player.health)
        hasher.combine(state.pendingActions.count)
        hasher.combine(state.career.status)
        hasher.combine(state.career.roleID)
        hasher.combine(state.career.performance)
        hasher.combine(state.finance.cashOnHand)
        hasher.combine(state.finance.financialStress)
        hasher.combine(state.resilience)
        hasher.combine(state.instantMomentum.overallStrength)
        hasher.combine(state.instantMomentum.healthMomentum)
        hasher.combine(state.instantMomentum.financeMomentum)
        hasher.combine(state.instantMomentum.relationshipMomentum)
        hasher.combine(state.discoverability.seenMomentumStripIntro)
        hasher.combine(state.discoverability.seenLifeShapeTeach)
        hasher.combine(state.discoverability.seenAdultChildrenCoach)
        hasher.combine(state.discoverability.pendingFamilyHouseholdBanner)
        hasher.combine(state.family.childCount)
        hasher.combine(state.family.dependentChildCount)
        hasher.combine(state.family.isPregnant)
        hasher.combine(adultChildrenGlanceFingerprint())
        hasher.combine(atHomeChildrenGlanceFingerprint())
        hasher.combine(recentInstantReactions)
        hasher.combine(currentLifeShape)
        hasher.combine(selectedTab)
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }

    private func presentationStateFingerprint() -> UInt64 {
        var hasher = Hasher()
        hasher.combine(presentedCardFingerprint())
        hasher.combine(state.activeYearChapter?.targetAge)
        hasher.combine(state.activeYearChapter?.phase)
        hasher.combine(state.isGameOver)
        hasher.combine(state.softRunGoal?.title)
        hasher.combine(state.softRunGoal?.status)
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }

    private func presentedCardFingerprint() -> String {
        presentedCard?.id ?? "none"
    }

    private func adultChildrenGlanceFingerprint() -> UInt64 {
        var hasher = Hasher()
        for child in state.family.children where !child.livesAtHome {
            hasher.combine(child.id)
            hasher.combine(child.age)
            hasher.combine(child.name)
            hasher.combine(child.adultProfile?.outcome)
            hasher.combine(child.adultProfile?.relationshipQuality)
            hasher.combine(child.bondWithPlayer)
        }
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }

    private func atHomeChildrenGlanceFingerprint() -> UInt64 {
        var hasher = Hasher()
        for child in state.family.children where child.livesAtHome {
            hasher.combine(child.id)
            hasher.combine(child.age)
            hasher.combine(child.bondWithPlayer)
            hasher.combine(child.supportLoad)
        }
        return UInt64(bitPattern: Int64(hasher.finalize()))
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
        chrome.setActivityPulse(nil)
        chrome.isResolvingInteraction = false
        chrome.resolvingInteractionContext = nil
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
        case .legal: return "Legal"
        case .finance: return "Money"
        case .relationships: return "Social"
        case .health: return "Health"
        case .family: return "Family"
        case .identity: return "Identity"
        case .play: return "Play"
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

    private func surfaceInstantActionFeedback(
        result: DomainYearResult,
        domain: ActionDomain,
        fallbackTitle: String,
        fallbackDetail: String
    ) {
        let worldReactionNotes = result.notes.filter { $0.tags.contains(.autonomousReaction) }

        if worldReactionNotes.isEmpty {
            AppFeedback.impact(.light)
        } else {
            AppFeedback.impact(.medium)
            AppFeedback.notify(.success)
        }

        chrome.setActivityPulse(activityPulseFromDomainResult(
            result,
            fallbackTitle: fallbackTitle,
            fallbackDetail: fallbackDetail
        ))

        if !worldReactionNotes.isEmpty, let enhanced = chrome.activityPulse {
            chrome.setActivityPulse(ActivityPulse(title: "Action + World Reaction", detail: enhanced.detail, tone: enhanced.tone))
            if let first = worldReactionNotes.first {
                pushAutonomyToast(title: first.title, detail: first.text, tone: .neutral)
            }

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

        spawnFloatingDeltas(from: result, domain: domain)
        showTransientActivityPulse()
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
        chrome.setSaveStatusBanner("Saved this year")
        saveStatusTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.chrome.setSaveStatusBanner(nil)
        }
    }

    private func showTransientActivityPulse() {
        activityPulseTask?.cancel()
        activityPulseTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            self?.chrome.setActivityPulse(nil)
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
        case .activities:
            return activitiesTabOverview()
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
        case .legal:
            pressure = PressureSummary(
                symbol: "building.columns.fill",
                title: state.legal.isInCustody ? "Custody controls this year" : "Legal case needs a response",
                detail: state.legal.isInCustody
                    ? "Life continued without you — \(state.legal.custodyProfile.facility.displayName), \(state.legal.yearsRemaining) year\(state.legal.yearsRemaining == 1 ? "" : "s") left, \(state.legal.custodyProfile.discretionaryActionsRemaining) meaningful choice\(state.legal.custodyProfile.discretionaryActionsRemaining == 1 ? "" : "s") remain."
                    : state.legal.reentryYearsRemaining > 0
                        ? "Reentry friction: \(state.legal.reentryYearsRemaining) year\(state.legal.reentryYearsRemaining == 1 ? "" : "s") of record pressure and closed doors."
                        : "Evidence is at \(state.legal.evidenceStrength). Your next legal choice will shape the resolution.",
                tone: .warning,
                destination: .careerOverview
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
        case .play:
            pressure = PressureSummary(
                symbol: "sparkles",
                title: "Play & Recovery",
                detail: "Instant hobbies and outings keep the year feeling alive.",
                tone: .positive,
                destination: nil
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
                isTeenExperience ? highSchoolShapeMetrics() : teenSchoolClimateMetrics(),
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
        let hasIllegal = state.assets.firearms.contains { $0.isCurrentlyIllicit }
        let legalExposureActive = state.legal.hasActiveCase
            && state.legal.allegedOffenses.contains(.illegalWeapon)
        let pressure = PressureSummary(
            symbol: hasIllegal ? "exclamationmark.shield.fill" : "bag.fill",
            title: legalExposureActive ? "Weapons case is active" : (hasIllegal ? "Possession is high risk" : "Armory is secure"),
            detail: hasIllegal 
                ? (legalExposureActive
                    ? "Illegal possession is now part of an active case with evidence at \(state.legal.evidenceStrength)."
                    : "Illegal firearms can create a case when criminal heat makes police scrutiny likely.")
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
        if state.legal.hasActiveCase || state.legal.isInCustody {
            return .legal
        }
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
