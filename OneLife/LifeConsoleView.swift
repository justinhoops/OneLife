import SwiftUI

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

struct LifeConsoleView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var chrome: GameSessionChromeState
    var onOpenFeed: () -> Void
    var onSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showedMomentumHint = false
    @State private var showResilienceSheet = false
    @State private var resiliencePulsing = false
    @State private var expandedConsoleSections: Set<String> = []

    private var bitLifeShell: Bool { vm.prefersBitLifeShell }
    private var compactLateGame: Bool { vm.prefersCompactLateGameUI }
    private var panelCompact: Bool { bitLifeShell || compactLateGame }

    private var snapshot: LifeConsoleSnapshot {
        vm.consoleSnapshot
    }

    private var currentDomain: ConsoleDomain {
        consoleDomain(for: vm.selectedTab)
    }

    private var presentation: ConsolePresentationSnapshot {
        vm.cachedConsolePresentation
    }

    private var panel: DomainPanelModel {
        presentation.panel(for: currentDomain) ?? vm.domainPanel(for: currentDomain)
    }

    private var secondaryPressures: [PlannerInsight] {
        vm.secondaryPressureItems(after: 3, limit: 3)
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
                        consoleDomainHost
                        ActivitiesInstantHubView(vm: vm)
                    } else if bitLifeShell {
                        consoleDomainHost

                        if currentDomain == .money {
                            housingHubCard
                        }
                    } else {
                        consoleDomainHost

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

    private func recognitionGlanceLine(_ item: RecognitionGlanceItem) -> some View {
        Button {
            AppFeedback.impact(.light)
            if let destination = item.destination {
                vm.openDetail(destination)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.tone == .warning ? "eye.trianglebadge.exclamationmark" : "star.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.tone.color)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(item.label) · \(item.score)")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if item.destination != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(item.tone.fill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recognition-glance-line")
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
        guard currentDomain == .people else { return nil }
        return presentation.teach.adultChildrenFocusChip
    }

    private var consoleDomainHost: some View {
        ConsoleDomainHostView(
            domain: currentDomain,
            presentation: presentation,
            bitLifeShell: bitLifeShell,
            panelCompact: panelCompact,
            onQuickAction: { action in
                vm.performQuickAction(action.choiceID, for: action.domain)
            },
            onSelectAction: { action in
                AppFeedback.impact(.light)
                vm.performQuickAction(action.choiceID, for: action.domain)
            },
            onDetail: { destination in
                AppFeedback.impact(.light)
                vm.openDetail(destination)
            },
            onDismissAdultChildrenCoach: { vm.markAdultChildrenCoachSeen() },
            onDismissFamilyBanner: { vm.markFamilyHouseholdBannerSeen() },
            onDismissFirstQuickActionTeach: { vm.markFirstQuickActionTeachSeen() },
            onLongPressPreview: { vm.markFirstLongPressTeachSeen() },
            onOpenPlayTab: { vm.selectedTab = .activities },
            onOpenAssets: { vm.openAssetsPlanner() }
        )
    }

    private var nowLaneCard: some View {
        let snapshot = vm.nowLaneSnapshotCache
        return NowLaneCard(snapshot: snapshot, canAct: vm.presentedCard == nil && vm.state.activeYearChapter == nil && !vm.state.isGameOver) {
            vm.performNowLaneQuickAction()
        }
        .onAppear {
            if snapshot.headline == "Coach" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    vm.markDossierStanceCoachSeen()
                }
            }
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

                        // P5 Cohesion Gate: One obvious "Life Pulse" surface in main console header
                        // Consolidates life shape + recognition/fame flavor (resilience has dedicated pill).
                        // Single glanceable surface for these major systems in the main console.
                        // Echoes via CohesionNarrative in summaries, forecasts, quiet notes, legacy.
                        let shapeLabel = LifeShapeResolver.label(from: vm.state)
                        let recLine = CohesionNarrative.recognitionEcho(state: vm.state, surface: .yearSummary) ?? ""
                        if !shapeLabel.isEmpty || !recLine.isEmpty {
                            let pulse = [shapeLabel, recLine].filter { !$0.isEmpty }.joined(separator: " · ")
                            Text(pulse)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
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

            if vm.momentumStripSnapshot.showsStrip {
                MomentumStripView(
                    snapshot: vm.momentumStripSnapshot,
                    showedMomentumHint: $showedMomentumHint,
                    onClearReactions: { vm.clearInstantReactions() },
                    onMarkMomentumSeen: {
                        vm.markMomentumStripIntroSeen()
                        vm.markMomentumCoachSeen()
                    },
                    onMarkLifeShapeTeachSeen: { vm.markLifeShapeTeachSeen() }
                )
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.momentumStripSnapshot.recentReactions.count)
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
        let needsCoach = !vm.state.discoverability.seenResilienceExplain
        return HStack(spacing: 3) {
            Image(systemName: isResilient ? "flame.fill" : "shield.fill")
                .font(.caption2.weight(.bold))
            Text(vm.state.resilience.persistentPlayLabel)
                .font(.system(size: 8, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(isResilient ? Color.green.opacity(needsCoach ? 0.28 : 0.15) : Color.orange.opacity(needsCoach ? 0.32 : 0.18))
        .foregroundStyle(isResilient ? Color.green : Color.orange)
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke((isResilient ? Color.green : Color.orange).opacity(needsCoach && resiliencePulsing ? 0.7 : 0), lineWidth: 1.5)
        )
        .scaleEffect(needsCoach && resiliencePulsing ? 1.06 : 1.0)
        .accessibilityLabel("Life feel: \(vm.state.resilience.displayName)")
        .accessibilityHint(needsCoach ? "Tap to learn how Resilient and Grounded change recovery." : "")
        .onAppear {
            guard needsCoach else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                resiliencePulsing = true
            }
        }
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
    showFamilyTraySubtitle: Bool = false,
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
            traySubtitle: showFamilyTraySubtitle ? "Shapes who they become" : nil,
            headerIcon: "figure.and.child.holdinghands",
            headerTint: .orange,
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

private struct FamilyHouseholdStrip: View {
    let snapshot: FamilyHouseholdSnapshot
    var onDismissBanner: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let banner = snapshot.bannerLine {
                Text(banner)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityIdentifier("family-household-teach-banner")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                            onDismissBanner?()
                        }
                    }
            }

            HStack(spacing: 10) {
                Label("\(snapshot.atHomeCount) at home", systemImage: "house.fill")
                Label("\(snapshot.adultCount) grown", systemImage: "figure.2.and.child.holdinghands")
                if let name = snapshot.strongestBondChildName, snapshot.strongestBondValue > 0 {
                    Text("\(name) · bond \(snapshot.strongestBondValue)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(snapshot.strongestBondValue >= 60 ? PlannerTone.positive.color : PlannerTone.warning.color)
                }
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            if let pressure = snapshot.topPressureLine {
                Text(pressure)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(PlannerTone.warning.color)
                    .lineLimit(2)
            }

            if let headline = snapshot.headlineChildLine {
                Text(headline)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .accessibilityIdentifier("family-household-strip")
    }
}

private struct FamilyAtHomeGlanceRow: View {
    let items: [FamilyAtHomeGlanceItem]
    let overflowCount: Int

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("At home")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.secondary)

                ForEach(items) { child in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(child.name)
                                .font(.caption.weight(.heavy))
                            Text("age \(child.age)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(child.temperament.capitalized)
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(PlannerTone.neutral.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(PlannerTone.neutral.fill)
                                .clipShape(Capsule())
                            Spacer(minLength: 0)
                            Text("Bond \(child.bond)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(child.bond >= 60 ? PlannerTone.positive.color : PlannerTone.warning.color)
                        }
                        Text(child.vibeLine)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityIdentifier("at-home-glance-\(child.id)")
                }

                if overflowCount > 0 {
                    Text("+\(overflowCount) more at home")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .accessibilityIdentifier("family-at-home-glance-row")
        }
    }
}

private struct ConsoleDomainHostView: View {
    let domain: ConsoleDomain
    let presentation: ConsolePresentationSnapshot
    let bitLifeShell: Bool
    let panelCompact: Bool
    var forceExpandYearPlan: Bool = false
    let onQuickAction: (ActionPresentationModel) -> Void
    let onSelectAction: (ActionPresentationModel) -> Void
    let onDetail: (PlannerDetailDestination) -> Void
    let onDismissAdultChildrenCoach: () -> Void
    let onDismissFamilyBanner: () -> Void
    let onDismissFirstQuickActionTeach: () -> Void
    let onLongPressPreview: () -> Void
    let onOpenPlayTab: () -> Void
    let onOpenAssets: () -> Void

    private var model: DomainPanelModel {
        presentation.panel(for: domain) ?? DomainPanelModel(
            id: domain,
            title: domain.rawValue.capitalized,
            icon: "circle",
            tone: .neutral,
            status: "",
            velocity: "",
            metrics: [],
            pressureLine: "",
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
    }

    private var adultChildrenGlance: [FamilyChildGlanceItem] {
        // P5 + late-game compaction: default to glance chips for adult children when many or late game.
        // Keeps glance rule. Full list one-tap (in panel).
        let full = presentation.familyGlance.adultChildrenFull
        if full.count > 2 {
            return Array(full.prefix(3))
        }
        return full
    }

    var body: some View {
        if bitLifeShell {
            DomainGlancePanelView(
                model: model,
                familyGlance: presentation.familyGlance,
                auditRibbon: presentation.auditRibbon,
                recognitionGlance: presentation.recognitionGlance,
                collectionGlance: presentation.collectionGlance,
                teach: presentation.teach,
                adultChildrenGlance: adultChildrenGlance,
                onDismissFamilyBanner: onDismissFamilyBanner,
                onDismissAdultChildrenCoach: onDismissAdultChildrenCoach,
                onDismissFirstQuickActionTeach: onDismissFirstQuickActionTeach,
                onLongPressPreview: onLongPressPreview,
                onOpenPlayTab: onOpenPlayTab,
                onOpenAssets: onOpenAssets,
                onQuickAction: onQuickAction,
                onDetail: onDetail
            )
        } else {
            DomainPanelView(
                model: model,
                compactMode: panelCompact,
                bitLifeMode: bitLifeShell,
                forceExpandYearPlan: forceExpandYearPlan,
                familyGlance: presentation.familyGlance,
                recognitionGlance: presentation.recognitionGlance,
                collectionGlance: presentation.collectionGlance,
                teach: presentation.teach,
                adultChildrenGlance: adultChildrenGlance,
                onDismissAdultChildrenCoach: onDismissAdultChildrenCoach,
                onDismissFirstQuickActionTeach: onDismissFirstQuickActionTeach,
                onLongPressPreview: onLongPressPreview,
                onOpenAssets: onOpenAssets,
                onDetail: onDetail,
                onQuickAction: onQuickAction,
                onSelectAction: onSelectAction
            )
        }
    }
}

private struct DomainGlancePanelView: View {
    let model: DomainPanelModel
    let familyGlance: ConsoleFamilyGlancePresentation
    let auditRibbon: ConsoleAuditRibbonSnapshot
    let recognitionGlance: RecognitionGlanceItem?
    let collectionGlance: CollectionGlanceItem?
    let teach: ConsoleTeachSnapshot
    var adultChildrenGlance: [FamilyChildGlanceItem] = []
    var onDismissFamilyBanner: (() -> Void)? = nil
    var onDismissAdultChildrenCoach: (() -> Void)? = nil
    var onDismissFirstQuickActionTeach: (() -> Void)? = nil
    var onLongPressPreview: (() -> Void)? = nil
    var onOpenPlayTab: (() -> Void)? = nil
    var onOpenAssets: (() -> Void)? = nil
    let onQuickAction: (ActionPresentationModel) -> Void
    let onDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("")
                .frame(width: 1, height: 1)
                .accessibilityIdentifier(accessibilityIdentifier)

            if model.id == .people, familyGlance.showHouseholdStrip {
                FamilyHouseholdStrip(
                    snapshot: familyGlance.household,
                    onDismissBanner: onDismissFamilyBanner
                )
                FamilyAtHomeGlanceRow(
                    items: familyGlance.atHomeItems,
                    overflowCount: familyGlance.atHomeOverflow
                )
            }

            if !model.quickActions.isEmpty || !model.familyQuickActions.isEmpty || !model.riskQuickActions.isEmpty {
                domainInstantDeckSection(
                    model: model,
                    showLongPressCoach: teach.showHoldHint && model.previewProvider != nil,
                    firstQuickActionTeachLine: teach.firstQuickActionTeachLine,
                    showLongPressFooter: !teach.seenFirstLongPressTeach,
                    showFamilyTraySubtitle: familyGlance.showFamilyTraySubtitle,
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

            if let recognitionGlance, model.id == .life {
                RecognitionGlanceRow(item: recognitionGlance, onDetail: onDetail)
            }

            if let collectionGlance, model.id == .money {
                CollectionGlanceRow(item: collectionGlance, onOpenAssets: onOpenAssets)
            }

            if !auditRibbon.chips.isEmpty || auditRibbon.momentumVisible || auditRibbon.showCulturalFame {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(auditRibbon.chips) { chip in
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
                        if auditRibbon.momentumVisible {
                            HStack(spacing: 4) {
                                Image(systemName: "globe.americas.fill")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(Color.purple)
                                Text("Mom \(auditRibbon.momentumStrength)")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(Color.purple)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        if auditRibbon.showCulturalFame {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(.orange)
                                Text("\(auditRibbon.culturalFame)")
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

            if model.id == .people, !adultChildrenGlance.isEmpty {
                AdultChildrenGlanceSection(
                    adultChildrenGlance: adultChildrenGlance,
                    compactSummary: familyGlance.adultChildrenCompact,
                    compactMode: true,
                    focusChip: teach.adultChildrenFocusChip,
                    onDismissFocusChip: onDismissAdultChildrenCoach,
                    onOpenFamilyDetail: model.detailDestination == .relationshipsFamily ? { onDetail(.relationshipsFamily) } : nil
                )
            }

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
                onOpenPlayTab?()
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
    var familyGlance: ConsoleFamilyGlancePresentation = .empty
    var recognitionGlance: RecognitionGlanceItem?
    var collectionGlance: CollectionGlanceItem?
    var teach: ConsoleTeachSnapshot = .empty
    var adultChildrenGlance: [FamilyChildGlanceItem] = []
    @State private var yearPlanExpanded = false
    @State private var familyTrayExpanded = false
    @State private var riskTrayExpanded = false
    var onDismissAdultChildrenCoach: (() -> Void)? = nil
    var onDismissFirstQuickActionTeach: (() -> Void)? = nil
    var onLongPressPreview: (() -> Void)? = nil
    var onOpenAssets: (() -> Void)? = nil
    let onDetail: (PlannerDetailDestination) -> Void
    let onQuickAction: (ActionPresentationModel) -> Void
    let onSelectAction: (ActionPresentationModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("")
                .frame(width: 1, height: 1)
                .accessibilityIdentifier(accessibilityIdentifier)

            if model.id == .people, familyGlance.showHouseholdStrip {
                FamilyHouseholdStrip(snapshot: familyGlance.household)
                FamilyAtHomeGlanceRow(
                    items: familyGlance.atHomeItems,
                    overflowCount: familyGlance.atHomeOverflow
                )
            }

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

            if compactMode, let recognitionGlance, model.id == .life {
                RecognitionGlanceRow(item: recognitionGlance, onDetail: onDetail)
            }

            if compactMode, let collectionGlance, model.id == .money {
                CollectionGlanceRow(item: collectionGlance, onOpenAssets: onOpenAssets)
            }

            if model.id == .people, !adultChildrenGlance.isEmpty {
                AdultChildrenGlanceSection(
                    adultChildrenGlance: adultChildrenGlance,
                    compactSummary: familyGlance.adultChildrenCompact,
                    compactMode: compactMode,
                    focusChip: teach.adultChildrenFocusChip,
                    onDismissFocusChip: onDismissAdultChildrenCoach,
                    onOpenFamilyDetail: model.detailDestination == .relationshipsFamily ? { onDetail(.relationshipsFamily) } : nil
                )
            }

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
                showLongPressCoach: teach.showHoldHint && model.previewProvider != nil,
                firstQuickActionTeachLine: teach.firstQuickActionTeachLine,
                showLongPressFooter: teach.showHoldHint,
                showFamilyTraySubtitle: familyGlance.showFamilyTraySubtitle,
                onDismissFirstQuickActionTeach: onDismissFirstQuickActionTeach,
                onLongPressPreview: onLongPressPreview,
                onQuickAction: onQuickAction
            )

            if !model.familyActions.isEmpty {
                if compactMode && !forceExpandYearPlan {
                    actionTrayDisclosure(title: "Family — Year Plan", isExpanded: $familyTrayExpanded) {
                        ActionTray(title: "Family — Year Plan", actions: model.familyActions, selectedBadge: "SET", accessibilityPrefix: "family-action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider, showHoldHint: teach.showHoldHint, showLongPressFooter: teach.showHoldHint, onPreviewActivated: onLongPressPreview)
                    }
                } else {
                    ActionTray(title: "Family — Year Plan", actions: model.familyActions, selectedBadge: "SET", accessibilityPrefix: "family-action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider, showHoldHint: teach.showHoldHint, showLongPressFooter: teach.showHoldHint, onPreviewActivated: onLongPressPreview)
                }
            }

            if !model.riskActions.isEmpty {
                if compactMode {
                    actionTrayDisclosure(title: "Risk — Year Plan", isExpanded: $riskTrayExpanded) {
                        ActionTray(title: "Risk — Year Plan", actions: model.riskActions, selectedBadge: "SET", accessibilityPrefix: "risk-action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider, showHoldHint: teach.showHoldHint, showLongPressFooter: teach.showHoldHint, onPreviewActivated: onLongPressPreview)
                    }
                } else {
                    ActionTray(title: "Risk — Year Plan", actions: model.riskActions, selectedBadge: "SET", accessibilityPrefix: "risk-action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider, showHoldHint: teach.showHoldHint, showLongPressFooter: teach.showHoldHint, onPreviewActivated: onLongPressPreview)
                }
            }

            if let sections = model.actionSections, !sections.isEmpty {
                if bitLifeMode && !forceExpandYearPlan {
                    yearPlanDisclosure {
                        ForEach(sections) { section in
                            ActionTray(title: section.title, actions: section.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice-\(section.id)", onSelect: onSelectAction, previewProvider: model.previewProvider, showHoldHint: teach.showHoldHint, showLongPressFooter: teach.showHoldHint, onPreviewActivated: onLongPressPreview)
                        }
                    }
                } else {
                    ForEach(sections) { section in
                        ActionTray(title: section.title, actions: section.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice-\(section.id)", onSelect: onSelectAction, previewProvider: model.previewProvider, showHoldHint: teach.showHoldHint, showLongPressFooter: teach.showHoldHint, onPreviewActivated: onLongPressPreview)
                    }
                }
            } else if !model.actions.isEmpty {
                if bitLifeMode && !forceExpandYearPlan {
                    yearPlanDisclosure {
                        ActionTray(title: "Year Plan", actions: model.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider, showHoldHint: teach.showHoldHint, showLongPressFooter: teach.showHoldHint, onPreviewActivated: onLongPressPreview)
                    }
                } else {
                    ActionTray(title: "Year Plan", actions: model.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice", onSelect: onSelectAction, previewProvider: model.previewProvider, showHoldHint: teach.showHoldHint, showLongPressFooter: teach.showHoldHint, onPreviewActivated: onLongPressPreview)
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

private struct CollectionGlanceRow: View {
    let item: CollectionGlanceItem
    let onOpenAssets: (() -> Void)?

    var body: some View {
        Button {
            AppFeedback.impact(.light)
            onOpenAssets?()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bag.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.tone.color)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(item.label) · \(item.score)")
                        .font(.caption.weight(.heavy))
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(item.tone.fill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("collection-glance-line")
    }
}

private struct RecognitionGlanceRow: View {
    let item: RecognitionGlanceItem
    let onDetail: (PlannerDetailDestination) -> Void

    var body: some View {
        Button {
            AppFeedback.impact(.light)
            if let destination = item.destination {
                onDetail(destination)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.tone == .warning ? "eye.trianglebadge.exclamationmark" : "star.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.tone.color)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(item.label) · \(item.score)")
                        .font(.caption.weight(.heavy))
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if item.destination != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(10)
            .background(item.tone.fill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recognition-glance-line")
    }
}

private struct AdultChildrenGlanceSection: View {
    let adultChildrenGlance: [FamilyChildGlanceItem]
    let compactSummary: AdultChildrenCompactSummary
    let compactMode: Bool
    let focusChip: String?
    let onDismissFocusChip: (() -> Void)?
    var onOpenFamilyDetail: (() -> Void)? = nil

    @State private var expanded = false

    private var visibleItems: [FamilyChildGlanceItem] {
        compactMode && !expanded ? compactSummary.previewItems : adultChildrenGlance
    }

    var body: some View {
        if focusChip != nil || !adultChildrenGlance.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Adult children")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                    if compactMode, let summary = compactSummary.summaryLine {
                        Text(summary)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if compactMode, !adultChildrenGlance.isEmpty {
                        Button(expanded ? "Less" : "All") {
                            AppFeedback.impact(.light)
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                expanded.toggle()
                            }
                        }
                        .font(.caption2.weight(.black))
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("adult-children-expand-button")
                    }
                }

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

                if !visibleItems.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            ForEach(visibleItems) { child in
                                adultChildButton(child, expanded: expanded || !compactMode)
                            }
                            if compactMode, !expanded, compactSummary.overflowCount > 0 {
                                Button {
                                    AppFeedback.impact(.light)
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                        expanded = true
                                    }
                                } label: {
                                    Text("+\(compactSummary.overflowCount) more")
                                        .font(.caption.weight(.heavy))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 88, height: 54)
                                        .background(PlannerTone.neutral.fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("adult-children-overflow-chip")
                            }
                        }
                    }
                }
            }
            .accessibilityIdentifier("adult-children-glance-strip")
        }
    }

    private func adultChildButton(_ child: FamilyChildGlanceItem, expanded: Bool) -> some View {
        Button {
            onDismissFocusChip?()
            onOpenFamilyDetail?()
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(child.name)
                        .font(.caption.weight(.heavy))
                        .lineLimit(1)
                    Text(child.outcomeLabel)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(outcomeTone(child).color)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(outcomeTone(child).fill)
                        .clipShape(Capsule())
                }
                Text("Bond \(child.relationshipQuality)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(child.relationshipQuality >= 60 ? PlannerTone.positive.color : PlannerTone.warning.color)
                    .lineLimit(1)
                if !child.storyTease.isEmpty {
                    Text(child.storyTease)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(expanded ? 2 : 1)
                } else {
                    Text(child.continuityHint)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if expanded {
                    Text("Age \(child.age) · \(child.continuityHint)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: expanded ? 160 : 132, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(PlannerTone.neutral.fill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("adult-child-glance-\(child.id)")
    }

    private func outcomeTone(_ child: FamilyChildGlanceItem) -> PlannerTone {
        if child.outcomeLabel == "Struggling" || child.outcomeLabel == "Distant" || child.relationshipQuality < 45 {
            return .warning
        }
        if child.outcomeLabel == "Thriving" || child.relationshipQuality >= 70 {
            return .positive
        }
        return .neutral
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

                if showHoldHint, previewProvider != nil, action.disabledReason == nil {
                    Text("hold")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(Color.purple.opacity(isPulsingHint ? 0.75 : 0.4))
                        .textCase(.uppercase)
                }

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
            if showHoldHint, previewProvider != nil, previewedActionID != action.choiceID {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.purple.opacity(isPulsingHint ? 0.95 : 0.45))
                    .scaleEffect(isPulsingHint ? 1.15 : 0.92)
                    .padding(8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            isPulsingHint = true
                        }
                    }
            }
            if let pid = previewedActionID, pid == action.choiceID, !previewLines.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(previewLines.prefix(4), id: \.self) { line in
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
    var traySubtitle: String? = nil
    var headerIcon: String? = nil
    var headerTint: Color? = nil
    var showHoldHint: Bool = false
    var showLongPressFooter: Bool = false
    var firstQuickActionTeachLine: String? = nil
    var onDismissFirstQuickActionTeach: (() -> Void)? = nil
    var onPreviewActivated: (() -> Void)? = nil

    @State private var previewedActionID: ActionChoiceID? = nil
    @State private var previewLines: [String] = []
    @State private var isPulsingHeaderHint = false
    @State private var showMoreActions = false

    private var isQuickDeck: Bool {
        let lower = title.lowercased()
        return lower.contains("quick") || lower.contains("right now") || lower.contains("do now")
    }

    private var primaryActions: [ActionPresentationModel] {
        isQuickDeck ? Array(actions.prefix(4)) : actions
    }

    private var overflowActions: [ActionPresentationModel] {
        isQuickDeck ? Array(actions.dropFirst(4)) : []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if isQuickDeck {
                    Image(systemName: "bolt.circle.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.green)
                } else if let headerIcon, let headerTint {
                    Image(systemName: headerIcon)
                        .font(.caption.weight(.black))
                        .foregroundStyle(headerTint)
                }
                Text(isQuickDeck ? "Right Now" : title)
                    .font(isQuickDeck ? .subheadline.weight(.black) : .caption.weight(.black))
                    .foregroundStyle(isQuickDeck ? .primary : .secondary)
                if showHoldHint, previewProvider != nil {
                    Text(isQuickDeck ? "HOLD TO PREVIEW" : "HOLD")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color.purple.opacity(isPulsingHeaderHint ? 0.95 : 0.75))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(isPulsingHeaderHint ? 0.24 : 0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.purple.opacity(isPulsingHeaderHint ? 0.55 : 0.2), lineWidth: 1.5)
                        )
                        .scaleEffect(isPulsingHeaderHint ? 1.08 : 0.98)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                isPulsingHeaderHint = true
                            }
                        }
                }
                if isQuickDeck {
                    Text("ALWAYS")
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

            if let traySubtitle, !traySubtitle.isEmpty {
                Text(traySubtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("\(accessibilityPrefix)-deck-subtitle")
            }

            // Overhauled for real estate + BitLife-like instant actions per domain:
            // Use 2-col grid for "instant / quick / right now" sections so more actions are visible without scrolling.
            // Larger cards, better thumb ergonomics, full width use.
            let lowerTitle = title.lowercased()
            let useGrid = lowerTitle.contains("quick") || lowerTitle.contains("right now") || lowerTitle.contains("do now") || lowerTitle.contains("instant")
            let gridColumns = useGrid 
                ? [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)] 
                : [GridItem(.flexible())]

            LazyVGrid(columns: gridColumns, spacing: useGrid ? 8 : 6) {
                ForEach(primaryActions) { action in
                    trayCell(action, useGrid: useGrid)
                }
            }

            if !overflowActions.isEmpty {
                Button {
                    AppFeedback.impact(.light)
                    showMoreActions = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.caption.weight(.black))
                        Text("More actions")
                            .font(.caption.weight(.black))
                        Spacer(minLength: 0)
                        Text("+\(overflowActions.count)")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(accessibilityPrefix)-more-actions-button")
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
        .sheet(isPresented: $showMoreActions) {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(overflowActions) { action in
                            trayCell(action, useGrid: true) { selected in
                                showMoreActions = false
                                onSelect(selected)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("More Actions")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showMoreActions = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .accessibilityIdentifier("\(accessibilityPrefix)-more-actions-sheet")
        }
    }

    private func trayCell(
        _ action: ActionPresentationModel,
        useGrid: Bool,
        onSelect overrideSelect: ((ActionPresentationModel) -> Void)? = nil
    ) -> some View {
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
            onSelect: overrideSelect ?? onSelect,
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

private struct MomentumStripView: View {
    let snapshot: MomentumStripSnapshot
    @Binding var showedMomentumHint: Bool
    let onClearReactions: () -> Void
    let onMarkMomentumSeen: () -> Void
    let onMarkLifeShapeTeachSeen: () -> Void

    var body: some View {
        let momentum = snapshot.momentum
        return VStack(alignment: .leading, spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Image(systemName: showedMomentumHint ? "info.circle.fill" : "waveform.path.ecg")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.purple)
                        .padding(.leading, 2)

                    if showedMomentumHint {
                        Text(snapshot.seenMomentumStripIntro
                             ? DiscoverabilityTeaching.momentumStripDetailLine
                             : DiscoverabilityTeaching.momentumStripIntroLine(resilience: snapshot.resilience))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.purple.opacity(0.9))
                            .lineLimit(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                            .accessibilityIdentifier("momentum-build-hint")
                    } else {
                        if momentum.isVisible {
                            ForEach(momentum.rankedDomainMomentum, id: \.domain) { entry in
                                momentumDomainBar(domain: entry.domain, value: entry.value)
                            }
                        }
                        ForEach(snapshot.recentReactions, id: \.self) { reaction in
                            momentumChip(reaction)
                        }
                        if !snapshot.lifeShape.isEmpty {
                            if !snapshot.seenLifeShapeTeach {
                                Text(DiscoverabilityTeaching.lifeShapeIntroLine(shape: snapshot.lifeShape, resilience: snapshot.resilience))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.purple.opacity(0.9))
                                    .lineLimit(3)
                                    .padding(.leading, 4)
                                    .accessibilityIdentifier("life-shape-first-teach")
                                    .onAppear { onMarkLifeShapeTeachSeen() }
                            } else {
                                Text("Shape: \(snapshot.lifeShape)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(snapshot.lifeShape.contains("loose") ? Color.orange : (snapshot.lifeShape.contains("driven") ? Color.purple : Color.green))
                                    .padding(.leading, 4)
                                    .accessibilityLabel("Current life shape: \(snapshot.lifeShape)")
                                    .accessibilityHint("Your recent focus choices are writing this shape. It affects quiet years, autonomy, and legacy.")
                            }
                        }
                    }

                    if !snapshot.recentReactions.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.3)) { onClearReactions() }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.purple.opacity(0.55))
                        }
                        .padding(.trailing, 4)
                    }
                }
            }

            if !showedMomentumHint, let hint = snapshot.topDomainMicroHint {
                Text(hint)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(momentumTone(for: momentum.rankedDomainMomentum.first?.domain ?? .health).color.opacity(0.9))
                    .lineLimit(2)
                    .accessibilityIdentifier("momentum-domain-micro-hint")
            }
        }
        .frame(minHeight: 28)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassCard(radius: DesignSystem.Radius.medium)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: snapshot.recentReactions.count)
        .accessibilityIdentifier("instant-momentum-strip")
        .accessibilityLabel("Momentum strip")
        .accessibilityHint("Tap to learn how momentum shapes your next year.")
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation { showedMomentumHint.toggle() }
            if showedMomentumHint {
                onMarkMomentumSeen()
            }
        }
        .onAppear {
            if snapshot.shouldAutoExpandHint {
                showedMomentumHint = true
            }
        }
        .onChange(of: snapshot.momentum.isVisible) { _, visible in
            if visible, snapshot.shouldAutoExpandHint {
                showedMomentumHint = true
            }
        }
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
