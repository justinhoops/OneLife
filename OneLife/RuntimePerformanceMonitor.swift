import Foundation

/// Documented runtime budgets from the stability plan (tune after Instruments baselines).
enum RuntimePerformanceBaseline {
    static let coldLaunchInteractiveMilliseconds: Double = 500
    static let saveResumeDecodeMilliseconds: Double = 300
    static let saveEncodeMilliseconds: Double = 150
    static let typicalAgeUpMilliseconds: Double = 200
    static let heavyAgeUpMilliseconds: Double = 1_000
}

enum RuntimePerformanceMarker: String, CaseIterable {
    case viewModelInit
    case persistenceLoad
    case persistenceSave
    case advanceYear
    case instantActionBurst
}

struct RuntimePerformanceRecord: Equatable, Identifiable {
    var id: String { marker.rawValue }
    let marker: RuntimePerformanceMarker
    let durationMilliseconds: Double
    let recordedAt: Date
    let detail: String?

    var exceedsBudget: Bool {
        switch marker {
        case .viewModelInit:
            return durationMilliseconds > RuntimePerformanceBaseline.coldLaunchInteractiveMilliseconds
        case .persistenceLoad:
            return durationMilliseconds > RuntimePerformanceBaseline.saveResumeDecodeMilliseconds
        case .persistenceSave:
            return durationMilliseconds > RuntimePerformanceBaseline.saveEncodeMilliseconds
        case .advanceYear:
            return durationMilliseconds > RuntimePerformanceBaseline.typicalAgeUpMilliseconds
        case .instantActionBurst:
            return durationMilliseconds > RuntimePerformanceBaseline.saveEncodeMilliseconds * 3
        }
    }
}

@MainActor
final class RuntimePerformanceMonitor {
    static let shared = RuntimePerformanceMonitor()

    private(set) var records: [RuntimePerformanceRecord] = []

    private init() {}

    func record(_ marker: RuntimePerformanceMarker, durationMilliseconds: Double, detail: String? = nil) {
        let record = RuntimePerformanceRecord(
            marker: marker,
            durationMilliseconds: durationMilliseconds,
            recordedAt: Date(),
            detail: detail
        )
        records.append(record)
        if records.count > 40 {
            records.removeFirst(records.count - 40)
        }
        #if DEBUG
        if record.exceedsBudget {
            let detailSuffix = detail.map { " (\($0))" } ?? ""
            print("OneLife perf budget exceeded: \(marker.rawValue) \(Int(durationMilliseconds))ms\(detailSuffix)")
        }
        #endif
    }

    func measure<T>(_ marker: RuntimePerformanceMarker, detail: String? = nil, _ work: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try work()
        record(marker, durationMilliseconds: millisecondsSince(start), detail: detail)
        return result
    }

    func clear() {
        records.removeAll()
    }

    private func millisecondsSince(_ start: CFAbsoluteTime) -> Double {
        ((CFAbsoluteTimeGetCurrent() - start) * 1_000).rounded()
    }
}
