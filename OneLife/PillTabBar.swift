import SwiftUI

// MARK: - App Store-style pill tab bar (Phase 1)
//
// See Docs/NAVIGATION-AND-TAB-PATTERN.md

struct PillTabItem: Identifiable, Equatable {
    let id: String
    let title: String
    let symbol: String?

    init(id: String, title: String, symbol: String? = nil) {
        self.id = id
        self.title = title
        self.symbol = symbol
    }
}

struct PillTabBar: View {
    let items: [PillTabItem]
    @Binding var selection: String
    var namespace: Namespace.ID
    var accent: Color = DesignSystem.Colors.accent

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items) { item in
                    pillButton(item)
                }
            }
            .padding(.horizontal, 2)
        }
        .accessibilityIdentifier("pill-tab-bar")
    }

    @ViewBuilder
    private func pillButton(_ item: PillTabItem) -> some View {
        let selected = selection == item.id
        Button {
            guard selection != item.id else { return }
            AppFeedback.impact(.light)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                selection = item.id
            }
        } label: {
            HStack(spacing: 4) {
                if let symbol = item.symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 10, weight: .bold))
                }
                Text(item.title)
                    .font(.system(size: 10, weight: .heavy))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .foregroundStyle(selected ? Color.white : Color.primary.opacity(0.85))
            .background {
                if selected {
                    Capsule()
                        .fill(accent)
                        .matchedGeometryEffect(id: "pill-selection", in: namespace)
                } else {
                    Capsule()
                        .fill(Color.primary.opacity(0.06))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pill-tab-\(item.id)")
    }
}

/// Bottom dock variant — vertical icon + label layout.
struct PillDockTabBar: View {
    let tabs: [GameViewModel.Tab]
    @ObservedObject var vm: GameViewModel
    var namespace: Namespace.ID
    var label: (GameViewModel.Tab) -> String
    var symbol: (GameViewModel.Tab) -> String
    var onSelect: (GameViewModel.Tab) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                dockButton(tab)
            }
        }
        .accessibilityIdentifier("bottom-domain-strip")
    }

    @ViewBuilder
    private func dockButton(_ tab: GameViewModel.Tab) -> some View {
        let selected = vm.selectedTab == tab && !vm.showingHealthConsole
        Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: symbol(tab))
                    .font(.system(size: 13, weight: .bold))
                Text(label(tab))
                    .font(.system(size: 8, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(selected ? Color.white : Color.primary.opacity(0.85))
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DesignSystem.Colors.accent)
                        .matchedGeometryEffect(id: "dock-pill-selection", in: namespace)
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tab.uiTestTabIdentifier)
    }
}
