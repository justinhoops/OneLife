import Foundation

// MARK: - Engine1: Lightweight System Correlation Ledger
// Low-overhead bus that lets Instant layer, Autonomous systems, and Background engines
// publish and read very cheap signals without full simulation every frame.
// Designed for high correlation with minimal cost (fixed small size + automatic decay).

struct CorrelationSignal: Codable, Equatable {
    enum Kind: String, Codable, Equatable {
        case instantActionPulse      // Player did a meaningful instant/quick action
        case autonomousReaction      // An autonomous system reacted (NPC, finance, health, etc.)
        case momentumEcho            // Strong momentum carry from instant → yearly
        case economicPressureShift   // WorldEra or finance stress changed meaningfully
        case npcAutonomyPulse        // NPC autonomy system fired something noticeable
        case worldAutonomyPulse      // Macro/world event or era shift
        case focusStance             // D4: yearly focus/stance chosen or completed (residue + autonomy reactivity + silent flavor)
    }

    var kind: Kind
    var domain: String?              // e.g. "finance", "relationships", "career"
    var strength: Int                // 0-100 scale (higher = more significant)
    var age: Int                     // When the signal was recorded
}

struct SystemCorrelationLedger: Codable, Equatable {
    private var signals: [CorrelationSignal] = []
    private static let maxSignals = 12      // Hard cap for low overhead

    // Engine4: Echo system - high-correlation moments can schedule future consequences
    private var echoHooks: [CorrelationEcho] = []
    private static let maxEchoHooks = 6

    mutating func publish(_ signal: CorrelationSignal) {
        signals.removeAll { $0.kind == signal.kind && $0.domain == signal.domain }
        signals.append(signal)

        if signals.count > Self.maxSignals {
            signals.sort { $0.strength > $1.strength }
            signals = Array(signals.prefix(Self.maxSignals))
        }
    }

    /// Returns recent signals, optionally filtered by kind and minimum strength.
    func recentSignals(kind: CorrelationSignal.Kind? = nil, minStrength: Int = 0, sinceAge: Int? = nil) -> [CorrelationSignal] {
        signals.filter { sig in
            (kind == nil || sig.kind == kind) &&
            sig.strength >= minStrength &&
            (sinceAge == nil || sig.age >= sinceAge!)
        }
        .sorted { $0.age > $1.age }
    }

    /// Total "heat" from recent instant/autonomous activity
    var recentActivityLevel: Int {
        let recent = signals.filter { $0.age > (signals.first?.age ?? 0) - 3 }
        return min(100, recent.reduce(0) { $0 + $1.strength } / max(1, recent.count))
    }

    mutating func decay(oldAge: Int) {
        signals.removeAll { $0.age < oldAge - 8 }

        // Engine4: Also clean old echo hooks
        echoHooks.removeAll { $0.dueAge < oldAge }
    }

    // Engine4: Record a high-correlation "echo" that can fire later
    mutating func recordEcho(tag: String, dueAge: Int, strength: Int, domain: String?) {
        let echo = CorrelationEcho(tag: tag, dueAge: dueAge, strength: strength, domain: domain)
        echoHooks.removeAll { $0.tag == tag && $0.domain == domain }
        echoHooks.append(echo)

        if echoHooks.count > Self.maxEchoHooks {
            echoHooks.sort { $0.strength > $1.strength }
            echoHooks = Array(echoHooks.prefix(Self.maxEchoHooks))
        }
    }

    func pendingEchoes(currentAge: Int) -> [CorrelationEcho] {
        echoHooks.filter { $0.dueAge <= currentAge }
    }

    mutating func consumeEcho(_ echo: CorrelationEcho) {
        echoHooks.removeAll { $0.tag == echo.tag && $0.dueAge == echo.dueAge }
    }
}

struct CorrelationEcho: Codable, Equatable {
    var tag: String
    var dueAge: Int
    var strength: Int
    var domain: String?
}

struct PressureCause: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var domain: String
    var label: String
    var delta: Int
    var age: Int
    var sourceAction: ActionChoiceID?
}

struct CorrelationHook: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var tag: String
    var domain: String
    var dueAge: Int
    var strength: Int
    var sourceAction: ActionChoiceID?
}

struct CorrelationLedger: Codable, Equatable {
    var actionCounts: [String: Int] = [:]
    var domainResidue: [String: Int] = [:]
    var pressureCauses: [PressureCause] = []
    var npcImpressions: [String: [String: Int]] = [:]
    var unresolvedHooks: [CorrelationHook] = []

    mutating func recordAction(_ action: PlayerYearAction) -> Int {
        let key = action.choiceID.rawValue
        actionCounts[key, default: 0] += 1
        return actionCounts[key, default: 0]
    }

    mutating func adjustResidue(domain: String, delta: Int) {
        guard delta != 0 else { return }
        domainResidue[domain] = (domainResidue[domain, default: 0] + delta).clamped(to: -100...100)
        if domainResidue[domain] == 0 {
            domainResidue.removeValue(forKey: domain)
        }
    }

    mutating func recordPressureCause(domain: String, label: String, delta: Int, age: Int, sourceAction: ActionChoiceID?) {
        guard delta != 0 else { return }
        pressureCauses.append(
            PressureCause(
                domain: domain,
                label: label,
                delta: delta,
                age: age,
                sourceAction: sourceAction
            )
        )
        if pressureCauses.count > 30 {
            pressureCauses = Array(pressureCauses.suffix(30))
        }
    }

    mutating func adjustNPCImpression(id: String, key: String, delta: Int) {
        guard delta != 0 else { return }
        var impressions = npcImpressions[id, default: [:]]
        impressions[key] = (impressions[key, default: 0] + delta).clamped(to: -100...100)
        npcImpressions[id] = impressions.filter { $0.value != 0 }
        if npcImpressions[id]?.isEmpty == true {
            npcImpressions.removeValue(forKey: id)
        }
    }

    mutating func upsertHook(tag: String, domain: String, dueAge: Int, strength: Int, sourceAction: ActionChoiceID?) {
        if let index = unresolvedHooks.firstIndex(where: { $0.tag == tag && $0.domain == domain && $0.sourceAction == sourceAction }) {
            unresolvedHooks[index].dueAge = min(unresolvedHooks[index].dueAge, dueAge)
            unresolvedHooks[index].strength = max(unresolvedHooks[index].strength, strength)
        } else {
            unresolvedHooks.append(
                CorrelationHook(
                    tag: tag,
                    domain: domain,
                    dueAge: dueAge,
                    strength: strength,
                    sourceAction: sourceAction
                )
            )
        }
        if unresolvedHooks.count > 20 {
            unresolvedHooks = Array(unresolvedHooks.suffix(20))
        }
    }

    func pressureCauseLine(for domain: String, limit: Int = 2) -> String? {
        let causes = pressureCauses
            .filter { $0.domain == domain }
            .sorted { lhs, rhs in
                if lhs.age == rhs.age {
                    return abs(lhs.delta) > abs(rhs.delta)
                }
                return lhs.age > rhs.age
            }
            .prefix(limit)
            .map { "\($0.label) \($0.delta > 0 ? "+" : "")\($0.delta)" }
        guard !causes.isEmpty else { return nil }
        return causes.joined(separator: ", ")
    }

    // Engine1+ compatibility + real low-overhead bus for engine collaboration.
    // All background engines (Silent, Continuity, WorldAuto, NPCAuto) + instant publishers
    // read/write the same tiny capped structure so they can influence each other cheaply
    // without duplicating state or heavy computation.
    private var signals: [CorrelationSignal] = []
    private static let maxSignals = 12
    private var echoHooks: [CorrelationEcho] = []
    private static let maxEchoHooks = 6

    var recentActivityLevel: Int {
        // Prefer real signals if present (from Engine1 publish path); fallback to action count approx.
        if !signals.isEmpty {
            let recent = signals.filter { $0.age > (signals.first?.age ?? 0) - 3 }
            return min(100, recent.reduce(0) { $0 + $1.strength } / max(1, recent.count))
        }
        let total = actionCounts.values.reduce(0, +)
        return min(100, total * 3)
    }

    mutating func publish(_ signal: CorrelationSignal) {
        // Low overhead: dedup same kind/domain, cap at 12, keep strongest.
        signals.removeAll { $0.kind == signal.kind && $0.domain == signal.domain }
        signals.append(signal)

        if signals.count > Self.maxSignals {
            signals.sort { $0.strength > $1.strength }
            signals = Array(signals.prefix(Self.maxSignals))
        }
    }

    mutating func recordEcho(tag: String, dueAge: Int, strength: Int, domain: String?) {
        let echo = CorrelationEcho(tag: tag, dueAge: dueAge, strength: strength, domain: domain)
        echoHooks.removeAll { $0.tag == tag && $0.domain == domain }
        echoHooks.append(echo)

        if echoHooks.count > Self.maxEchoHooks {
            echoHooks.sort { $0.strength > $1.strength }
            echoHooks = Array(echoHooks.prefix(Self.maxEchoHooks))
        }
    }

    mutating func decay(oldAge: Int) {
        signals.removeAll { $0.age < oldAge - 8 }
        echoHooks.removeAll { $0.dueAge < oldAge }
    }

    func pendingEchoes(currentAge: Int) -> [CorrelationEcho] {
        echoHooks.filter { $0.dueAge <= currentAge }
    }

    mutating func consumeEcho(_ echo: CorrelationEcho) {
        echoHooks.removeAll { $0.tag == echo.tag && $0.dueAge == echo.dueAge }
    }

    /// Returns recent signals (for cross-engine reads, e.g. SilentYear reacting to autonomy pulses).
    /// Kept tiny and cheap. (real impl now lives on the active ledger)
    func recentSignals(kind: CorrelationSignal.Kind? = nil, minStrength: Int = 0, sinceAge: Int? = nil) -> [CorrelationSignal] {
        signals.filter { sig in
            (kind == nil || sig.kind == kind) &&
            sig.strength >= minStrength &&
            (sinceAge == nil || sig.age >= sinceAge!)
        }
        .sorted { $0.age > $1.age }
    }
}

