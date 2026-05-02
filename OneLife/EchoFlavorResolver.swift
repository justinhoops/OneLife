import Foundation

// MARK: - EchoFlavorResolver
//
// Codex IX, Layer 2: Consequence Memory.
//
// Choices that aren't remembered never mattered.
//
// EchoFlavorResolver maps active narrative flags and live state conditions
// to a single-sentence echo prefix that is prepended to event text before display.
// The echo makes past decisions feel present — it is never preachy or moralistic.
// It states a fact. The player supplies the meaning.
//
// Usage:
//   let echo = EchoFlavorResolver().resolve(for: event, state: state)
//   let fullText = [echo, event.text].compactMap { $0 }.joined(separator: " ")

struct EchoFlavorResolver {

    /// Returns an optional one-sentence echo line to prepend to an event's text.
    /// Returns nil if no active flags or conditions are relevant to this event.
    func resolve(for event: GameEvent, state: GameState) -> String? {
        // Flag-based echoes take priority — they reflect explicit player choices
        if let flagEcho = flagEcho(for: event, state: state) {
            return flagEcho
        }
        // State echoes fire from live numeric conditions — always current
        return stateEcho(for: event, state: state)
    }

    // MARK: - Flag Echoes
    // Keyed to flags set by event choices (ConsequenceState.narrativeFlags).
    // The value stored in narrativeFlags is the age at which the flag was set.

    private func flagEcho(for event: GameEvent, state: GameState) -> String? {
        let flags    = state.consequences.narrativeFlags
        let age      = state.player.age
        let tags     = Set(event.tags)
        let category = event.category

        // Financial flags
        if flags["bill_delayed"] != nil, matchesAny(tags: tags, category: category, matching: ["money", "finance", "cost", "debt"]) {
            let yearsAgo = age - (flags["bill_delayed"] ?? age)
            if yearsAgo <= 1 {
                return "That delayed bill is still sitting there."
            } else {
                return "You've been carrying that bill for \(yearsAgo) years now."
            }
        }

        if flags["took_payday_loan"] != nil, matchesAny(tags: tags, category: category, matching: ["money", "finance", "cost"]) {
            let yearsAgo = age - (flags["took_payday_loan"] ?? age)
            if yearsAgo <= 2 {
                return "You're still paying off that short-term loan."
            } else {
                return "The payday loan trap — you know this feeling well."
            }
        }

        if flags["missed_payment"] != nil, matchesAny(tags: tags, category: category, matching: ["money", "finance", "credit"]) {
            return "Your credit took a hit you haven't fully recovered from."
        }

        // Career / work flags
        if flags["overworked_recently"] != nil, matchesAny(tags: tags, category: category, matching: ["work", "career", "performance", "health", "sleep"]) {
            return "You haven't fully recovered from last year's pace."
        }

        if flags["passed_over_promotion"] != nil, matchesAny(tags: tags, category: category, matching: ["work", "career", "performance"]) {
            return "The promotion that went to someone else still stings."
        }

        if flags["quit_without_plan"] != nil, matchesAny(tags: tags, category: category, matching: ["work", "career", "money"]) {
            return "You burned a bridge last time. You've been rebuilding since."
        }

        // Health flags
        if flags["missed_checkup"] != nil, matchesAny(tags: tags, category: category, matching: ["health", "body", "medical"]) {
            let years = age - (flags["missed_checkup"] ?? age)
            if years >= 3 {
                return "You haven't seen a doctor in \(years) years."
            } else {
                return "You skipped the checkup again last year."
            }
        }

        if flags["ignored_symptom"] != nil, matchesAny(tags: tags, category: category, matching: ["health", "body"]) {
            return "That thing you've been ignoring hasn't gone away."
        }

        // Relationship flags
        if flags["let_friendship_lapse"] != nil, matchesAny(tags: tags, category: category, matching: ["social", "friends", "relationship"]) {
            return "You've been out of touch with most people for a while now."
        }

        if flags["ended_relationship_badly"] != nil, matchesAny(tags: tags, category: category, matching: ["relationship", "romance", "social"]) {
            return "The last one ended badly. That's still in the background."
        }

        // Housing flags
        if flags["eviction_scare"] != nil, matchesAny(tags: tags, category: category, matching: ["housing", "money", "stress"]) {
            return "The eviction notice from two years ago changed how you think about rent."
        }

        // Education flags
        if flags["dropped_course"] != nil, matchesAny(tags: tags, category: category, matching: ["school", "education", "career"]) {
            return "That dropped course is a gap you haven't filled."
        }

        if flags["academic_warning"] != nil, matchesAny(tags: tags, category: category, matching: ["school", "education"]) {
            return "You're still on thin ice academically."
        }

        return nil
    }

    // MARK: - State Echoes
    // Fired from live numeric conditions — no flag required.
    // These capture accumulated reality that events alone can't convey.

    private func stateEcho(for event: GameEvent, state: GameState) -> String? {
        let tags     = Set(event.tags)
        let category = event.category

        // Chronic financial stress
        if state.finance.financialStress >= 60,
           matchesAny(tags: tags, category: category, matching: ["money", "finance", "cost", "work"]) {
            return "The financial pressure has been constant long enough to feel normal."
        }

        // Deep debt
        if state.finance.studentDebt > 30_000,
           matchesAny(tags: tags, category: category, matching: ["money", "finance", "career"]) {
            let formatted = formatCurrency(state.finance.studentDebt)
            return "The \(formatted) in student debt sits underneath every financial decision."
        }

        // Career burnout
        if state.career.burnout >= 70,
           matchesAny(tags: tags, category: category, matching: ["work", "career", "health", "sleep"]) {
            return "You're running on borrowed energy and everyone can probably tell."
        }

        // Long career plateau
        if state.career.yearsWorked >= 5 && state.career.performance < 60,
           matchesAny(tags: tags, category: category, matching: ["work", "career"]) {
            return "Five years and the job still feels like a waiting room."
        }

        // Health neglect
        if state.healthProfile.physicalWellness < 40,
           matchesAny(tags: tags, category: category, matching: ["health", "body", "energy"]) {
            return "Your body has been sending signals you've been ignoring."
        }

        // Mental health strain
        if state.healthProfile.mentalWellness < 40,
           matchesAny(tags: tags, category: category, matching: ["stress", "sleep", "social", "health"]) {
            return "The mental weight of things has been heavier than you let on."
        }

        // Social isolation
        if state.relationships.friends.isEmpty,
           matchesAny(tags: tags, category: category, matching: ["social", "friends", "relationship"]) {
            return "Your social circle has been quiet for longer than you planned."
        }

        // Strained relationships
        if state.relationships.friends.filter({ $0.status == .strained }).count >= 2,
           matchesAny(tags: tags, category: category, matching: ["social", "friends", "relationship"]) {
            return "Most of your close relationships have been running on friction lately."
        }

        // Housing instability
        if state.housing.housingStability < 40,
           matchesAny(tags: tags, category: category, matching: ["housing", "stress", "money"]) {
            return "The housing situation has been unstable long enough to wear on you."
        }

        return nil
    }

    // MARK: - Helpers

    private func matchesAny(tags: Set<String>, category: EventCategory, matching targets: [String]) -> Bool {
        let categoryString = category.rawValue
        for target in targets {
            if tags.contains(target) { return true }
            if categoryString.contains(target) { return true }
        }
        return false
    }

    private func formatCurrency(_ amount: Int) -> String {
        if amount >= 1_000_000 {
            return "$\(amount / 1_000_000)M"
        } else if amount >= 1_000 {
            return "$\(amount / 1_000)K"
        }
        return "$\(amount)"
    }
}

// MARK: - GameEvent Extension

extension GameEvent {
    /// Returns the event text with any applicable echo prefix prepended.
    /// This is what the UI should display — never raw `text` directly.
    func displayText(echoing state: GameState) -> String {
        let resolver = EchoFlavorResolver()
        guard let echo = resolver.resolve(for: self, state: state) else {
            return text
        }
        return "\(echo)\n\n\(text)"
    }
}
