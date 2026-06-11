import Combine
import SwiftUI

/// Lightweight draft for character creation — no `GameState`, orchestrator, or domain systems.
struct CharacterCreationDraft: Equatable {
    var step: CharacterCreationStep = .name
    var pendingName: String = ""
    var pendingRegionID: String = "mountain_standard"
    var pendingTrait: PersonalityTrait?
    var selectedResilience: LifeResilience = .resilient
    var selectedStartMode: StartMode = .quickStart
    var selectedTemplate: OriginTemplateID = .stableHomeAverageMeans
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
