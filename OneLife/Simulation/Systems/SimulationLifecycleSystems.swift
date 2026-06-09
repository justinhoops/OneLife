import Foundation

struct FameSystem {}
struct RecoverySystem {}
struct SafetyNetSystem {}

struct CorrelationEchoSystem {
    func resolveYear(state: inout GameState) {
        state.correlationLedger.decay(oldAge: state.player.age)

        for echo in state.correlationLedger.pendingEchoes(currentAge: state.player.age) {
            if echo.tag == "intense_stretch_echo" {
                let note = echo.strength >= 80
                    ? "The intensity of the last few years is finally catching up. You feel it in your body and your relationships."
                    : "The long stretch of focused action is still reverberating. Some doors that were open before feel harder to reach now."

                state.history.insert(
                    HistoryEntry(age: state.player.age, title: "Echo", text: note, tags: [.progress]),
                    at: 0
                )

                if echo.domain == "relationships" || echo.domain == "finance" {
                    state.relationships.activeRumorHeat = min(100, state.relationships.activeRumorHeat + 8)
                }
            }
            state.correlationLedger.consumeEcho(echo)
        }

        if state.correlationLedger.recentActivityLevel >= 80,
           state.player.age >= 45,
           !state.history.prefix(4).contains(where: { $0.title.contains("Burned") || $0.title.contains("Intensity") }) {
            state.history.insert(
                HistoryEntry(
                    age: state.player.age,
                    title: "Burned Bright",
                    text: "There was a stretch, years ago, where everything felt accelerated. Looking back, it was both the most alive and the most expensive period of your life.",
                    tags: [.progress]
                ),
                at: 0
            )
        }
    }
}

struct LifeTerminationSystem {
    func isGameOver(state: GameState) -> Bool {
        let wealthFloor = state.resilience.scaling.wealthGameOverFloor
        return state.player.health <= 0
            || state.healthProfile.physicalWellness <= 0
            || state.finance.totalWealth < wealthFloor
    }
}
