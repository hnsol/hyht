import XCTest
@testable import HyhtCore

final class PreviewSnapshotFactoryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    func testCompletedPreviewIsDoneEvenBeforeDeadline() {
        let snapshot = PreviewSnapshotFactory.snapshot(
            deadline: now.addingTimeInterval(3 * day),
            now: now,
            isCompleted: true
        )

        XCTAssertEqual(snapshot.mode, .done)
    }

    func testActivePreviewUsesRepresentativeCountdownAfterDeadline() {
        let snapshot = PreviewSnapshotFactory.snapshot(
            deadline: now.addingTimeInterval(-day),
            now: now,
            isCompleted: false
        )

        XCTAssertEqual(snapshot.mode, .week)
        XCTAssertEqual(snapshot.primaryText, "4.29")
    }

    func testActivePreviewPreservesFutureDeadline() {
        let snapshot = PreviewSnapshotFactory.snapshot(
            deadline: now.addingTimeInterval(3 * day),
            now: now,
            isCompleted: false
        )

        XCTAssertEqual(snapshot.mode, .hour)
        XCTAssertEqual(snapshot.primaryText, "72.0")
    }
}
