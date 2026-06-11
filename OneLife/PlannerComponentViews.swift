import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SignalSummary {
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

struct StatusPill: View {
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
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
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

struct PlannerSectionCard<Content: View>: View {
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

struct MetricRow: View {
    let metrics: [(String, String, PlannerTone)]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                MetricTile(label: metric.0, value: metric.1, tone: metric.2)
            }
        }
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    let tone: PlannerTone

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
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

struct RecentLifeModule: View {
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
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            } else {
                ForEach(Array(history.prefix(3))) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Age \(item.age) • \(item.title)")
                            .font(.subheadline.weight(.semibold))
                        Text(item.text)
                            .font(.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
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

struct TrendBadge: View {
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

struct OverviewSignalStrip: View {
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

struct CompactFocusDock: View {
    let focus: RecommendedFocus
    let actionChoices: [ActionChoiceID]
    let onSelectAction: (ActionChoiceID) -> Void

    var body: some View {
        ActionSelectionModule(actionChoices: actionChoices, onSelectAction: onSelectAction)
    }
}

struct CompressedPlannerTab: View {
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
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
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

struct ContinuityHubSection: View {
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
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(item.tone.color)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(3)
                    }
                }
            }
        }
    }
}

struct AutonomyToastOverlay: View {
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
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
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

struct FeedHomeTab: View {
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
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(3)

                    Text(queuedInteractionCount > 0 ? "Finish the live card stack to settle the year." : pendingActionSummary)
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

func yearGoalStatusLine(vm: GameViewModel) -> String {
    let stance = vm.state.yearlyStance.selectedStance?.title ?? "Recommended: \(vm.recommendedYearlyStance().title)"
    // D4: surface ambient life shape from recent focus residue
    let shapeLabel = LifeShapeResolver.label(from: vm.state)
    let shape = shapeLabel.isEmpty ? "" : " · \(shapeLabel)"
    return "\(stance) · \(vm.state.resilience.shortLabel)\(shape)"
}

struct ForecastStakesPage: Identifiable {
    let id: String
    let label: String
    let title: String
    let detail: String
    let tone: PlannerTone
    let icon: String
}

struct CompactInteractionOverlay: View {
    let card: InteractionCardPayload
    let state: GameState
    var stakes: TurnStakesSnapshot? = nil
    var stanceChips: [YearlyStanceChip] = []
    var recommendedStance: YearlyStanceID = .protectHealth
    var onSelectStance: ((YearlyStanceID) -> Void)? = nil
    var onPrepareForecast: (() -> Void)? = nil
    var onDismissMomentumCarry: (() -> Void)? = nil
    let onAdvance: () -> Void
    let onPick: (EventChoice) -> Void
    let onCrisisPick: (CrisisChoice) -> Void
    let onPitchPick: (PitchDeckChoice) -> Void

    @State private var stakesPageIndex = 0
    @State private var yearSummaryExpanded = false

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
                case .combatFight(let summary):
                    combatFightView(summary)
                case .legalCase(let summary):
                    legalCaseView(summary)
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
            .padding(22)
            .frame(maxWidth: 560, alignment: .leading)
            .glassCard(radius: DesignSystem.Radius.large)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(sheetAccessibilityIdentifier)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.horizontal, 10)
        .padding(.bottom, 12)
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
        case .combatFight:
            return "combat-fight-card"
        case .legalCase:
            return "legal-case-card"
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

    private func combatFightView(_ summary: CombatFightSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.discipline == .boxing ? "BOXING RESULT" : "MMA RESULT")
                .font(.caption.weight(.heavy))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text("\(summary.result) by \(summary.method)")
                .font(.title2.weight(.black))
            Text("vs. \(summary.opponentName)")
                .font(.headline)

            HStack(spacing: 10) {
                combatResultMetric("Record", summary.record)
                combatResultMetric("Rank", summary.rankingText)
                combatResultMetric("Purse", "$\(summary.purse)")
            }

            if let injury = summary.injuryText {
                Label(injury, systemImage: "cross.case.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.warning)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("WHY IT MOVED")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                ForEach(summary.decisiveCauses, id: \.self) { cause in
                    Text("• \(cause)")
                        .font(.caption)
                }
            }

            Button("Continue") {
                onAdvance()
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignSystem.Colors.positive)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityIdentifier("combat-fight-continue-button")
        }
    }

    private func legalCaseView(_ summary: LegalCaseSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LEGAL RESULT")
                .font(.caption.weight(.heavy))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(summary.title)
                .font(.title2.weight(.black))
            Text(summary.allegation)
                .font(.headline)

            HStack(spacing: 10) {
                combatResultMetric("Evidence", "\(summary.evidence)")
                combatResultMetric("Result", summary.disposition)
            }

            Text(summary.consequence)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DesignSystem.Colors.warning)

            VStack(alignment: .leading, spacing: 5) {
                Text("WHY IT MOVED")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                ForEach(summary.decisiveCauses.prefix(3), id: \.self) { cause in
                    Text("• \(cause)")
                        .font(.caption)
                }
            }

            Button("Continue") {
                onAdvance()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func combatResultMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.heavy))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func summaryView(_ summary: YearlyOutcomeSummary) -> some View {
        // Phase 6–7: Glance-first hierarchy — top 3 beats, rest behind disclosure
        let resilienceAccent = state.resilience == .grounded ? Color.orange.opacity(0.35) : Color.green.opacity(0.28)
        let hadHardYear = summary.mainTradeoff?.tone == .warning || summary.nextYearPressure?.tone == .warning
        let recentFocus = state.yearlyStance.recentStances.prefix(2).map { $0.title }.joined(separator: " → ")
        let causeItems = causeTrailItems(from: summary)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Age \(summary.age)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
                Text("Year In Brief")
                    .font(.headline.weight(.bold))
            }

            if !state.discoverability.seenInstantMomentumYearSummary,
               let carry = state.lastYearInstantMomentumCarry,
               carry.overallStrength >= 12 {
                let carryLine = DiscoverabilityTeaching.instantMomentumCarryLine(
                    snapshot: carry,
                    resilience: state.resilience
                )
                compactItem(
                    label: "From Your Moves",
                    title: "Quick-action momentum",
                    detail: carryLine,
                    tone: .neutral
                )
                .accessibilityIdentifier("year-summary-momentum-carry")
                .onAppear {
                    onDismissMomentumCarry?()
                }
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

            if let nextYearPressure = summary.nextYearPressure {
                compactItem(label: "Carries Over", title: nextYearPressure.title, detail: nextYearPressure.detail, tone: PlannerTone(nextYearPressure.tone))
            } else if let momentum = summary.momentum {
                compactItem(label: "Momentum", title: momentum.title, detail: momentum.detail, tone: PlannerTone(momentum.tone))
            }

            if let yearlyStanceOutcome = summary.yearlyStanceOutcome {
                compactItem(label: "Goal", title: yearlyStanceOutcome.title, detail: yearlyStanceOutcome.detail, tone: PlannerTone(yearlyStanceOutcome.tone))
            } else if let focusOutcome = summary.focusOutcome {
                compactItem(label: "Pattern", title: focusOutcome.title, detail: focusOutcome.detail, tone: PlannerTone(focusOutcome.tone))
            }

            DisclosureGroup(isExpanded: $yearSummaryExpanded) {
                VStack(alignment: .leading, spacing: 8) {
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

                    if let focusOutcome = summary.focusOutcome, summary.yearlyStanceOutcome != nil {
                        compactItem(label: "Pattern", title: focusOutcome.title, detail: focusOutcome.detail, tone: PlannerTone(focusOutcome.tone))
                    }

                    if let mainTradeoff = summary.mainTradeoff {
                        compactItem(label: "Cost", title: mainTradeoff.title, detail: mainTradeoff.detail, tone: PlannerTone(mainTradeoff.tone))
                    }

                    if !recentFocus.isEmpty || state.yearlyStance.lastCompletedStance != nil {
                        compactItem(
                            label: "Shape",
                            title: state.yearlyStance.lastCompletedStance?.title ?? "Life shape",
                            detail: recentFocus.isEmpty ? "Your focus residue is shaping quiet years." : "Recent: \(recentFocus)",
                            tone: .neutral
                        )
                    }

                    if !causeItems.isEmpty {
                        CauseTrailStrip(
                            title: "Why It Moved",
                            items: Array(causeItems.prefix(2)),
                            identifier: "year-summary-cause-trail"
                        )
                    }
                }
            } label: {
                Text("More detail")
                    .font(.caption.weight(.black))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

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
        .onAppear {
            AppFeedback.impact(.medium)
            if hadHardYear {
                AppFeedback.notify(.warning)
            } else if summary.momentum != nil || state.softRunGoal?.status == .met {
                AppFeedback.notify(.success)
            } else {
                AppFeedback.impact(.light)
            }
        }
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
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text(state.resilience.shortLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(state.resilience == .grounded ? .orange : .green)
                }

                Text(forecast.title)
                    .font(.headline.weight(.bold))

                Text(forecast.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

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
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(page.tone.fill.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium, style: .continuous)
                                    .stroke(page.tone.color.opacity(0.2), lineWidth: 1)
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 154)
                    .accessibilityIdentifier("forecast-stakes-pager")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What are you protecting this year?")
                        .font(.caption.weight(.black))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("Recommended: \(recommendedStance.title)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

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
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(stance.isSelected ? PlannerTone.positive.fill.opacity(0.85) : Color.primary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.medium, style: .continuous)
                                        .stroke(stance.isSelected ? PlannerTone.positive.color.opacity(0.5) : Color.primary.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: stance.isSelected ? PlannerTone.positive.color.opacity(0.15) : .clear, radius: 6, y: 3)
                            }

                            .buttonStyle(.plain)
                            .accessibilityIdentifier("forecast-stance-\(stance.id.rawValue)")
                            .accessibilityLabel("Select \(stance.title) goal")
                            .accessibilityHint(stance.detail)
                            .accessibilityAddTraits(stance.isSelected ? .isSelected : [])
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
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(event.title)
                .font(.title3.weight(.bold))

            Text(event.displayText(echoing: state))
                .font(.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(preview.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(tone.color)

            Text(preview.detail)
                .font(.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(preview.title)
                .font(.title3.weight(.bold))

            Text(preview.detail)
                .font(.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .lineLimit(5)

            // Replayability transparency: at the end of a life, gently remind the player what "Life Feel" they chose
            if preview.title.contains("Life Closed") || preview.title.contains("Life Ended") {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.caption2)
                    Text("Your Life Feel choice shaped how this story could recover")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                .foregroundStyle(DesignSystem.Colors.textSecondary)

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
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                .foregroundStyle(DesignSystem.Colors.textSecondary)

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
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
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
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(tone.fill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func iconForCompactLabel(_ label: String) -> String {
        let lower = label.lowercased()
        if lower.contains("goal") || lower.contains("run") { return "scope" }
        if lower.contains("pattern") || lower.contains("shape") { return "point.topleft.down.curvedto.point.bottomright.up" }
        if lower.contains("cost") { return "arrow.down.right.circle" }
        if lower.contains("carries") || lower.contains("pressure") { return "exclamationmark.triangle.fill" }
        if lower.contains("momentum") { return "globe.americas.fill" }
        if lower.contains("try") || lower.contains("next") { return "lightbulb.fill" }
        if lower.contains("focus") { return "target" }
        if lower.contains("coming") { return "calendar" }
        return "circle.fill"
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


struct ActionChoiceRow: View {
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
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
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
            .background(OLTheme.cardFill(colorScheme).opacity(0.85)) // Slight transparency for glass feel
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                rowTone.fill,
                                rowTone.fill.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: rowTone.color.opacity(0.12), radius: 10, y: 5) // Soft ambient glow based on action tone
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

struct ActionSelectionModule: View {
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

struct InsightStrip: View {
    let title: String
    let insights: [PlannerInsight]
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            HStack(spacing: 8) {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
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

struct AuditStrip: View {
    let insights: [PlannerInsight]
    let identifier: String

    var body: some View {
        InsightStrip(title: "2-Second Audit", insights: insights, identifier: identifier)
    }
}

struct YearlyConsequenceStrip: View {
    let items: [YearlyOutcomeItem]
    let identifier: String

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Consequences")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

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
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .accessibilityIdentifier(identifier)
        }
    }
}

struct MomentumAgeUpTeachRow: View {
    let momentum: InstantMomentumState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(momentum.rankedDomainMomentum, id: \.domain) { entry in
                        HStack(spacing: 4) {
                            Text(momentumDomainLabel(entry.domain))
                                .font(.caption2.weight(.heavy))
                            Text("+\(entry.value)")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(Color.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
            Text(DiscoverabilityTeaching.firstMomentumAgeUpLine)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, 4)
    }

    private func momentumDomainLabel(_ domain: ActionDomain) -> String {
        switch domain {
        case .health: return "Body"
        case .finance: return "Money"
        case .relationships: return "People"
        default: return domain.rawValue.capitalized
        }
    }
}

struct AgeUpRiskPreviewStrip: View {
    let signals: [AgeUpRiskSignal]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Risk Preview")
                .font(.caption2.weight(.bold))
                .foregroundStyle(DesignSystem.Colors.textSecondary)

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

struct CauseTrailStrip: View {
    let title: String
    let items: [CauseTrailItem]
    let identifier: String

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

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
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04))
            .glassCard(radius: 12)
            .accessibilityIdentifier(identifier)
        }
    }
}

struct ChipStrip: View {
    let title: String
    let items: [String]
    let tone: PlannerTone
    let identifier: String

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(tone.fill.opacity(0.6))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(tone.color.opacity(0.15), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .accessibilityIdentifier(identifier)
        }
    }
}
