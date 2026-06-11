import SwiftUI
import Combine

/// Overlay, toast, and loading flags isolated from core game state to reduce SwiftUI invalidation fan-out.
@MainActor
final class GameSessionChromeState: ObservableObject {
    @Published var microBeatOverlay: String?
    @Published var actionFrictionJitter = false
    @Published var isResolvingInteraction = false
    @Published var resolvingInteractionContext: String?
    @Published var isStartingNewLife = false
    @Published private(set) var isLoadingPersistedGame = false
    @Published private(set) var floatingDeltas: [FloatingDelta] = []
    @Published var autonomyToasts: [AutonomyToast] = []
    @Published private(set) var activityPulse: ActivityPulse?
    @Published private(set) var saveStatusBanner: String?

    func setLoadingPersistedGame(_ loading: Bool) {
        isLoadingPersistedGame = loading
    }

    func appendFloatingDeltas(_ newDeltas: [FloatingDelta], maxConcurrent: Int = 5) {
        if floatingDeltas.count + newDeltas.count > maxConcurrent {
            floatingDeltas.removeFirst(max(0, floatingDeltas.count + newDeltas.count - maxConcurrent))
        }
        floatingDeltas.append(contentsOf: newDeltas)
    }

    func removeFloatingDeltas(withIDs ids: Set<UUID>) {
        floatingDeltas.removeAll { ids.contains($0.id) }
    }

    func setActivityPulse(_ pulse: ActivityPulse?) {
        activityPulse = pulse
    }

    func setSaveStatusBanner(_ banner: String?) {
        saveStatusBanner = banner
    }

    func clearTransientChrome() {
        microBeatOverlay = nil
        actionFrictionJitter = false
        isResolvingInteraction = false
        resolvingInteractionContext = nil
        isStartingNewLife = false
        floatingDeltas = []
        autonomyToasts = []
        activityPulse = nil
        saveStatusBanner = nil
    }
}
