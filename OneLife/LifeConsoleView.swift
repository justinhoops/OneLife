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

struct DomainNavItem: Identifiable {
    let id: ConsoleDomain
    let title: String
    let icon: String
    let tone: PlannerTone
    let accessibilityIdentifier: String
}

enum ConsoleDomain: String, CaseIterable, Identifiable {
    case life
    case work
    case money
    case people
    case body
    case log

    var id: String { rawValue }
}

struct LifeConsoleView: View {
    @ObservedObject var vm: GameViewModel
    var onOpenFeed: () -> Void
    var onSettings: () -> Void

    @State private var selectedDomain: ConsoleDomain = .life
    @Environment(\.colorScheme) private var colorScheme

    private var snapshot: LifeConsoleSnapshot {
        vm.lifeConsoleSnapshot()
    }

    private var panel: DomainPanelModel {
        vm.domainPanel(for: selectedDomain)
    }

    var body: some View {
        VStack(spacing: 0) {
            consoleHeader
                .padding(.horizontal, 14)
                .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if let pulse = vm.activityPulse {
                        ConsoleActivityPulse(pulse: pulse)
                    }

                    if selectedDomain == .life {
                        autoLifePaceCard
                        pressureDeck
                        backgroundPulseDeck
                    }

                    DomainPanelView(
                        model: panel,
                        onDetail: { destination in
                            AppFeedback.impact(.light)
                            vm.openDetail(destination)
                        },
                        onQuickAction: { action in
                            vm.performQuickAction(action.choiceID, for: action.domain)
                        },
                        onSelectAction: { action in
                            AppFeedback.impact(.light)
                            vm.setAction(action.choiceID, for: action.domain)
                        }
                    )

                    if selectedDomain == .money {
                        assetSummary
                    }

                    if selectedDomain == .log {
                        LifeLogView(history: vm.state.history)
                            .accessibilityIdentifier("history-tab-content")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 18)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomConsoleBar
        }
        .background(consoleBackground.ignoresSafeArea())
        .onAppear {
            selectedDomain = consoleDomain(for: vm.selectedTab)
        }
    }

    private var consoleHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    AppFeedback.impact(.light)
                    onOpenFeed()
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(snapshot.name)
                            .font(.system(size: 28, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        HStack(spacing: 8) {
                            Text("Age \(snapshot.age)")
                            Text(snapshot.role)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("open-life-feed-button")

                VStack(alignment: .trailing, spacing: 4) {
                    Text(snapshot.cash)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(snapshot.cashTone.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Label("\(snapshot.health)%", systemImage: "heart.fill")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(snapshot.healthTone.color)
                }

                Button {
                    AppFeedback.impact(.light)
                    onSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, height: 42)
                        .background(consoleSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings-button")
            }

            HStack(spacing: 8) {
                quickStat(title: "Cash", value: snapshot.cash, tone: snapshot.cashTone)
                quickStat(title: "Health", value: "\(snapshot.health)%", tone: snapshot.healthTone)
                quickStat(title: "Pattern", value: snapshot.selectedAction, tone: vm.state.actionMemory.latestAction == nil ? .neutral : .positive)
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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.fill)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var pressureDeck: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Pressures")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)

            ForEach(snapshot.topPressures.prefix(3)) { pressure in
                HStack(spacing: 10) {
                    Circle()
                        .fill(pressure.tone.color)
                        .frame(width: 9, height: 9)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pressure.title)
                            .font(.subheadline.weight(.bold))
                        Text(pressure.value)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(pressure.tone.color)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(consoleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityIdentifier(homeUrgencyIdentifier(for: pressure.title))
                .onTapGesture {
                    if let destination = vm.plannerDestination(forUrgencyItemTitle: pressure.title) {
                        vm.openDetail(destination)
                    }
                }
            }
        }
        .accessibilityIdentifier("home-opportunities")
    }

    private var autoLifePaceCard: some View {
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
        .padding(14)
        .background(consoleSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityIdentifier("home-auto-life")
    }

    private var backgroundPulseDeck: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Background Pulse")
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)

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
        .accessibilityIdentifier("home-background-pulse")
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

    private var bottomConsoleBar: some View {
        VStack(spacing: 8) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityIdentifier("bottom-game-bar")

            if vm.presentedCard == nil, vm.state.activeYearChapter == nil {
                ConsoleRiskStrip(signals: snapshot.ageUpRisk)
            }

            if vm.presentedCard == nil,
               vm.state.activeYearChapter == nil,
               let last = vm.state.yearlyStance.lastCompletedStance,
               vm.state.yearlyStance.selectedStance == nil {
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
                    .padding(.vertical, 9)
                    .background(PlannerTone.positive.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bottom-continue-stance-button")
            }

            HStack(spacing: 10) {
                Menu {
                    ForEach(vm.domainNavItems()) { item in
                        Button {
                            AppFeedback.impact(.light)
                            selectedDomain = item.id
                            vm.selectedTab = tab(for: item.id)
                        } label: {
                            Label(item.title, systemImage: item.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "list.bullet.rectangle.portrait.fill")
                            .font(.system(size: 19, weight: .black))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Actions")
                                .font(.system(size: 14, weight: .black))
                            Text(panel.title)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .padding(.horizontal, 14)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bottom-actions-menu")

                Button {
                    vm.ageUp()
                    if vm.state.isGameOver {
                        AppFeedback.notify(.warning)
                    }
                } label: {
                    Label(vm.state.isGameOver ? "Ended" : "Age Up", systemImage: vm.state.isGameOver ? "xmark" : "arrow.up.circle.fill")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(vm.state.isGameOver ? Color.gray : DesignSystem.Colors.positive)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(GameBouncyButtonStyle())
                .disabled(vm.state.isGameOver || vm.presentedCard != nil || vm.state.activeYearChapter != nil)
                .accessibilityIdentifier("age-up-button")
            }

            HStack(spacing: 7) {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("bottom-domain-strip")

                ForEach(vm.domainNavItems()) { item in
                    Button {
                        AppFeedback.impact(.light)
                        selectedDomain = item.id
                        vm.selectedTab = tab(for: item.id)
                    } label: {
                        VStack(spacing: 4) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: .black))
                                Circle()
                                    .fill(item.tone.color)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 6, y: -3)
                            }
                            Text(item.title)
                                .font(.system(size: 10, weight: .black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .foregroundStyle(selectedDomain == item.id ? Color.white : Color.primary.opacity(0.72))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(selectedDomain == item.id ? Color.primary : Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(item.title)
                        .accessibilityIdentifier(item.accessibilityIdentifier)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(item.accessibilityIdentifier)
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.pendingActionStatus())
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.secondary)
                    Text(vm.pendingActionSummary())
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let pulse = vm.activityPulse {
                ConsoleActivityPulse(pulse: pulse)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 0)
        .background(.bar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
        }
    }

    private var consoleBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.06, green: 0.07, blue: 0.08), Color(red: 0.11, green: 0.12, blue: 0.11)]
                : [Color(red: 0.96, green: 0.96, blue: 0.94), Color(red: 0.90, green: 0.93, blue: 0.91)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var consoleSurface: Color {
        colorScheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.82)
    }

    private func consoleDomain(for tab: GameViewModel.Tab) -> ConsoleDomain {
        switch tab {
        case .home: return .life
        case .occupation: return .work
        case .assets: return .money
        case .relationships: return .people
        case .history: return .log
        }
    }

    private func tab(for domain: ConsoleDomain) -> GameViewModel.Tab {
        switch domain {
        case .life, .body: return .home
        case .work: return .occupation
        case .money: return .assets
        case .people: return .relationships
        case .log: return .history
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

private struct DomainPanelView: View {
    let model: DomainPanelModel
    let onDetail: (PlannerDetailDestination) -> Void
    let onQuickAction: (ActionPresentationModel) -> Void
    let onSelectAction: (ActionPresentationModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("")
                .frame(width: 1, height: 1)
                .accessibilityIdentifier(accessibilityIdentifier)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: model.icon)
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(model.tone.color)
                    .frame(width: 42, height: 42)
                    .background(model.tone.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title)
                        .font(.title2.weight(.black))
                    Text(model.status)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(model.tone.color)
                }

                Spacer(minLength: 0)

                if let destination = model.detailDestination {
                    Button("Details") {
                        onDetail(destination)
                    }
                    .font(.caption.weight(.black))
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(model.detailButtonIdentifier ?? "\(model.id.rawValue)-detail-button")
                }
            }

            Text(model.velocity)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                ForEach(model.metrics) { metric in
                    ConsoleMetricTile(metric: metric)
                }
            }
            .accessibilityIdentifier("\(model.id.rawValue)-overview-audit")

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: model.tone == .warning ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .foregroundStyle(model.tone.color)
                    .padding(.top, 2)
                Text(model.pressureLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }
            .padding(12)
            .background(model.tone.fill)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("\(model.id.rawValue)-overview-pressure")

            if !model.quickActions.isEmpty {
                ActionTray(title: "Quick Actions", actions: model.quickActions, selectedBadge: "DONE", accessibilityPrefix: "quick-action", onSelect: onQuickAction)
            }

            if !model.familyQuickActions.isEmpty {
                ActionTray(title: "Family — Right Now", actions: model.familyQuickActions, selectedBadge: "DONE", accessibilityPrefix: "family-quick-action", onSelect: onQuickAction)
            }
            if !model.familyActions.isEmpty {
                ActionTray(title: "Family — Year Plan", actions: model.familyActions, selectedBadge: "SET", accessibilityPrefix: "family-action-choice", onSelect: onSelectAction)
            }

            if !model.riskQuickActions.isEmpty {
                ActionTray(title: "Risk — Right Now", actions: model.riskQuickActions, selectedBadge: "DONE", accessibilityPrefix: "risk-quick-action", onSelect: onQuickAction)
            }
            if !model.riskActions.isEmpty {
                ActionTray(title: "Risk — Year Plan", actions: model.riskActions, selectedBadge: "SET", accessibilityPrefix: "risk-action-choice", onSelect: onSelectAction)
            }

            if let sections = model.actionSections, !sections.isEmpty {
                ForEach(sections) { section in
                    ActionTray(title: section.title, actions: section.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice-\(section.id)", onSelect: onSelectAction)
                }
            } else if !model.actions.isEmpty {
                ActionTray(title: "Year Plan", actions: model.actions, selectedBadge: "SET", accessibilityPrefix: "action-choice", onSelect: onSelectAction)
            }
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var accessibilityIdentifier: String {
        switch model.id {
        case .life: return "home-tab-content"
        case .work: return model.title == "Education" ? "education-tab-content" : "career-tab-content"
        case .money: return "finance-tab-content"
        case .people: return "relationships-tab-content"
        case .body: return "health-tab-content"
        case .log: return "history-console-content"
        }
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
        .background(metric.tone.fill)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ActionTray: View {
    let title: String
    let actions: [ActionPresentationModel]
    let selectedBadge: String
    let accessibilityPrefix: String
    let onSelect: (ActionPresentationModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("\(accessibilityPrefix)-deck-header")

            ForEach(actions) { action in
                Button {
                    onSelect(action)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: action.icon)
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(action.tone.color)
                            .frame(width: 38, height: 38)
                            .background(action.tone.fill)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(action.title)
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.74)
                                if action.isSelected {
                                    Text(selectedBadge)
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(PlannerTone.positive.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(PlannerTone.positive.fill)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(action.disabledReason ?? action.subtitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(action.disabledReason == nil ? .secondary : action.tone.color)
                                .lineLimit(2)

                            HStack(spacing: 5) {
                                ForEach(action.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2.weight(.black))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 4)
                                        .background(action.tone.fill)
                                        .clipShape(Capsule())
                                }
                            }
                            .accessibilityIdentifier("action-preview-strip")
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(action.isSelected ? PlannerTone.positive.fill : Color.primary.opacity(0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(action.isSelected ? PlannerTone.positive.color.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(accessibilityPrefix)-\(action.choiceID.rawValue)")
            }
        }
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
            ageUpRisk: ageUpRiskPreviewSignals()
        )
    }

    func domainNavItems() -> [DomainNavItem] {
        [
            DomainNavItem(id: .life, title: "Life", icon: "figure.play", tone: feedUrgencyItems().contains(where: { $0.tone == .warning }) ? .warning : .neutral, accessibilityIdentifier: "home-tab"),
            DomainNavItem(id: .work, title: showingEducationAsPrimaryTab ? "School" : "Work", icon: showingEducationAsPrimaryTab ? "book.closed.fill" : "briefcase.fill", tone: workTone(), accessibilityIdentifier: "career-tab"),
            DomainNavItem(id: .money, title: "Money", icon: "dollarsign.circle.fill", tone: moneyTone(), accessibilityIdentifier: "finance-tab"),
            DomainNavItem(id: .people, title: "People", icon: "person.2.fill", tone: peopleTone(), accessibilityIdentifier: "relationships-tab"),
            DomainNavItem(id: .body, title: "Body", icon: "heart.fill", tone: bodyTone(), accessibilityIdentifier: "body-tab"),
            DomainNavItem(id: .log, title: "Log", icon: "scroll.fill", tone: .neutral, accessibilityIdentifier: "history-tab")
        ]
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
                detailButtonIdentifier: nil
            )
        case .work:
            let actionDomain: ActionDomain = showingEducationAsPrimaryTab ? .education : .career
            return DomainPanelModel(
                id: .work,
                title: showingEducationAsPrimaryTab ? "Education" : "Career",
                icon: showingEducationAsPrimaryTab ? "book.closed.fill" : "briefcase.fill",
                tone: workTone(),
                status: showingEducationAsPrimaryTab ? educationStatusLine() : roleTitle(),
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
                detailButtonIdentifier: showingEducationAsPrimaryTab ? "education-overview-detail-button" : "career-overview-detail-button"
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
                    ConsoleMetricModel(title: "Net", value: "$\(state.finance.annualNetIncome)", tone: state.finance.annualNetIncome >= 0 ? .positive : .warning),
                    ConsoleMetricModel(title: "Stress", value: "\(state.finance.financialStress)", tone: moneyTone())
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
                detailButtonIdentifier: "finance-cashflow-detail-button"
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
                detailButtonIdentifier: state.family.isPregnant || state.family.childCount > 0 ? "relationships-family-detail-button" : "relationships-connections-detail-button"
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
                detailButtonIdentifier: "health-overview-detail-button"
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
        let priorityDomains: [ActionDomain] = [preferredDomain].compactMap { $0 } + [.finance, .career, .relationships, .health, .education]
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
}
