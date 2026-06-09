import Foundation

// MARK: - Helpers

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Array where Element == Relationship {
    var strongestBond: Int {
        map(\.bond).max() ?? 0
    }

    var strongestName: String? {
        self.max(by: { $0.bond < $1.bond })?.name
    }
}

