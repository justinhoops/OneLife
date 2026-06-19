import Foundation

/// Shared OneLife depth for BitLife-style static instant actions (dossier, resilience, shape, fame).
enum StaticInstantActionFlavor {
    static func publishPulse(_ state: inout GameState, domain: String, strength: Int = 16) {
        state.correlationLedger.publish(
            CorrelationSignal(kind: .instantActionPulse, domain: domain, strength: strength, age: state.player.age)
        )
    }

    static func isGrounded(_ state: GameState) -> Bool { state.resilience == .grounded }
    static func isResilient(_ state: GameState) -> Bool { state.resilience == .resilient }

    static func resilienceScaled(_ state: GameState, grounded: Int, resilient: Int) -> Int {
        isGrounded(state) ? grounded : resilient
    }

    static func shapeResidueLine(_ state: GameState) -> String? {
        let label = LifeShapeResolver.label(from: state)
        guard !label.isEmpty else { return nil }
        return "The \(label.lowercased()) current you've been riding is starting to feel like the default."
    }

    static func stanceStreakLine(_ state: GameState) -> String? {
        guard let streak = LifeShapeResolver.stanceStreak(in: state, minimum: 2) else { return nil }
        return "You've been in a \(streak.title.lowercased()) stretch — that residue shows up in how this lands."
    }

    static func fameGravitySuffix(_ state: GameState, highFame: String, lowFame: String = "") -> String {
        if state.fame.culturalFame >= 55 || state.specialCareer.fame >= 55 {
            return highFame
        }
        if state.fame.notoriety >= 45 {
            return " The notoriety makes even small moves feel watched."
        }
        return lowFame
    }

    static func dossierAnalytical(_ state: GameState) -> Bool {
        (state.childhoodDossier?.aptitudes.analytical ?? 0) >= 55
    }

    static func dossierSocial(_ state: GameState) -> Bool {
        (state.childhoodDossier?.aptitudes.social ?? 0) >= 55
    }

    static func dossierPhysical(_ state: GameState) -> Bool {
        (state.childhoodDossier?.aptitudes.physical ?? 0) >= 55
    }

    static func dossierEntrepreneurial(_ state: GameState) -> Bool {
        (state.childhoodDossier?.aptitudes.entrepreneurial ?? 0) >= 55
    }
}
