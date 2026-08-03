import XCTest
@testable import HyhtCore

final class TimelinePlannerTests: XCTestCase {
    // MARK: - Fixtures

    private let policy = CountdownModePolicy.fallback

    /// Fixed instant that is an exact multiple of one hour (and therefore of
    /// every update interval used by the planner), so expected entry times
    /// can be written down exactly.
    private let deadline = Date(timeIntervalSince1970: 1_800_000_000)

    private let minute: TimeInterval = 60
    private let hour: TimeInterval = 3600
    private let day: TimeInterval = 86_400

    private func now(remaining: TimeInterval) -> Date {
        deadline.addingTimeInterval(-remaining)
    }

    private func plan(remaining: TimeInterval, maxEntries: Int = 300) -> TimelinePlan {
        TimelinePlanner.plan(
            deadline: deadline,
            now: now(remaining: remaining),
            policy: policy,
            maxEntries: maxEntries
        )
    }

    /// Every invariant the plan must satisfy no matter how it was produced.
    private func assertInvariants(
        _ plan: TimelinePlan,
        maxEntries: Int = 300,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(plan.entryDates.isEmpty, "plan must always contain the current instant", file: file, line: line)
        XCTAssertLessThanOrEqual(plan.entryDates.count, maxEntries, file: file, line: line)
        for (previous, next) in zip(plan.entryDates, plan.entryDates.dropFirst()) {
            XCTAssertLessThan(previous, next, "entries must be strictly ascending (ordered, no duplicates)", file: file, line: line)
        }
        XCTAssertEqual(Set(plan.entryDates).count, plan.entryDates.count, "entries must be unique", file: file, line: line)
    }

    private func seconds(of date: Date) -> Double {
        let value = date.timeIntervalSince1970
        return value - (value / 60).rounded(.down) * 60
    }

    // MARK: - Size, ordering and coverage

    func testEntryCountNeverExceedsLimitAcrossHorizons() {
        let horizons: [TimeInterval] = [
            400 * day,   // far future: week mode all the way
            40 * day,    // week mode, boundary well beyond the plan
            13 * day,    // week mode, crosses into day mode
            6 * day,     // day mode
            25 * hour,   // hour mode, crosses into clock mode
            3 * hour,    // clock mode
            90 * minute, // min mode
            5 * minute,  // min mode, reaches the deadline
            31           // min mode, a single step from the deadline
        ]
        for remaining in horizons {
            let result = plan(remaining: remaining)
            assertInvariants(result)
            XCTAssertLessThanOrEqual(
                result.entryDates.count,
                300,
                "remaining=\(remaining) produced \(result.entryDates.count) entries"
            )
        }
    }

    func testEntriesAreAscendingAndUnique() {
        for remaining in [400 * day, 40 * day, 25 * hour, 3 * hour, 10 * minute] {
            assertInvariants(plan(remaining: remaining))
        }
    }

    func testFirstEntryIsExactlyNow() {
        // The planning instant is deliberately *not* grid-aligned so the
        // widget renders a correct value the moment the timeline is
        // installed.
        let unaligned = now(remaining: 3 * hour + 17)
        let result = TimelinePlanner.plan(deadline: deadline, now: unaligned, policy: policy)

        XCTAssertEqual(result.entryDates.first, unaligned)
        XCTAssertNotEqual(seconds(of: unaligned), 0, "fixture should be off the minute grid")
    }

    // MARK: - Interval switching across a mode boundary

    func testUpdateIntervalSwitchesWhenModeChanges() {
        // 25h remaining: `hour` mode (6 minute updates) until
        // `deadline - (24h + 30s)`, then `clock` mode (1 minute updates).
        let result = plan(remaining: 25 * hour)
        assertInvariants(result)

        let boundary = deadline.addingTimeInterval(-policy.hourLowerBound)
        guard let boundaryIndex = result.entryDates.firstIndex(of: boundary) else {
            return XCTFail("the 24h+30s boundary must be an entry")
        }

        // Before the boundary: the 6 minute grid.
        XCTAssertGreaterThan(boundaryIndex, 1)
        for index in 1..<boundaryIndex {
            XCTAssertEqual(
                result.entryDates[index].timeIntervalSince(result.entryDates[index - 1]),
                6 * minute,
                "entry \(index) should follow the hour-mode 6 minute interval"
            )
        }

        // After the boundary the mode is `clock`: entries realign onto the
        // minute grid (so the very first step may be shorter), then run at a
        // 1 minute cadence.
        let afterBoundary = result.entryDates[(boundaryIndex + 2)...].prefix(5)
        var previous = result.entryDates[boundaryIndex + 1]
        for date in afterBoundary {
            XCTAssertEqual(date.timeIntervalSince(previous), minute)
            previous = date
        }
    }

    // MARK: - Reload policy

    func testRegularUpdateTruncationUsesAtEnd() {
        // 40 days out: `week` mode updates hourly and the next boundary
        // (12d + 30s before the deadline) is 28 days away, so all 300
        // default-limit entries are regular updates.
        let result = plan(remaining: 40 * day)

        assertInvariants(result)
        XCTAssertEqual(result.entryDates.count, 300)
        XCTAssertEqual(result.policy, .atEnd)
        XCTAssertEqual(result.entryDates.last, now(remaining: 40 * day).addingTimeInterval(299 * hour))
    }

    func testModeBoundaryIsPulledForwardWithAtEnd() {
        // `clock` mode, 1 minute updates, planning from an exact minute:
        // entries land on now + 0, 60, ..., and the `deadline - 120m`
        // boundary is exactly the 11th candidate for a 10 entry limit.
        let maxEntries = 10
        let boundary = deadline.addingTimeInterval(-policy.clockLowerBound)
        let start = boundary.addingTimeInterval(-Double(maxEntries) * minute)

        let result = TimelinePlanner.plan(deadline: deadline, now: start, policy: policy, maxEntries: maxEntries)

        assertInvariants(result, maxEntries: maxEntries)
        XCTAssertEqual(result.entryDates.count, maxEntries)
        XCTAssertEqual(result.policy, .atEnd)
        XCTAssertEqual(result.entryDates.last, boundary, "the boundary must be pulled forward into the plan")
        XCTAssertTrue(result.entryDates.contains(boundary))
        XCTAssertFalse(
            result.entryDates.contains(start.addingTimeInterval(9 * minute)),
            "the last regular update must be dropped to make room"
        )
        XCTAssertNotEqual(result.entryDates.last, deadline)
    }

    func testDeadlineIsPulledForwardWithNever() {
        // `min` mode, 1 minute updates: the deadline itself is exactly the
        // 11th candidate for a 10 entry limit.
        let maxEntries = 10
        let start = deadline.addingTimeInterval(-Double(maxEntries) * minute)

        let result = TimelinePlanner.plan(deadline: deadline, now: start, policy: policy, maxEntries: maxEntries)

        assertInvariants(result, maxEntries: maxEntries)
        XCTAssertEqual(result.entryDates.count, maxEntries)
        XCTAssertEqual(result.policy, .never)
        XCTAssertEqual(result.entryDates.last, deadline, "the completion entry must be pulled forward")
        XCTAssertFalse(
            result.entryDates.contains(start.addingTimeInterval(9 * minute)),
            "the last regular update must be dropped to make room"
        )
        XCTAssertEqual(
            CountdownCalculator.mode(deadline: deadline, now: deadline, policy: policy),
            .done
        )
    }

    func testReachingTheDeadlineMidPlanUsesNever() {
        // 2 hours out: ~120 one-minute entries plus the deadline, well
        // inside the limit.
        let result = plan(remaining: 2 * hour)

        assertInvariants(result)
        XCTAssertLessThan(result.entryDates.count, 300)
        XCTAssertEqual(result.policy, .never)
        XCTAssertEqual(result.entryDates.last, deadline)
    }

    func testPullForwardKeepsOrderingAndLimit() {
        // Both pull-forward flavours, checked against the shared invariants.
        let maxEntries = 10
        let boundaryStart = deadline
            .addingTimeInterval(-policy.clockLowerBound)
            .addingTimeInterval(-Double(maxEntries) * minute)
        let deadlineStart = deadline.addingTimeInterval(-Double(maxEntries) * minute)

        for start in [boundaryStart, deadlineStart] {
            let result = TimelinePlanner.plan(deadline: deadline, now: start, policy: policy, maxEntries: maxEntries)
            assertInvariants(result, maxEntries: maxEntries)
            XCTAssertEqual(result.entryDates.count, maxEntries)
        }
    }

    // MARK: - Already complete

    func testAlreadyCompleteYieldsSingleDoneEntry() {
        for elapsed in [0, 1, 60, 86_400] as [TimeInterval] {
            let instant = deadline.addingTimeInterval(elapsed)
            let result = TimelinePlanner.plan(deadline: deadline, now: instant, policy: policy)

            XCTAssertEqual(result.entryDates, [instant])
            XCTAssertEqual(result.policy, .never)
            XCTAssertEqual(
                CountdownCalculator.mode(deadline: deadline, now: instant, policy: policy),
                .done
            )
        }
    }

    // MARK: - Boundary instants

    func testModeBoundariesInsideTheHorizonAreExactEntries() {
        // 25h out: the 24h + 30s boundary must appear at its exact instant.
        let hourBoundary = deadline.addingTimeInterval(-policy.hourLowerBound)
        XCTAssertTrue(plan(remaining: 25 * hour).entryDates.contains(hourBoundary))

        // 121h out: the 120h + 30s boundary, reached on the 15 minute grid.
        let dayBoundary = deadline.addingTimeInterval(-policy.dayLowerBound)
        XCTAssertTrue(plan(remaining: 121 * hour).entryDates.contains(dayBoundary))

        // 3h out: the 120m boundary between `clock` and `min`.
        let clockBoundary = deadline.addingTimeInterval(-policy.clockLowerBound)
        XCTAssertTrue(plan(remaining: 3 * hour).entryDates.contains(clockBoundary))
    }

    func testClockAndMinuteEntriesAlignToWholeMinutes() {
        // `deadline` sits on a whole minute, so every boundary does too;
        // only the (deliberately unaligned) first entry may carry seconds.
        let start = now(remaining: 3 * hour + 17)
        let result = TimelinePlanner.plan(deadline: deadline, now: start, policy: policy)

        assertInvariants(result)
        XCTAssertNotEqual(seconds(of: start), 0)
        for (index, date) in result.entryDates.enumerated() where index > 0 {
            XCTAssertEqual(seconds(of: date), 0, "entry \(index) at \(date) is not on a whole minute")
        }
    }
}
