import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("Age \(vm.state.player.age)")
                        .font(.headline.bold())
                        .foregroundStyle(DesignSystem.Colors.accent)
                    Text(summary.closingLine)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 40)
                .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 14) {
                    Text("The Life")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)

                    Text(summary.relationshipLine)
                        .font(.subheadline.weight(.semibold))
                    Text(summary.reputationLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Divider().padding(.vertical, 4)

                    HStack {
                        legacyMetric("Path", summary.lifePathTitle)
                        Spacer()
                        legacyMetric("Legacy", "\(summary.legacyScore)")
                        Spacer()
                        legacyMetric("Next Life", "+\(summary.legacyPointsEarned)")
                    }
                }
                .padding(20)
                .glassCard(radius: DesignSystem.Radius.large)
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
                                .foregroundStyle(.secondary)
                            Text("$\(vm.state.finance.totalWealth)")
                                .font(.title3.bold())
                        }
                        Spacer()
                        if vm.state.assets.ownsHome {
                            VStack(alignment: .trailing) {
                                Text("Property")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text(vm.state.assets.primaryResidence?.homeValue ?? 0 > 0 ? "Bequeathed" : "None")
                                    .font(.title3.bold())
                                    .foregroundStyle(DesignSystem.Colors.positive)
                            }
                        }
                    }
                    .padding(20)
                    .glassCard(radius: DesignSystem.Radius.medium)
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
                                    .foregroundStyle(DesignSystem.Colors.accent)
                                    .frame(width: 44, height: 44)
                                    .background(DesignSystem.Colors.accent.opacity(0.15))
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
                            .padding(16)
                            .glassCard(radius: DesignSystem.Radius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        vm.finishLegacyWithoutSuccessor()
                    } label: {
                        Text(vm.state.family.children.isEmpty ? "Begin Another Life" : "Start a New Family")
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
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
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Label(item, systemImage: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(radius: DesignSystem.Radius.medium)
        .padding(.horizontal)
    }
}

