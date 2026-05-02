import SwiftUI

// MARK: - Character Creation Flow
//
// Codex IX: Voice, Echo, Silence & Mood.
// The player must feel ownership of this character before age 14 begins.
// Five steps: Name → Location → Origin → Trait → Preview.

// MARK: - Step Enum

enum CharacterCreationStep: Int, CaseIterable {
    case name     = 0
    case location = 1
    case origin   = 2
    case trait    = 3
    case preview  = 4

    var title: String {
        switch self {
        case .name:     return "Name"
        case .location: return "Location"
        case .origin:   return "Background"
        case .trait:    return "Trait"
        case .preview:  return "Preview"
        }
    }
}

// MARK: - Region Model

struct RegionChoice: Identifiable {
    var id: String
    var displayName: String
    var tagline: String
    var detail: String
    var costLabel: String
    var ceilingLabel: String
}

extension RegionChoice {
    static let all: [RegionChoice] = [
        RegionChoice(
            id: "mountain_standard",
            displayName: "Midwest / Mountain",
            tagline: "Average cost. Average ceiling. Entirely yours.",
            detail: "Stable enough to catch your breath. Not expensive enough to trap you. The life here is whatever you build it into.",
            costLabel: "Affordable",
            ceilingLabel: "Moderate"
        ),
        RegionChoice(
            id: "expensive_coastal",
            displayName: "Coastal City",
            tagline: "Rent is brutal. Opportunity is real.",
            detail: "Everything costs more — rent, food, the bus. The ceiling is higher too, but the gap between struggling and thriving is thin and mean.",
            costLabel: "Expensive",
            ceilingLabel: "High"
        ),
        RegionChoice(
            id: "factory_town",
            displayName: "Small Town / Rural",
            tagline: "Cheap to live. Hard to leave.",
            detail: "The cost of living is low. The ladder has fewer rungs. Some people get out. Most people don't think about it.",
            costLabel: "Cheap",
            ceilingLabel: "Limited"
        )
    ]
}

// MARK: - Trait Voice Lines

extension PersonalityTrait {
    /// First-person character voice at age 14. Used in character creation.
    var creationVoiceLine: String {
        switch self {
        case .disciplined:
            return "You finish what you start. Even when you don't want to."
        case .impulsive:
            return "You decide fast. Sometimes that's the whole problem."
        case .charismatic:
            return "People come to you. You're still figuring out what to do with that."
        case .anxious:
            return "You think three steps ahead. Which means you're always worried about step two."
        case .lucky:
            return "Things just work out more than they should. You don't ask why."
        case .manipulative:
            return "You can read what people want fast. What you do with that is the dangerous part."
        case .coldBlooded:
            return "You stay calm when other people panic. It makes you useful and a little hard to know."
        case .visionary:
            return "You keep seeing the bigger picture, even when nobody asked for one."
        case .burnoutProne:
            return "You push harder than you should, then feel the cost all at once."
        }
    }

    var creationLabel: String {
        switch self {
        case .disciplined: return "Disciplined"
        case .impulsive:   return "Impulsive"
        case .charismatic: return "Charismatic"
        case .anxious:     return "Anxious"
        case .lucky:       return "Lucky"
        case .manipulative: return "Manipulative"
        case .coldBlooded: return "Cold-Blooded"
        case .visionary: return "Visionary"
        case .burnoutProne: return "Burnout-Prone"
        }
    }
}

// MARK: - Random Name Pool

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

// MARK: - CharacterCreationView

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

                    // Name Section
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
                                .textInputAutocapitalization(.words)

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

                    // Origin & Region Section
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

                    // Trait Section
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

                                ForEach(PersonalityTrait.allCases) { trait in
                                    Button {
                                        vm.pendingTraitOverride = trait
                                        vm.applyPendingTraitToPreview()
                                    } label: {
                                        Text(trait.creationLabel)
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
                    }

                    Spacer().frame(height: 100) // Room for sticky button
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
            }

            // Big Begin Button
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
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
        }
        .onAppear {
            if vm.originPreview == nil {
                vm.previewQuickStart()
            }
        }
    }

    // MARK: Step Indicator (Removed/Hidden)

    private var stepIndicator: some View { EmptyView() }

    // MARK: Step Dispatch (Removed/Hidden)

    @ViewBuilder
    private var stepContent: some View { EmptyView() }


    // MARK: - Step 1: Name

    private var nameStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your name?")
                        .font(DesignSystem.Typography.titleLarge)
                    Text("You're 14. This is where it starts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    TextField("Enter a name...", text: $vm.pendingCharName)
                        .font(.title3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .onSubmit { vm.advanceCreation() }

                    Button {
                        vm.pendingCharName = randomCharacterName()
                    } label: {
                        Label("Pick a name for me", systemImage: "shuffle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 20)

                creationNavRow(
                    canGoBack: false,
                    continueLabel: "Continue",
                    continueAction: { vm.advanceCreation() }
                )
            }
            .padding(.bottom, 28)
        }
    }

    // MARK: - Step 2: Location

    private var locationStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where did you grow up?")
                        .font(DesignSystem.Typography.titleLarge)
                    Text("Your zip code shapes your starting ceiling.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    ForEach(RegionChoice.all) { region in
                        Button {
                            AppFeedback.impact(.light)
                            vm.pendingRegionID = region.id
                        } label: {
                            regionCard(region, selected: vm.pendingRegionID == region.id)
                        }
                        .buttonStyle(.plain)
                    }
                }

                creationNavRow(
                    canGoBack: true,
                    continueLabel: "Continue",
                    continueAction: { vm.advanceCreation() }
                )
            }
            .padding(.bottom, 28)
        }
    }

    private func regionCard(_ region: RegionChoice, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(region.displayName)
                    .font(.headline)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.white)
                }
            }

            Text(region.tagline)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selected ? Color.white.opacity(0.9) : Color.primary)

            Text(region.detail)
                .font(.caption)
                .foregroundStyle(selected ? Color.white.opacity(0.75) : Color.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                regionBadge("Cost", value: region.costLabel, selected: selected)
                regionBadge("Ceiling", value: region.ceilingLabel, selected: selected)
            }
        }
        .foregroundStyle(selected ? Color.white : Color.primary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? DesignSystem.Colors.background.opacity(0.82) : DesignSystem.Colors.textPrimary.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func regionBadge(_ label: String, value: String, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(selected ? Color.white.opacity(0.6) : Color.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.white : Color.primary)
        }
    }

    // MARK: - Step 3: Origin (existing system, kept intact)

    private var originStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What was home like?")
                        .font(DesignSystem.Typography.titleLarge)
                    Text("Pick a starting template or let it be random. You can reroll the details.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Mode toggle
                HStack(spacing: 8) {
                    Button { vm.previewQuickStart() } label: {
                        originModeCard(
                            title: "Quick",
                            subtitle: "Weighted random.",
                            isSelected: vm.selectedStartMode == .quickStart
                        )
                    }
                    .buttonStyle(.plain)

                    Button { vm.previewTemplate(vm.selectedTemplate) } label: {
                        originModeCard(
                            title: "Templates",
                            subtitle: "Archetype picks.",
                            isSelected: vm.selectedStartMode == .template
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        vm.selectedStartMode = .custom
                        if vm.originPreview == nil { vm.previewQuickStart() }
                        vm.selectedStartMode = .custom
                    } label: {
                        originModeCard(
                            title: "Custom",
                            subtitle: "Direct control.",
                            isSelected: vm.selectedStartMode == .custom
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Custom editors (only when custom mode)
                if vm.selectedStartMode == .custom {
                    VStack(alignment: .leading, spacing: 16) {
                        // Region override
                        VStack(alignment: .leading, spacing: 10) {
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
                        }

                        // Stat adjustments (Simplified for UX)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Stat Bias").font(.caption.bold()).foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                customStatPill(title: "Smarts", value: $vm.originPreview.map { $0.player.smarts } ?? .constant(0))
                                customStatPill(title: "Looks", value: $vm.originPreview.map { $0.player.looks } ?? .constant(0))
                                customStatPill(title: "Wealth", value: $vm.originPreview.map { $0.finance.cashOnHand / 10 } ?? .constant(0))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                // Template picker (only when template mode)
                if vm.selectedStartMode == .template {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(OriginCatalog.templates, id: \.id) { template in
                                Button { vm.previewTemplate(template.id) } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(template.title)
                                            .font(.subheadline.weight(.semibold))
                                        Text(template.summary)
                                            .font(.caption)
                                            .foregroundStyle(vm.selectedTemplate == template.id ? Color.white.opacity(0.82) : .secondary)
                                            .lineLimit(3)
                                    }
                                    .foregroundStyle(vm.selectedTemplate == template.id ? Color.white : Color.primary)
                                    .padding(14)
                                    .frame(width: 190, alignment: .leading)
                                    .background(vm.selectedTemplate == template.id ? Color.black.opacity(0.82) : Color.white.opacity(0.55))
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }

                // Preview snapshot
                if let preview = vm.originPreview {
                    originSnapshot(preview)

                    Button("Randomize Details") {
                        AppFeedback.impact(.light)
                        vm.rerollOrigin()
                    }
                    .buttonStyle(.bordered)
                    .font(.subheadline)
                }

                creationNavRow(
                    canGoBack: true,
                    continueLabel: "Continue",
                    continueEnabled: vm.originPreview != nil,
                    continueAction: { vm.advanceCreation() }
                )
            }
            .padding(.bottom, 28)
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
                .lineLimit(3)
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

    // MARK: - Step 4: Trait

    private var traitStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("One thing that's already true about you.")
                        .font(DesignSystem.Typography.titleLarge)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("This shapes how you move through events. It's not everything — just the loudest part.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    ForEach(PersonalityTrait.allCases) { trait in
                        Button {
                            AppFeedback.impact(.light)
                            vm.pendingTraitOverride = trait
                        } label: {
                            traitCard(trait, selected: vm.pendingTraitOverride == trait)
                        }
                        .buttonStyle(.plain)
                    }

                    // Surprise me
                    Button {
                        AppFeedback.impact(.light)
                        vm.pendingTraitOverride = nil
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Surprise me")
                                    .font(.subheadline.weight(.semibold))
                                Text("Let the game decide. Based on your origin.")
                                    .font(.caption)
                                    .foregroundStyle(vm.pendingTraitOverride == nil ? Color.white.opacity(0.7) : Color.secondary)
                            }
                            Spacer()
                            if vm.pendingTraitOverride == nil {
                                Image(systemName: "shuffle.circle.fill")
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                        }
                        .foregroundStyle(vm.pendingTraitOverride == nil ? Color.white : Color.primary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(vm.pendingTraitOverride == nil ? Color.black.opacity(0.82) : Color.white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                creationNavRow(
                    canGoBack: true,
                    continueLabel: "Preview Life",
                    continueAction: {
                        vm.applyPendingTraitToPreview()
                        vm.advanceCreation()
                    }
                )
            }
            .padding(.bottom, 28)
        }
    }

    private func traitCard(_ trait: PersonalityTrait, selected: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(trait.creationLabel)
                    .font(.subheadline.weight(.semibold))
                Text(trait.creationVoiceLine)
                    .font(.caption)
                    .foregroundStyle(selected ? Color.white.opacity(0.78) : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.white)
                    .padding(.top, 2)
            }
        }
        .foregroundStyle(selected ? Color.white : Color.primary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? DesignSystem.Colors.background.opacity(0.82) : DesignSystem.Colors.textPrimary.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Step 5: Preview + Begin

    private var previewStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    let name = resolvedDisplayName()
                    Text("\(name) — Age 14.")
                        .font(DesignSystem.Typography.titleLarge)
                    Text("This is who you're starting with. The real shaping happens from here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let preview = vm.originPreview {
                    fullPreviewCard(preview)
                }

                // Vignette — the opening scene
                if let vignette = vm.originPreview?.openingSummary {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Opening")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(vignette)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                VStack(spacing: 10) {
                    Button {
                        AppFeedback.notify(.success)
                        vm.beginLife()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Begin at 14", systemImage: "play.fill")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.black.opacity(0.82))
                    .accessibilityIdentifier("begin-life-button")

                    Button {
                        vm.retreatCreation()
                    } label: {
                        Text("Go back")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 28)
        }
    }

    private func fullPreviewCard(_ state: GameState) -> some View {
        VStack(spacing: 10) {
            // Stats row
            HStack(spacing: 8) {
                statBlock("Cash", "$\(state.finance.cashOnHand)", state.finance.cashOnHand >= 500 ? .green : (state.finance.cashOnHand <= 100 ? .red : .primary))
                statBlock("Stress", "\(state.finance.financialStress)", state.finance.financialStress >= 28 ? .red : .primary)
                statBlock("Health", "\(state.player.health)", state.player.health < 50 ? .red : .primary)
                statBlock("Smarts", "\(state.player.smarts)", .primary)
            }

            // Region
            if let regionID = state.finance.currentRegionPolicyID,
               let region = RegionChoice.all.first(where: { $0.id == regionID }) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.secondary)
                    Text(region.displayName)
                        .font(.subheadline)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(region.tagline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Traits
            if !state.player.traits.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(state.player.traits) { trait in
                            HStack(spacing: 6) {
                                Text(trait.creationLabel)
                                    .font(.caption.weight(.semibold))
                                Text("·")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(trait.creationVoiceLine)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.black.opacity(0.06))
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Narrative arcs preview
            if !state.narrativeArcs.previewTensionLabels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(state.narrativeArcs.previewTensionLabels, id: \.self) { label in
                            Text(label)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.white.opacity(0.45))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func statBlock(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Nav Row

    private func creationNavRow(
        canGoBack: Bool,
        continueLabel: String,
        continueEnabled: Bool = true,
        continueAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            if canGoBack {
                Button {
                    AppFeedback.impact(.light)
                    vm.retreatCreation()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding(14)
                        .background(Color.white.opacity(0.55))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Button {
                AppFeedback.impact(.light)
                continueAction()
            } label: {
                Text(continueLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.black.opacity(0.82))
            .disabled(!continueEnabled)
        }
    }

    // MARK: - Helpers

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

