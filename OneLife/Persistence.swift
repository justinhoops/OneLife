import Foundation

struct PersistedGameState: Codable, Equatable {
    static let currentVersion = 1

    var version: Int
    var savedAt: Date
    var gameState: GameState

    init(version: Int = PersistedGameState.currentVersion, savedAt: Date = Date(), gameState: GameState) {
        self.version = version
        self.savedAt = savedAt
        self.gameState = gameState
    }
}

enum PersistenceRecoveryResult: String, Codable, Equatable {
    case primary
    case backup
    case legacyPrimary
    case legacyFile

    var restoredFromBackup: Bool {
        self == .backup
    }

    var userMessage: String? {
        switch self {
        case .primary:
            return nil
        case .backup:
            return "Recovered your last valid save from backup."
        case .legacyPrimary:
            return "Loaded an older save format and kept your progress."
        case .legacyFile:
            return "Recovered progress from a legacy save file."
        }
    }
}

enum PersistenceError: Error, LocalizedError, Equatable {
    case saveFailure(path: String, reason: String)
    case loadFailure(path: String, reason: String)
    case decodeFailure(path: String, reason: String)
    case noValidSave(paths: [String])

    var errorDescription: String? {
        switch self {
        case .saveFailure(_, let reason):
            return "Couldn't save your progress. \(reason)"
        case .loadFailure(_, let reason):
            return "Couldn't read saved progress. \(reason)"
        case .decodeFailure(_, let reason):
            return "Saved progress is unreadable. \(reason)"
        case .noValidSave:
            return "No valid saved progress could be recovered."
        }
    }
}

struct PersistenceSaveResult: Equatable {
    var timingSnapshot: SimulationTimingSnapshot
    var warning: PersistenceError? = nil
}

struct PersistenceLoadResult: Equatable {
    var state: GameState
    var recoveryResult: PersistenceRecoveryResult
    var errors: [PersistenceError] = []
    var timingSnapshot: SimulationTimingSnapshot = SimulationTimingSnapshot()
}

enum PersistenceStartupResult: Equatable {
    case loaded(PersistenceLoadResult)
    case noSave
    case failed(primaryError: PersistenceError, errors: [PersistenceError], timingSnapshot: SimulationTimingSnapshot)
}

struct PersistenceCoordinator {
    private static let fileName = "OneLife_Save.json"
    private static let backupFileName = "OneLife_Save.backup.json"
    private static let legacyFileName = "LifeSimBase_Save.json"
    private static let metaFileName = "OneLife_Meta.json"

    let fileManager: FileManager
    private let directoryProvider: () throws -> URL

    init(
        fileManager: FileManager = .default,
        directoryProvider: @escaping () throws -> URL = {
            try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
    ) {
        self.fileManager = fileManager
        self.directoryProvider = directoryProvider
    }

    static let live = PersistenceCoordinator()

    func save(_ state: GameState) throws -> PersistenceSaveResult {
        let prunedState = prunedState(from: state)
        let envelope = PersistedGameState(gameState: prunedState)
        let data: Data
        let urls: StorageURLs

        do {
            data = try JSONEncoder().encode(envelope)
            urls = try storageURLs()
            try data.write(to: urls.primary, options: [.atomic])
        } catch {
            throw PersistenceError.saveFailure(path: fallbackPath(for: error), reason: error.localizedDescription)
        }

        var warning: PersistenceError?
        do {
            try refreshBackup(primaryURL: urls.primary, backupURL: urls.backup)
        } catch {
            warning = .saveFailure(path: urls.backup.path, reason: error.localizedDescription)
        }

        #if DEBUG
        if data.count > PerformanceBudgets.saveSizeWarningBytes {
            print("OneLife performance warning: save payload is \(data.count) bytes.")
        }
        #endif

        return PersistenceSaveResult(
            timingSnapshot: SimulationTimingSnapshot(
                persistedHistoryCount: prunedState.history.count,
                persistedSaveBytes: data.count
            ),
            warning: warning
        )
    }

    func saveMeta(_ meta: MetaState) throws {
        do {
            let data = try JSONEncoder().encode(meta)
            let urls = try storageURLs()
            try data.write(to: urls.meta, options: [.atomic])
        } catch {
            throw PersistenceError.saveFailure(path: PersistenceCoordinator.metaFileName, reason: error.localizedDescription)
        }
    }

    func loadMeta() -> MetaState {
        do {
            let urls = try storageURLs()
            guard fileManager.fileExists(atPath: urls.meta.path) else { return MetaState() }
            let data = try Data(contentsOf: urls.meta)
            return try JSONDecoder().decode(MetaState.self, from: data)
        } catch {
            print("OneLife: Failed to load meta state: \(error.localizedDescription)")
            return MetaState()
        }
    }

    func loadForStartup() -> PersistenceStartupResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let candidates: [LoadCandidate]

        do {
            candidates = try loadCandidates()
        } catch {
            let failure = PersistenceError.loadFailure(path: "", reason: error.localizedDescription)
            return .failed(
                primaryError: failure,
                errors: [failure],
                timingSnapshot: SimulationTimingSnapshot(
                    loadMilliseconds: millisecondsSince(startTime),
                    loadErrorCount: 1
                )
            )
        }

        guard !candidates.isEmpty else { return .noSave }

        var errors: [PersistenceError] = []
        for candidate in candidates {
            let data: Data
            do {
                data = try Data(contentsOf: candidate.url)
            } catch {
                errors.append(.loadFailure(path: candidate.url.path, reason: error.localizedDescription))
                continue
            }

            do {
                let state = try decodeState(from: data, expectsEnvelope: candidate.expectsEnvelope, path: candidate.url.path)
                let snapshot = SimulationTimingSnapshot(
                    loadMilliseconds: millisecondsSince(startTime),
                    persistedHistoryCount: state.history.count,
                    persistedSaveBytes: data.count,
                    loadErrorCount: errors.count,
                    persistenceRecoverySource: candidate.recovery.rawValue,
                    restoredFromBackup: candidate.recovery.restoredFromBackup
                )
                return .loaded(
                    PersistenceLoadResult(
                        state: state,
                        recoveryResult: candidate.recovery,
                        errors: errors,
                        timingSnapshot: snapshot
                    )
                )
            } catch let persistenceError as PersistenceError {
                errors.append(persistenceError)
            } catch {
                errors.append(.decodeFailure(path: candidate.url.path, reason: error.localizedDescription))
            }
        }

        let paths = candidates.map(\.url.path)
        let failure = PersistenceError.noValidSave(paths: paths)
        return .failed(
            primaryError: failure,
            errors: errors + [failure],
            timingSnapshot: SimulationTimingSnapshot(
                loadMilliseconds: millisecondsSince(startTime),
                loadErrorCount: errors.count + 1
            )
        )
    }

    func reset() throws {
        do {
            let urls = try storageURLs()
            try removeIfPresent(urls.primary)
            try removeIfPresent(urls.backup)
            try removeIfPresent(urls.legacy)
        } catch {
            throw PersistenceError.saveFailure(path: fallbackPath(for: error), reason: error.localizedDescription)
        }
    }

    private func storageURLs() throws -> StorageURLs {
        let directory = try directoryProvider()
        return StorageURLs(
            primary: directory.appendingPathComponent(Self.fileName),
            backup: directory.appendingPathComponent(Self.backupFileName),
            legacy: directory.appendingPathComponent(Self.legacyFileName),
            meta: directory.appendingPathComponent(Self.metaFileName)
        )
    }

    private func loadCandidates() throws -> [LoadCandidate] {
        let urls = try storageURLs()
        let ordered: [LoadCandidate] = [
            LoadCandidate(url: urls.primary, recovery: .primary, expectsEnvelope: true),
            LoadCandidate(url: urls.backup, recovery: .backup, expectsEnvelope: true),
            LoadCandidate(url: urls.primary, recovery: .legacyPrimary, expectsEnvelope: false),
            LoadCandidate(url: urls.legacy, recovery: .legacyFile, expectsEnvelope: false)
        ]

        return ordered.filter { fileManager.fileExists(atPath: $0.url.path) }
    }

    private func decodeState(from data: Data, expectsEnvelope: Bool, path: String) throws -> GameState {
        if expectsEnvelope {
            do {
                let envelope = try JSONDecoder().decode(PersistedGameState.self, from: data)
                guard envelope.version <= PersistedGameState.currentVersion else {
                    throw PersistenceError.decodeFailure(
                        path: path,
                        reason: "Save version \(envelope.version) is newer than supported version \(PersistedGameState.currentVersion)."
                    )
                }
                return envelope.gameState
            } catch let persistenceError as PersistenceError {
                throw persistenceError
            } catch {
                throw PersistenceError.decodeFailure(path: path, reason: error.localizedDescription)
            }
        }

        do {
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            throw PersistenceError.decodeFailure(path: path, reason: error.localizedDescription)
        }
    }

    private func refreshBackup(primaryURL: URL, backupURL: URL) throws {
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.copyItem(at: primaryURL, to: backupURL)
    }

    private func removeIfPresent(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    private func prunedState(from state: GameState) -> GameState {
        var copy = state
        if copy.history.count > PerformanceBudgets.maxPersistedHistoryItems {
            copy.history = Array(copy.history.prefix(PerformanceBudgets.maxPersistedHistoryItems))
        }
        // Align with FinanceState decoding, which normalizes balances (including peak wealth) after load.
        copy.finance.normalizeInvestmentBalances()
        return copy
    }

    private func millisecondsSince(_ start: CFAbsoluteTime) -> Double {
        ((CFAbsoluteTimeGetCurrent() - start) * 1_000).rounded()
    }

    private func fallbackPath(for error: Error) -> String {
        (error as NSError).userInfo[NSFilePathErrorKey] as? String ?? ""
    }
}

private struct StorageURLs {
    var primary: URL
    var backup: URL
    var legacy: URL
    var meta: URL
}

private struct LoadCandidate {
    var url: URL
    var recovery: PersistenceRecoveryResult
    var expectsEnvelope: Bool
}
