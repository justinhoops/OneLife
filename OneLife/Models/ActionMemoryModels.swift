import Foundation

struct PlayerYearAction: Codable, Equatable, Identifiable {
    var domain: ActionDomain
    var choiceID: ActionChoiceID

    var id: String { domain.rawValue }
}

struct ActionMemoryEntry: Codable, Equatable, Identifiable {
    var age: Int
    var domain: ActionDomain
    var choiceID: ActionChoiceID

    var id: String { "\(age)-\(domain.rawValue)-\(choiceID.rawValue)" }
}

struct ActionMemoryState: Codable, Equatable {
    var currentAge: Int? = nil
    var recentActions: [ActionMemoryEntry] = []
    var lastActionByDomain: [String: ActionChoiceID] = [:]

    var latestAction: PlayerYearAction? {
        recentActions.last.map { PlayerYearAction(domain: $0.domain, choiceID: $0.choiceID) }
    }

    var actionsThisAge: [PlayerYearAction] {
        recentActions.map { PlayerYearAction(domain: $0.domain, choiceID: $0.choiceID) }
    }

    func lastAction(for domain: ActionDomain) -> ActionChoiceID? {
        lastActionByDomain[domain.rawValue]
    }

    mutating func record(action: PlayerYearAction, age: Int) {
        if currentAge != age {
            currentAge = age
            recentActions = []
        }

        recentActions.removeAll { $0.domain == action.domain }
        recentActions.append(ActionMemoryEntry(age: age, domain: action.domain, choiceID: action.choiceID))
        lastActionByDomain[action.domain.rawValue] = action.choiceID

        if recentActions.count > 6 {
            recentActions = Array(recentActions.suffix(6))
        }
    }

    mutating func clearForNewAge(_ age: Int) {
        currentAge = age
        recentActions = []
    }
}

struct QuickActionMemoryState: Codable, Equatable {
    var currentAge: Int? = nil
    var completedThisAge: [ActionMemoryEntry] = []
    var maxActionsPerAge: Int = 3

    var countThisAge: Int { completedThisAge.count }

    mutating func rolloverIfNeeded(age: Int) {
        if currentAge != age {
            currentAge = age
            completedThisAge = []
        }
    }

    mutating func canPerform(_ action: PlayerYearAction, age: Int) -> Bool {
        rolloverIfNeeded(age: age)
        return !completedThisAge.contains { $0.domain == action.domain && $0.choiceID == action.choiceID }
            && completedThisAge.count < maxActionsPerAge
    }

    mutating func blockReason(for action: PlayerYearAction, age: Int) -> String? {
        rolloverIfNeeded(age: age)
        if completedThisAge.contains(where: { $0.domain == action.domain && $0.choiceID == action.choiceID }) {
            return "Already done this year."
        }
        if completedThisAge.count >= maxActionsPerAge {
            return "Quick actions are used up for this year."
        }
        return nil
    }

    mutating func record(_ action: PlayerYearAction, age: Int) {
        rolloverIfNeeded(age: age)
        guard !completedThisAge.contains(where: { $0.domain == action.domain && $0.choiceID == action.choiceID }) else { return }
        completedThisAge.append(ActionMemoryEntry(age: age, domain: action.domain, choiceID: action.choiceID))
    }
}

