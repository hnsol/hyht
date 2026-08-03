import Foundation

/// Persists and loads the app's single `AppState`.
///
/// Implementations must serialize writes (e.g. via `actor`) so that
/// concurrent save requests from within the app process never interleave.
public protocol CountdownRepository: Sendable {
    /// Loads the persisted state, initializing/recovering it as needed.
    func load() async -> RepositoryLoadResult

    /// Persists `state`. May throw if the repository has entered a
    /// save-disabled state (e.g. after detecting an unknown newer
    /// `schemaVersion`) or if the underlying write fails.
    func save(_ state: AppState) async throws
}

/// The outcome of a `CountdownRepository.load()` call.
public enum RepositoryLoadResult: Equatable, Sendable {
    /// A supported, valid state was found and decoded.
    case loaded(AppState)

    /// The persisted data declares a `schemaVersion` newer than this build
    /// supports. The raw file was left untouched on disk.
    case unknownNewerVersion(foundVersion: Int)

    /// The persisted data was corrupt. It was moved aside and a fresh
    /// default state was written and returned.
    case recoveredFromCorruption(AppState)

    /// No persisted file existed yet. A fresh default state was written and
    /// returned.
    case emptyInitialized(AppState)
}
