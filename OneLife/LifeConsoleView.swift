import SwiftUI

struct LifeConsoleSnapshot {
    let name: String
    let age: Int
    let role: String
    let cash: String
    let cashTone: PlannerTone
    let health: Int
    let healthTone: PlannerTone
    let topPressures: [PlannerInsight]
    let selectedAction: String
    let ageUpRisk: [AgeUpRiskSignal]
    
    // Macro QoL
    let eraName: String
    let eraIcon: String
    let eraTone: PlannerTone
}

struct ActionSectionModel: Identifiable {
    let id: String
    let title: String
    let actions: [ActionPresentationModel]
}

struct DomainPanelModel {
    let id: ConsoleDomain
    let title: String
    let icon: String
    let tone: PlannerTone
    let status: String
    let velocity: String
    let metrics: [ConsoleMetricModel]
    let pressureLine: String
    let quickActions: [ActionPresentationModel]
    let actions: [ActionPresentationModel]
    /// When set (Money tab), year-plan actions render in labeled sections instead of a flat list.
    let actionSections: [ActionSectionModel]?
    /// Crime lane surfaced on Work / Life when heat or pending crime intent is active.
    let riskQuickActions: [ActionPresentationModel]
    let riskActions: [ActionPresentationModel]
    /// Parenting / pregnancy deck on People tab.
    let familyQuickActions: [ActionPresentationModel]
    let familyActions: [ActionPresentationModel]
    let detailDestination: PlannerDetailDestination?
    let detailButtonIdentifier: String?
    
    // NEW QoL: Predictive previews
    var previewProvider: ((ActionChoiceID) -> [String])? = nil
    
    // NEW QoL: Contextual secondary actions (e.g. Liquidate Assets)
    var secondaryAction: (title: String, icon: String, action: () -> Void)? = nil
}

struct ActiveEffectsView: View {
    let effects: [ActiveEffect]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Modifiers")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(effects) { effect in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(effect.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(effect.tone.color)
                            Text(effect.detail)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .padding(14)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ConsoleMetricModel: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let tone: PlannerTone
}

struct ActionPresentationModel: Identifiable {
    let id: String
    let domain: ActionDomain
    let choiceID: ActionChoiceID
    var title: String
    let subtitle: String
    let icon: String
    let tone: PlannerTone
    let tags: [String]
    var disabledReason: String?
    var isSelected: Bool
}

enum ConsoleDomain: String, CaseIterable, Identifiable {
    case life
    case work
    case money
    case people
    case activities
    case body
    case log

    var id: String { rawValue }
}

struct LifeConsoleView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var chrome: GameSessionChromeState
    var onOpenFeed: () -> Void
    var onSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showedMomentumHint = false
    @State private var showResilienceSheet = false
    @State private var expandedConsoleSections: Set<String> = []

    private var bitLifeShell: Bool { vm.prefersBitLifeShell }
    private var compactLateGame: Bool { vm.prefersCompactLateGameUI }
    private var panelCompact: Bool { bitLifeShell || compactLateGame }

    private var snapshot: LifeConsoleSnapshot {
        vm.lifeConsoleSnapshot()
    }

    private var currentDomain: ConsoleDomain {
        consoleDomain(for: vm.selectedTab)
    }

    private var panel: DomainPanelModel {
        vm.domainPanel(for: currentDomain)
    }

    private var secondaryPressures: [PlannerInsight] {
        Array(vm.feedUrgencyItems().dropFirst(3).prefix(3))
    }

    private var showsLifeHubExtras: Bool {
        currentDomain == .life && !bitLifeShell
    }

    /// Life-tab compaction: glance ribbon + collapsible decks (works in BitLife shell).
    private var showsLifeAuditDeck: Bool {
        currentDomain == .life && compactLateGame
    }

    var body: some View {
        VStack(spacing: 0) {
            consoleHeader
                .padding(.horizontal, 10)
                .padding(.top, 6)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    if let pulse = chrome.activityPulse {
                        ConsoleActivityPulse(pulse: pulse)
                    }

                    let activeEffects = vm.activeEffects()
                    if !activeEffects.isEmpty {
                        ActiveEffectsView(effects: activeEffects)
                    }

                    nowLaneCard
                    if (showsLifeHubExtras || showsLifeAuditDeck), !vm.castStripMembers().isEmpty {
                        if compactLateGame {
                            compactCastStrip
                        } else {
                            castStripCard
                        }
                    }

                    if showsLifeHubExtras || showsLifeAuditDeck {
                        if let ribbon = vm.lateGameContextRibbon() {
                            lateGameContextRibbon(ribbon)
                        }
                        if !compactLateGame {
                            glanceStrip
                        }
                        if compactLateGame {
                            collapsibleConsoleSection(
                                id: "pressures",
                                title: "More Pressures",
                                subtitle: secondaryPressures.first.map { "\($0.title): \($0.value)" } ?? "No secondary pressure",
                                tone: secondaryPressures.contains(where: { $0.tone == .warning }) ? .warning : .neutral,
                                icon: "exclamationmark.triangle"
                            ) {
                                pressureDeckContent
                            }
                            collapsibleConsoleSection(
                                id: "pace",
                                title: "Auto-Life Pace",
                                subtitle: vm.autoLifePace.title,
                                tone: vm.autoLifePace == .autopilot ? .positive : .neutral,
                                icon: "forward.end.fill"
                            ) {
                                autoLifePaceCardContent
                            }
                            collapsibleConsoleSection(
                                id: "pulse",
                                title: "Background Pulse",
                                subtitle: backgroundPulseSummary,
                                tone: vm.backgroundPulseItems().contains(where: { $0.tone == .warning }) ? .warning : .neutral,
                                icon: "waveform.path.ecg"
                            ) {
                                backgroundPulseDeckContent
                            }
                        } else {
                            autoLifePaceCard
                            pressureDeck
                            backgroundPulseDeck
                        }
                    }

                    if vm.showingHealthConsole {
                        Button {
                            AppFeedback.impact(.light)
                            vm.showingHealthConsole = false
                            vm.selectedTab = .activities
                        } label: {
                            Label("Open Play tab for instant actions", systemImage: "sparkles")
                                .font(.caption.weight(.black))
                        }
                        .buttonStyle(.plain)
                    }

                    if currentDomain == .activities {
                        ActivitiesInstantHubView(vm: vm)
                    } else if bitLifeShell {
                        DomainGlancePanelView(
                            model: panel,
                            vm: vm,
                            adultChildrenGlance: panelCompact ? vm.adultChildrenGlanceItems() : [],
                            adultChildrenFocusChip: adultChildrenFocusHistoryChip,
                            onDismissAdultChildrenCoach: { vm.markAdultChildrenCoachSeen() },
                            showLongPressCoach: vm.state.discoverability.shouldShowHoldHint() && panel.previewProvider != nil,
                            firstQuickActionTeachLine: vm.firstQuickActionTeachLine(),
                            onDismissFirstQuickActionTeach: { vm.markFirstQuickActionTeachSeen() },
                            onLongPressPreview: { vm.markFirstLongPressTeachSeen() },
                            onQuickAction: { action in
                                vm.performQuickAction(action.choiceID, for: action.domain)
                            },
                            onDetail: { destination in
                                AppFeedback.impact(.light)
                                vm.openDetail(destination)
                            }
                        )

                        if currentDomain == .money {
                            housingHubCard
                        }
                    } else {
                        DomainPanelView(
                            model: panel,
                            compactMode: panelCompact,
                            bitLifeMode: bitLifeShell,
                            forceExpandYearPlan: vm.shouldExpandHomeYearPlan() && currentDomain == .money,
                            adultChildrenGlance: panelCompact ? vm.adultChildrenGlanceItems() : [],
                            showLongPressCoach: vm.state.discoverability.shouldShowHoldHint() && panel.previewProvider != nil,
                            adultChildrenFocusChip: adultChildrenFocusHistoryChip,
                            onDismissAdultChildrenCoach: { vm.markAdultChildrenCoachSeen() },
                            firstQuickActionTeachLine: vm.firstQuickActionTeachLine(),
                            onDismissFirstQuickActionTeach: { vm.markFirstQuickActionTeachSeen() },
                            onLongPressPreview: { vm.markFirstLongPressTeachSeen() },
                            onDetail: { destination in
                                AppFeedback.impact(.light)
                                vm.openDetail(destination)
                            },
                            onQuickAction: { action in
                                vm.performQuickAction(action.choiceID, for: action.domain)
                            },
                            onSelectAction: { action in
                                AppFeedback.impact(.light)
                                vm.performQuickAction(action.choiceID, for: action.domain)
                            }
                        )

                        if currentDomain == .money {
                            housingHubCard
                        }
                    }

                    if currentDomain == .log, !bitLifeShell {
                        LifeLogView(history: vm.state.history)
                            .accessibilityIdentifier("history-tab-content")
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
        }
        // Content now includes risk/stance/ageup controls (moved from inset for space)
        .background(consoleBackground.ignoresSafeArea())
        .sheet(isPresented: $showResilienceSheet) {
            resilienceExplainSheet
        }
        .onAppear { syncConsoleSectionDefaults() }
        .onChange(of: panelCompact) { _, _ in syncConsoleSectionDefaults() }
    }

    private func syncConsoleSectionDefaults() {
        if panelCompact {
            expandedConsoleSections = []
        } else {
            expandedConsoleSections = ["pressures", "pace", "pulse"]
        }
    }

    private var backgroundPulseSummary: String {
        let pulses = vm.backgroundPulseItems()
        if pulses.isEmpty { return "Quiet" }
        if let first = pulses.first { return first.detail }
        return "\(pulses.count) signals"
    }

    private func lateGameContextRibbon(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(consoleSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityIdentifier("late-game-context-ribbon")
    }

    private func collapsibleConsoleSection<Content: View>(
        id: String,
        title: String,
        subtitle: String,
        tone: PlannerTone,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let isExpanded = expandedConsoleSections.contains(id)
        return VStack(alignment: .leading, spacing: 8) {
            Button {
                AppFeedback.impact(.light)
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    if isExpanded {
                        expandedConsoleSections.remove(id)
                    } else {
                        expandedConsoleSections.insert(id)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tone.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.caption.weight(.black))
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(tone.color)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(consoleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("console-section-\(id)-toggle")

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityIdentifier("console-section-\(id)")
    }

    private var adultChildrenFocusHistoryChip: String? {
        guard currentDomain == .people, !vm.state.discoverability.seenAdultChildrenCoach else { return nil }
        let adults = vm.state.family.children.filter { !$0.livesAtHome }
        guard !adults.isEmpty else { return nil }
        return DiscoverabilityTeaching.adultChildFocusHistoryLine
    }

    private var nowLaneCard: some View {
        NowLaneCard(snapshot: vm.nowLaneSnapshot(), canAct: vm.presentedCard == nil && vm.state.activeYearChapter == nil && !vm.state.isGameOver) {
            vm.performNowLaneQuickAction()
        }
    }

    private var castStripCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your circle")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.castStripMembers()) { member in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Image(systemName: member.icon)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.purple)
                                Text(member.name)
                                    .font(.caption.weight(.heavy))
                                    .lineLimit(1)
                            }
                            Text(member.roleLabel)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text(member.line)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(10)
                        .frame(width: 128, alignment: .leading)
                        .background(Color.purple.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityIdentifier("cast-member-\(member.id)")
                    }
                }
            }
        }
        .padding(12)
        .background(consoleSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("life-cast-strip")
    }

    private var glanceStrip: some View {
        let limit = panelCompact ? 2 : 3
        let pressures = Array(snapshot.topPressures.prefix(limit))
        return Group {
            if !pressures.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text("At a glance")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                    }
                    ForEach(pressures) { pressure in
                        HStack(spacing: 6) {
                            Image(systemName: iconForPressureTitle(pressure.title))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(pressure.tone.color)
                                .frame(width: 14)
                            Text(pressure.title)
                                .font(.caption2.weight(.heavy))
                                .lineLimit(1)
                            Text(pressure.value)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(pressure.tone.color)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(consoleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityIdentifier("glance-pressure-strip")
            }
        }
    }

    /// Horizontal top-3 audit chips — always visible in compact late-game header.
    private var glanceAuditStrip: some View {
        let chips = vm.glanceAuditChips(limit: 3)
        return Group {
            if !chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(chips) { chip in
                            Button {
                                AppFeedback.impact(.light)
                                if let dest = vm.plannerDestination(forUrgencyItemTitle: chip.title) {
                                    vm.openDetail(dest)
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: chip.icon)
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(chip.tone.color)
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(chip.title)
                                            .font(.system(size: 8, weight: .heavy))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        Text(chip.value)
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundStyle(chip.tone.color)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(chip.tone.fill)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("glance-audit-\(chip.id)")
                        }
                    }
                }
                .accessibilityIdentifier("glance-audit-strip")
            }
        }
    }

    private var compactCastStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(vm.castStripMembers()) { member in
                    HStack(spacing: 4) {
                        Image(systemName: member.icon)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.purple)
                        Text(member.name)
                            .font(.system(size: 9, weight: .heavy))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Capsule(style: .continuous))
                    .accessibilityIdentifier("cast-member-\(member.id)")
                }
            }
        }
        .accessibilityIdentifier("life-cast-strip-compact")
    }

    private var healthActivitiesDeck: some View {
        VStack(alignment: .leading, spacing: 12) {
            HealthActivitiesPanel(
                state: vm.state,
                categories: vm.activityCategories(),
                activitiesForCategory: { vm.activities(in: $0) },
                statusLine: vm.activityThisYearStatus(),
                onPerformActivity: { vm.performActivity($0) }
            )

            if vm.showsLuxurySuite {
                LuxurySuiteCard(vm: vm) { action in
                    vm.performQuickAction(action.choiceID, for: action.domain)
                }
            }
        }
        .accessibilityIdentifier("health-activities-deck")
    }

    private var resilienceExplainSheet: some View {
        let isResilient = vm.state.resilience == .resilient
        return NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Label(isResilient ? "Resilient" : "Grounded", systemImage: isResilient ? "shield.fill" : "exclamationmark.triangle.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(isResilient ? Color.green : Color.orange)
                Text(vm.state.resilience.description)
                    .font(.body)
                Text(isResilient
                     ? "Forecasts and recoveries leave more slack. Spirals are softer — the life still bites, but bends."
                     : "Setbacks hit at full weight. Choosing rest or care in a bad year is a real win, not a given.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Got It") {
                        vm.markResilienceExplainSeen()
                        showResilienceSheet = false
                    }
                }
            }
            .onAppear {
                if !vm.state.discoverability.seenResilienceExplain {
                    vm.markResilienceExplainSeen()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var consoleHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Phase 6: Cleaner flowing header with prominent settings gear at top right
            HStack(alignment: .center) {
                Button {
                    AppFeedback.impact(.light)
                    onOpenFeed()
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(snapshot.name)
                            .font(.system(size: 22, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        HStack(spacing: 6) {
                            Text("Age \(snapshot.age)")
                            Text("•")
                            Text(snapshot.role)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            resiliencePill
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("open-life-feed-button")

                Spacer()

                // Flowing settings gear at top right
                Button {
                    AppFeedback.impact(.light)
                    onSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings-button")
            }

            HStack(spacing: 12) {
                quickStat(title: "Cash", value: snapshot.cash, tone: snapshot.cashTone)
                quickStat(title: "Health", value: "\(snapshot.health)%", tone: snapshot.healthTone)
                quickStat(title: "Pattern", value: snapshot.selectedAction, tone: vm.state.actionMemory.latestAction == nil ? .neutral : .positive)
            }

            if compactLateGame {
                glanceAuditStrip
            }

            if !vm.recentInstantReactions.isEmpty || vm.state.instantMomentum.isVisible {
                instantMomentumStrip
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.recentInstantReactions.count)
            }
        }
        .padding(14)
        .background(consoleSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var instantMomentumStrip: some View {
        let momentum = vm.state.instantMomentum
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    withAnimation { showedMomentumHint.toggle() }
                    if showedMomentumHint { vm.markMomentumCoachSeen() }
                } label: {
                    Image(systemName: showedMomentumHint ? "questionmark.circle.fill" : "globe")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.purple)
                        .padding(.leading, 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Explain momentum")
                .accessibilityIdentifier("momentum-explain-button")

                if showedMomentumHint {
                    Text(momentum.buildHint(resilience: vm.state.resilience))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.purple.opacity(0.9))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                        .accessibilityIdentifier("momentum-build-hint")
                } else {
                    if momentum.isVisible {
                        ForEach(momentum.rankedDomainMomentum, id: \.domain) { entry in
                            momentumDomainBar(domain: entry.domain, value: entry.value)
                        }
                    }
                    ForEach(Array(vm.recentInstantReactions.prefix(3).enumerated()), id: \.element) { _, reaction in
                        momentumChip(reaction)
                    }
                    // P2: life-shape subtitle for D4 prominence and reactivity (using VM computed)
                    let shape = vm.currentLifeShape
                    if !shape.isEmpty {
                        Text("Shape: \(shape)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(shape.contains("loose") ? Color.orange : (shape.contains("driven") ? Color.purple : Color.green))
                            .padding(.leading, 4)
                            .accessibilityLabel("Current life shape: \(shape)")
                            .accessibilityHint("Your recent focus choices are writing this shape. It affects quiet years, autonomy, and legacy.")
                    }
                }

                if !vm.recentInstantReactions.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.3)) { vm.clearInstantReactions() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.purple.opacity(0.55))
                    }
                    .padding(.trailing, 4)
                }
            }
        }
        .frame(minHeight: 28)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassCard(radius: DesignSystem.Radius.medium)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: vm.recentInstantReactions.count)
        .accessibilityIdentifier("instant-momentum-strip")
    }

    private func momentumDomainBar(domain: ActionDomain, value: Int) -> some View {
        let tone = momentumTone(for: domain)
        let label = momentumLabel(for: domain)
        return HStack(spacing: 4) {
            Image(systemName: momentumIcon(for: domain))
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(tone.color)
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(tone.color)
            Text("\(value)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(tone.color.opacity(0.85))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(tone.fill.opacity(0.6))
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(tone.color.opacity(0.15), lineWidth: 1)
        )
        .accessibilityIdentifier("momentum-domain-\(domain.rawValue)")
    }

    private func momentumTone(for domain: ActionDomain) -> PlannerTone {
        switch domain {
        case .health: return .positive
        case .finance: return .warning
        case .relationships: return .neutral
        default: return .neutral
        }
    }

    private func momentumLabel(for domain: ActionDomain) -> String {
        switch domain {
        case .health: return "Body"
        case .finance: return "Money"
        case .relationships: return "People"
        default: return "Focus"
        }
    }

    private func momentumIcon(for domain: ActionDomain) -> String {
        switch domain {
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .relationships: return "person.2.fill"
        default: return "sparkles"
        }
    }

    private func momentumChip(_ reaction: String) -> some View {
        let tone = reactionTone(for: reaction)
        return HStack(spacing: 5) {
            Image(systemName: iconForReaction(reaction))
                .font(.caption2.weight(.bold))
                .foregroundStyle(tone.color)
            Text(reaction)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tone.color.opacity(0.95))
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(tone.fill.opacity(0.6))
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(tone.color.opacity(0.15), lineWidth: 1)
        )
    }

    private func reactionTone(for reaction: String) -> PlannerTone {
        if reaction.contains("Financial") || reaction.contains("Resourcefulness") || reaction.contains("Money") { return .warning }
        if reaction.contains("Mental") || reaction.contains("Body") || reaction.contains("Health") { return .positive }
        if reaction.contains("Bond") || reaction.contains("Responded") || reaction.contains("Word Spread") { return .neutral }
        return .neutral
    }

    private func iconForReaction(_ reaction: String) -> String {
        if reaction.contains("Mental") || reaction.contains("Body") || reaction.contains("Health") { return "heart.fill" }
        if reaction.contains("Financial") || reaction.contains("Resourcefulness") { return "dollarsign.circle.fill" }
        if reaction.contains("Bond") || reaction.contains("Responded") || reaction.contains("Word Spread") { return "person.2.fill" }
        return "sparkles"
    }

    private func quickStat(title: String, value: String, tone: PlannerTone) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tone.color)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(radius: 12)
    }


    /// Very small, low-attention indicator so the player always knows which replayability mode they're in.
    private var resiliencePill: some View {
        // Phase 4: More visible but still subtle Life Feel indicator (replayability core)
        let isResilient = vm.state.resilience == .resilient
        return HStack(spacing: 3) {
            Image(systemName: isResilient ? "shield.fill" : "exclamationmark.triangle.fill")
                .font(.caption2.weight(.bold))
            Text(isResilient ? "Resilient" : "Grounded")
                .font(.system(size: 9, weight: .black))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(isResilient ? Color.green.opacity(0.15) : Color.orange.opacity(0.18))
        .foregroundStyle(isResilient ? Color.green : Color.orange)
        .clipShape(Capsule(style: .continuous))
        .accessibilityLabel("Life feel: \(vm.state.resilience.displayName)")
        .onTapGesture {
            AppFeedback.impact(.light)
            showResilienceSheet = true
        }
    }

    private var pressureDeck: some View {
        pressureDeckContent
    }

    private var pressureDeckContent: some View {
        // Phase 6: Glance-optimized (icons derived from title + short text)
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Secondary Pressures")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                Text(vm.state.resilience.shortLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(vm.state.resilience == .grounded ? Color.orange : Color.green)
                if vm.hasHarshConsolePressure {
                    Text(DiscoverabilityTeaching.harshYearConsoleSubtitle(resilience: vm.state.resilience))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(vm.state.resilience == .grounded ? Color.orange.opacity(0.9) : Color.green.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("harsh-year-resilience-subtitle")
                }
            }

            if secondaryPressures.isEmpty {
                Text("The primary audit already contains every active pressure.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ForEach(secondaryPressures) { pressure in
                HStack(spacing: 8) {
                    Image(systemName: iconForPressureTitle(pressure.title))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(pressure.tone.color)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(pressure.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text(pressure.value)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(pressure.tone.color)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .padding(8)
                .background(consoleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onTapGesture {
                    if let destination = vm.plannerDestination(forUrgencyItemTitle: pressure.title) {
                        vm.openDetail(destination)
                    }
                }
            }
        }
    }

    private func iconForPressureTitle(_ title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("money") || lower.contains("finance") { return "dollarsign.circle" }
        if lower.contains("work") || lower.contains("school") || lower.contains("career") { return "briefcase" }
        if lower.contains("social") || lower.contains("relationship") { return "person.2" }
        if lower.contains("burnout") || lower.contains("health") { return "heart" }
        return "exclamationmark.triangle"
    }

    private var autoLifePaceCard: some View {
        autoLifePaceCardContent
            .padding(14)
            .background(consoleSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityIdentifier("home-auto-life")
    }

    private var autoLifePaceCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Auto-Life Pace", systemImage: "forward.end.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(vm.autoLifePace.title)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(vm.autoLifePace == .autopilot ? PlannerTone.positive.color : .secondary)
            }

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
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(vm.autoLifePace == .autopilot ? "Autopilot bias" : "Guided pick")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.secondary)
                            Text(recommendation.title)
                                .font(.subheadline.weight(.black))
                                .lineLimit(2)
                            Text("Why: \(recommendation.cost)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(recommendation.tone.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("guided-recommendation-button")
            }
        }
    }

    private var backgroundPulseDeck: some View {
        backgroundPulseDeckContent
            .accessibilityIdentifier("home-background-pulse")
    }

    private var backgroundPulseDeckContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !compactLateGame {
                Text("Background Pulse")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
            }

            let pulses = vm.backgroundPulseItems()
            if pulses.isEmpty {
                Text("No background pressure is asking for attention.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(consoleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ForEach(pulses) { pulse in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(pulse.tone.color)
                            .frame(width: 8, height: 8)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pulse.title)
                                .font(.caption.weight(.black))
                            Text(pulse.detail)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(consoleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityIdentifier("background-pulse-item")
                }
            }
        }
    }

    private var housingHubCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Housing", systemImage: "house.fill")
                    .font(.headline.weight(.bold))
                Spacer()
                Button("Details") {
                    vm.openDetail(.lifeHousing)
                }
                .font(.caption.weight(.black))
                .buttonStyle(.bordered)
            }
            HStack(spacing: 8) {
                quickStat(title: "Setup", value: vm.housingArrangementLabel(), tone: .neutral)
                quickStat(title: "Stability", value: "\(vm.state.housing.housingStability)", tone: vm.state.housing.housingStability < 40 ? .warning : .neutral)
                quickStat(title: "Home", value: vm.state.assets.ownsHome ? "Owned" : "Renting", tone: vm.state.assets.ownsHome ? .positive : .neutral)
            }
        }
        .padding(12)
        .background(consoleSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("life-housing-hub-card")
    }

    private var assetSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Assets", systemImage: "shippingbox.fill")
                    .font(.headline.weight(.bold))
                Spacer()
                Button("Ledger") {
                    vm.openDetail(.lifeHousing)
                }
                .font(.caption.weight(.bold))
                .buttonStyle(.bordered)
                .accessibilityIdentifier("life-housing-detail-button")
            }

            HStack(spacing: 8) {
                quickStat(title: "Home", value: vm.state.assets.ownsHome ? "Owned" : "None", tone: vm.state.assets.ownsHome ? .positive : .neutral)
                quickStat(title: "Vehicles", value: "\(vm.state.assets.vehicles.count)", tone: .neutral)
                quickStat(title: "Collectibles", value: "\(vm.state.assets.jewelry.count + vm.state.assets.aviation.count + vm.state.assets.marine.count)", tone: .neutral)
            }
        }
        .padding(14)
        .background(consoleSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityIdentifier("assets-housing-legacy-section")
    }

    private var consoleBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [DesignSystem.Colors.backgroundDark, Color(red: 0.12, green: 0.11, blue: 0.18)]
                : [DesignSystem.Colors.lightBackgroundStart, DesignSystem.Colors.lightBackgroundEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var consoleSurface: Color {
        colorScheme == .dark ? Color(white: 0.1, opacity: 0.8) : Color.white.opacity(0.85)
    }

    private func consoleDomain(for tab: GameViewModel.Tab) -> ConsoleDomain {
        switch tab {
        case .home: return .life
        case .occupation: return .work
        case .assets: return .money
        case .relationships: return .people
        case .activities: return .activities
        case .history: return .log
        }
    }

    private func homeUrgencyIdentifier(for title: String) -> String {
        switch title {
        case "Money Pressure": return "home-urgency-money"
        case "School Momentum": return "home-urgency-school"
        case "Work Stability": return "home-urgency-work"
        case "Social Life": return "home-urgency-social"
        case "Burnout": return "home-urgency-burnout"
        default: return "home-urgency-row"
        }
    }
}

// MARK: - BitLife Instant Hub (Play tab)

private struct ActivitiesInstantHubView: View {
    @ObservedObject var vm: GameViewModel
    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        let sections = vm.instantHubSections()
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.positive)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Right Now")
                        .font(.title3.weight(.black))
                    Text("Every tap resolves instantly — deltas, momentum, fame, ledger.")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, 2)

            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: section.symbol)
                            .font(.caption.weight(.black))
                            .foregroundStyle(section.isLuxury ? Color(red: 0.75, green: 0.55, blue: 0.12) : .secondary)
                        Text(section.title)
                            .font(.caption.weight(.black))
                            .foregroundStyle(section.isLuxury ? Color(red: 0.55, green: 0.38, blue: 0.05) : .secondary)
                    }

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(section.items) { item in
                            Button {
                                vm.performInstantHubItem(item)
                            } label: {
                                InstantHubTile(item: item)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("instant-hub-\(item.id)")
                        }
                    }
                }
                .padding(section.isLuxury ? 10 : 0)
                .background(
                    Group {
                        if section.isLuxury {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.98, green: 0.94, blue: 0.82).opacity(0.45))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color(red: 0.85, green: 0.65, blue: 0.15).opacity(0.45), lineWidth: 1)
                                )
                        }
                    }
                )
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("activities-tab-content")
    }
}

private struct InstantHubTile: View {
    let item: GameViewModel.InstantHubItem

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(item.isLuxury ? Color(red: 0.55, green: 0.38, blue: 0.05) : item.tone.color)
            Text(item.title)
                .font(.system(size: 10, weight: .heavy))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.primary)
            Text(item.subtitle)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(item.isLuxury ? Color.white.opacity(0.85) : item.tone.fill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(item.isLuxury ? Color(red: 0.75, green: 0.55, blue: 0.12).opacity(0.35) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Domain Glance Panel (BitLife domain tabs)

@ViewBuilder
private func domainInstantDeckSection(
    model: DomainPanelModel,
    showLongPressCoach: Bool,
    firstQuickActionTeachLine: String? = nil,
    showLongPressFooter: Bool = false,
    onDismissFirstQuickActionTeach: (() -> Void)? = nil,
    onLongPressPreview: (() -> Void)?,
    onQuickAction: @escaping (ActionPresentationModel) -> Void
) -> some View {
    if !model.quickActions.isEmpty {
        ActionTray(
            title: "Right Now",
            actions: model.quickActions,
            selectedBadge: "DONE",
            accessibilityPrefix: "quick-action",
            onSelect: onQuickAction,
            previewProvider: model.previewProvider,
            showHoldHint: showLongPressCoach,
            showLongPressFooter: showLongPressFooter,
            firstQuickActionTeachLine: firstQuickActionTeachLine,
            onDismissFirstQuickActionTeach: onDismissFirstQuickActionTeach,
            onPreviewActivated: onLongPressPreview
        )
    }

    if !model.familyQuickActions.isEmpty {
        ActionTray(
            title: "Family — Right Now",
            actions: model.familyQuickActions,
            selectedBadge: "DONE",
            accessibilityPrefix: "family-quick-action",
            onSelect: onQuickAction,
            previewProvider: model.previewProvider,
            showHoldHint: showLongPressCoach,
            showLongPressFooter: showLongPressFooter,
            onPreviewActivated: onLongPressPreview
        )
    }

    if !model.riskQuickActions.isEmpty {
        ActionTray(
            title: "Risk — Right Now",
            actions: model.riskQuickActions,
            selectedBadge: "DONE",
            accessibilityPrefix: "risk-quick-action",
            onSelect: onQuickAction,
            previewProvider: model.previewProvider,
            showHoldHint: showLongPressCoach,
            showLongPressFooter: showLongPressFooter,
            onPreviewActivated: onLongPressPreview
        )
    }
}

private struct DomainGlancePanelView: View {
    let model: DomainPanelModel
    @ObservedObject var vm: GameViewModel
    var adultChildrenGlance: [GameViewModel.AdultChildGlanceItem] = []
    var adultChildrenFocusChip: String? = nil
    var onDismissAdultChildrenCoach: (() -> Void)? = nil
    var showLongPressCoach: Bool = false
    var firstQuickActionTeachLine: String? = nil
    var onDismissFirstQuickActionTeach: (() -> Void)? = nil
    var onLongPressPreview: (() -> Void)? = nil
    let onQuickAction: (ActionPresentationModel) -> Void
    let onDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("")
                .frame(width: 1, height: 1)
                .accessibilityIdentifier(accessibilityIdentifier)

            if !model.quickActions.isEmpty || !model.familyQuickActions.isEmpty || !model.riskQuickActions.isEmpty {
                domainInstantDeckSection(
                    model: model,
                    showLongPressCoach: showLongPressCoach,
                    firstQuickActionTeachLine: firstQuickActionTeachLine,
                    showLongPressFooter: !vm.state.discoverability.seenFirstLongPressTeach,
                    onDismissFirstQuickActionTeach: onDismissFirstQuickActionTeach,
                    onLongPressPreview: onLongPressPreview,
                    onQuickAction: onQuickAction
                )
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title)
                        .font(.headline.weight(.black))
                    Text(model.status)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(model.tone.color)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if let destination = model.detailDestination {
                    Button("Details") { onDetail(destination) }
                        .font(.caption.weight(.black))
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier(model.detailButtonIdentifier ?? "\(model.id.rawValue)-detail-button")
                }
            }

            HStack(spacing: 8) {
                ForEach(Array(model.metrics.prefix(3))) { metric in
                    ConsoleMetricTile(metric: metric)
                }
            }
            .accessibilityIdentifier("\(model.id.rawValue)-overview-audit")

            if !vm.glanceAuditChips(limit: 3).isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(vm.glanceAuditChips(limit: 3)) { chip in
                            HStack(spacing: 4) {
                                Image(systemName: chip.icon)
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(chip.tone.color)
                                Text(chip.value)
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(chip.tone.color)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(chip.tone.fill)
                            .clipShape(Capsule())
                        }
                        if vm.state.instantMomentum.isVisible {
                            HStack(spacing: 4) {
                                Image(systemName: "globe.americas.fill")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(Color.purple)
                                Text("Mom \(vm.state.instantMomentum.overallStrength)")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(Color.purple)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        if vm.state.fame.culturalFame >= 45 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(.orange)
                                Text("\(vm.state.fame.culturalFame)")
                                    .font(.system(size: 9, weight: .heavy))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            adultChildrenGlanceSection(
                adultChildrenGlance: adultChildrenGlance,
                focusChip: adultChildrenFocusChip,
                onDismissFocusChip: onDismissAdultChildrenCoach
            )

            glanceHighlightRow(
                icon: model.tone == .warning ? "exclamationmark.triangle.fill" : "checkmark.seal.fill",
                title: model.tone == .warning ? "Top pressure" : "Status",
                detail: model.pressureLine,
                tone: model.tone,
                destination: model.detailDestination
            )

            if !model.velocity.isEmpty, model.detailDestination != nil {
                glanceHighlightRow(
                    icon: "arrow.triangle.branch",
                    title: "Trajectory",
                    detail: model.velocity,
                    tone: .neutral,
                    destination: model.detailDestination
                )
            }

            Button {
                AppFeedback.impact(.light)
                vm.selectedTab = .activities
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("More instant actions on Play tab")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(10)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("\(model.id.rawValue)-open-play-tab")
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func glanceHighlightRow(
        icon: String,
        title: String,
        detail: String,
        tone: PlannerTone,
        destination: PlannerDetailDestination?
    ) -> some View {
        Button {
            AppFeedback.impact(.light)
            if let destination { onDetail(destination) }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(tone.color)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if destination != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(10)
            .background(tone.fill)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(destination == nil)
    }

    private var accessibilityIdentifier: String {
        switch model.id {
        case .life: return "home-tab-content"
        case .work: return model.title == "Education" ? "education-tab-content" : "career-tab-content"
        case .money: return "finance-tab-content"
        case .people: return "relationships-tab-content"
        case .activities: return "activities-tab-content"
        case .body: return "health-tab-content"
        case .log: return "history-console-content"
        }
    }
}

private struct DomainPanelView: View {
    let model: DomainPanelModel
    var compactMode: Bool = false
    var bitLifeMode: Bool = false
    var forceExpandYearPlan: Bool = false
    var adultChildrenGlance: [GameViewModel.AdultChildGlanceItem] = []
    @State private var yearPlanExpanded = false
    @State private var familyTrayExpanded = false
    @State private var riskTrayExpanded = false
    var showLongPressCoach: Bool = false
    var adultChildrenFocusChip: String? = nil
    var onDismissAdultChildrenCoach: (() -> Void)? = nil
    var firstQuickActionTeachLine: String? = nil
    var onDismissFirstQuickActionTeach: (() -> Void)? = nil
    var onLongPressPreview: (() -> Void)? = nil
    let onDetail: (PlannerDetailDestination) -> Void
    let onQuickAction: (ActionPresentationModel) -> Void
    let onSelectAction: (ActionPresentationModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("")
                .frame(width: 1, height: 1)
                .accessibilityIdentifier(accessibilityIdentifier)

            HStack(alignment: .top, spacing: bitLifeMode ? 8 : 12) {
                if !bitLifeMode {
                    Image(systemName: model.icon)
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(model.tone.color)
                        .frame(width: 42, height: 42)
                        .background(model.tone.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title)
                        .font(bitLifeMode ? .headline.weight(.black) : .title2.weight(.black))
                    Text(model.status)
                        .font(bitLifeMode ? .caption.weight(.bold) : .subheadline.weight(.bold))
                        .foregroundStyle(model.tone.color)
                        .lineLimit(bitLifeMode ? 1 : 2)
                }

                Spacer(minLength: 0)

                if let destination = model.detailDestination {
                    Button(bitLifeMode ? "More" : "Details") {
                        onDetail(destination)
                    }
                    .font(.caption.weight(.black))
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(model.detailButtonIdentifier ?? "\(model.id.rawValue)-detail-button")
                }
            }

            if !compactMode, !bitLifeMode {
                Text(model.velocity)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                ForEach(Array(model.metrics.prefix(compactMode ? 3 : model.metrics.count))) { metric in
                    ConsoleMetricTile(metric: metric)
                }
            }
            .accessibilityIdentifier("\(model.id.rawValue)-overview-audit")

            adultChildrenGlanceSection(
                adultChildrenGlance: adultChildrenGlance,
                focusChip: adultChildrenFocusChip,
                onDismissFocusChip: onDismissAdultChildrenCoach
            )

            if !bitLifeMode || model.tone == .warning {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: model.tone == .warning ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                        .foregroundStyle(model.tone.color)
                        .padding(.top, 2)
                    Text(model.pressureLine)
                        .font(compactMode ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(compactMode ? 2 : 3)
                }
                .padding(12)
                .background(model.tone.fill)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier("\(model.id.rawValue)-overview-pressure")
            }

            if let secondary = model.secondaryAction {
                Button(action: secondary.action) {
                    HStack(spacing: 6) {
                        Image(systemName: secondary.icon)
                        Text(secondary.title)
                    }
                    .font(.caption.weight(.black))
                    .foregroundStyle(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }

            domainInstantDeckSection(
                model: model,
                showLongPressCoach: showLongPressCoach,
                firstQuickActionTeachLine: firstQuickActionTeachLine,
                showLongPressFooter: showLongPressCoach,
                onDismissFirstQuickActionTeach: onDismissFirstQuickActionTeach,
                onLongPressPreview: onLongPressPreview,
                onQuickAction: onQuickAction
            )

            if !model.familyActions.isEmpty {
                if compactMode && !forceExpandYearPlan {
                    actionTrayDisclosure(title: "Family — Year Plan", isExpanded: $familyTrayExpanded) {
                        ActionTray(title: "Family — Year Plan", actions: model.familyActions, selectedBadge: "SET", accessibilityPrefix: "family-action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider)
                    }
                } else {
                    ActionTray(title: "Family — Year Plan", actions: model.familyActions, selectedBadge: "SET", accessibilityPrefix: "family-action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider)
                }
            }

            if !model.riskActions.isEmpty {
                if compactMode {
                    actionTrayDisclosure(title: "Risk — Year Plan", isExpanded: $riskTrayExpanded) {
                        ActionTray(title: "Risk — Year Plan", actions: model.riskActions, selectedBadge: "SET", accessibilityPrefix: "risk-action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider)
                    }
                } else {
                    ActionTray(title: "Risk — Year Plan", actions: model.riskActions, selectedBadge: "SET", accessibilityPrefix: "risk-action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider)
                }
            }

            if let sections = model.actionSections, !sections.isEmpty {
                if bitLifeMode && !forceExpandYearPlan {
                    yearPlanDisclosure {
                        ForEach(sections) { section in
                            ActionTray(title: section.title, actions: section.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice-\(section.id)", onSelect: onSelectAction, previewProvider: model.previewProvider)
                        }
                    }
                } else {
                    ForEach(sections) { section in
                        ActionTray(title: section.title, actions: section.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice-\(section.id)", onSelect: onSelectAction, previewProvider: model.previewProvider)
                    }
                }
            } else if !model.actions.isEmpty {
                if bitLifeMode && !forceExpandYearPlan {
                    yearPlanDisclosure {
                        ActionTray(title: "Year Plan", actions: model.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider)
                    }
                } else {
                    ActionTray(title: "Year Plan", actions: model.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider)
                }
            }
        }
        .padding(bitLifeMode ? 12 : 16)
        .onAppear { syncYearPlanExpansion() }
        .onChange(of: forceExpandYearPlan) { _, _ in syncYearPlanExpansion() }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func syncYearPlanExpansion() {
        if forceExpandYearPlan {
            yearPlanExpanded = true
        }
    }

    @ViewBuilder
    private func yearPlanDisclosure<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        DisclosureGroup(isExpanded: $yearPlanExpanded) {
            content()
        } label: {
            Text("Year Plan")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("year-plan-disclosure")
    }

    @ViewBuilder
    private func actionTrayDisclosure<Content: View>(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            content()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var accessibilityIdentifier: String {
        switch model.id {
        case .life: return "home-tab-content"
        case .work: return model.title == "Education" ? "education-tab-content" : "career-tab-content"
        case .money: return "finance-tab-content"
        case .people: return "relationships-tab-content"
        case .activities: return "activities-tab-content"
        case .body: return "health-tab-content"
        case .log: return "history-console-content"
        }
    }
}

@ViewBuilder
private func adultChildrenGlanceSection(
    adultChildrenGlance: [GameViewModel.AdultChildGlanceItem],
    focusChip: String?,
    onDismissFocusChip: (() -> Void)?
) -> some View {
    if focusChip != nil || !adultChildrenGlance.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
            Text("Adult children")
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)

            if let chip = focusChip {
                Text(chip)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityIdentifier("adult-children-focus-chip")
            }

            if !adultChildrenGlance.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(adultChildrenGlance) { child in
                            Button {
                                onDismissFocusChip?()
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(child.name)
                                        .font(.caption.weight(.heavy))
                                        .lineLimit(1)
                                    Text("Age \(child.age) · \(child.outcomeLabel)")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(PlannerTone.neutral.fill)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("adult-child-glance-\(child.id)")
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("adult-children-glance-strip")
    }
}

private struct ConsoleMetricTile: View {
    let metric: ConsoleMetricModel

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(metric.title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(metric.value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(metric.tone.color)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(metric.tone.fill.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(metric.tone.color.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct ActionTrayCell: View {
    let action: ActionPresentationModel
    let useGrid: Bool
    let selectedBadge: String
    let accessibilityPrefix: String
    let showHoldHint: Bool
    let showLongPressFooter: Bool
    let isQuickDeck: Bool
    let previewProvider: ((ActionChoiceID) -> [String])?
    let previewedActionID: ActionChoiceID?
    let previewLines: [String]
    let onSelect: (ActionPresentationModel) -> Void
    let onPreviewActivated: (() -> Void)?
    let onClearPreview: () -> Void
    let onBeginPreview: (ActionChoiceID, [String]) -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var isPulsingHint = false

    var body: some View {
        Button {
            onSelect(action)
            onClearPreview()
        } label: {
            VStack(alignment: .leading, spacing: useGrid ? 5 : 6) {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: action.icon)
                        .font(.system(size: useGrid ? 18 : 16, weight: .black))
                        .foregroundStyle(action.tone.color)
                        .frame(width: useGrid ? 32 : 28, height: useGrid ? 32 : 28)
                        .background(action.tone.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.title)
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        if action.isSelected {
                            Text(selectedBadge)
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(PlannerTone.positive.color)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(PlannerTone.positive.fill)
                                .clipShape(Capsule())
                        }
                    }
                }

                Text(action.disabledReason ?? action.subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(action.disabledReason == nil ? .secondary : action.tone.color)
                    .lineLimit(2)

                if !useGrid {
                    HStack(spacing: 3) {
                        ForEach(action.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(action.tone.fill)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(useGrid ? 12 : 10)
            .frame(maxWidth: .infinity, minHeight: useGrid ? 80 : 52, alignment: .topLeading)
            .background(
                action.isSelected
                    ? PlannerTone.positive.fill.opacity(0.8)
                    : OLTheme.cardFill(colorScheme).opacity(0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium, style: .continuous)
                    .stroke(
                        action.isSelected
                            ? PlannerTone.positive.color.opacity(0.4)
                            : Color.primary.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .shadow(color: action.isSelected ? PlannerTone.positive.color.opacity(0.15) : Color.clear, radius: 8, y: 4)
            .onLongPressGesture(minimumDuration: 0.4) {
                guard let provider = previewProvider else { return }
                let lines = provider(action.choiceID)
                onBeginPreview(action.choiceID, lines.isEmpty ? ["Instant effect + possible reaction"] : lines)
                onPreviewActivated?()
                AppFeedback.impact(.medium)
            }
        }
        .buttonStyle(.plain)
        .disabled(action.disabledReason != nil)
        .accessibilityIdentifier("\(accessibilityPrefix)-\(action.choiceID.rawValue)")
        .overlay(alignment: .topTrailing) {
            if showHoldHint, previewProvider != nil, isQuickDeck, previewedActionID != action.choiceID {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.purple.opacity(isPulsingHint ? 0.8 : 0.3))
                    .scaleEffect(isPulsingHint ? 1.1 : 0.9)
                    .padding(8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            isPulsingHint = true
                        }
                    }
            }
            if let pid = previewedActionID, pid == action.choiceID, !previewLines.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(previewLines.prefix(2), id: \.self) { line in
                        Text(line)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    if showLongPressFooter {
                        Text(DiscoverabilityTeaching.longPressFooterLine)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.purple.opacity(0.95))
                    }
                }
                .padding(5)
                .background(Color.black.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .offset(x: 1, y: -1)
                .onTapGesture { onClearPreview() }
                .accessibilityIdentifier("long-press-preview-footer")
            }
        }
    }
}

private struct ActionTray: View {
    let title: String
    let actions: [ActionPresentationModel]
    let selectedBadge: String
    let accessibilityPrefix: String
    let onSelect: (ActionPresentationModel) -> Void
    var previewProvider: ((ActionChoiceID) -> [String])? = nil
    var showHoldHint: Bool = false
    var showLongPressFooter: Bool = false
    var firstQuickActionTeachLine: String? = nil
    var onDismissFirstQuickActionTeach: (() -> Void)? = nil
    var onPreviewActivated: (() -> Void)? = nil

    @State private var previewedActionID: ActionChoiceID? = nil
    @State private var previewLines: [String] = []
    @State private var isPulsingHeaderHint = false

    private var isQuickDeck: Bool {
        let lower = title.lowercased()
        return lower.contains("quick") || lower.contains("right now") || lower.contains("do now")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if isQuickDeck {
                    Image(systemName: "bolt.circle.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.green)
                }
                Text(isQuickDeck ? "Right Now" : title)
                    .font(isQuickDeck ? .subheadline.weight(.black) : .caption.weight(.black))
                    .foregroundStyle(isQuickDeck ? .primary : .secondary)
                if showHoldHint, previewProvider != nil, isQuickDeck {
                    Text("HOLD TO PREVIEW")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color.purple.opacity(isPulsingHeaderHint ? 0.95 : 0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(isPulsingHeaderHint ? 0.2 : 0.05))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.purple.opacity(isPulsingHeaderHint ? 0.4 : 0.1), lineWidth: 1)
                        )
                        .scaleEffect(isPulsingHeaderHint ? 1.05 : 0.98)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                isPulsingHeaderHint = true
                            }
                        }
                }
                if isQuickDeck {
                    Text("Instant — tap anytime")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.16))
                        .clipShape(Capsule())
                }
                Spacer(minLength: 0)
            }
            .accessibilityIdentifier("\(accessibilityPrefix)-deck-header")

            // Overhauled for real estate + BitLife-like instant actions per domain:
            // Use 2-col grid for "instant / quick / right now" sections so more actions are visible without scrolling.
            // Larger cards, better thumb ergonomics, full width use.
            let lowerTitle = title.lowercased()
            let useGrid = lowerTitle.contains("quick") || lowerTitle.contains("right now") || lowerTitle.contains("do now") || lowerTitle.contains("instant")
            let gridColumns = useGrid 
                ? [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)] 
                : [GridItem(.flexible())]

            LazyVGrid(columns: gridColumns, spacing: useGrid ? 8 : 6) {
                ForEach(actions) { action in
                    ActionTrayCell(
                        action: action,
                        useGrid: useGrid,
                        selectedBadge: selectedBadge,
                        accessibilityPrefix: accessibilityPrefix,
                        showHoldHint: showHoldHint,
                        showLongPressFooter: showLongPressFooter,
                        isQuickDeck: isQuickDeck,
                        previewProvider: previewProvider,
                        previewedActionID: previewedActionID,
                        previewLines: previewLines,
                        onSelect: onSelect,
                        onPreviewActivated: onPreviewActivated,
                        onClearPreview: {
                            previewedActionID = nil
                            previewLines = []
                        },
                        onBeginPreview: { choiceID, lines in
                            withAnimation {
                                previewedActionID = choiceID
                                previewLines = lines
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                if previewedActionID == choiceID {
                                    withAnimation {
                                        previewedActionID = nil
                                        previewLines = []
                                    }
                                }
                            }
                        }
                    )
                }
            }

            if isQuickDeck, let teach = firstQuickActionTeachLine {
                Text(teach)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.green.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                    .accessibilityIdentifier("first-quick-action-teach")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            onDismissFirstQuickActionTeach?()
                        }
                    }
            }
        }
        .padding(isQuickDeck ? 12 : 0)
        .background(
            Group {
                if isQuickDeck {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.green.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.green.opacity(0.28), lineWidth: 1.5)
                        )
                }
            }
        )
    }
}

private struct ConsoleRiskStrip: View {
    let signals: [AgeUpRiskSignal]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(signals) { signal in
                    Label(signal.title, systemImage: signal.symbol)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(signal.tone.color)
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(signal.tone.fill)
                        .clipShape(Capsule())
                }
            }
        }
        .accessibilityIdentifier("age-up-risk-preview")
    }
}

private struct NowLaneCard: View {
    let snapshot: NowLaneSnapshot
    let canAct: Bool
    let onQuickAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .foregroundStyle(snapshot.tone.color)
                Text("Now")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(snapshot.ageUpHint)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }

            Text(snapshot.headline)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(snapshot.tone.color)
                .lineLimit(2)

            Text(snapshot.detail)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if snapshot.showsQuickAction, let title = snapshot.quickActionTitle, canAct {
                Button(action: onQuickAction) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                        Text(title)
                            .font(.caption.weight(.heavy))
                            .lineLimit(1)
                        Spacer()
                        Text("Quick")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(snapshot.tone.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("now-lane-quick-action")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(snapshot.tone.fill.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(snapshot.tone.color.opacity(0.35), lineWidth: 1)
        )
        .accessibilityIdentifier("now-lane-card")
    }
}

private struct ConsoleActivityPulse: View {
    let pulse: ActivityPulse

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: pulse.tone == .warning ? "flame.fill" : "checkmark.circle.fill")
                .foregroundStyle(pulse.tone.color)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(pulse.title)
                    .font(.subheadline.weight(.black))
                Text(pulse.detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(pulse.tone.fill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("activity-pulse-banner")
    }
}

extension GameViewModel {
    func lifeConsoleSnapshot() -> LifeConsoleSnapshot {
        LifeConsoleSnapshot(
            name: state.player.name,
            age: state.player.age,
            role: headerOccupationHighlight().title,
            cash: formattedCashOnHand(),
            cashTone: state.finance.cashOnHand >= 0 ? .positive : .warning,
            health: state.player.health,
            healthTone: state.player.health < 45 ? .warning : .positive,
            topPressures: Array(feedUrgencyItems().prefix(3)),
            selectedAction: pendingActionSummary(),
            ageUpRisk: ageUpRiskPreviewSignals(),
            eraName: state.currentEra.displayName,
            eraIcon: state.currentEra.icon,
            eraTone: state.currentEra.tone
        )
    }

    func domainPanel(for domain: ConsoleDomain) -> DomainPanelModel {
        let registry = makeActionRegistry()
        let riskQuick = registry.isCrimeLaneActive() ? quickActionModels(for: .crime) : []
        let riskPlan = registry.isCrimeLaneActive() ? actionModels(for: .crime) : []
        let familyQuick = registry.familyPhaseIsActive() ? familyQuickActionModels(registry: registry) : []
        let familyPlan = registry.familyPhaseIsActive() ? familyYearPlanModels(registry: registry) : []

        switch domain {
        case .life:
            return DomainPanelModel(
                id: .life,
                title: "Life",
                icon: "figure.play",
                tone: feedUrgencyItems().contains(where: { $0.tone == .warning }) ? .warning : .neutral,
                status: chapterStatus(),
                velocity: nextDecisionPrompt().isEmpty ? pendingActionSummary() : nextDecisionPrompt(),
                metrics: [
                    ConsoleMetricModel(title: "Cash", value: formattedCashOnHand(), tone: state.finance.cashOnHand >= 0 ? .positive : .warning),
                    ConsoleMetricModel(title: "Health", value: "\(state.player.health)%", tone: bodyTone()),
                    ConsoleMetricModel(title: "Rep", value: "\(state.relationships.publicReputation)", tone: state.relationships.publicReputation < 35 ? .warning : .neutral)
                ],
                pressureLine: feedUrgencyItems().first(where: { $0.tone == .warning })?.value ?? "No loud pressure yet. Tap a right-now action or set a year stance.",
                quickActions: homeQuickActionModels(),
                actions: homeYearPlanModels(),
                actionSections: nil,
                riskQuickActions: riskQuick,
                riskActions: riskPlan,
                familyQuickActions: [],
                familyActions: [],
                detailDestination: nil,
                detailButtonIdentifier: nil,
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
            )
        case .work:
            if state.military.track != .inactive {
                return DomainPanelModel(
                    id: .work,
                    title: state.military.branch?.displayName ?? "Military",
                    icon: "shield.fill",
                    tone: state.military.isAWOL ? .warning : .neutral,
                    status: "\(state.military.rank) (\(state.military.specialty?.displayName ?? "Unspecialized"))",
                    velocity: state.military.isAWOL ? "You are AWOL! Desertion risk is high." : "Served: \(state.military.yearsServed)y. Contract: \(state.military.contractYearsRemaining)y. \(state.military.track.rawValue.capitalized).",
                    metrics: [
                        ConsoleMetricModel(title: "Fitness", value: "\(state.military.fitness)", tone: state.military.fitness < 40 ? .warning : .positive),
                        ConsoleMetricModel(title: "Discipline", value: "\(state.military.discipline)", tone: state.military.discipline < 40 ? .warning : .positive),
                        ConsoleMetricModel(title: "Trauma", value: "\(state.military.combatTrauma)", tone: state.military.combatTrauma > 40 ? .warning : .neutral)
                    ],
                    pressureLine: state.military.deploymentStatus == .activeCombat ? "ACTIVE COMBAT! Survival is the priority." : (state.military.combatTrauma > 50 ? "War trauma is bleeding into your daily stability." : "Duty and discipline are the backbone of your year."),
                    quickActions: quickActionModels(for: .military),
                    actions: actionModels(for: .military),
                    actionSections: nil,
                    riskQuickActions: riskQuick,
                    riskActions: riskPlan,
                    familyQuickActions: [],
                    familyActions: [],
                    detailDestination: .careerOverview,
                    detailButtonIdentifier: "military-overview-detail-button",
                    previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
                )
            }
            let actionDomain: ActionDomain = showingEducationAsPrimaryTab ? .education : .career
            return DomainPanelModel(
                id: .work,
                title: showingEducationAsPrimaryTab ? "Education" : "Career",
                icon: showingEducationAsPrimaryTab ? "book.closed.fill" : "briefcase.fill",
                tone: workTone(),
                status: showingEducationAsPrimaryTab ? educationStatusLine() : (state.career.specializedTrack != nil ? state.career.professionalRank : roleTitle()),
                velocity: showingEducationAsPrimaryTab ? "Applications, standing, and burnout decide what opens next." : "Performance, income, and burnout decide whether work becomes stability or drag.",
                metrics: showingEducationAsPrimaryTab ? consoleMetrics(teenSchoolClimateMetrics()) : [
                    ConsoleMetricModel(title: "Perf", value: "\(state.career.performance)", tone: state.career.performance >= 70 ? .positive : (state.career.performance < 45 ? .warning : .neutral)),
                    ConsoleMetricModel(title: "Income", value: "$\(state.career.annualIncome)", tone: state.career.annualIncome > 0 ? .positive : .warning),
                    ConsoleMetricModel(title: "Burnout", value: "\(state.career.burnout)", tone: state.career.burnout >= 58 ? .warning : .neutral)
                ],
                pressureLine: showingEducationAsPrimaryTab ? (teenPressureSources().first ?? "School is stable enough to plan deliberately.") : (state.career.status == .unemployed ? "Stable work is missing." : "Work is active, but performance still has to survive the year."),
                quickActions: quickActionModels(for: actionDomain),
                actions: actionModels(for: actionDomain),
                actionSections: nil,
                riskQuickActions: riskQuick,
                riskActions: riskPlan,
                familyQuickActions: [],
                familyActions: [],
                detailDestination: showingEducationAsPrimaryTab ? .educationOverview : .careerOverview,
                detailButtonIdentifier: showingEducationAsPrimaryTab ? "education-overview-detail-button" : "career-overview-detail-button",
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
            )
        case .money:
            return DomainPanelModel(
                id: .money,
                title: "Money",
                icon: "dollarsign.circle.fill",
                tone: moneyTone(),
                status: state.finance.lastYearBalanceDelta < 0 ? "Deficit pressure" : "Cash flow holding",
                velocity: "Net last year: \(signedCurrency(state.finance.lastYearBalanceDelta)). Stress \(state.finance.financialStress).",
                metrics: [
                    ConsoleMetricModel(title: "Cash", value: formattedCashOnHand(), tone: state.finance.cashOnHand >= 0 ? .positive : .warning),
                    ConsoleMetricModel(title: "Portfolio", value: "$\(state.finance.portfolio.totalValue)", tone: .positive),
                    ConsoleMetricModel(title: "Projected", value: "\(projectedNetFlow() >= 0 ? "+" : "")$\(projectedNetFlow())", tone: projectedNetFlow() < 0 ? .warning : .positive)
                ],
                pressureLine: state.finance.financialStress >= 45 || state.finance.lastYearBalanceDelta < 0 ? "Money is shaping the rest of life right now." : "Money is contained, but not comfortable enough to ignore.",
                quickActions: quickActionModels(for: .finance),
                actions: [],
                actionSections: financeActionSectionModels(registry: registry),
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: [],
                familyActions: [],
                detailDestination: .financeCashflow,
                detailButtonIdentifier: "finance-cashflow-detail-button",
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] },
                secondaryAction: ("Liquidate Low-Value Assets", "bag.badge.minus", { [weak self] in self?.sellLowValueAssets() })
            )
        case .people:
            return DomainPanelModel(
                id: .people,
                title: "People",
                icon: "person.2.fill",
                tone: peopleTone(),
                status: state.relationships.hasPartner ? "Partner active" : "\(state.relationships.friends.count) friends",
                velocity: "Bond, rumor heat, and family load decide how much support survives the year.",
                metrics: [
                    ConsoleMetricModel(title: "Friends", value: "\(state.relationships.friends.count)", tone: state.relationships.friends.isEmpty ? .warning : .positive),
                    ConsoleMetricModel(title: "Partner", value: "\(state.relationships.partnerBond)", tone: state.relationships.partnerBond < 45 && state.relationships.hasPartner ? .warning : .neutral),
                    ConsoleMetricModel(title: "Tension", value: "\(state.relationships.activeTensionCount)", tone: state.relationships.activeTensionCount > 0 ? .warning : .neutral)
                ],
                pressureLine: npcAutonomyPulse() ?? (state.relationships.activeTensionCount > 0 ? "Loose ends are making the year less stable." : "Relationships can absorb pressure if you keep them alive."),
                quickActions: quickActionModels(for: .relationships),
                actions: actionModels(for: .relationships),
                actionSections: nil,
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: familyQuick,
                familyActions: familyPlan,
                detailDestination: state.family.isPregnant || state.family.childCount > 0 ? .relationshipsFamily : .relationshipsConnections,
                detailButtonIdentifier: state.family.isPregnant || state.family.childCount > 0 ? "relationships-family-detail-button" : "relationships-connections-detail-button",
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
            )
        case .body:
            return DomainPanelModel(
                id: .body,
                title: "Body",
                icon: "heart.fill",
                tone: bodyTone(),
                status: state.player.health < 45 ? "Fragile" : "Holding",
                velocity: "Health, sleep, stress, and active conditions set the pace for every other domain.",
                metrics: [
                    ConsoleMetricModel(title: "Health", value: "\(state.player.health)", tone: bodyTone()),
                    ConsoleMetricModel(title: "Mental", value: "\(state.healthProfile.mentalWellness)", tone: state.healthProfile.mentalWellness < 45 ? .warning : .neutral),
                    ConsoleMetricModel(title: "Stress", value: "\(100 - state.healthProfile.mentalWellness)", tone: state.healthProfile.mentalWellness < 45 ? .warning : .neutral)
                ],
                pressureLine: !state.healthProfile.activeConditions.isEmpty ? "Active conditions need attention before they compound." : "Recovery is playable, but neglect will leak into work and relationships.",
                quickActions: quickActionModels(for: .health),
                actions: actionModels(for: .health),
                actionSections: nil,
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: [],
                familyActions: [],
                detailDestination: .healthOverview,
                detailButtonIdentifier: "health-overview-detail-button",
                previewProvider: { [weak self] choice in self?.previewAction(choice) ?? [] }
            )
        case .activities:
            return DomainPanelModel(
                id: .activities,
                title: "Play",
                icon: "sparkles",
                tone: .positive,
                status: activityThisYearStatus(),
                velocity: "Instant hub — every flex resolves now.",
                metrics: [
                    ConsoleMetricModel(title: "Health", value: "\(state.player.health)", tone: bodyTone()),
                    ConsoleMetricModel(title: "Relief", value: "\(state.activities.recoveryBalance)", tone: .positive),
                    ConsoleMetricModel(title: "Risk", value: "\(state.activities.riskLoad)", tone: state.activities.riskLoad >= 8 ? .warning : .neutral)
                ],
                pressureLine: activityPushbackSummary(),
                quickActions: [],
                actions: [],
                actionSections: nil,
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: [],
                familyActions: [],
                detailDestination: nil,
                detailButtonIdentifier: nil
            )
        case .log:
            return DomainPanelModel(
                id: .log,
                title: "Log",
                icon: "scroll.fill",
                tone: .neutral,
                status: "\(state.history.count) entries",
                velocity: state.history.first?.title ?? "Your story will build here after each year.",
                metrics: [
                    ConsoleMetricModel(title: "Years", value: "\(max(0, state.player.age - 14))", tone: .neutral),
                    ConsoleMetricModel(title: "Events", value: "\(state.history.count)", tone: .neutral),
                    ConsoleMetricModel(title: "Legacy", value: "\(state.progress.legacyScore)", tone: .neutral)
                ],
                pressureLine: "The log is for pattern recognition, not moment-to-moment play.",
                quickActions: [],
                actions: [],
                actionSections: nil,
                riskQuickActions: [],
                riskActions: [],
                familyQuickActions: [],
                familyActions: [],
                detailDestination: .lifeHistory,
                detailButtonIdentifier: "life-history-detail-button"
            )
        }
    }

    private func homeQuickActionModels() -> [ActionPresentationModel] {
        for pair in homeQuickActionChips() where quickActionChoices(for: pair.domain).contains(pair.choiceID) {
            return [quickActionPresentation(choiceID: pair.choiceID, domain: pair.domain)]
        }
        let preferredDomain = recommendedYearlyStance().domain
        let priorityDomains: [ActionDomain] = [preferredDomain].compactMap { $0 } + [.finance, .career, .relationships, .health, .education, .identity]  // D1: self work always surfaces in Life quicks
        for domain in priorityDomains {
            if let choiceID = quickActionChoices(for: domain).first {
                return [quickActionPresentation(choiceID: choiceID, domain: domain)]
            }
        }
        return []
    }

    private func homeYearPlanModels() -> [ActionPresentationModel] {
        let registry = makeActionRegistry()
        if let recommendation = guidedRecommendation(),
           registry.resolutionTier(for: recommendation.choiceID, domain: recommendation.domain) == .committed {
            return [actionPresentation(choiceID: recommendation.choiceID, domain: recommendation.domain)]
        }
        let stance = recommendedYearlyStance()
        if let domain = stance.domain,
           let choiceID = actionChoices(for: domain).first(where: {
               makeActionRegistry().resolutionTier(for: $0, domain: domain) == .committed
           }) {
            return [actionPresentation(choiceID: choiceID, domain: domain)]
        }
        return []
    }

    private func actionModels(for domain: ActionDomain, limit: Int = 12) -> [ActionPresentationModel] {
        let registry = makeActionRegistry()
        return actionChoices(for: domain)
            .filter { registry.resolutionTier(for: $0, domain: domain) == .committed }
            .prefix(limit)
            .map { actionPresentation(choiceID: $0, domain: domain) }
    }

    private func financeActionSectionModels(registry: DomainActionRegistry) -> [ActionSectionModel] {
        registry.financeActionSections().map { section in
            ActionSectionModel(
                id: section.id,
                title: "Year Plan — \(section.title)",
                actions: section.choices
                    .filter { registry.resolutionTier(for: $0, domain: .finance) == .committed }
                    .map { actionPresentation(choiceID: $0, domain: .finance) }
            )
        }
        .filter { !$0.actions.isEmpty }
    }

    private func familyQuickActionModels(registry: DomainActionRegistry) -> [ActionPresentationModel] {
        registry.familyPhaseQuickChoices().map { choiceID in
            let domain: ActionDomain = [.protectSleep, .rest, .seeDoctor, .pushThrough].contains(choiceID) ? .health : .relationships
            return quickActionPresentation(choiceID: choiceID, domain: domain)
        }
    }

    private func familyYearPlanModels(registry: DomainActionRegistry) -> [ActionPresentationModel] {
        registry.familyPhaseCommittedChoices().map { choiceID in
            let domain: ActionDomain = choiceID == .seeDoctor || choiceID == .protectSleep ? .health : .relationships
            return actionPresentation(choiceID: choiceID, domain: domain)
        }
    }

    private func quickActionModels(for domain: ActionDomain) -> [ActionPresentationModel] {
        quickActionChoices(for: domain).map { choiceID in
            quickActionPresentation(choiceID: choiceID, domain: domain)
        }
    }

    private func quickActionPresentation(choiceID: ActionChoiceID, domain: ActionDomain) -> ActionPresentationModel {
        var model = actionPresentation(choiceID: choiceID, domain: domain)
        model.title = QuickActionCatalog.title(for: choiceID)
        model.disabledReason = quickActionBlockReason(choiceID, domain: domain)
        model.isSelected = hasPerformedQuickAction(choiceID, domain: domain)
        return model
    }

    private func actionPresentation(choiceID: ActionChoiceID, domain: ActionDomain) -> ActionPresentationModel {
        let definition = ActionChoiceCatalog.definition(for: choiceID)
        let tone: PlannerTone = definition.baseFriction == .none ? .neutral : .warning
        return ActionPresentationModel(
            id: "\(domain)-\(choiceID.rawValue)",
            domain: domain,
            choiceID: choiceID,
            title: definition.title,
            subtitle: definition.subtitle,
            icon: actionIcon(for: definition),
            tone: tone,
            tags: Array(definition.previewTags.prefix(3)),
            disabledReason: definition.baseFriction == .locked ? "Locked right now" : nil,
            isSelected: selectedAction(for: domain) == choiceID
        )
    }

    private func consoleMetrics(_ items: [(String, String, PlannerTone)]) -> [ConsoleMetricModel] {
        items.prefix(3).map { ConsoleMetricModel(title: $0.0, value: $0.1, tone: $0.2) }
    }

    private func workTone() -> PlannerTone {
        if showingEducationAsPrimaryTab {
            return state.education.burnoutRisk >= 55 || state.education.attendancePressure >= 55 || state.education.schoolStanding < 40 ? .warning : .neutral
        }
        return state.career.status == .unemployed || state.career.performance < 45 || state.career.burnout >= 58 ? .warning : .neutral
    }

    private func moneyTone() -> PlannerTone {
        state.finance.financialStress >= 35 || state.finance.lastYearBalanceDelta < 0 || state.finance.cashOnHand < 0 ? .warning : .neutral
    }

    private func peopleTone() -> PlannerTone {
        state.relationships.activeTensionCount > 0 || (state.relationships.hasPartner && state.relationships.partnerBond < 45) || (state.relationships.friends.isEmpty && !state.relationships.hasPartner) ? .warning : .neutral
    }

    private func bodyTone() -> PlannerTone {
        state.player.health < 45 || state.healthProfile.mentalWellness < 45 || !state.healthProfile.activeConditions.isEmpty ? .warning : .positive
    }

    private func educationStatusLine() -> String {
        if state.education.stage == .university { return "University" }
        if state.education.stage == .tradeTraining { return "Trade training" }
        // D3: show branch
        if state.education.academicTrack == .honors { return "Honors track" }
        if state.education.academicTrack == .vocational { return "Trade/vocational" }
        return state.education.schoolStanding >= 70 ? "On track" : "Under pressure"
    }

    private func signedCurrency(_ value: Int) -> String {
        value >= 0 ? "$\(value)" : "-$\(abs(value))"
    }

    private func actionIcon(for definition: ActionChoiceDefinition) -> String {
        let tags = definition.previewTags.joined(separator: " ").lowercased()
        if tags.contains("money") || tags.contains("cash") || tags.contains("debt") { return "dollarsign.circle.fill" }
        if tags.contains("health") || tags.contains("sleep") || tags.contains("recovery") || tags.contains("stress") { return "heart.fill" }
        if tags.contains("friend") || tags.contains("bond") || tags.contains("belonging") || tags.contains("support") { return "person.2.fill" }
        if tags.contains("standing") || tags.contains("readiness") || tags.contains("school") { return "book.closed.fill" }
        if definition.baseFriction != .none { return "exclamationmark.triangle.fill" }
        return "bolt.fill"
    }

    var showsLuxurySuite: Bool {
        state.assets.lifestyleScore >= 50
            || state.finance.totalWealth >= 5_000_000
            || !state.assets.signatureAssets.isEmpty
            || state.fame.culturalFame >= 55
    }

    var luxurySuiteStatusLine: String {
        if !luxurySuiteActions().isEmpty {
            return "Lifestyle \(state.assets.lifestyleScore) · Fame \(state.fame.culturalFame)"
        }
        return "Elite tier locked · Lifestyle \(state.assets.lifestyleScore)"
    }

    func luxurySuiteActions() -> [ActionPresentationModel] {
        let luxuryIDs: [ActionChoiceID] = [
            .hostLuxuryEvent, .acquireLuxuryAsset, .indulgeInExcess, .displayWealth, .maintainLuxuryCollection,
            .flexLuxuryAsset, .liquidateLuxury, .upgradeCollection, .hostAtSignatureEstate
        ]
        return luxuryIDs.compactMap { choiceID in
            guard quickActionChoices(for: .finance).contains(choiceID) else { return nil }
            return quickActionPresentation(choiceID: choiceID, domain: .finance)
        }
    }
}

// MARK: - Housing Hub (Tier A)

private struct HousingHubCard: View {
    @ObservedObject var vm: GameViewModel
    var onOpenDetails: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var surface: Color {
        colorScheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.82)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Housing", systemImage: "house.fill")
                    .font(.headline.weight(.black))
                Spacer()
                Button("Details", action: onOpenDetails)
                    .font(.caption.weight(.black))
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("life-housing-detail-button")
            }

            if vm.state.assets.ownsHome, let home = vm.state.assets.primaryResidence {
                ownedHomeContent(home)
            } else if vm.state.player.age >= 18 {
                savingLaneContent
            } else {
                Text("Housing unlocks at 18 when you can rent, save, or buy.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityIdentifier("assets-housing-legacy-section")
    }

    @ViewBuilder
    private func ownedHomeContent(_ home: PrimaryResidenceState) -> some View {
        HStack(spacing: 8) {
            hubMetric(title: "Value", value: "$\(home.totalValue)", tone: .positive)
            hubMetric(title: "Equity", value: "$\(home.equity)", tone: .positive)
            hubMetric(title: "Reserve", value: "$\(home.maintenanceReserve)", tone: home.maintenanceReserve < 1_000 ? .warning : .neutral)
        }

        if home.status == .delinquent {
            Text("Mortgage delinquent — top up reserve or set Refinance on the year plan.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PlannerTone.warning.color)
        } else {
            Text("$\(home.monthlyMortgageCost)/mo mortgage · \(home.remainingMortgageYears) yrs left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }

        HStack(spacing: 8) {
            hubInstantButton(
                title: "Repair Reserve",
                symbol: "wrench.and.screwdriver.fill",
                id: "housing-top-up-reserve-button"
            ) {
                vm.performQuickAction(.topUpHouseReserve, for: .finance)
            }
            .disabled(vm.housingInstantReserveAmount() < 750)

            Button {
                AppFeedback.impact(.light)
                vm.sellProperty()
            } label: {
                Label("Sell", systemImage: "signpost.right.fill")
                    .font(.caption.weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .accessibilityIdentifier("housing-sell-home-button")
        }

        if !home.upgrades.isEmpty {
            Text("Upgrades: \(home.upgrades.map { $0.rawValue.capitalized }.joined(separator: ", "))")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }

        if !HouseUpgrade.allCases.filter({ !home.upgrades.contains($0) }).isEmpty {
            Text("Upgrades")
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HouseUpgrade.allCases.filter { !home.upgrades.contains($0) }, id: \.self) { upgrade in
                        HousingUpgradeChip(upgrade: upgrade) {
                            vm.upgradeHouse(upgrade)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var savingLaneContent: some View {
        let needed = vm.housingDownPaymentNeeded()
        let saved = vm.state.finance.homeDownPaymentSavings
        let progress = vm.housingFundProgress()

        HStack(spacing: 8) {
            hubMetric(title: "Setup", value: vm.housingArrangementLabel(), tone: .neutral)
            hubMetric(title: "Stability", value: "\(vm.state.housing.housingStability)", tone: vm.state.housing.housingStability < 40 ? .warning : .neutral)
            hubMetric(title: "Target", value: "$\(vm.housingTargetHomeValue())", tone: .positive)
        }

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("House fund")
                    .font(.caption.weight(.black))
                Spacer()
                Text("$\(saved) / $\(needed)")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(progress >= 1 ? PlannerTone.positive.color : .primary)
            }
            ProgressView(value: progress)
                .tint(PlannerTone.positive.color)
        }

        HStack(spacing: 8) {
            hubInstantButton(
                title: "Deposit $\(vm.housingInstantDepositAmount())",
                symbol: "banknote.fill",
                id: "housing-deposit-fund-button"
            ) {
                vm.performQuickAction(.depositToHouseFund, for: .finance)
            }
            .disabled(vm.housingInstantDepositAmount() < 500)

            Button(action: onOpenDetails) {
                Label("Buy path", systemImage: "map.fill")
                    .font(.caption.weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("housing-buy-path-button")
        }

        Text(saved + vm.state.finance.cashOnHand >= needed
             ? "You may qualify to set Buy Home on the year plan this year."
             : "Deposit now, then set Save For Home before Age Up.")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func hubMetric(title: String, value: String, tone: PlannerTone) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.heavy))
                .foregroundStyle(tone.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func hubInstantButton(title: String, symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button {
            AppFeedback.impact(.light)
            action()
        } label: {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(.primary)
                .background(Color.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

private struct HousingUpgradeChip: View {
    let upgrade: HouseUpgrade
    let onUpgrade: () -> Void

    var body: some View {
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: 3) {
                Text(upgrade.rawValue.capitalized)
                    .font(.caption2.weight(.heavy))
                    .lineLimit(1)
                Text("$\(upgrade.cost)")
                    .font(.system(size: 9, weight: .bold))
                Text("+\(upgrade.valueBoost)")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.green)
            }
            .frame(width: 96, height: 58)
            .padding(6)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("housing-upgrade-\(upgrade.rawValue)")
    }
}

/// Activities in the Health console — compact category picker + instant rows.
private struct HealthActivitiesPanel: View {
    let state: GameState
    let categories: [ActivityCategory]
    let activitiesForCategory: (ActivityCategory) -> [ActivityDefinition]
    let statusLine: String
    let onPerformActivity: (String) -> Void

    @State private var selectedCategory: ActivityCategory = .mindBody

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.positive)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activities")
                        .font(.headline.weight(.black))
                    Text(statusLine)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { category in
                        Button {
                            AppFeedback.impact(.light)
                            selectedCategory = category
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category.symbol)
                                Text(category.title)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(selectedCategory == category ? Color.white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.black : Color.primary.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(spacing: 8) {
                ForEach(activitiesForCategory(selectedCategory)) { activity in
                    Button {
                        onPerformActivity(activity.id)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: activity.category.symbol)
                                .foregroundStyle(PlannerTone.neutral.color)
                                .frame(width: 32, height: 32)
                                .background(PlannerTone.neutral.fill)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(activity.costLine)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(DesignSystem.Colors.positive)
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("activity-\(activity.id)")
                }
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("activities-tab-content")
    }
}

/// Elite lifestyle actions — visually separated from everyday activities.
private struct LuxurySuiteCard: View {
    @ObservedObject var vm: GameViewModel
    let onQuickAction: (ActionPresentationModel) -> Void

    private var actions: [ActionPresentationModel] { vm.luxurySuiteActions() }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.15))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Luxury Suite")
                        .font(.headline.weight(.black))
                    Text(vm.luxurySuiteStatusLine)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }

            if actions.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    Text("Reach elite wealth or lifestyle score 75+ to unlock gala, collection, and flex moves.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.85, green: 0.65, blue: 0.15).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(actions) { action in
                            Button {
                                AppFeedback.impact(.medium)
                                onQuickAction(action)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: action.icon)
                                        .font(.system(size: 14, weight: .bold))
                                    Text(action.title)
                                        .font(.system(size: 8, weight: .heavy))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(width: 72)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 6)
                                .foregroundStyle(Color(red: 0.55, green: 0.38, blue: 0.05))
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.98, green: 0.92, blue: 0.72),
                                            Color(red: 0.92, green: 0.78, blue: 0.45)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color(red: 0.75, green: 0.55, blue: 0.12).opacity(0.45), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("luxury-action-\(action.choiceID.rawValue)")
                        }
                    }
                }
            }

            Text("Long-press Money actions elsewhere for deep previews. Luxury moves carry fame, family, and scrutiny costs.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.12, green: 0.10, blue: 0.06).opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.65, blue: 0.15).opacity(0.55),
                            Color(red: 0.55, green: 0.38, blue: 0.05).opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .accessibilityIdentifier("luxury-suite-card")
    }
}
