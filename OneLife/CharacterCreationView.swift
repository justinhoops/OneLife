import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Character Creation Flow (BitLife Style)

private let characterNamePool: [String] = [
    "Alex", "Jordan", "Casey", "Morgan", "Riley",
    "Taylor", "Avery", "Quinn", "Reese", "Skyler",
    "Jamie", "Drew", "Finley", "Hayden", "Logan",
    "Parker", "Peyton", "Rowan", "Sawyer", "Spencer",
    "Liam", "Noah", "Oliver", "Elijah", "James",
    "William", "Benjamin", "Lucas", "Henry", "Theodore",
    "Olivia", "Emma", "Charlotte", "Amelia", "Ava",
    "Sophia", "Isabella", "Mia", "Evelyn", "Harper",
    "Kai", "Zane", "River", "Micah", "Ezra",
    "Nova", "Sage", "Asher", "Silas", "Brooks",
    "Arthur", "Charles", "Thomas", "George", "Edward",
    "Eleanor", "Grace", "Alice", "Lucy", "Clara",
    "Omar", "Amir", "Kofi", "Tariq", "Jamal",
    "Diego", "Javier", "Elena", "Maria", "Mei"
]

func randomCharacterName() -> String {
    characterNamePool.randomElement() ?? "Alex"
}

struct RegionChoice: Identifiable {
    let id: String
    let displayName: String

    static let all: [RegionChoice] = [
        RegionChoice(id: "mountain_standard", displayName: "Mountain Standard"),
        RegionChoice(id: "expensive_coastal", displayName: "Expensive Coastal"),
        RegionChoice(id: "factory_town", displayName: "Factory Town")
    ]
}

struct CharacterCreationView: View {
    @ObservedObject var vm: GameViewModel
    @StateObject private var creation = CharacterCreationViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    CreationHeaderSection(step: creation.draft.step)

                    if let card = creation.previewCard {
                        CreationPreviewCardView(card: card, colorScheme: colorScheme)
                    } else if creation.draft.step != .name {
                        previewPrompt
                    }

                    switch creation.draft.step {
                    case .name:
                        CreationNameSection(
                            name: $creation.draft.pendingName,
                            onRandomize: { creation.draft.pendingName = randomCharacterName() }
                        )
                    case .origin:
                        CreationOriginSection(
                            draft: $creation.draft,
                            availableTemplates: vm.filteredTemplates,
                            onModeChange: { creation.clearPreview() },
                            onReroll: { refreshPreview() }
                        )
                    case .trait:
                        CreationTraitSection(
                            selectedTrait: $creation.draft.pendingTrait,
                            onTraitChange: { creation.clearPreview() }
                        )
                    case .resilience:
                        CreationResilienceSection(selection: $creation.draft.selectedResilience)
                    }

                    Spacer().frame(height: 140)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }

            CreationFooterSection(
                step: creation.draft.step,
                isRefreshingPreview: creation.isRefreshingPreview,
                onBack: {
                    AppFeedback.impact(.light)
                    creation.retreatStep()
                },
                onNext: {
                    AppFeedback.impact(.light)
                    if creation.draft.step == .origin, creation.previewCard == nil {
                        refreshPreview()
                    }
                    creation.advanceStep()
                },
                onPreview: { refreshPreview() },
                onBegin: {
                    AppFeedback.notify(.success)
                    vm.beginLifeSafely(from: creation.draft)
                }
            )
        }
        .accessibilityIdentifier("character-creation-screen")
        .onAppear {
            vm.clearPopupStateIfNeeded()
            creation.reset()
        }
    }

    private var previewPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview your starting conditions when you're ready — nothing heavy runs while you type.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                AppFeedback.impact(.light)
                refreshPreview()
            } label: {
                Label(
                    creation.isRefreshingPreview ? "Building Preview…" : "Preview Starting Conditions",
                    systemImage: "eye.fill"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(creation.isRefreshingPreview)
        }
        .padding(12)
        .background(Color.white.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func refreshPreview() {
        creation.refreshPreview { draft in
            await vm.makeCreationPreviewCard(for: draft)
        }
    }
}

// MARK: - Sections

private struct CreationHeaderSection: View {
    let step: CharacterCreationStep

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start a New Life")
                .font(DesignSystem.Typography.titleLarge)
            Text("You're 14. The world is already moving. Choose your starting shape.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(CharacterCreationStep.allCases, id: \.self) { item in
                    let isCurrent = step == item
                    let isPast = item.rawValue < step.rawValue
                    Capsule()
                        .fill(isCurrent ? DesignSystem.Colors.accent : (isPast ? Color.primary.opacity(0.6) : Color.primary.opacity(0.2)))
                        .frame(width: isCurrent ? 28 : 18, height: 6)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 4)
    }
}

private struct CreationNameSection: View {
    @Binding var name: String
    let onRandomize: () -> Void

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Enter a name...", text: $name)
                        .font(.title3.weight(.semibold))
                        .autocorrectionDisabled()
#if os(iOS)
                        .textInputAutocapitalization(.words)
#endif
                    Button(action: onRandomize) {
                        Image(systemName: "dice.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("What will they call you?")
            } footer: {
                Text("Names are just the first story you tell.")
            }
        }
        .scrollDisabled(true)
        .frame(minHeight: 160)
    }
}

private struct CreationOriginSection: View {
    @Binding var draft: CharacterCreationDraft
    let availableTemplates: [OriginTemplateDefinition]
    let onModeChange: () -> Void
    let onReroll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where does your story begin?")
                .font(.headline.weight(.semibold))

            HStack(spacing: 10) {
                originModeCard(title: "Quick Start", subtitle: "Roll the dice", isSelected: draft.selectedStartMode == .quickStart) {
                    draft.selectedStartMode = .quickStart
                    onModeChange()
                }
                originModeCard(title: "Archetype", subtitle: "Pick a template", isSelected: draft.selectedStartMode == .template) {
                    draft.selectedStartMode = .template
                    onModeChange()
                }
                originModeCard(title: "Custom", subtitle: "Full control", isSelected: draft.selectedStartMode == .custom) {
                    draft.selectedStartMode = .custom
                    onModeChange()
                }
            }

            if draft.selectedStartMode == .template {
                Text("Choose your origin archetype")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(OriginCatalog.templates, id: \.id) { template in
                        let isLocked = !availableTemplates.contains { $0.id == template.id } && availableTemplates.count < OriginCatalog.templates.count
                        Button {
                            guard !isLocked else { return }
                            draft.selectedTemplate = template.id
                            onModeChange()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(template.title)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    if draft.selectedTemplate == template.id {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(DesignSystem.Colors.accent)
                                    } else if isLocked {
                                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Text(template.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(draft.selectedTemplate == template.id ? Color.black.opacity(0.85) : Color.white.opacity(0.6))
                            .foregroundStyle(draft.selectedTemplate == template.id ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(isLocked)
                    }
                }
            }

            if draft.selectedStartMode == .custom {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Region")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(RegionChoice.all) { region in
                                Button {
                                    draft.pendingRegionID = region.id
                                } label: {
                                    Text(region.displayName)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(draft.pendingRegionID == region.id ? Color.black : Color.white.opacity(0.55))
                                        .foregroundStyle(draft.pendingRegionID == region.id ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button(action: onReroll) {
                Label("Reroll Background & Preview", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
        }
    }

    private func originModeCard(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : .secondary)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.black.opacity(0.85) : Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CreationTraitSection: View {
    @Binding var selectedTrait: PersonalityTrait?
    let onTraitChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pick a defining trait (or let life surprise you)")
                .font(.headline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                Button {
                    selectedTrait = nil
                    onTraitChange()
                } label: {
                    traitCell(title: "🎲 Surprise Me", isSelected: selectedTrait == nil)
                }
                .buttonStyle(.plain)

                ForEach(PersonalityTrait.allCases, id: \.self) { trait in
                    Button {
                        selectedTrait = trait
                        onTraitChange()
                    } label: {
                        traitCell(title: trait.rawValue.capitalized, isSelected: selectedTrait == trait)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func traitCell(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .padding(12)
        .background(isSelected ? Color.black.opacity(0.85) : Color.white.opacity(0.6))
        .foregroundStyle(isSelected ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct CreationResilienceSection: View {
    @Binding var selection: LifeResilience

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Life Feel")
                    .font(.title2.weight(.black))
                Text("How much bite do you want in this life?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(LifeResilience.allCases, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(option.displayName)
                                    .font(.headline.weight(.semibold))
                                Spacer()
                                if selection == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(DesignSystem.Colors.accent)
                                }
                            }
                            Text(option.description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selection == option ? Color.black.opacity(0.82) : Color.white.opacity(0.55))
                        .foregroundStyle(selection == option ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("You can always start another life with a different feel.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}

private struct CreationFooterSection: View {
    let step: CharacterCreationStep
    let isRefreshingPreview: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onPreview: () -> Void
    let onBegin: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if step == .resilience {
                Button(action: onBegin) {
                    HStack {
                        Text("BEGIN LIFE")
                            .font(.headline.weight(.black))
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: DesignSystem.Colors.accent.opacity(0.35), radius: 14, x: 0, y: 8)
                }
                .buttonStyle(GameBouncyButtonStyle())
                .accessibilityIdentifier("begin-life-button")
            } else {
                Button(action: onNext) {
                    Text("NEXT")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.primary)
                        .foregroundStyle(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(GameBouncyButtonStyle())
                .accessibilityIdentifier("creation-next-button")

                if step == .trait || step == .origin {
                    Button(action: onPreview) {
                        Text(isRefreshingPreview ? "Building Preview…" : "Preview Starting Conditions")
                            .font(.subheadline.weight(.semibold))
                    }
                    .disabled(isRefreshingPreview)
                }
            }

            if step != .name {
                Button(action: onBack) {
                    Text("Back")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .background(
            LinearGradient(colors: [Color(UIColor.systemBackground).opacity(0), Color(UIColor.systemBackground), Color(UIColor.systemBackground)], startPoint: .top, endPoint: .bottom)
        )
    }
}

private struct CreationPreviewCardView: View {
    let card: CreationPreviewCard
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(card.displayName)
                    .font(.system(size: 22, weight: .black))
                    .lineLimit(1)
                Spacer()
                Text("14 • \(card.regionName)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                statPill("Smarts", card.smarts)
                statPill("Looks", card.looks)
                statPill("Cash", "$\(card.cashOnHand)")
                statPill("Health", card.health)
            }

            if let homeSummary = card.homeSummary {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Life Before 14")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    Text(homeSummary)
                        .font(.footnote)
                        .lineLimit(3)
                    if let narrative = card.dossierNarrative {
                        Text(narrative)
                            .font(.footnote.italic())
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if !card.visibleHints.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Starting Shape")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    Text(card.visibleHints.joined(separator: "  •  "))
                        .font(.footnote.bold())
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
            }

            if !card.futurePathHints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Echoes of What Could Be")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    ForEach(card.futurePathHints, id: \.self) { hint in
                        Text("• \(hint)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color.white.opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func statPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 9, weight: .black)).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.black))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statPill(_ label: String, _ value: Int) -> some View {
        statPill(label, "\(value)")
    }
}
