import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Phase 1: High-Quality Floating Deltas Overlay (Frictionless Visual Polish)

struct FloatingDeltasOverlay: View {
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
        case .legal: return "building.columns.fill"
        case .military: return "shield.fill"
        case .family: return "person.2.fill"
        case .identity: return "person.fill"
        }
    }
}

struct HidePlannerNavigationBar: ViewModifier {
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
struct AgeUpChromeButton: View {
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

/// Pinned domain / action shortcuts — sits on the domain bar for one-tap repeat moves.
struct DomainShortcutStrip: View {
    @ObservedObject var vm: GameViewModel
    var onOpenJournal: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(vm.domainShortcutPins) { pin in
                    Button {
                        vm.executeDomainShortcut(pin, onOpenJournal: onOpenJournal)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: pin.symbol)
                                .font(.system(size: 13, weight: .bold))
                            Text(pin.title)
                                .font(.system(size: 8, weight: .heavy))
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                        }
                        .frame(minWidth: 54)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .foregroundStyle(Color.white)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(DesignSystem.Colors.positive.opacity(0.92))
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            vm.removeDomainShortcut(id: pin.id)
                        } label: {
                            Label("Remove Shortcut", systemImage: "pin.slash")
                        }
                    }
                    .accessibilityIdentifier("domain-shortcut-\(pin.id)")
                }

                Button {
                    AppFeedback.impact(.light)
                    vm.showingDomainShortcutEditor = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: vm.domainShortcutPins.count >= GameViewModel.maxDomainShortcutPins ? "slider.horizontal.3" : "plus.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text(vm.domainShortcutPins.isEmpty ? "Pin" : "Edit")
                            .font(.system(size: 8, weight: .heavy))
                    }
                    .frame(minWidth: 48)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .foregroundStyle(.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("domain-shortcut-add-button")
            }
            .padding(.horizontal, 2)
        }
        .accessibilityIdentifier("domain-shortcut-strip")
    }
}

struct DomainShortcutEditorSheet: View {
    @ObservedObject var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !vm.domainShortcutPins.isEmpty {
                    Section("Pinned (\(vm.domainShortcutPins.count)/\(GameViewModel.maxDomainShortcutPins))") {
                        ForEach(vm.domainShortcutPins) { pin in
                            HStack(spacing: 10) {
                                Image(systemName: pin.symbol)
                                    .foregroundStyle(DesignSystem.Colors.positive)
                                Text(pin.title)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Button(role: .destructive) {
                                    vm.removeDomainShortcut(id: pin.id)
                                } label: {
                                    Image(systemName: "pin.slash")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section {
                    Text("Pin domains or quick actions you repeat often. Shortcuts fire instantly from the domain bar — no tab hunting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Add shortcut") {
                    if vm.domainShortcutPins.count >= GameViewModel.maxDomainShortcutPins {
                        Text("Remove a pin to add another.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.domainShortcutCandidates()) { candidate in
                            Button {
                                vm.addDomainShortcut(candidate)
                                AppFeedback.notify(.success)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: candidate.symbol)
                                        .frame(width: 22)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(candidate.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text(shortcutKindLabel(candidate.target))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Domain Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func shortcutKindLabel(_ target: DomainShortcutPin.Target) -> String {
        switch target {
        case .tab: return "Open domain tab"
        case .special: return "Special panel"
        case .quickAction: return "Instant action"
        }
    }
}

/// BitLife-style bottom chrome: Age Up, four domain tabs, health/journal shortcuts.
struct BitLifeGameChrome: View {
    @ObservedObject var vm: GameViewModel
    var onOpenFeed: () -> Void
    var onOpenJournal: () -> Void
    var safeAreaBottom: CGFloat

    private var canAct: Bool {
        vm.presentedCard == nil && vm.state.activeYearChapter == nil && !vm.state.isGameOver
    }

    private var ageUpRiskSignals: [AgeUpRiskSignal] {
        vm.ageUpRiskPreviewSignals()
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

            if vm.shouldShowMomentumAgeUpTeach() {
                MomentumAgeUpTeachRow(momentum: vm.state.instantMomentum)
                    .accessibilityIdentifier("momentum-age-up-teach-row")
            }

            if !ageUpRiskSignals.isEmpty {
                AgeUpRiskPreviewStrip(signals: ageUpRiskSignals)
            }

            AgeUpChromeButton(
                vm: vm,
                isEnabled: canAct && !vm.state.isGameOver && !vm.chrome.isResolvingInteraction
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

            DomainShortcutStrip(vm: vm, onOpenJournal: onOpenJournal)

            HStack(spacing: 8) {
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
                    Button {
                        vm.showingDomainShortcutEditor = true
                    } label: {
                        Label("Domain Shortcuts", systemImage: "pin.fill")
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
                    .font(.system(size: 13, weight: .bold))
                Text(vm.dockLabel(for: tab))
                    .font(.system(size: 8, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
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

func startupLoadingOverlay(title: String) -> some View {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
    .accessibilityIdentifier("startup-loading-overlay")
}


