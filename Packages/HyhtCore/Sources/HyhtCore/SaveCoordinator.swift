import Foundation

/// Controls automatic, debounced persistence of edits made in the app's UI.
///
/// - Coalesces rapid edits behind a debounce window so only the latest state
///   is saved.
/// - Skips saving when the incoming state is equal to the last saved state.
/// - Serializes actual writes through the injected `CountdownRepository`
///   (expected to be an `actor`).
/// - Triggers `reloadWidgets` at most once per save, and only when at least
///   one of the coalesced changes was marked `affectsWidget: true`.
/// - Does not depend on WidgetKit directly; the reload action is injected by
///   the app.
@MainActor
public final class SaveCoordinator: ObservableObject {
    public enum SaveStatus: Equatable, Sendable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    @Published public private(set) var status: SaveStatus = .idle

    private let repository: any CountdownRepository
    private let reloadWidgets: () -> Void
    private let debounceNanoseconds: UInt64

    private var lastSavedState: AppState?
    private var pendingState: AppState?
    private var pendingAffectsWidget = false
    private var debounceTask: Task<Void, Never>?

    /// - Parameters:
    ///   - repository: Storage backend. Should serialize writes internally
    ///     (e.g. be an `actor`).
    ///   - reloadWidgets: Invoked after a successful save that included a
    ///     widget-affecting change. Production callers pass
    ///     `{ WidgetCenter.shared.reloadTimelines(ofKind: "HyhtWidget") }`;
    ///     HyhtCore itself never imports WidgetKit.
    ///   - debounceNanoseconds: Debounce window before a pending change is
    ///     saved. Defaults to 400ms per spec; tests may inject a shorter
    ///     value to avoid slow, timing-dependent tests.
    ///   - initialSavedState: Optional state to seed as "already saved" (for
    ///     example, right after a successful `load()`) so an identical first
    ///     edit doesn't trigger a redundant save.
    public init(
        repository: any CountdownRepository,
        reloadWidgets: @escaping () -> Void,
        debounceNanoseconds: UInt64 = 400_000_000,
        initialSavedState: AppState? = nil
    ) {
        self.repository = repository
        self.reloadWidgets = reloadWidgets
        self.debounceNanoseconds = debounceNanoseconds
        self.lastSavedState = initialSavedState
    }

    /// Notifies the coordinator that the edited state changed. Debounced;
    /// only the most recent state across a burst of calls is eventually
    /// saved.
    public func stateChanged(_ state: AppState, affectsWidget: Bool) {
        guard state != lastSavedState else {
            return
        }

        pendingState = state
        pendingAffectsWidget = pendingAffectsWidget || affectsWidget

        debounceTask?.cancel()
        debounceTask = Task { [weak self, debounceNanoseconds] in
            try? await Task.sleep(nanoseconds: debounceNanoseconds)
            guard !Task.isCancelled else { return }
            await self?.performSave()
        }
    }

    /// Immediately saves any pending change, bypassing the debounce window.
    /// Intended to be called when the app leaves the foreground
    /// (`scenePhase` change).
    public func flush() async {
        debounceTask?.cancel()
        debounceTask = nil
        await performSave()
    }

    private func performSave() async {
        guard let state = pendingState else { return }

        guard state != lastSavedState else {
            pendingState = nil
            pendingAffectsWidget = false
            return
        }

        let affectsWidget = pendingAffectsWidget
        pendingState = nil
        pendingAffectsWidget = false

        status = .saving
        do {
            try await repository.save(state)
            lastSavedState = state
            status = .saved
            if affectsWidget {
                reloadWidgets()
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }
}
