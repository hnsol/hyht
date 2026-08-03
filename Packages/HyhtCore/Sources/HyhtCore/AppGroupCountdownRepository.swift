import Foundation

/// `CountdownRepository` backed by a JSON file (`state.json`) inside an App
/// Group container. Writes are serialized by this `actor`; process-level
/// (app <-> widget) read consistency relies on atomic file writes.
///
/// This type is used by the main app only. Widgets must use
/// `WidgetStateReader` instead, which never writes to disk.
public actor AppGroupCountdownRepository: CountdownRepository {
    public enum RepositoryError: Error, LocalizedError, Sendable {
        /// A previous `load()` detected a `schemaVersion` newer than this
        /// build supports; saving is disabled until the app is upgraded.
        case saveDisabledUnknownSchemaVersion(foundVersion: Int)

        public var errorDescription: String? {
            switch self {
            case .saveDisabledUnknownSchemaVersion(let version):
                return "Refusing to save: persisted data has an unsupported newer schemaVersion (\(version))."
            }
        }
    }

    private static let stateFileName = "state.json"

    private let containerURL: URL
    private let stateFileURL: URL
    private let now: @Sendable () -> Date

    /// Set once `load()` observes an unknown newer schema version. While
    /// non-nil, `save(_:)` is rejected to avoid overwriting data this build
    /// cannot fully understand.
    private var saveDisabledUnknownVersion: Int?

    /// - Parameters:
    ///   - containerURL: Directory the state file lives in. Pass the App
    ///     Group container URL in production, or a temp directory in tests.
    ///   - now: Clock used for default-state generation and corrupt-file
    ///     timestamps. Injectable for deterministic tests.
    public init(containerURL: URL, now: @escaping @Sendable () -> Date = Date.init) {
        self.containerURL = containerURL
        self.stateFileURL = containerURL.appendingPathComponent(Self.stateFileName)
        self.now = now
    }

    /// Convenience factory that resolves the real App Group container.
    public static func makeForAppGroup(now: @escaping @Sendable () -> Date = Date.init) throws -> AppGroupCountdownRepository {
        let url = try HyhtCore.containerURL()
        return AppGroupCountdownRepository(containerURL: url, now: now)
    }

    public func load() async -> RepositoryLoadResult {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: stateFileURL.path) else {
            let defaultState = AppState.makeDefault(now: now(), timeZone: .current)
            saveDisabledUnknownVersion = nil
            try? writeToFile(defaultState)
            return .emptyInitialized(defaultState)
        }

        guard let data = try? Data(contentsOf: stateFileURL) else {
            return recoverFromCorruption()
        }

        switch AppStateDecoder.decode(data) {
        case .loaded(let state):
            saveDisabledUnknownVersion = nil
            return .loaded(state)

        case .unknownNewerVersion(_, let foundVersion):
            // Leave the file untouched; disable future saves.
            saveDisabledUnknownVersion = foundVersion
            return .unknownNewerVersion(foundVersion: foundVersion)

        case .corrupt:
            return recoverFromCorruption()
        }
    }

    public func save(_ state: AppState) async throws {
        if let version = saveDisabledUnknownVersion {
            throw RepositoryError.saveDisabledUnknownSchemaVersion(foundVersion: version)
        }
        try writeToFile(state)
    }

    private func recoverFromCorruption() -> RepositoryLoadResult {
        let fileManager = FileManager.default
        let corruptURL = containerURL.appendingPathComponent(corruptFileName())
        try? fileManager.moveItem(at: stateFileURL, to: corruptURL)

        let defaultState = AppState.makeDefault(now: now(), timeZone: .current)
        saveDisabledUnknownVersion = nil
        try? writeToFile(defaultState)
        return .recoveredFromCorruption(defaultState)
    }

    private func writeToFile(_ state: AppState) throws {
        try? FileManager.default.createDirectory(
            at: containerURL,
            withIntermediateDirectories: true
        )
        let data = try AppStateCoding.encoder.encode(state)
        try data.write(to: stateFileURL, options: .atomic)
    }

    private func corruptFileName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd-HHmmssSSS"
        return "state.corrupt-\(formatter.string(from: now())).json"
    }
}
