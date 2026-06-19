import Combine
import SwiftUI

// MARK: - Character Creation Overhaul Models (Phase 1)

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male, female, nonBinary
    var id: String { rawValue }
}

enum Background: String, Codable, CaseIterable, Identifiable {
    case average
    case wealthy
    case poor
    case immigrant
    case militaryFamily
    case singleParent
    case academicGrind
    case streetHustler
    case rebel
    case blueCollar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .average: return "Average Suburbs"
        case .wealthy: return "Trust Fund / Affluent"
        case .poor: return "Working Poor / Struggling"
        case .immigrant: return "New to the Country"
        case .militaryFamily: return "Military Family"
        case .singleParent: return "Single Parent Household"
        case .academicGrind: return "Academic / Scholar Path"
        case .streetHustler: return "Street Smart / Hustler"
        case .rebel: return "Rebel / Troublemaker"
        case .blueCollar: return "Blue Collar Roots"
        }
    }

    var cashRange: ClosedRange<Int> {
        switch self {
        case .wealthy: return 25000...60000
        case .average: return 3000...8000
        case .poor, .singleParent, .immigrant: return 200...1500
        case .militaryFamily, .blueCollar: return 1500...5000
        case .academicGrind: return 2000...6000
        case .streetHustler, .rebel: return 500...3000
        }
    }

    var possibleStarterAssetTypes: [String] {
        switch self {
        case .wealthy: return ["luxury_car", "small_investment_portfolio"]
        case .average: return ["used_car", "basic_savings"]
        case .poor, .singleParent: return ["old_bike", "family_heirloom"]
        case .immigrant: return ["family_savings", "work_tools"]
        case .militaryFamily: return ["military_memento", "reliable_truck"]
        case .blueCollar: return ["work_truck", "tools_set"]
        case .academicGrind: return ["laptop", "books_collection"]
        case .streetHustler, .rebel: return ["beat_up_car", "street_gear"]
        }
    }
}

struct CharacterTemplate: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let baseStats: [String: Int] // e.g. "smarts": 50, "looks": 45, etc.
    let traits: [String] // trait raw values
    let background: Background
    let startingCashRange: ClosedRange<Int>
}

struct AppearanceDesc: Codable, Equatable {
    var height: String = "average"
    var build: String = "average"
    var hair: String = "brown"
    var eyes: String = "brown"
    var style: String = "casual"
}

struct MorphParams: Equatable {
    var name: String = ""
    var pointsToSpend: Int = 10
    var statDeltas: [String: Int] = [:]
    var selectedTraits: Set<String> = []
    var chosenBackground: Background = .average
}

struct Character: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var birthYear: Int
    var gender: Gender
    var traits: Set<String>
    var stats: [String: Int]
    var background: Background
    var appearance: AppearanceDesc
    var startingAssets: [String] // asset type ids or simple refs
}

// MARK: - Generation Helpers (Phase 1)
extension Character {
    static func generateRandom(seed: Int? = nil) -> Character {
        let rng = seed.map { s in { (max: Int) -> Int in (s &* 1103515245 + 12345) % 2147483647 % max } } ?? { max in Int.random(in: 0..<max) }
        let name = randomCharacterName()
        let bg = Background.allCases.randomElement()!
        var stats: [String: Int] = ["smarts": 45, "looks": 45, "health": 55, "happiness": 50, "reputation": 40]
        // variance
        for key in stats.keys {
            stats[key] = (stats[key]! + (rng(21) - 10)).clamped(to: 20...80)
        }
        let traits = Set(["resilient", "curious"].shuffled().prefix(2).map { $0 })
        let gender: Gender = [.male, .female, .nonBinary].randomElement()!
        let app = AppearanceDesc()
        let assets = bg.possibleStarterAssetTypes.prefix(1).map { $0 }
        return Character(id: UUID(), name: name, birthYear: 2000 + rng(20), gender: gender, traits: traits, stats: stats, background: bg, appearance: app, startingAssets: Array(assets))
    }
}

extension CharacterTemplate {
    static let presets: [CharacterTemplate] = [
        CharacterTemplate(id: UUID(), name: "Average Joe", description: "Solid middle ground. Reliable but unremarkable start.", baseStats: ["smarts":50,"looks":48,"health":55,"happiness":52,"reputation":45], traits: ["average","steady"], background: .average, startingCashRange: 3000...8000),
        CharacterTemplate(id: UUID(), name: "Trust Fund Kid", description: "Head start in cash, risk of entitlement.", baseStats: ["smarts":55,"looks":60,"health":60,"happiness":45,"reputation":55], traits: ["privileged","ambitious"], background: .wealthy, startingCashRange: 25000...60000),
        CharacterTemplate(id: UUID(), name: "Street Hustler", description: "Low cash, high street smarts and grit.", baseStats: ["smarts":40,"looks":45,"health":58,"happiness":48,"reputation":35], traits: ["hustler","resilient"], background: .streetHustler, startingCashRange: 500...3000),
        // Add 4+ more as needed
    ]
}

// End new models

extension CharacterCreationViewModel {
    func generateStarterAssets(for background: Background) -> [String] {
        return Array(background.possibleStarterAssetTypes.prefix(1))
    }

    func applyBackgroundToDraft(_ bg: Background) {
        draft.selectedBackground = bg
        // In full flow, this would adjust preview stats/cash
    }

    func generateAndApplyStarterAssets(to state: inout GameState, background: Background) {
        let starters = generateStarterAssets(for: background)
        // Tie into existing AssetState (simplified for Phase 1)
        // For demo, just log; real would add to state.assets
        print("Starter assets for \(background): \(starters)")
        // Example: could set state.assets.signatureAssets or vehicles etc.
    }
}

/// Lightweight draft for character creation — no `GameState`, orchestrator, or domain systems.
struct CharacterCreationDraft: Equatable {
    var step: CharacterCreationStep = .name
    var pendingName: String = ""
    var pendingRegionID: String = "mountain_standard"
    var pendingTrait: PersonalityTrait?
    var selectedResilience: LifeResilience = .resilient
    var selectedStartMode: StartMode = .quickStart
    var selectedTemplate: OriginTemplateID = .stableHomeAverageMeans
    // Overhaul additions
    var selectedBackground: Background? = nil
    var morphPointsRemaining: Int = 10
    var isRandomSpawn: Bool = false
}

/// UI-only snapshot built from a one-shot preview generation (not a live `GameState` binding).
struct CreationPreviewCard: Equatable {
    var displayName: String
    var regionName: String
    var smarts: Int
    var looks: Int
    var health: Int
    var cashOnHand: Int
    var homeSummary: String?
    var dossierNarrative: String?
    var visibleHints: [String]
    var futurePathHints: [String]

    static func from(state: GameState, draftName: String) -> CreationPreviewCard {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        let regionID = state.finance.currentRegionPolicyID ?? "mountain_standard"
        let regionName = RegionChoice.all.first(where: { $0.id == regionID })?.displayName ?? "Unknown"
        let dossier = state.childhoodDossier

        return CreationPreviewCard(
            displayName: trimmed.isEmpty ? "Your character" : trimmed,
            regionName: regionName,
            smarts: state.player.smarts,
            looks: state.player.looks,
            health: state.healthProfile.physicalWellness,
            cashOnHand: state.finance.cashOnHand,
            homeSummary: state.originProfile?.homeSummary,
            dossierNarrative: dossier?.narrative,
            visibleHints: dossier?.visibleHints ?? [],
            futurePathHints: Self.futurePathHints(from: state)
        )
    }

    private static func futurePathHints(from state: GameState) -> [String] {
        var paths: [String] = []
        let player = state.player
        let profile = state.originProfile

        if let dossier = state.childhoodDossier {
            if dossier.aptitudes.physical >= 62 { paths.append("Athlete or military calling") }
            if dossier.aptitudes.entrepreneurial >= 60 { paths.append("Founder / venture lean") }
            if dossier.aptitudes.social >= 65 { paths.append("Politics or creator spotlight") }
            if dossier.aptitudes.analytical >= 65 { paths.append("Academic or corporate track") }
            if dossier.aptitudes.entrepreneurial >= 55, dossier.aptitudes.technical >= 50 {
                paths.append("Trader or gray market edge")
            }
            if profile?.templateID == .financialStrainToughenedEarly || profile?.templateID == .chaoticHomeSelfReliant {
                paths.append("Street or gray-market opportunities")
            }
        } else {
            if player.smarts > 70 { paths.append("Sharp mind opens elite doors") }
            if player.looks > 70 { paths.append("Looks + charm = social capital") }
        }
        if player.traits.contains(.impulsive) || player.traits.contains(.coldBlooded) {
            paths.append("Risk and edge will find you")
        }
        return Array(Set(paths)).prefix(3).sorted()
    }
}

@MainActor
final class CharacterCreationViewModel: ObservableObject {
    @Published var draft = CharacterCreationDraft()
    @Published private(set) var previewCard: CreationPreviewCard?
    @Published private(set) var isRefreshingPreview = false

    private var previewTask: Task<Void, Never>?

    func reset() {
        previewTask?.cancel()
        draft = CharacterCreationDraft()
        previewCard = nil
        isRefreshingPreview = false
    }

    func advanceStep() {
        let order: [CharacterCreationStep] = [.name, .origin, .trait, .resilience]
        guard let index = order.firstIndex(of: draft.step), index + 1 < order.count else { return }
        draft.step = order[index + 1]
    }

    func retreatStep() {
        let order: [CharacterCreationStep] = [.name, .origin, .trait, .resilience]
        guard let index = order.firstIndex(of: draft.step), index > 0 else { return }
        draft.step = order[index - 1]
    }

    func clearPreview() {
        previewTask?.cancel()
        previewCard = nil
        isRefreshingPreview = false
    }

    /// Explicit preview only — never tied to slider/text onChange.
    func refreshPreview(using builder: @escaping (CharacterCreationDraft) async -> CreationPreviewCard?) {
        previewTask?.cancel()
        isRefreshingPreview = true
        let snapshot = draft
        previewTask = Task {
            let card = await builder(snapshot)
            guard !Task.isCancelled else { return }
            previewCard = card
            isRefreshingPreview = false
        }
    }
}
