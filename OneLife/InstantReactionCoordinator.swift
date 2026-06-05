import Foundation

/// Phase 1 (Orchestrator Cleanup – Complete): Dedicated coordinator for the fast "instant action + autonomous world reaction" path.
///
/// This is the single home for the frictionless reactive layer.
/// It was fully extracted and promoted; the orchestrator no longer contains a copy of this logic.
///
/// Responsibilities:
/// - Enrich an already-applied instant action with immediate autonomous reactions (NPC, Health, Finance, etc.)
/// - Record `InstantMomentum` so recent focused play can influence the next yearly simulation (Phase 2/3 bridge)
/// - Keep history injection and light side effects clean
///
/// The orchestrator (LifeSimulationOrchestrator) owns the heavy yearly tick (resolvePreparedYearChapter and friends).
/// This coordinator owns only the "press button → world reacts *now*" enrichment.
///
/// See LifeSimulationOrchestrator.swift for the "Player Micro Move vs Year Commitment" mental model documentation.
struct InstantReactionCoordinator {

    private var npcAutonomySystem: NPCAutonomySystem
    private var healthSystem: HealthSystem
    private var financeSystem: FinanceSystem

    init(
        npcAutonomySystem: NPCAutonomySystem = NPCAutonomySystem(),
        healthSystem: HealthSystem = HealthSystem(),
        financeSystem: FinanceSystem = FinanceSystem()
    ) {
        self.npcAutonomySystem = npcAutonomySystem
        self.healthSystem = healthSystem
        self.financeSystem = financeSystem
    }

    /// The main enrichment method for the frictionless instant path.
    /// Call this after `applyImmediateAction` to add autonomous reactions + momentum.
    mutating func enrichWithAutonomousReactions(
        choiceID: ActionChoiceID,
        domain: ActionDomain,
        baseResult: inout DomainYearResult,
        state: inout GameState
    ) {
        var autonomousNotes: [DomainNote] = []

        switch domain {
        case .relationships:
            let notes = npcAutonomySystem.reactToPlayerSocialAction(choiceID, state: &state)
            autonomousNotes.append(contentsOf: notes)
            for note in notes {
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }

        case .health:
            let notes = healthSystem.reactToPlayerHealthAction(choiceID, state: &state)
            autonomousNotes.append(contentsOf: notes)
            for note in notes {
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }

        case .finance:
            let notes = financeSystem.reactToPlayerFinanceAction(choiceID, state: &state)
            autonomousNotes.append(contentsOf: notes)
            for note in notes {
                state.history.insert(HistoryEntry(age: state.player.age, title: note.title, text: note.text, tags: note.tags), at: 0)
            }

        default:
            break
        }

        baseResult.notes.append(contentsOf: autonomousNotes)

        // Record momentum so it can influence the next year's simulation
        if !autonomousNotes.isEmpty {
            let strength = min(25, autonomousNotes.count * 8 + 10)
            state.instantMomentum.recordReaction(domain: domain, strength: strength, currentAge: state.player.age)

            // Engine1: Publish lightweight correlation signal so autonomous systems
            // and background engines can react to this instant action without heavy cost.
            let signalStrength = min(100, strength * 4)
            state.correlationLedger.publish(CorrelationSignal(
                kind: .autonomousReaction,
                domain: domain.rawValue,
                strength: signalStrength,
                age: state.player.age
            ))
        }

        // Also publish a pulse even for "quiet" instant actions (so the ledger stays useful)
        if autonomousNotes.isEmpty {
            state.correlationLedger.publish(CorrelationSignal(
                kind: .instantActionPulse,
                domain: domain.rawValue,
                strength: 12,
                age: state.player.age
            ))
        }

        // Engine4: If the player is having an extremely intense stretch, schedule a future "echo"
        let currentHeat = state.correlationLedger.recentActivityLevel
        if currentHeat >= 75 && Int.random(in: 0...100) < 12 {
            let echoAge = state.player.age + Int.random(in: 2...5)
            state.correlationLedger.recordEcho(
                tag: "intense_stretch_echo",
                dueAge: echoAge,
                strength: currentHeat,
                domain: domain.rawValue
            )
        }

        // Light history budget
        if state.history.count > 120 {
            state.history = Array(state.history.prefix(120))
        }
    }
}