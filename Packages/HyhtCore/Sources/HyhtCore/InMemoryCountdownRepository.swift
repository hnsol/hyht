import Foundation

/// In-memory `CountdownRepository` for tests. Records the number of `save`
/// calls and supports injecting a failure on the next save.
public actor InMemoryCountdownRepository: CountdownRepository {
    public struct InjectedFailure: Error, LocalizedError, Sendable {
        public let message: String

        public init(message: String = "Injected failure") {
            self.message = message
        }

        public var errorDescription: String? { message }
    }

    private var loadResult: RepositoryLoadResult
    private var shouldFailNextSave = false
    private var failureMessage = "Injected failure"

    public private(set) var savedState: AppState?
    public private(set) var saveCallCount = 0

    public init(loadResult: RepositoryLoadResult) {
        self.loadResult = loadResult
        switch loadResult {
        case .loaded(let state), .recoveredFromCorruption(let state), .emptyInitialized(let state):
            self.savedState = state
        case .unknownNewerVersion:
            self.savedState = nil
        }
    }

    public func load() async -> RepositoryLoadResult {
        loadResult
    }

    public func save(_ state: AppState) async throws {
        saveCallCount += 1
        if shouldFailNextSave {
            shouldFailNextSave = false
            throw InjectedFailure(message: failureMessage)
        }
        savedState = state
    }

    /// Makes the next `save(_:)` call throw `InjectedFailure(message:)`.
    public func failNextSave(message: String = "Injected failure") {
        shouldFailNextSave = true
        failureMessage = message
    }

    /// Updates the value `load()` will return on subsequent calls.
    public func setLoadResult(_ result: RepositoryLoadResult) {
        loadResult = result
    }
}
