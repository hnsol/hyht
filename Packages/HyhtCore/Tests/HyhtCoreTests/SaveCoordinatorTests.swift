import XCTest
@testable import HyhtCore

@MainActor
final class SaveCoordinatorTests: XCTestCase {
    /// Debounce window used in tests: short enough to keep the suite fast,
    /// long enough to reliably observe coalescing behavior.
    private let testDebounceNanoseconds: UInt64 = 60_000_000 // 60ms

    private func waitPastDebounce() async {
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
    }

    private func makeState(name: String = "Event") -> AppState {
        var state = AppState.makeDefault(now: Date(timeIntervalSince1970: 0), timeZone: .current)
        state.event.name = name
        return state
    }

    private final class ReloadSpy: @unchecked Sendable {
        private(set) var count = 0
        func call() { count += 1 }
    }

    func testBurstOfChangesResultsInSingleSave() async {
        let repository = InMemoryCountdownRepository(loadResult: .emptyInitialized(AppState.makeDefault(now: Date(), timeZone: .current)))
        let spy = ReloadSpy()
        let coordinator = SaveCoordinator(
            repository: repository,
            reloadWidgets: { spy.call() },
            debounceNanoseconds: testDebounceNanoseconds
        )

        for i in 0..<10 {
            coordinator.stateChanged(makeState(name: "Event \(i)"), affectsWidget: true)
        }

        await waitPastDebounce()

        let saveCount = await repository.saveCallCount
        XCTAssertEqual(saveCount, 1)

        let saved = await repository.savedState
        XCTAssertEqual(saved?.event.name, "Event 9")
    }

    func testEquivalentStateIsNotSaved() async {
        let initial = makeState(name: "Same")
        let repository = InMemoryCountdownRepository(loadResult: .emptyInitialized(initial))
        let coordinator = SaveCoordinator(
            repository: repository,
            reloadWidgets: {},
            debounceNanoseconds: testDebounceNanoseconds,
            initialSavedState: initial
        )

        coordinator.stateChanged(initial, affectsWidget: true)
        await waitPastDebounce()

        let saveCount = await repository.saveCallCount
        XCTAssertEqual(saveCount, 0)
    }

    func testReloadWidgetsNotCalledWhenNoChangeAffectsWidget() async {
        let repository = InMemoryCountdownRepository(loadResult: .emptyInitialized(AppState.makeDefault(now: Date(), timeZone: .current)))
        let spy = ReloadSpy()
        let coordinator = SaveCoordinator(
            repository: repository,
            reloadWidgets: { spy.call() },
            debounceNanoseconds: testDebounceNanoseconds
        )

        coordinator.stateChanged(makeState(name: "NonWidget"), affectsWidget: false)
        await waitPastDebounce()

        let saveCount = await repository.saveCallCount
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(spy.count, 0)
    }

    func testReloadWidgetsCalledOnceWhenAnyChangeAffectsWidget() async {
        let repository = InMemoryCountdownRepository(loadResult: .emptyInitialized(AppState.makeDefault(now: Date(), timeZone: .current)))
        let spy = ReloadSpy()
        let coordinator = SaveCoordinator(
            repository: repository,
            reloadWidgets: { spy.call() },
            debounceNanoseconds: testDebounceNanoseconds
        )

        coordinator.stateChanged(makeState(name: "A"), affectsWidget: false)
        coordinator.stateChanged(makeState(name: "B"), affectsWidget: true)
        coordinator.stateChanged(makeState(name: "C"), affectsWidget: false)
        await waitPastDebounce()

        let saveCount = await repository.saveCallCount
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(spy.count, 1)
    }

    func testFlushSavesPendingChangeImmediately() async {
        let repository = InMemoryCountdownRepository(loadResult: .emptyInitialized(AppState.makeDefault(now: Date(), timeZone: .current)))
        let coordinator = SaveCoordinator(
            repository: repository,
            reloadWidgets: {},
            debounceNanoseconds: 10_000_000_000 // 10s: would not fire within test timeframe without flush
        )

        coordinator.stateChanged(makeState(name: "Flushed"), affectsWidget: false)
        await coordinator.flush()

        let saveCount = await repository.saveCallCount
        XCTAssertEqual(saveCount, 1)
        let saved = await repository.savedState
        XCTAssertEqual(saved?.event.name, "Flushed")
    }

    func testSaveFailureSetsFailedStatusNotSaved() async {
        let repository = InMemoryCountdownRepository(loadResult: .emptyInitialized(AppState.makeDefault(now: Date(), timeZone: .current)))
        await repository.failNextSave(message: "disk full")
        let coordinator = SaveCoordinator(
            repository: repository,
            reloadWidgets: {},
            debounceNanoseconds: testDebounceNanoseconds
        )

        coordinator.stateChanged(makeState(name: "WillFail"), affectsWidget: false)
        await waitPastDebounce()

        if case .failed(let message) = coordinator.status {
            XCTAssertEqual(message, "disk full")
        } else {
            XCTFail("Expected .failed status, got \(coordinator.status)")
        }
    }
}
