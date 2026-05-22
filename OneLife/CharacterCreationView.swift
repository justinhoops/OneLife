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

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start a New Life")
                            .font(DesignSystem.Typography.titleLarge)
                        Text("You're 14. This is where it starts.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    switch vm.charCreationStep {
                    case .name:
                        nameSection
                    case .origin:
                        originSection
                    case .trait:
                        traitSection
                    }

                    Spacer().frame(height: 160) // Room for sticky buttons
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
            }

            // Navigation Footer
            VStack(spacing: 12) {
                if vm.charCreationStep == .trait {
                    Button {
                        AppFeedback.notify(.success)
                        vm.beginLife()
                    } label: {
                        Text("BEGIN LIFE")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: DesignSystem.Colors.accent.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(GameBouncyButtonStyle())
                } else {
                    Button {
                        AppFeedback.impact(.light)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.advanceCreation()
                        }
                    } label: {
                        Text("NEXT STEP")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.primary)
                            .foregroundStyle(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .buttonStyle(GameBouncyButtonStyle())
                }

                if vm.charCreationStep != .name {
                    Button {
                        AppFeedback.impact(.light)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.retreatCreation()
                        }
                    } label: {
                        Text("Go Back")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
            .background(
                LinearGradient(colors: [Color(UIColor.systemBackground).opacity(0), Color(UIColor.systemBackground), Color(UIColor.systemBackground)], startPoint: .top, endPoint: .bottom)
            )
        }
        .onAppear {
            if vm.originPreview == nil {
                vm.previewQuickStart()
            }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identity").font(.headline)
            HStack {
                TextField("Enter a name...", text: $vm.pendingCharName)
                    .font(.title3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .autocorrectionDisabled()
#if os(iOS)
                    .textInputAutocapitalization(.words)
#endif

                Button {
                    vm.pendingCharName = randomCharacterName()
                } label: {
                    Image(systemName: "dice.fill")
                        .font(.title3)
                        .padding()
                        .background(Color.white.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var originSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Starting Background").font(.headline)
            
            HStack(spacing: 8) {
                Button { vm.previewQuickStart() } label: {
                    originModeCard(title: "Quick", subtitle: "Random", isSelected: vm.selectedStartMode == .quickStart)
                }
                .buttonStyle(.plain)

                Button { vm.previewTemplate(vm.selectedTemplate) } label: {
                    originModeCard(title: "Archetype", subtitle: "Select", isSelected: vm.selectedStartMode == .template)
                }
                .buttonStyle(.plain)
                
                Button {
                    vm.selectedStartMode = .custom
                    if vm.originPreview == nil { vm.previewQuickStart() }
                    vm.selectedStartMode = .custom
                } label: {
                    originModeCard(title: "Custom", subtitle: "Control", isSelected: vm.selectedStartMode == .custom)
                }
                .buttonStyle(.plain)
            }

            if vm.selectedStartMode == .template {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(OriginCatalog.templates, id: \.id) { template in
                            Button { vm.previewTemplate(template.id) } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(template.title).font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(vm.selectedTemplate == template.id ? Color.white : Color.primary)
                                .padding(14)
                                .background(vm.selectedTemplate == template.id ? Color.black.opacity(0.82) : Color.white.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 4)
            }

            if vm.selectedStartMode == .custom {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Economic Region").font(.caption.bold()).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(RegionChoice.all) { region in
                                Button {
                                    vm.pendingRegionID = region.id
                                    AppFeedback.impact(.light)
                                } label: {
                                    Text(region.displayName)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(vm.pendingRegionID == region.id ? Color.black : Color.white.opacity(0.4))
                                        .foregroundStyle(vm.pendingRegionID == region.id ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Text("Stat Bias").font(.caption.bold()).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        customStatPill(title: "Smarts", value: $vm.originPreview.map(get: { $0?.player.smarts ?? 0 }, set: { state, val in var s = state; s?.player.smarts = val; return s }))
                        customStatPill(title: "Looks", value: $vm.originPreview.map(get: { $0?.player.looks ?? 0 }, set: { state, val in var s = state; s?.player.looks = val; return s }))
                        customStatPill(title: "Wealth", value: $vm.originPreview.map(get: { ($0?.finance.cashOnHand ?? 0)/100 }, set: { state, val in var s = state; s?.finance.cashOnHand = val * 100; return s }))
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else if let preview = vm.originPreview {
                originSnapshot(preview)
                Button("Randomize Details") {
                    AppFeedback.impact(.light)
                    vm.rerollOrigin()
                }
                .buttonStyle(.bordered)
                .font(.subheadline)
            }
        }
    }

    private var traitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Starting Trait").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        vm.pendingTraitOverride = nil
                        vm.applyPendingTraitToPreview()
                    } label: {
                        Text("Surprise Me")
                            .font(.caption.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(vm.pendingTraitOverride == nil ? Color.black : Color.white.opacity(0.4))
                            .foregroundStyle(vm.pendingTraitOverride == nil ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    ForEach(PersonalityTrait.allCases, id: \.self) { trait in
                        Button {
                            vm.pendingTraitOverride = trait
                            vm.applyPendingTraitToPreview()
                        } label: {
                            Text(trait.rawValue.capitalized)
                                .font(.caption.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(vm.pendingTraitOverride == trait ? Color.black : Color.white.opacity(0.4))
                                .foregroundStyle(vm.pendingTraitOverride == trait ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if let preview = vm.originPreview {
                originSnapshot(preview)
                    .padding(.top, 16)
            }
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

    private func originModeCard(title: String, subtitle: String, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(isSelected ? Color.white.opacity(0.82) : .secondary)
                .lineLimit(1)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.black.opacity(0.82) : Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

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
}

extension Binding {
    func map<T>(get: @escaping (Value) -> T, set: @escaping (Value, T) -> Value) -> Binding<T> {
        Binding<T>(
            get: { get(wrappedValue) },
            set: { newValue in wrappedValue = set(wrappedValue, newValue) }
        )
    }
}
