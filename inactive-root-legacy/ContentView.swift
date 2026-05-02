import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

final class GameViewModel: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case career
        case finance
        case relationships
        case health

        var id: String { rawValue }

        var title: String {
            switch self {
            case .career: return "Career"
            case .finance: return "Finance"
            case .relationships: return "Relationships"
            case .health: return "Health"
            }
        }

        var symbol: String {
            switch self {
            case .career: return "briefcase.fill"
            case .finance: return "dollarsign.circle.fill"
            case .relationships: return "person.2.fill"
            case .health: return "cross.case.fill"
            }
        }
    }

    @Published private(set) var state: GameState
    @Published var originPreview: GameState?
    @Published var currentEvent: GameEvent?
    @Published var showingEvent: Bool = false
    @Published var selectedTab: Tab = .career
    @Published var showingSettings: Bool = false
    @Published var selectedStartMode: StartMode = .quickStart
    @Published var selectedTemplate: OriginTemplateID = .stableHomeAverageMeans
    @Published var persistenceBanner: String?
    @Published var persistenceAlert: PersistenceAlertContext?
    @Published private(set) var historyDigest: HistoryDigest = .empty
    @Published private(set) var lastTimingSnapshot: SimulationTimingSnapshot?

    private let orchestrator = LifeSimulationOrchestrator()
    private let persistence: PersistenceCoordinator

    init(persistence: PersistenceCoordinator = .live) {
        self.persistence = persistence

        switch persistence.loadForStartup() {
        case .loaded(let result):
            self.state = result.state
            self.lastTimingSnapshot = result.timingSnapshot
            self.persistenceBanner = result.recoveryResult.userMessage
            configureStartupStateForLoadedGame()
        case .noSave:
            self.state = GameState()
            self.originPreview = orchestrator.previewStart(mode: .quickStart, templateID: nil)
        case .failed(let primaryError, let errors, let timingSnapshot):
            self.state = GameState()
            self.originPreview = orchestrator.previewStart(mode: .quickStart, templateID: nil)
            self.lastTimingSnapshot = timingSnapshot
            self.persistenceAlert = PersistenceAlertContext(
                title: "Couldn't Recover Saved Progress",
                message: persistenceMessage(for: primaryError, fallbacks: errors)
            )
        }
        refreshDerivedState()
    }

    func newLife() {
        state = GameState()
        originPreview = orchestrator.previewStart(mode: .quickStart, templateID: nil)
        selectedStartMode = .quickStart
        selectedTemplate = .stableHomeAverageMeans
        currentEvent = nil
        showingEvent = false
        selectedTab = .career
        persistenceBanner = nil
        refreshDerivedState()
        save()
    }

    func ageUp() {
        guard !state.isGameOver else { return }
        currentEvent = orchestrator.advanceYear(state: &state)
        showingEvent = (currentEvent != nil)
        refreshDerivedState()
        save()
    }

    func choose(_ choice: EventChoice) {
        guard let ev = currentEvent else { return }
        orchestrator.apply(choice: choice, event: ev, state: &state)
        currentEvent = nil
        showingEvent = false
        refreshDerivedState()
        save()
    }

    func previewQuickStart() {
        selectedStartMode = .quickStart
        originPreview = orchestrator.previewStart(mode: .quickStart, templateID: nil)
    }

    func previewTemplate(_ template: OriginTemplateID) {
        selectedStartMode = .template
        selectedTemplate = template
        originPreview = orchestrator.previewStart(mode: .template, templateID: template)
    }

    func rerollOrigin() {
        switch selectedStartMode {
        case .quickStart:
            previewQuickStart()
        case .template:
            previewTemplate(selectedTemplate)
        }
    }

    func beginLife() {
        guard var preview = originPreview else { return }
        currentEvent = orchestrator.activatePreview(state: &preview)
        showingEvent = (currentEvent != nil)
        state = preview
        originPreview = nil
        selectedTab = .career
        refreshDerivedState()
        save()
    }

    func save() {
        do {
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

    func roleTitle() -> String {
        orchestrator.roleTitle(for: state.career)
    }

    var showingEducationAsPrimaryTab: Bool {
        state.player.age < 18 || state.education.pathway == .student || state.education.pathway == .training
    }

    func tabTitle(for tab: Tab) -> String {
        switch tab {
        case .career where showingEducationAsPrimaryTab:
            return "Education"
        default:
            return tab.title
        }
    }

    func tabSymbol(for tab: Tab) -> String {
        switch tab {
        case .career where showingEducationAsPrimaryTab:
            return "book.closed.fill"
        default:
            return tab.symbol
        }
    }

    func selectedAction(for domain: ActionDomain) -> ActionChoiceID? {
        state.pendingActions.first(where: { $0.domain == domain })?.choiceID
    }

    func setAction(_ choiceID: ActionChoiceID, for domain: ActionDomain) {
        state.pendingActions.removeAll { $0.domain == domain }
        state.pendingActions.append(PlayerYearAction(domain: domain, choiceID: choiceID))
        refreshDerivedState()
    }

    func actionChoices(for domain: ActionDomain) -> [ActionChoiceID] {
        switch domain {
        case .education:
            return [.studyHard, .phoneItIn, .skipClass]
        case .career:
            return [.workHard, .coast, .jobHunt]
        case .finance:
            return [.cutSpending, .spendForRelief, .takeSideWork]
        case .relationships:
            return [.reachOut, .keepDistance, .repairTension]
        case .health:
            return [.rest, .pushThrough, .seeDoctor]
        }
    }

    func actionLabel(for choiceID: ActionChoiceID) -> String {
        switch choiceID {
        case .studyHard: return "Study Hard"
        case .phoneItIn: return "Phone It In"
        case .skipClass: return "Skip Class"
        case .workHard: return "Work Hard"
        case .coast: return "Coast"
        case .jobHunt: return "Job Hunt"
        case .cutSpending: return "Cut Spending"
        case .spendForRelief: return "Spend for Relief"
        case .takeSideWork: return "Take Side Work"
        case .reachOut: return "Reach Out"
        case .keepDistance: return "Keep Distance"
        case .repairTension: return "Repair Tension"
        case .rest: return "Rest"
        case .pushThrough: return "Push Through"
        case .seeDoctor: return "See a Doctor"
        }
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

    func pendingActionSummary() -> String {
        guard !state.pendingActions.isEmpty else {
            return "No yearly focus set"
        }

        let planned = state.pendingActions
            .sorted { $0.domain.rawValue < $1.domain.rawValue }
            .prefix(2)
            .map { "\(actionDomainLabel(for: $0.domain)): \(actionLabel(for: $0.choiceID))" }
            .joined(separator: " • ")

        if state.pendingActions.count > 2 {
            return "\(planned) • +\(state.pendingActions.count - 2) more"
        }

        return planned
    }

    func pendingActionStatus() -> String {
        state.pendingActions.isEmpty ? "Optional" : "\(state.pendingActions.count) planned"
    }

    private func refreshDerivedState() {
        historyDigest = HistoryDigest(state: state)
        #if DEBUG
        lastTimingSnapshot = orchestrator.latestTimingSnapshot ?? lastTimingSnapshot
        #endif
    }

    private func actionDomainLabel(for domain: ActionDomain) -> String {
        switch domain {
        case .education: return "School"
        case .career: return "Work"
        case .finance: return "Money"
        case .relationships: return "Social"
        case .health: return "Health"
        }
    }

    private func configureStartupStateForLoadedGame() {
        if state.startupState == .active {
            self.originPreview = nil
        } else {
            self.originPreview = orchestrator.previewStart(mode: .quickStart, templateID: nil)
            self.selectedStartMode = .quickStart
            self.selectedTemplate = .stableHomeAverageMeans
        }
    }

    private func persistenceMessage(for primaryError: PersistenceError, fallbacks: [PersistenceError]) -> String {
        let details = fallbacks
            .map { $0.errorDescription ?? "Unknown persistence error." }
            .joined(separator: " ")
        return [primaryError.errorDescription, details]
            .compactMap { $0 }
            .joined(separator: " ")
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

private enum AppFeedback {
    static func impact(_ style: ImpactStyle) {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    static func notify(_ type: NoticeType) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type.uiKitType)
        #endif
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

        #if canImport(UIKit)
        var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: return .success
            case .warning: return .warning
            }
        }
        #endif
    }
}

struct ContentView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    plannerBackground
                        .ignoresSafeArea()

                    if vm.state.startupState == .active {
                        VStack(spacing: 18) {
                            topBar
                            persistenceNotice
                            tabStrip
                            lifeSignals
                            activeTabContent
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 14)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 104)
                    } else {
                        startupExperience
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 28)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if vm.state.startupState == .active {
                        ageUpDock
                            .padding(.horizontal, 18)
                            .padding(.top, 8)
                            .padding(.bottom, max(geometry.safeAreaInsets.bottom, 12))
                            .background(.ultraThinMaterial)
                    }
                }
            }
            .modifier(HidePlannerNavigationBar())
            .sheet(isPresented: $vm.showingEvent) {
                EventSheet(event: vm.currentEvent) { choice in
                    AppFeedback.impact(.light)
                    vm.choose(choice)
                    AppFeedback.notify(vm.state.isGameOver ? .warning : .success)
                }
            }
            .alert(item: $vm.persistenceAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("Okay"))
                )
            }
            .confirmationDialog("Settings", isPresented: $vm.showingSettings, titleVisibility: .visible) {
                Button("Start New Life", role: .destructive) { vm.newLife() }
                Button("Reset Saved Progress", role: .destructive) { vm.resetSave() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose a secondary action without leaving your current life planner flow.")
            }
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

                        Button {
                            AppFeedback.notify(.success)
                            vm.beginLife()
                        } label: {
                            Label("Begin at 14", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    private var startupHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OneLife")
                .font(.system(size: 34, weight: .bold, design: .rounded))

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
                ForEach(OriginCatalog.templates, id: \.id) { template in
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
                    .foregroundStyle(PlannerTone.warning.tint)
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
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.94, blue: 0.90),
                    Color(red: 0.88, green: 0.90, blue: 0.87)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 220, height: 220)
                .offset(x: 140, y: -260)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color.black.opacity(0.05))
                .frame(height: 280)
                .blur(radius: 30)
                .offset(y: -300)
        }
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("OneLife")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("\(vm.state.player.name), Age \(vm.state.player.age)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Legacy \(vm.state.progress.legacyScore)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let lifePath = vm.currentLifePathProfile() {
                    Label(lifePath.title, systemImage: lifePath.symbol)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.08))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Button {
                vm.showingSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                    .frame(width: 42, height: 42)
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
            }
            .accessibilityIdentifier("settings-button")
        }
    }

    private var tabStrip: some View {
        HStack(spacing: 10) {
            ForEach(GameViewModel.Tab.allCases) { tab in
                Button {
                    AppFeedback.impact(.light)
                    vm.selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: vm.tabSymbol(for: tab))
                            .font(.headline)
                        Text(vm.tabTitle(for: tab))
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(vm.selectedTab == tab ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(vm.selectedTab == tab ? Color.black.opacity(0.82) : Color.white.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .accessibilityIdentifier("\(tab.rawValue)-tab")
            }
        }
    }

    private var lifeSignals: some View {
        let signals = topSignals()
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(signals, id: \.title) { signal in
                    StatusPill(symbol: signal.symbol, title: signal.title, value: signal.value, tone: signal.tone)
                }
            }
            .padding(.horizontal, 2)
        }
        .accessibilityIdentifier("life-signals")
    }

    @ViewBuilder
    private var activeTabContent: some View {
        switch vm.selectedTab {
        case .career:
            if vm.showingEducationAsPrimaryTab {
                EducationPlannerTab(
                    state: vm.state,
                    recentHistory: vm.historyDigest.education,
                    selectedAction: vm.selectedAction(for: .education),
                    actionChoices: vm.actionChoices(for: .education),
                    actionLabel: vm.actionLabel(for:),
                    onSelectAction: { vm.setAction($0, for: .education) }
                )
            } else {
                CareerPlannerTab(
                    state: vm.state,
                    roleTitle: vm.roleTitle(),
                    recentHistory: vm.historyDigest.all,
                    selectedAction: vm.selectedAction(for: .career),
                    actionChoices: vm.actionChoices(for: .career),
                    actionLabel: vm.actionLabel(for:),
                    onSelectAction: { vm.setAction($0, for: .career) }
                )
            }
        case .finance:
            FinancePlannerTab(
                state: vm.state,
                policyLabel: vm.policyLabel(),
                recentHistory: vm.historyDigest.finance,
                selectedAction: vm.selectedAction(for: .finance),
                actionChoices: vm.actionChoices(for: .finance),
                actionLabel: vm.actionLabel(for:),
                onSelectAction: { vm.setAction($0, for: .finance) }
            )
        case .relationships:
            RelationshipsPlannerTab(
                state: vm.state,
                recentHistory: vm.historyDigest.relationships,
                selectedAction: vm.selectedAction(for: .relationships),
                actionChoices: vm.actionChoices(for: .relationships),
                actionLabel: vm.actionLabel(for:),
                onSelectAction: { vm.setAction($0, for: .relationships) }
            )
        case .health:
            HealthPlannerTab(
                state: vm.state,
                recentHistory: vm.historyDigest.health,
                selectedAction: vm.selectedAction(for: .health),
                actionChoices: vm.actionChoices(for: .health),
                actionLabel: vm.actionLabel(for:),
                onSelectAction: { vm.setAction($0, for: .health) }
            )
        }
    }

    private var ageUpDock: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.pendingActionStatus())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(vm.state.pendingActions.isEmpty ? PlannerTone.warning.tint : .secondary)

                Text(vm.pendingActionSummary())
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                AppFeedback.impact(.medium)
                vm.ageUp()
                if vm.state.isGameOver {
                    AppFeedback.notify(.warning)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "forward.fill")
                    Text(vm.state.isGameOver ? "Life Ended" : "Age Up")
                        .fontWeight(.bold)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(vm.state.isGameOver ? Color.gray : Color.black)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.18), radius: 18, y: 8)
            }
            .disabled(vm.state.isGameOver)
            .accessibilityIdentifier("age-up-button")
        }
    }

    private func topSignals() -> [SignalSummary] {
        let thirdSignal = vm.showingEducationAsPrimaryTab
            ? SignalSummary(
                symbol: vm.state.education.pathway == .graduate ? "checkmark.seal.fill" : "book.closed.fill",
                title: "Education",
                value: vm.state.education.pathway == .graduate ? "Graduated" : (vm.state.education.schoolStanding >= 70 ? "On Track" : (vm.state.education.attendancePressure >= 55 ? "At Risk" : "Holding")),
                tone: vm.state.education.pathway == .graduate ? .positive : (vm.state.education.attendancePressure >= 55 ? .warning : .neutral)
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

private enum PlannerTone {
    case positive
    case neutral
    case warning

    var tint: Color {
        switch self {
        case .positive: return Color(red: 0.17, green: 0.48, blue: 0.27)
        case .neutral: return Color(red: 0.23, green: 0.29, blue: 0.36)
        case .warning: return Color(red: 0.68, green: 0.22, blue: 0.18)
        }
    }

    var fill: Color {
        tint.opacity(0.12)
    }
}

struct HistoryDigest {
    let all: [HistoryEntry]
    let education: [HistoryEntry]
    let finance: [HistoryEntry]
    let relationships: [HistoryEntry]
    let health: [HistoryEntry]

    static let empty = HistoryDigest(all: [], education: [], finance: [], relationships: [], health: [])

    init(state: GameState) {
        let budget = PerformanceBudgets.maxRenderedHistoryItems
        all = Array(state.history.prefix(budget))
        education = Array(state.history.lazy.filter { $0.title.contains("Education") || $0.title.contains("School") || $0.title.contains("Training") || $0.title == "Milestone" }.prefix(budget))
        finance = Array(state.history.lazy.filter { $0.title.contains("Finance") || $0.title.contains("Stress") || $0.title.contains("Milestone") }.prefix(budget))
        relationships = Array(state.history.lazy.filter { $0.title.contains("Relationship") || $0.title == "Relationships" || $0.title == "Milestone" }.prefix(budget))
        health = Array(state.history.lazy.filter { $0.title.contains("Health") || $0.title == "Life Ended" }.prefix(budget))
    }

    private init(all: [HistoryEntry], education: [HistoryEntry], finance: [HistoryEntry], relationships: [HistoryEntry], health: [HistoryEntry]) {
        self.all = all
        self.education = education
        self.finance = finance
        self.relationships = relationships
        self.health = health
    }
}

private struct SignalSummary {
    let symbol: String
    let title: String
    let value: String
    let tone: PlannerTone
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
                .foregroundStyle(tone.tint)
                .frame(width: 30, height: 30)
                .background(tone.fill)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tone.tint)
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
    }
}

private struct PlannerSectionCard<Content: View>: View {
    let title: String
    let symbol: String
    let status: String
    let tone: PlannerTone
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: symbol)
                        .foregroundStyle(tone.tint)
                        .frame(width: 36, height: 36)
                        .background(tone.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(status)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(tone.tint)
                    }
                }

                Spacer()
            }

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MetricRow: View {
    let metrics: [(String, String, PlannerTone)]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(metric.1)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(metric.2.tint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(metric.2.fill)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

private struct RecentLifeModule: View {
    let history: [HistoryEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Life")
                .font(.headline)

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
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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

private struct ActionSelectionModule: View {
    let title: String
    let selectedAction: ActionChoiceID?
    let actionChoices: [ActionChoiceID]
    let actionLabel: (ActionChoiceID) -> String
    let onSelectAction: (ActionChoiceID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(actionChoices) { action in
                    Button {
                        AppFeedback.impact(.light)
                        onSelectAction(action)
                    } label: {
                        Text(actionLabel(action))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selectedAction == action ? Color.black.opacity(0.82) : Color.black.opacity(0.06))
                            .foregroundStyle(selectedAction == action ? Color.white : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
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
    let recentHistory: [HistoryEntry]
    let selectedAction: ActionChoiceID?
    let actionChoices: [ActionChoiceID]
    let actionLabel: (ActionChoiceID) -> String
    let onSelectAction: (ActionChoiceID) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PlannerSectionCard(
                title: "Education",
                symbol: "book.closed.fill",
                status: educationStatus,
                tone: state.education.pathway == .graduate ? .positive : (state.education.attendancePressure >= 55 ? .warning : .neutral)
            ) {
                MetricRow(metrics: [
                    ("Standing", "\(state.education.schoolStanding)", state.education.schoolStanding >= 70 ? .positive : (state.education.schoolStanding < 40 ? .warning : .neutral)),
                    ("Engagement", "\(state.education.engagement)", state.education.engagement >= 65 ? .positive : (state.education.engagement < 40 ? .warning : .neutral)),
                    ("Pressure", "\(state.education.attendancePressure)", state.education.attendancePressure >= 55 ? .warning : .neutral)
                ])

                Text(educationSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ActionSelectionModule(title: "Yearly Focus", selectedAction: selectedAction, actionChoices: actionChoices, actionLabel: actionLabel, onSelectAction: onSelectAction)
            }

            RecentLifeModule(history: recentHistory)
        }
        .accessibilityIdentifier("education-tab-content")
    }

    private var educationStatus: String {
        switch state.education.pathway {
        case .graduate: return "Graduated"
        case .training: return "In training"
        case .dropout: return "Off track"
        case .student: return state.education.schoolStanding >= 70 ? "On track" : "School under pressure"
        }
    }

    private var educationSummary: String {
        if state.education.hasScholarship {
            return "Your school performance is opening doors and easing the financial burden."
        }
        if state.education.attendancePressure >= 55 {
            return "School is becoming fragile, and this year’s discipline could decide a lot."
        }
        return "Education is still shaping the floor under the rest of your life."
    }
}

private struct CareerPlannerTab: View {
    let state: GameState
    let roleTitle: String
    let recentHistory: [HistoryEntry]
    let selectedAction: ActionChoiceID?
    let actionChoices: [ActionChoiceID]
    let actionLabel: (ActionChoiceID) -> String
    let onSelectAction: (ActionChoiceID) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PlannerSectionCard(
                title: "Career",
                symbol: "briefcase.fill",
                status: roleTitle,
                tone: state.career.status == .unemployed ? .warning : (state.career.performance >= 75 ? .positive : .neutral)
            ) {
                MetricRow(metrics: [
                    ("Performance", "\(state.career.performance)", state.career.performance >= 75 ? .positive : (state.career.performance < 35 ? .warning : .neutral)),
                    ("Income", "$\(state.career.annualIncome)", state.career.annualIncome > 0 ? .positive : .warning),
                    ("Years", "\(state.career.yearsWorked)", .neutral)
                ])

                Text(careerSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ActionSelectionModule(title: "Yearly Focus", selectedAction: selectedAction, actionChoices: actionChoices, actionLabel: actionLabel, onSelectAction: onSelectAction)
            }

            RecentLifeModule(history: recentHistory)
        }
        .accessibilityIdentifier("career-tab-content")
    }

    private var careerSummary: String {
        if state.career.status == .unemployed {
            return "Work stability is the pressure point right now, so the next year matters."
        }
        if state.career.performance >= 75 {
            return "Your work momentum is healthy and could convert into better opportunities."
        }
        return "Your career is moving, but it still needs steadier performance to feel secure."
    }
}

private struct FinancePlannerTab: View {
    let state: GameState
    let policyLabel: String
    let recentHistory: [HistoryEntry]
    let selectedAction: ActionChoiceID?
    let actionChoices: [ActionChoiceID]
    let actionLabel: (ActionChoiceID) -> String
    let onSelectAction: (ActionChoiceID) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PlannerSectionCard(
                title: "Finance",
                symbol: "dollarsign.circle.fill",
                status: balanceStatus,
                tone: state.finance.lastYearBalanceDelta < 0 ? .warning : (state.finance.lastYearBalanceDelta > 5_000 ? .positive : .neutral)
            ) {
                MetricRow(metrics: [
                    ("Net", "$\(state.finance.annualNetIncome)", state.finance.annualNetIncome > 0 ? .positive : .warning),
                    ("Expenses", "$\(state.finance.annualTotalExpenses)", state.finance.annualTotalExpenses > state.finance.annualNetIncome ? .warning : .neutral),
                    ("Stress", "\(state.finance.financialStress)", state.finance.financialStress >= 45 ? .warning : .neutral)
                ])

                MetricRow(metrics: [
                    ("Cash", "$\(state.finance.cashOnHand)", state.finance.cashOnHand >= 0 ? .positive : .warning),
                    ("Housing", housingLabel, state.housing.housingStability < 35 ? .warning : .neutral),
                    ("Policy", policyLabel, .neutral)
                ])

                Text(financeSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ActionSelectionModule(title: "Yearly Focus", selectedAction: selectedAction, actionChoices: actionChoices, actionLabel: actionLabel, onSelectAction: onSelectAction)
            }

            RecentLifeModule(history: recentHistory)
        }
        .accessibilityIdentifier("finance-tab-content")
    }

    private var housingLabel: String {
        switch state.housing.livingArrangement {
        case .familyHome: return "Family home"
        case .roommates: return "Roommates"
        case .soloRenting: return "Solo rent"
        case .couchSurfing: return "Unstable"
        }
    }

    private var balanceStatus: String {
        if state.finance.lastYearBalanceDelta < 0 { return "Budget under strain" }
        if state.finance.lastYearBalanceDelta > 5_000 { return "Building surplus" }
        return "Cash flow holding"
    }

    private var financeSummary: String {
        if state.finance.financialStress >= 45 {
            return "Money pressure is actively shaping the rest of your life."
        }
        if state.housing.housingStability < 35 {
            return "Housing instability is now part of your money problem, not separate from it."
        }
        if state.finance.lastYearBalanceDelta < 0 {
            return "Your costs are still beating your income, so stability has not landed yet."
        }
        return "This year feels financially livable, even if it is not comfortable yet."
    }
}

private struct RelationshipsPlannerTab: View {
    let state: GameState
    let recentHistory: [HistoryEntry]
    let selectedAction: ActionChoiceID?
    let actionChoices: [ActionChoiceID]
    let actionLabel: (ActionChoiceID) -> String
    let onSelectAction: (ActionChoiceID) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PlannerSectionCard(
                title: "Relationships",
                symbol: "person.2.fill",
                status: relationshipStatus,
                tone: strainedRelationshipCount > 0 ? .warning : (connectionCount > 0 ? .positive : .neutral)
            ) {
                MetricRow(metrics: [
                    ("Connections", "\(connectionCount)", connectionCount > 0 ? .positive : .warning),
                    ("Best Bond", "\(max(state.relationships.friends.strongestBond, state.relationships.romanticPartners.strongestBond))", strongestBondTone),
                    ("Strained", "\(strainedRelationshipCount)", strainedRelationshipCount > 0 ? .warning : .neutral)
                ])

                Text(relationshipSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                connectionPreview

                ActionSelectionModule(title: "Yearly Focus", selectedAction: selectedAction, actionChoices: actionChoices, actionLabel: actionLabel, onSelectAction: onSelectAction)
            }

            RecentLifeModule(history: recentHistory)
        }
        .accessibilityIdentifier("relationships-tab-content")
    }

    private var connectionCount: Int {
        state.relationships.friends.count + state.relationships.romanticPartners.count
    }

    private var strainedRelationshipCount: Int {
        (state.relationships.friends + state.relationships.romanticPartners).filter { $0.status == .strained }.count
    }

    private var strongestBondTone: PlannerTone {
        let strongest = max(state.relationships.friends.strongestBond, state.relationships.romanticPartners.strongestBond)
        if strongest >= 75 { return .positive }
        if strongest < 35 { return .warning }
        return .neutral
    }

    private var relationshipStatus: String {
        if let spouse = state.relationships.spouseName {
            return "Married to \(spouse)"
        }
        if let partner = state.relationships.romanticPartners.first {
            return "With \(partner.name)"
        }
        if !state.relationships.friends.isEmpty {
            return "Friend network active"
        }
        return "Social life is thin"
    }

    private var relationshipSummary: String {
        if strainedRelationshipCount > 0 {
            return "At least one close connection is fraying and needs care."
        }
        if connectionCount == 0 {
            return "Your support system is light right now, which makes hard years hit harder."
        }
        return "Your social life is carrying some warmth and stability."
    }

    private var connectionPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let partner = state.relationships.romanticPartners.first {
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
}

private struct HealthPlannerTab: View {
    let state: GameState
    let recentHistory: [HistoryEntry]
    let selectedAction: ActionChoiceID?
    let actionChoices: [ActionChoiceID]
    let actionLabel: (ActionChoiceID) -> String
    let onSelectAction: (ActionChoiceID) -> Void

    var body: some View {
        VStack(spacing: 14) {
            PlannerSectionCard(
                title: "Health",
                symbol: "cross.case.fill",
                status: healthStatus,
                tone: state.player.health < 40 || !state.healthProfile.activeConditions.isEmpty ? .warning : .positive
            ) {
                MetricRow(metrics: [
                    ("Overall", "\(state.player.health)", state.player.health >= 60 ? .positive : (state.player.health < 40 ? .warning : .neutral)),
                    ("Physical", "\(state.healthProfile.physicalWellness)", state.healthProfile.physicalWellness >= 60 ? .positive : (state.healthProfile.physicalWellness < 40 ? .warning : .neutral)),
                    ("Mental", "\(state.healthProfile.mentalWellness)", state.healthProfile.mentalWellness >= 60 ? .positive : (state.healthProfile.mentalWellness < 40 ? .warning : .neutral))
                ])

                MetricRow(metrics: [
                    ("Exercise", "\(state.healthProfile.habits.exercise)", tone(for: state.healthProfile.habits.exercise)),
                    ("Nutrition", "\(state.healthProfile.habits.nutrition)", tone(for: state.healthProfile.habits.nutrition)),
                    ("Housing", "\(state.housing.housingStability)", state.housing.housingStability < 35 ? .warning : .neutral)
                ])

                Text(healthSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if !state.healthProfile.activeConditions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(state.healthProfile.activeConditions) { condition in
                                Text("\(condition.name) • \(condition.severity)")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(PlannerTone.warning.fill)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                ActionSelectionModule(title: "Yearly Focus", selectedAction: selectedAction, actionChoices: actionChoices, actionLabel: actionLabel, onSelectAction: onSelectAction)
            }

            RecentLifeModule(history: recentHistory)
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
}

private func signedCurrency(_ value: Int) -> String {
    value >= 0 ? "+$\(value)" : "-$\(abs(value))"
}

struct EventSheet: View {
    let event: GameEvent?
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

                    Text(event.text)
                        .foregroundStyle(.secondary)

                    Divider()

                    VStack(spacing: 10) {
                        ForEach(event.choices) { choice in
                            Button {
                                onPick(choice)
                                dismiss()
                            } label: {
                                Text(choice.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
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
        }
    }
}
