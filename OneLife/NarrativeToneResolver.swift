import Foundation

// MARK: - NarrativeTone
//
// Codex IX, Layer 4: The UI Carries the Weight.
//
// NarrativeTone is the emotional register of the player's current life.
// It is computed fresh from GameState — never stored, never stale.
// Used by SilentYearEngine, EchoFlavorResolver, and the UI layer
// to adjust prose register and visual treatment.

enum NarrativeTone: String, Equatable {
    /// Financially stressed with no relief in sight. Numbers are bad and getting worse.
    case grinding
    /// High burnout from career or education. Exhausted and coasting.
    case burnedOut
    /// Low relationships, low belonging. Functionally alone.
    case isolated
    /// Stable but not thriving. The plateau. Nothing is wrong; nothing is right.
    case holding
    /// Genuine upward momentum in at least one domain. Something is actually working.
    case hopeful
    /// Multiple critical statuses active at once. The walls are closing.
    case cornered
    /// Genuinely stable across all domains. Rare enough to notice.
    case clear
    
    // MARK: - Visual Stress Filter (Codex IX)
    
    var saturation: Double {
        switch self {
        case .grinding, .burnedOut: return 0.65
        case .isolated: return 0.8
        case .hopeful: return 1.25
        case .cornered: return 0.55
        case .clear: return 1.1
        default: return 1.0
        }
    }
    
    var vignetteIntensity: Double {
        switch self {
        case .cornered: return 0.35
        case .grinding, .burnedOut: return 0.15
        default: return 0.0
        }
    }

    // MARK: UI Signals

    /// Short label used in UI micro-copy when this tone is active.
    var financeTabLabel: String {
        switch self {
        case .grinding, .cornered: return "Debt"
        case .burnedOut:           return "Barely Breaking Even"
        case .holding:             return "Finances"
        default:                   return "Finances"
        }
    }

    /// Accent color hint passed to the UI layer. Interpreted by ContentView.
    var accentColorHint: ToneColorHint {
        switch self {
        case .cornered:   return .critical
        case .grinding:   return .warning
        case .burnedOut:  return .muted
        case .isolated:   return .muted
        case .holding:    return .neutral
        case .hopeful:    return .positive
        case .clear:      return .positive
        }
    }
}

enum ToneColorHint: String, Equatable {
    case critical   // deep red — multiple systems failing
    case warning    // amber — one domain in distress
    case muted      // desaturated — exhausted, drained
    case neutral    // standard palette
    case positive   // green-shifted — momentum
}

// MARK: - NarrativeToneResolver

/// Pure function: GameState → NarrativeTone.
/// No stored state. Call this each tick or on demand.
struct NarrativeToneResolver {

    func resolve(for state: GameState) -> NarrativeTone {
        let criticalCount   = criticalStatusCount(state)
        let isGrinding      = checkGrinding(state)
        let isBurnedOut     = checkBurnedOut(state)
        let isIsolated      = checkIsolated(state)
        let isHopeful       = checkHopeful(state)
        let isClear         = checkClear(state)

        // Cornered: two or more distinct pressure points active simultaneously
        if criticalCount >= 2 {
            return .cornered
        }

        // A single dominant distress takes priority over hopeful signals
        if isGrinding {
            return .grinding
        }

        if isBurnedOut {
            return .burnedOut
        }

        if isIsolated {
            return .isolated
        }

        if isClear {
            return .clear
        }

        if isHopeful {
            return .hopeful
        }

        return .holding
    }

    // MARK: - Private checks

    private func criticalStatusCount(_ state: GameState) -> Int {
        var count = 0
        if checkGrinding(state)  { count += 1 }
        if checkBurnedOut(state) { count += 1 }
        if checkIsolated(state)  { count += 1 }
        if state.housing.housingStability < 42 { count += 1 }
        return count
    }

    private func checkGrinding(_ state: GameState) -> Bool {
        state.finance.financialStress >= 50 || state.finance.cashOnHand < 0
    }

    private func checkBurnedOut(_ state: GameState) -> Bool {
        let careerBurnout    = state.career.burnout >= 60
        let educationBurnout = state.education.burnoutRisk >= 65
        let mentallyDrained  = state.healthProfile.mentalWellness < 40
        return careerBurnout || educationBurnout || mentallyDrained
    }

    private func checkIsolated(_ state: GameState) -> Bool {
        let noConnections   = state.relationships.friends.isEmpty && !state.relationships.hasPartner
        let allStrained     = !state.relationships.friends.isEmpty &&
                              state.relationships.friends.allSatisfy { $0.status == .strained }
        let veryLowBond     = state.relationships.friends.strongestBond < 30 &&
                              state.relationships.partnerBond < 30
        return noConnections || allStrained || veryLowBond
    }

    private func checkHopeful(_ state: GameState) -> Bool {
        let financeRising   = state.finance.lastYearBalanceDelta > 500 && state.finance.financialStress < 35
        let careerMomentum  = state.career.performance >= 70 && state.career.burnout < 40
        let healthStrong    = state.healthProfile.physicalWellness >= 70 && state.healthProfile.mentalWellness >= 65
        return financeRising || careerMomentum || healthStrong
    }

    private func checkClear(_ state: GameState) -> Bool {
        let financeOk    = state.finance.financialStress < 25 && state.finance.cashOnHand > 0
        let healthOk     = state.healthProfile.physicalWellness >= 60 && state.healthProfile.mentalWellness >= 60
        let relationOk   = state.relationships.friends.strongestBond >= 50 || state.relationships.partnerBond >= 50
        let careerOk     = state.career.burnout < 35
        let housingOk    = state.housing.housingStability >= 60
        return financeOk && healthOk && relationOk && careerOk && housingOk
    }
}
