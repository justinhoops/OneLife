import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif



struct ContentView: View {
    @ObservedObject var vm: GameViewModel
    @State private var isPulsing = false
    @State private var showLifeFeedSheet = false
    @State private var showLifeJournalSheet = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.clear
                        .onAppear {
                            guard !vm.chrome.isLoadingPersistedGame else { return }
                            if vm.state.startupState == .active {
                                vm.hydrateRuntimeCachesIfNeeded()
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

                    if vm.chrome.isLoadingPersistedGame {
                        startupLoadingOverlay(title: "Loading your life...")
                            .zIndex(120)
                            .transition(.opacity)
                    } else if vm.state.startupState == .active {
                        LifeConsoleView(
                            vm: vm,
                            chrome: vm.chrome,
                            onOpenFeed: { showLifeFeedSheet = true },
                            onSettings: { vm.showingSettings = true }
                        )
                        .offset(x: vm.chrome.actionFrictionJitter ? 4 : 0)
                        .animation(vm.chrome.actionFrictionJitter ? .default.repeatCount(3, autoreverses: true) : .default, value: vm.chrome.actionFrictionJitter)
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
                        FloatingDeltasOverlay(deltas: vm.chrome.floatingDeltas)
                            .allowsHitTesting(false)

                        AutonomyToastOverlay(toasts: vm.chrome.autonomyToasts)
                            .zIndex(48)

                        // Micro-beat (transient reaction text) -- suppressed during popup resolving to keep focus on the processing card/loading.
                        if !vm.chrome.isResolvingInteraction, let beat = vm.chrome.microBeatOverlay {
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

                    if let saveStatusBanner = vm.chrome.saveStatusBanner, vm.state.startupState == .active {
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
                    if vm.presentedCard != nil || vm.chrome.isResolvingInteraction {
                        ZStack(alignment: .bottom) {
                            // Full dimming scrim (root level ensures it covers TabView content + bar + everything).
                            Color.black.opacity(0.55)
                                .ignoresSafeArea()
                                .allowsHitTesting(true)
                                .onTapGesture {
                                    if !vm.chrome.isResolvingInteraction, let card = vm.presentedCard, !vm.isChoiceCard(card) {
                                        AppFeedback.impact(.light)
                                        vm.dismissPresentedCard()
                                    }
                                }
                                .zIndex(1)

                            if vm.chrome.isResolvingInteraction {
                                // Processing/loading state (visible immediately after button press thanks to flag + yield).
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.2)
                                    Text(vm.chrome.resolvingInteractionContext.map { "Resolving: \($0)" } ?? "Resolving your choice...")
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
                                    onDismissMomentumCarry: { vm.markInstantMomentumYearSummarySeen() },
                                    onDismissFirstAgeUpReflection: { vm.markFirstAgeUpReflectionSeen() },
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
                    if vm.chrome.isStartingNewLife {
                        startupLoadingOverlay(title: "Generating your life...")
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
                    latestYearSummary: vm.latestYearSummary,
                    onDismissAdultChildrenCoach: { vm.markAdultChildrenCoachSeen() }
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
                            urgencyItems: vm.prefersCompactLateGameUI ? vm.compactPressureItems(limit: 3) : vm.feedUrgencyItems(),
                            secondaryUrgencyItems: vm.prefersCompactLateGameUI ? vm.secondaryPressureItems(after: 3) : [],
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
            .sheet(isPresented: $vm.showingDomainShortcutEditor) {
                DomainShortcutEditorSheet(vm: vm)
            }
            #if DEBUG
            .sheet(isPresented: $vm.showingDebugLab) {
                DebugScenarioLabSheet(
                    timingSnapshot: vm.lastTimingSnapshot,
                    performanceRecords: RuntimePerformanceMonitor.shared.records,
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
            .animation(vm.animationSetting == .off ? nil : .easeInOut(duration: vm.animationSetting == .reduced ? 0.14 : 0.24), value: vm.chrome.saveStatusBanner)
            .animation(vm.animationSetting == .off ? nil : .easeInOut(duration: vm.animationSetting == .reduced ? 0.14 : 0.24), value: vm.chrome.activityPulse)
            .animation(vm.animationSetting == .off ? nil : .easeInOut(duration: vm.animationSetting == .reduced ? 0.14 : 0.24), value: vm.returnPrompt)
            .onChange(of: scenePhase) { _, phase in
                guard phase == .background || phase == .inactive else { return }
                Task { await vm.flushPendingSave() }
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
                    DesignSystem.Colors.backgroundDark,
                    Color(red: 0.12, green: 0.11, blue: 0.18) // Slightly lighter warm dark for gradient
                ]
                : [
                    DesignSystem.Colors.lightBackgroundStart,
                    DesignSystem.Colors.lightBackgroundEnd
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
            Image(systemName: isWorldReaction ? "globe.americas.fill" : (pulse.tone == .warning ? "flame.fill" : "sparkles"))
                .foregroundStyle(isWorldReaction ? Color.purple : pulse.tone.color)
                .padding(.top, 2)
                .scaleEffect(isWorldReaction ? 1.15 : 1.0)

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
        .shadow(color: isWorldReaction ? Color.purple.opacity(0.22) : Color.black.opacity(OLTheme.cardShadowOpacity(colorScheme)), radius: isWorldReaction ? 20 : 12, x: 0, y: isWorldReaction ? 8 : 6)
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
        case "Legal Status": return "home-urgency-legal"
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
                    status: (compactHome ? vm.compactPressureItems(limit: 3) : vm.feedUrgencyItems()).first(where: { $0.tone == .warning })?.value
                        ?? (compactHome ? vm.compactPressureItems(limit: 1) : vm.feedUrgencyItems(limit: 1)).first?.value
                        ?? "Glance",
                    tone: (compactHome ? vm.compactPressureItems(limit: 3) : vm.feedUrgencyItems()).contains(where: { $0.tone == .warning }) ? .warning : .neutral,
                    collapsible: compactHome,
                    startsCollapsed: compactHome
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(compactHome ? vm.compactPressureItems(limit: 3) : vm.feedUrgencyItems()) { item in
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
                            if compactHome {
                                let more = vm.secondaryPressureItems(after: 3)
                                if !more.isEmpty {
                                    Text("+\(more.count) more pressures")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                        .accessibilityIdentifier("home-more-pressures-count")
                                }
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
                        schoolClimateMetrics: vm.isTeenExperience ? vm.highSchoolShapeMetrics() : vm.teenSchoolClimateMetrics(),
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
                        legalActionChoices: vm.actionChoices(for: .legal),
                        onSelectLegalAction: { vm.setAction($0, for: .legal) },
                        comingUpItems: vm.comingUpItems(for: .occupation),
                        openDetail: vm.openDetail(_:),
                        selectedSubTab: Binding(
                            get: { vm.consoleNavigation.careersSubTab },
                            set: { vm.consoleNavigation.careersSubTab = $0 }
                        )
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
                    selectedSubTab: Binding(
                        get: { vm.consoleNavigation.assetsSubTab },
                        set: { vm.consoleNavigation.assetsSubTab = $0 }
                    ),
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

        case .activities:
            EmptyView()
                .accessibilityIdentifier("activities-tab-content")

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





#if DEBUG
struct DebugScenarioLabSheet: View {
    let timingSnapshot: SimulationTimingSnapshot?
    let performanceRecords: [RuntimePerformanceRecord]
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

                    runtimePerformancePanel

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

    @ViewBuilder
    private var runtimePerformancePanel: some View {
        PlannerSectionCard(
            title: "Runtime Performance",
            symbol: "gauge.with.dots.needle.67percent",
            status: "DEBUG",
            tone: .neutral
        ) {
            VStack(alignment: .leading, spacing: 8) {
                if let timingSnapshot {
                    perfRow("Load", timingSnapshot.loadMilliseconds, budget: RuntimePerformanceBaseline.saveResumeDecodeMilliseconds)
                    perfRow("Save", timingSnapshot.saveMilliseconds, budget: RuntimePerformanceBaseline.saveEncodeMilliseconds)
                    perfRow("Age Up", timingSnapshot.totalAdvanceYearMilliseconds, budget: RuntimePerformanceBaseline.typicalAgeUpMilliseconds)
                    if timingSnapshot.persistedSaveBytes > 0 {
                        Text("Save size: \(timingSnapshot.persistedSaveBytes) bytes · history \(timingSnapshot.persistedHistoryCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let source = timingSnapshot.persistenceRecoverySource {
                        Text("Recovery source: \(source)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !timingSnapshot.entries.isEmpty {
                        Text("System breakdown")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        ForEach(timingSnapshot.entries.prefix(8)) { entry in
                            Text("\(entry.label): \(Int(entry.durationMilliseconds))ms")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("No timing snapshot yet. Age up or save to populate metrics.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !performanceRecords.isEmpty {
                    Text("Recent markers")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    ForEach(performanceRecords.suffix(6).reversed()) { record in
                        HStack {
                            Text(record.marker.rawValue)
                            Spacer()
                            Text("\(Int(record.durationMilliseconds))ms")
                                .foregroundStyle(record.exceedsBudget ? Color.orange : Color.secondary)
                        }
                        .font(.caption2.monospacedDigit())
                    }
                }
            }
        }
        .accessibilityIdentifier("debug-runtime-performance-panel")
    }

    private func perfRow(_ label: String, _ value: Double, budget: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(Int(value))ms")
                .foregroundStyle(value > budget ? Color.orange : Color.secondary)
        }
        .font(.caption.monospacedDigit())
    }

    private func tone(for scenario: DebugScenarioID) -> PlannerTone {
        switch scenario {
        case .healthCrisis, .housingDeficitFlow, .specialCareerCrime, .pregnancyYoungFamily, .teenEducationPressure, .yearSummaryPreview,
             .legalInvestigation, .legalCharged, .legalConvicted, .legalCustody, .legalSupervision:
            return .warning
        case .adultCareerFlow, .specialCareerEntertainment, .partnerCohabitationFlow, .universityTrack, .tradeTrack,
             .combatBoxing, .combatMMA, .combatCrossover, .combatChampion, .fightEmpire, .sportsOwnerBillionaire,
             .longLifeStressTest:
            return .positive
        case .adultEdRebuild, .eventPreview, .combatInjured, .legalReleased:
            return .neutral
        }
    }

    private func symbol(for scenario: DebugScenarioID) -> String {
        switch scenario {
        case .teenEducationPressure, .universityTrack, .tradeTrack, .adultEdRebuild:
            return "book.closed.fill"
        case .adultCareerFlow:
            return "briefcase.fill"
        case .combatBoxing, .combatMMA, .combatCrossover, .combatChampion, .combatInjured:
            return "figure.boxing"
        case .fightEmpire:
            return "building.columns.fill"
        case .sportsOwnerBillionaire:
            return "building.2.crop.circle"
        case .legalInvestigation, .legalCharged, .legalConvicted, .legalCustody, .legalSupervision, .legalReleased:
            return "building.columns.fill"
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
        case .longLifeStressTest:
            return "clock.arrow.circlepath"
        }
    }
}
#endif



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
                    urgencyItems: vm.prefersCompactLateGameUI ? vm.compactPressureItems(limit: 3) : vm.feedUrgencyItems(),
                    secondaryUrgencyItems: vm.prefersCompactLateGameUI ? vm.secondaryPressureItems(after: 3) : [],
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
