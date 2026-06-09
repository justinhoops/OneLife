import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Character Creation Flow (BitLife Style)

private let characterNamePool: [String] = [
    // Standard Neutral
    "Alex", "Jordan", "Casey", "Morgan", "Riley",
    "Taylor", "Avery", "Quinn", "Reese", "Skyler",
    "Jamie", "Drew", "Finley", "Hayden", "Logan",
    "Parker", "Peyton", "Rowan", "Sawyer", "Spencer",
    
    // Traditional Masculine
    "Liam", "Noah", "Oliver", "Elijah", "James",
    "William", "Benjamin", "Lucas", "Henry", "Theodore",
    "Jack", "Levi", "Alexander", "Jackson", "Mateo",
    "Daniel", "Michael", "Mason", "Sebastian", "Ethan",
    
    // Traditional Feminine
    "Olivia", "Emma", "Charlotte", "Amelia", "Ava",
    "Sophia", "Isabella", "Mia", "Evelyn", "Harper",
    "Camila", "Gianna", "Abigail", "Luna", "Ella",
    "Elizabeth", "Sofia", "Emily", "Mila", "Evelyn",
    
    // Modern / Trendy
    "Kai", "Zane", "River", "Micah", "Ezra",
    "Nova", "Sage", "Asher", "Silas", "Brooks",
    "Milo", "Beau", "Jude", "Miles", "Cole",
    "Hazel", "Willow", "Ruby", "Stella", "Ivy",
    
    // Classic / Heritage
    "Arthur", "Charles", "Thomas", "George", "Edward",
    "Eleanor", "Grace", "Alice", "Lucy", "Clara",
    "Samuel", "David", "Joseph", "Matthew", "John",
    "Rose", "Jane", "Margaret", "Mary", "Anna",

    // Global / Diverse
    "Omar", "Amir", "Kofi", "Tariq", "Jamal",
    "Diego", "Javier", "Carlos", "Luis", "Miguel",
    "Elena", "Maria", "Carmen", "Rosa", "Ana",
    "Mei", "Aisha", "Fatima", "Zahara", "Yasmin",
    "Hiro", "Kenji", "Akira", "Ren", "Yuki",
    "Hana", "Sora", "Rin", "Aiko", "Emi"
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Overhauled Hero Header + Progress
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Start a New Life")
                            .font(DesignSystem.Typography.titleLarge)
                        Text("You're 14. The world is already moving. Choose your starting shape.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Step progress (4 steps, BitLife-like but premium)
                        HStack(spacing: 8) {
                            ForEach(Array(CharacterCreationStep.allCases.enumerated()), id: \.element) { index, step in
                                let isCurrent = vm.charCreationStep == step
                                let isPast = step.rawValue < vm.charCreationStep.rawValue
                                Capsule()
                                    .fill(isCurrent ? DesignSystem.Colors.accent : (isPast ? Color.primary.opacity(0.6) : Color.primary.opacity(0.2)))
                                    .frame(width: isCurrent ? 28 : 18, height: 6)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 4)

                    // Always-visible rich live preview (the heart of the overhaul)
                    if let preview = vm.originPreview {
                        enhancedOriginPreview(preview, colorScheme: colorScheme)
                            .padding(.bottom, 8)
                    }

                    // Current step content
                    switch vm.charCreationStep {
                    case .name:
                        nameSection
                    case .origin:
                        originSection
                    case .trait:
                        traitSection
                    case .resilience:
                        resilienceSection
                    }

                    Spacer().frame(height: 140) // Room for sticky footer
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }

            // Overhauled sticky Navigation Footer (more dramatic BEGIN)
            VStack(spacing: 10) {
                if vm.charCreationStep == .resilience {
                    Button {
                        AppFeedback.notify(.success)
                        vm.beginLifeSafely()
                    } label: {
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
                } else {
                    Button {
                        AppFeedback.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            vm.advanceCreation()
                        }
                    } label: {
                        Text("NEXT")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.primary)
                            .foregroundStyle(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(GameBouncyButtonStyle())
                }

                if vm.charCreationStep != .name {
                    Button {
                        AppFeedback.impact(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            vm.retreatCreation()
                        }
                    } label: {
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
        .onAppear {
            vm.clearPopupStateIfNeeded()
            if vm.originPreview == nil {
                vm.previewQuickStart()
            }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What will they call you?")
                .font(.headline.weight(.semibold))
            HStack {
                TextField("Enter a name...", text: $vm.pendingCharName)
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .autocorrectionDisabled()
#if os(iOS)
                    .textInputAutocapitalization(.words)
#endif

                Button {
                    AppFeedback.impact(.light)
                    vm.pendingCharName = randomCharacterName()
                } label: {
                    Image(systemName: "dice.fill")
                        .font(.title2)
                        .padding(14)
                        .background(Color.black.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            Text("Names are just the first story you tell.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var originSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where does your story begin?")
                .font(.headline.weight(.semibold))

            // Mode selector - big tappable cards
            HStack(spacing: 10) {
                originModeCard(title: "Quick Start", subtitle: "Roll the dice", isSelected: vm.selectedStartMode == .quickStart) {
                    vm.previewQuickStart()
                }
                originModeCard(title: "Archetype", subtitle: "Pick a template", isSelected: vm.selectedStartMode == .template) {
                    vm.previewTemplate(vm.selectedTemplate)
                }
                originModeCard(title: "Custom", subtitle: "Full control", isSelected: vm.selectedStartMode == .custom) {
                    vm.selectedStartMode = .custom
                    if vm.originPreview == nil { vm.previewQuickStart() }
                }
            }

            if vm.selectedStartMode == .template {
                Text("Choose your origin archetype")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                // Richer template grid (2-col on wide, scroll on narrow)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(OriginCatalog.templates, id: \.id) { template in
                        let isLocked = !vm.filteredTemplates.contains { $0.id == template.id } && vm.filteredTemplates.count < OriginCatalog.templates.count
                        Button {
                            if !isLocked {
                                vm.previewTemplate(template.id)
                                AppFeedback.impact(.light)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(template.title)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    if vm.selectedTemplate == template.id {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(DesignSystem.Colors.accent)
                                    } else if isLocked {
                                        Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Text(template.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                if isLocked {
                                    Text("Unlocked via legacy in another life")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(.secondary.opacity(0.7))
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(vm.selectedTemplate == template.id ? Color.black.opacity(0.85) : Color.white.opacity(0.6))
                            .foregroundStyle(vm.selectedTemplate == template.id ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(vm.selectedTemplate == template.id ? DesignSystem.Colors.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLocked)
                    }
                }
            }

            if vm.selectedStartMode == .custom {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Region & Starting Vibe")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(RegionChoice.all) { region in
                                Button {
                                    vm.pendingRegionID = region.id
                                    AppFeedback.impact(.light)
                                } label: {
                                    Text(region.displayName)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(vm.pendingRegionID == region.id ? Color.black : Color.white.opacity(0.55))
                                        .foregroundStyle(vm.pendingRegionID == region.id ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Simplified live bias (the top preview updates live)
                    Text("Tweak the numbers — the preview above reacts instantly.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.white.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if vm.selectedStartMode != .custom && vm.originPreview != nil {
                // Duplicate snapshot removed in favor of the always-on enhanced one above.
                // Keep a "reroll" affordance.
                Button {
                    AppFeedback.impact(.light)
                    vm.rerollOrigin()
                } label: {
                    Label("Reroll This Background", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var traitSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pick a defining trait (or let life surprise you)")
                .font(.headline.weight(.semibold))

            // 2-col grid for traits + surprise (more scannable)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                Button {
                    vm.pendingTraitOverride = nil
                    vm.applyPendingTraitToPreview()
                    AppFeedback.impact(.light)
                } label: {
                    HStack {
                        Text("🎲 Surprise Me")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        if vm.pendingTraitOverride == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(12)
                    .background(vm.pendingTraitOverride == nil ? Color.black.opacity(0.85) : Color.white.opacity(0.6))
                    .foregroundStyle(vm.pendingTraitOverride == nil ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                ForEach(PersonalityTrait.allCases, id: \.self) { trait in
                    Button {
                        vm.pendingTraitOverride = trait
                        vm.applyPendingTraitToPreview()
                        AppFeedback.impact(.light)
                    } label: {
                        HStack {
                            Text(trait.rawValue.capitalized)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            if vm.pendingTraitOverride == trait {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding(12)
                        .background(vm.pendingTraitOverride == trait ? Color.black.opacity(0.85) : Color.white.opacity(0.6))
                        .foregroundStyle(vm.pendingTraitOverride == trait ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            // The top preview already shows the effect live + dossier
        }
    }

    private func customStatPill(title: String, value: Binding<Int>) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Button { value.wrappedValue = max(0, value.wrappedValue - 5) } label: { Image(systemName: "minus.circle") }
                Text("\(value.wrappedValue)").font(.caption.bold()).frame(width: 30)
                Button { value.wrappedValue = min(100, value.wrappedValue + 5) } label: { Image(systemName: "plus.circle") }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    // MARK: - Overhauled Live Preview (always shown, updates with every choice)
    private func enhancedOriginPreview(_ state: GameState, colorScheme: ColorScheme) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Hero identity
            HStack(alignment: .firstTextBaseline) {
                Text(resolvedDisplayName())
                    .font(.system(size: 22, weight: .black))
                    .lineLimit(1)
                Spacer()
                Text("14 • \(regionDisplayName(for: state.finance.currentRegionPolicyID ?? "mountain_standard"))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            // Core stats in nice row (live)
            HStack(spacing: 10) {
                statPill("Smarts", state.player.smarts)
                statPill("Looks", state.player.looks)
                cashPill("Cash", "$\(state.finance.cashOnHand)")
                if let health = state.healthProfile.physicalWellness as Int? {
                    statPill("Health", health)
                }
            }

            // Backstory from origin + dossier if available (the rich narrative now in preview thanks to engine wiring)
            if let profile = state.originProfile {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Life Before 14")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    Text(profile.homeSummary)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                    if let dossier = state.childhoodDossier {
                        Text(dossier.narrative)
                            .font(.footnote.italic())
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Aptitudes + Future Seeds (showcases the deep career/ special systems)
            if let dossier = state.childhoodDossier {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Starting Shape")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    Text(dossier.visibleHints.joined(separator: "  •  "))
                        .font(.footnote.bold())
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
                .padding(.horizontal, 4)
            }

            let futures = possibleFuturePaths(from: state)
            if !futures.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Echoes of What Could Be")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                    ForEach(futures, id: \.self) { hint in
                        Text("• \(hint)")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color.white.opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.08), radius: 10, y: 4)
    }

    private func statPill(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 9, weight: .black)).foregroundStyle(.secondary)
            Text("\(value)").font(.subheadline.weight(.black))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func cashPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(size: 9, weight: .black)).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.black))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func regionDisplayName(for id: String) -> String {
        RegionChoice.all.first(where: { $0.id == id })?.displayName ?? "Unknown"
    }

    private func possibleFuturePaths(from state: GameState) -> [String] {
        var paths: [String] = []
        let p = state.player
        let prof = state.originProfile
        let dossier = state.childhoodDossier

        if let d = dossier {
            if d.aptitudes.physical >= 62 { paths.append("Athlete or military calling") }
            if d.aptitudes.entrepreneurial >= 60 { paths.append("Founder / venture lean") }
            if d.aptitudes.social >= 65 { paths.append("Politics or creator spotlight") }
            if d.aptitudes.analytical >= 65 { paths.append("Academic or corporate track") }
            if d.aptitudes.entrepreneurial >= 55 && d.aptitudes.technical >= 50 {
                paths.append("Trader or gray market edge")
            }
            if prof?.templateID == .financialStrainToughenedEarly || prof?.templateID == .chaoticHomeSelfReliant {
                paths.append("Street or gray-market opportunities")
            }
            // Now that dossier feeds special career qualification & seeding, high combos open special paths earlier/stronger
        } else {
            if p.smarts > 70 { paths.append("Sharp mind opens elite doors") }
            if p.looks > 70 { paths.append("Looks + charm = social capital") }
        }
        if p.traits.contains(.impulsive) || p.traits.contains(.coldBlooded) { paths.append("Risk and edge will find you") }
        return Array(Set(paths)).prefix(3).sorted()
    }

    // Keep old snapshot for any other uses (or remove later)
    private func originSnapshot(_ state: GameState) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(resolvedDisplayName().uppercased())
                    .font(.system(size: 14, weight: .black))
                Spacer()
                Text("Age 14")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    snapshotBlock("Home",   state.originProfile?.householdPressure ?? "—")
                    snapshotBlock("School", state.originProfile?.schoolStanding ?? "—")
                }
                HStack(spacing: 8) {
                    snapshotBlock("Cash", "$\(state.finance.cashOnHand)")
                    snapshotBlock("Smarts", "\(state.player.smarts)%")
                    snapshotBlock("Looks", "\(state.player.looks)%")
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func snapshotBlock(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func resolvedDisplayName() -> String {
        let trimmed = vm.pendingCharName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Your character" : trimmed
    }

    // MARK: - Resilience / "Life Feel" Picker (Replayability Core)
    private var resilienceSection: some View {
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
                        vm.selectedResilience = option
                        AppFeedback.impact(.light)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(option.displayName)
                                    .font(.headline.weight(.semibold))
                                Spacer()
                                if vm.selectedResilience == option {
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
                        .background(
                            vm.selectedResilience == option
                                ? Color.black.opacity(0.82)
                                : Color.white.opacity(0.55)
                        )
                        .foregroundStyle(vm.selectedResilience == option ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("You can always start another life with a different feel. Every run is a fresh story.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            if vm.originPreview != nil {
                Text("Current feel: \(vm.selectedResilience.displayName) — the preview stats above will feel the difference once you begin.")
                    .font(.caption.italic())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

extension Binding {
    func map<T>(get: @escaping (Value) -> T, set: @escaping (Value, T) -> Value) -> Binding<T> {
        Binding<T>(
            get: { get(wrappedValue) },
            set: { newValue in wrappedValue = set(wrappedValue, newValue) }
        )
    }
}
