import Foundation

struct PerformanceBudgets {
    static let maxRenderedHistoryItems = 3
    /// Headroom for macro/NPC autonomy notes appended in the same tick as headline inserts.
    static let maxPersistedHistoryItems = 280
    static let eventPackWarningThreshold = 250
    static let saveSizeWarningBytes = 180_000
}

struct SimulationTimingEntry: Codable, Equatable, Identifiable {
    var id: String { label }
    var label: String
    var durationMilliseconds: Double
}

struct SimulationTimingSnapshot: Codable, Equatable {
    var totalAdvanceYearMilliseconds: Double = 0
    var eventPickMilliseconds: Double = 0
    var loadMilliseconds: Double = 0
    var saveMilliseconds: Double = 0
    var persistedHistoryCount: Int = 0
    var persistedSaveBytes: Int = 0
    var loadErrorCount: Int = 0
    var persistenceRecoverySource: String? = nil
    var restoredFromBackup: Bool = false
    var entries: [SimulationTimingEntry] = []
}

