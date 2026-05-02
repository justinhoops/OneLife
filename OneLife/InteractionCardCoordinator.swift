import Foundation

struct InteractionCardCoordinator {
    private var queue: [InteractionCardPayload] = []

    var queuedCount: Int { queue.count }

    mutating func reset() {
        queue = []
    }

    mutating func load(_ cards: [InteractionCardPayload]) -> InteractionCardPayload? {
        queue = cards
        return advance()
    }

    mutating func advance() -> InteractionCardPayload? {
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }
}
