import XCTest
@testable import HyhtCore

final class CountdownCalculatorTests: XCTestCase {
    // MARK: - Fixtures

    /// Arbitrary fixed instant; every case derives `now` from it, so no test
    /// ever reads the system clock.
    private let deadline = Date(timeIntervalSince1970: 1_800_000_000)

    private let policy = CountdownModePolicy.fallback

    private func now(remaining: TimeInterval) -> Date {
        deadline.addingTimeInterval(-remaining)
    }

    private func mode(remaining: TimeInterval) -> CountdownDisplayMode {
        CountdownCalculator.mode(deadline: deadline, now: now(remaining: remaining), policy: policy)
    }

    private func snapshot(remaining: TimeInterval) -> CountdownSnapshot {
        CountdownCalculator.snapshot(deadline: deadline, now: now(remaining: remaining), policy: policy)
    }

    private let day: TimeInterval = 86_400
    private let hour: TimeInterval = 3_600
    private let minute: TimeInterval = 60

    // MARK: - Boundaries: exact hits

    /// `week` requires `remaining > 12d + 30s`, so landing exactly on the
    /// boundary already means `day`.
    func testTwelveDaysPlusThirtySecondsExactlyIsDay() {
        XCTAssertEqual(mode(remaining: 12 * day + 30), .day)
    }

    func testOneHundredTwentyHoursPlusThirtySecondsExactlyIsHour() {
        XCTAssertEqual(mode(remaining: 120 * hour + 30), .hour)
    }

    func testTwentyFourHoursPlusThirtySecondsExactlyIsClock() {
        XCTAssertEqual(mode(remaining: 24 * hour + 30), .clock)
    }

    /// The `clock` lower bound is inclusive, so exactly 120 minutes is `clock`.
    func testOneHundredTwentyMinutesExactlyIsClock() {
        XCTAssertEqual(mode(remaining: 120 * minute), .clock)
    }

    func testZeroRemainingIsDone() {
        XCTAssertEqual(mode(remaining: 0), .done)
    }

    // MARK: - Boundaries: ±1 second

    func testWeekDayBoundaryPlusMinusOneSecond() {
        XCTAssertEqual(mode(remaining: 12 * day + 31), .week)
        XCTAssertEqual(mode(remaining: 12 * day + 30), .day)
        XCTAssertEqual(mode(remaining: 12 * day + 29), .day)
    }

    func testDayHourBoundaryPlusMinusOneSecond() {
        XCTAssertEqual(mode(remaining: 120 * hour + 31), .day)
        XCTAssertEqual(mode(remaining: 120 * hour + 30), .hour)
        XCTAssertEqual(mode(remaining: 120 * hour + 29), .hour)
    }

    func testHourClockBoundaryPlusMinusOneSecond() {
        XCTAssertEqual(mode(remaining: 24 * hour + 31), .hour)
        XCTAssertEqual(mode(remaining: 24 * hour + 30), .clock)
        XCTAssertEqual(mode(remaining: 24 * hour + 29), .clock)
    }

    func testClockMinBoundaryPlusMinusOneSecond() {
        XCTAssertEqual(mode(remaining: 120 * minute + 1), .clock)
        XCTAssertEqual(mode(remaining: 120 * minute), .clock)
        XCTAssertEqual(mode(remaining: 120 * minute - 1), .min)
    }

    func testDoneBoundaryPlusMinusOneSecond() {
        XCTAssertEqual(mode(remaining: 1), .min)
        XCTAssertEqual(mode(remaining: 0), .done)
        XCTAssertEqual(mode(remaining: -1), .done)
    }

    func testSubSecondRemainingIsStillMin() {
        XCTAssertEqual(mode(remaining: 0.001), .min)
        XCTAssertEqual(mode(remaining: -0.001), .done)
    }

    func testEveryModeIsReachable() {
        XCTAssertEqual(mode(remaining: 30 * day), .week)
        XCTAssertEqual(mode(remaining: 8 * day), .day)
        XCTAssertEqual(mode(remaining: 48 * hour), .hour)
        XCTAssertEqual(mode(remaining: 5 * hour), .clock)
        XCTAssertEqual(mode(remaining: 30 * minute), .min)
        XCTAssertEqual(mode(remaining: -1 * day), .done)
    }

    // MARK: - Primary text

    func testWeekPrimaryTextUsesToFixed2() {
        XCTAssertEqual(snapshot(remaining: 20 * day).primaryText, "2.86")
        XCTAssertEqual(snapshot(remaining: 12 * day + 31).primaryText, "1.71")
        XCTAssertEqual(snapshot(remaining: 14 * day).primaryText, "2.00")
    }

    func testDayPrimaryTextUsesToFixed2() {
        XCTAssertEqual(snapshot(remaining: 12 * day + 30).primaryText, "12.00")
        XCTAssertEqual(snapshot(remaining: 120 * hour + 31).primaryText, "5.00")
    }

    func testHourPrimaryTextUsesToFixed1() {
        XCTAssertEqual(snapshot(remaining: 120 * hour + 30).primaryText, "120.0")
        XCTAssertEqual(snapshot(remaining: 24 * hour + 31).primaryText, "24.0")
        XCTAssertEqual(snapshot(remaining: 48.5 * hour).primaryText, "48.5")
    }

    func testDonePrimaryTextIsEmptyAndCarriesNoClockComponents() {
        let result = snapshot(remaining: -5)
        XCTAssertEqual(result.mode, .done)
        XCTAssertEqual(result.primaryText, "")
        XCTAssertNil(result.clockHour)
        XCTAssertNil(result.clockMinute)
    }

    func testNonClockModesCarryNoClockComponents() {
        for remaining in [30 * day, 8 * day, 48 * hour, 30 * minute] {
            let result = snapshot(remaining: remaining)
            XCTAssertNil(result.clockHour, "mode \(result.mode)")
            XCTAssertNil(result.clockMinute, "mode \(result.mode)")
        }
    }

    // MARK: - Clock formatting

    func testClockSplitsHoursAndZeroPaddedMinutes() {
        let result = snapshot(remaining: 3 * hour + 7 * minute + 12)
        XCTAssertEqual(result.mode, .clock)
        XCTAssertEqual(result.clockHour, 3)
        XCTAssertEqual(result.clockMinute, 7)
        XCTAssertEqual(result.primaryText, "3:07")
    }

    func testClockHoursAreNotZeroPadded() {
        let result = snapshot(remaining: 2 * hour + 5 * minute)
        XCTAssertEqual(result.primaryText, "2:05")
    }

    func testClockUpperRange() {
        let result = snapshot(remaining: 23 * hour + 58 * minute)
        XCTAssertEqual(result.mode, .clock)
        XCTAssertEqual(result.clockHour, 23)
        XCTAssertEqual(result.clockMinute, 58)
        XCTAssertEqual(result.primaryText, "23:58")
    }

    func testClockAtLowerBoundIsTwoZeroZero() {
        let result = snapshot(remaining: 120 * minute)
        XCTAssertEqual(result.mode, .clock)
        XCTAssertEqual(result.clockHour, 2)
        XCTAssertEqual(result.clockMinute, 0)
        XCTAssertEqual(result.primaryText, "2:00")
    }

    /// The largest remaining time that still selects `clock`.
    func testClockAtUpperBoundIsTwentyFourZeroZero() {
        let result = snapshot(remaining: 24 * hour + 30)
        XCTAssertEqual(result.mode, .clock)
        XCTAssertEqual(result.clockHour, 24)
        XCTAssertEqual(result.clockMinute, 0)
        XCTAssertEqual(result.primaryText, "24:00")
    }

    func testClockTruncatesSecondsRatherThanRounding() {
        // 4:59:59 must stay "4:59", never round to "5:00".
        let result = snapshot(remaining: 4 * hour + 59 * minute + 59.999)
        XCTAssertEqual(result.clockHour, 4)
        XCTAssertEqual(result.clockMinute, 59)
        XCTAssertEqual(result.primaryText, "4:59")
    }

    // MARK: - Min formatting

    func testMinFloorsToWholeMinutes() {
        XCTAssertEqual(snapshot(remaining: 120 * minute - 1).primaryText, "119")
        XCTAssertEqual(snapshot(remaining: 60 * minute + 59).primaryText, "60")
        XCTAssertEqual(snapshot(remaining: 2 * minute).primaryText, "2")
        XCTAssertEqual(snapshot(remaining: 59).primaryText, "0")
    }

    /// One second left is still `min` (the mode only flips at `remaining <= 0`),
    /// even though the floored minute count is zero.
    func testOneSecondRemainingIsMinDisplayingZero() {
        let result = snapshot(remaining: 1)
        XCTAssertEqual(result.mode, .min)
        XCTAssertEqual(result.primaryText, "0")
    }

    // MARK: - Next transition

    func testNextTransitionForEachMode() {
        func transition(remaining: TimeInterval) -> Date? {
            CountdownCalculator.nextTransition(
                deadline: deadline,
                now: now(remaining: remaining),
                policy: policy
            )
        }

        XCTAssertEqual(transition(remaining: 30 * day), deadline.addingTimeInterval(-(12 * day + 30)))
        XCTAssertEqual(transition(remaining: 8 * day), deadline.addingTimeInterval(-(120 * hour + 30)))
        XCTAssertEqual(transition(remaining: 48 * hour), deadline.addingTimeInterval(-(24 * hour + 30)))
        XCTAssertEqual(transition(remaining: 5 * hour), deadline.addingTimeInterval(-(120 * minute)))
        XCTAssertEqual(transition(remaining: 30 * minute), deadline)
    }

    func testNextTransitionIsNilAfterDeadline() {
        XCTAssertNil(
            CountdownCalculator.nextTransition(deadline: deadline, now: deadline, policy: policy)
        )
        XCTAssertNil(
            CountdownCalculator.nextTransition(
                deadline: deadline,
                now: deadline.addingTimeInterval(60),
                policy: policy
            )
        )
    }

    func testSnapshotCarriesTheSameTransitionDate() {
        for remaining in [30 * day, 8 * day, 48 * hour, 5 * hour, 30 * minute, -1] as [TimeInterval] {
            let result = snapshot(remaining: remaining)
            XCTAssertEqual(
                result.nextTransition,
                CountdownCalculator.nextTransition(
                    deadline: deadline,
                    now: now(remaining: remaining),
                    policy: policy
                ),
                "remaining \(remaining)"
            )
        }
    }

    /// Stepping to a mode's transition date must actually produce the next mode
    /// (for the strict boundaries) or the final instant of the current mode
    /// (for `clock`'s inclusive boundary).
    func testTransitionDatesLandOnTheExpectedMode() {
        let weekBoundary = deadline.addingTimeInterval(-(12 * day + 30))
        XCTAssertEqual(
            CountdownCalculator.mode(deadline: deadline, now: weekBoundary, policy: policy),
            .day
        )

        let dayBoundary = deadline.addingTimeInterval(-(120 * hour + 30))
        XCTAssertEqual(
            CountdownCalculator.mode(deadline: deadline, now: dayBoundary, policy: policy),
            .hour
        )

        let hourBoundary = deadline.addingTimeInterval(-(24 * hour + 30))
        XCTAssertEqual(
            CountdownCalculator.mode(deadline: deadline, now: hourBoundary, policy: policy),
            .clock
        )

        // Inclusive bound: at the boundary the mode is still `clock`; `min`
        // starts immediately after it.
        let clockBoundary = deadline.addingTimeInterval(-(120 * minute))
        XCTAssertEqual(
            CountdownCalculator.mode(deadline: deadline, now: clockBoundary, policy: policy),
            .clock
        )
        XCTAssertEqual(
            CountdownCalculator.mode(
                deadline: deadline,
                now: clockBoundary.addingTimeInterval(1),
                policy: policy
            ),
            .min
        )

        XCTAssertEqual(
            CountdownCalculator.mode(deadline: deadline, now: deadline, policy: policy),
            .done
        )
    }

    func testTransitionsAreStrictlyOrdered() {
        let boundaries = [
            CountdownCalculator.nextTransition(deadline: deadline, now: now(remaining: 30 * day), policy: policy),
            CountdownCalculator.nextTransition(deadline: deadline, now: now(remaining: 8 * day), policy: policy),
            CountdownCalculator.nextTransition(deadline: deadline, now: now(remaining: 48 * hour), policy: policy),
            CountdownCalculator.nextTransition(deadline: deadline, now: now(remaining: 5 * hour), policy: policy),
            CountdownCalculator.nextTransition(deadline: deadline, now: now(remaining: 30 * minute), policy: policy)
        ].compactMap { $0 }

        XCTAssertEqual(boundaries.count, 5)
        for (earlier, later) in zip(boundaries, boundaries.dropFirst()) {
            XCTAssertLessThan(earlier, later)
        }
    }

    // MARK: - Purity / constants

    func testConstantsMatchTheirNames() {
        XCTAssertEqual(CountdownCalculator.twelveDays, 12 * 24 * 60 * 60)
        XCTAssertEqual(CountdownCalculator.oneHundredTwentyHours, 120 * 60 * 60)
        XCTAssertEqual(CountdownCalculator.twentyFourHours, 24 * 60 * 60)
        XCTAssertEqual(CountdownCalculator.oneHundredTwentyMinutes, 120 * 60)
        XCTAssertEqual(CountdownCalculator.eps30Sec, 30)

        // The policy's bounds are exactly "threshold + EPS" (except `clock`,
        // which has no epsilon).
        XCTAssertEqual(policy.weekLowerBound, CountdownCalculator.twelveDays + CountdownCalculator.eps30Sec)
        XCTAssertEqual(policy.dayLowerBound, CountdownCalculator.oneHundredTwentyHours + CountdownCalculator.eps30Sec)
        XCTAssertEqual(policy.hourLowerBound, CountdownCalculator.twentyFourHours + CountdownCalculator.eps30Sec)
        XCTAssertEqual(policy.clockLowerBound, CountdownCalculator.oneHundredTwentyMinutes)
    }

    func testSnapshotIsDeterministicForTheSameInputs() {
        let instant = now(remaining: 9 * day)
        let first = CountdownCalculator.snapshot(deadline: deadline, now: instant, policy: policy)
        let second = CountdownCalculator.snapshot(deadline: deadline, now: instant, policy: policy)
        XCTAssertEqual(first, second)
    }

    /// Only the *interval* between the two dates matters, never the absolute
    /// wall-clock time.
    func testSnapshotDependsOnlyOnTheInterval() {
        let remaining: TimeInterval = 9 * day + 1234
        let other = Date(timeIntervalSince1970: 0)

        let a = CountdownCalculator.snapshot(deadline: deadline, now: now(remaining: remaining), policy: policy)
        let b = CountdownCalculator.snapshot(
            deadline: other.addingTimeInterval(remaining),
            now: other,
            policy: policy
        )

        XCTAssertEqual(a.mode, b.mode)
        XCTAssertEqual(a.primaryText, b.primaryText)
    }

    func testSweepAcrossAllModesNeverCrashesAndAlwaysProducesText() {
        var remaining: TimeInterval = 40 * day
        while remaining > -2 * day {
            let result = snapshot(remaining: remaining)
            if result.mode == .done {
                XCTAssertTrue(result.primaryText.isEmpty)
                XCTAssertNil(result.nextTransition)
            } else {
                XCTAssertFalse(result.primaryText.isEmpty, "remaining \(remaining)")
                XCTAssertNotNil(result.nextTransition)
            }
            remaining -= 991
        }
    }
}
