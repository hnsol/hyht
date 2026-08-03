import Foundation

/// Pure countdown math: mode selection, primary value formatting and mode
/// boundary calculation.
///
/// Everything here is a pure function of `(deadline, now, policy)`. Nothing in
/// this type reads the system clock or touches UI/WidgetKit, so both the app
/// preview and the widget timeline provider can call it with an injected
/// instant and get identical results.
///
/// The behaviour mirrors the original Scriptable widget. Note that the
/// Scriptable source's constant *names* (`TEN_DAYS_MS`, `HUNDRED_HOURS_MS`,
/// `HUNDRED_MINUTES_MS`) disagree with their *values*; the values are
/// authoritative and are reproduced here under names that match them.
public enum CountdownCalculator {
    // MARK: - Time constants (names match the actual values)

    /// 12 days, in seconds.
    public static let twelveDays: TimeInterval = 12 * 24 * 60 * 60
    /// 120 hours, in seconds.
    public static let oneHundredTwentyHours: TimeInterval = 120 * 60 * 60
    /// 24 hours, in seconds.
    public static let twentyFourHours: TimeInterval = 24 * 60 * 60
    /// 120 minutes, in seconds.
    public static let oneHundredTwentyMinutes: TimeInterval = 120 * 60
    /// Margin applied to the `week`/`day`/`hour` boundaries, in seconds.
    public static let eps30Sec: TimeInterval = CountdownModePolicy.epsilon

    /// Seconds in one week, used as the `week` mode divisor.
    public static let secondsPerWeek: TimeInterval = 7 * 24 * 60 * 60
    /// Seconds in one day, used as the `day` mode divisor.
    public static let secondsPerDay: TimeInterval = 24 * 60 * 60
    /// Seconds in one hour, used as the `hour` mode divisor.
    public static let secondsPerHour: TimeInterval = 60 * 60
    /// Seconds in one minute, used as the `min` mode divisor.
    public static let secondsPerMinute: TimeInterval = 60

    // MARK: - Mode selection

    /// Returns the display mode for the given remaining time, in seconds.
    ///
    /// Evaluation order (first match wins):
    ///
    /// | condition                       | mode  |
    /// |---------------------------------|-------|
    /// | `remaining <= 0`                | done  |
    /// | `remaining > 12d + 30s`         | week  |
    /// | `remaining > 120h + 30s`        | day   |
    /// | `remaining > 24h + 30s`         | hour  |
    /// | `remaining >= 120m`             | clock |
    /// | otherwise (`remaining > 0`)     | min   |
    ///
    /// The first three boundaries are strict (`>`), so a remaining time of
    /// *exactly* `12d + 30s` is already `day`. The `clock` boundary is
    /// inclusive (`>=`), so exactly `120m` is still `clock`.
    public static func mode(
        remaining: TimeInterval,
        policy: CountdownModePolicy = .fallback
    ) -> CountdownDisplayMode {
        if remaining <= 0 { return .done }
        if remaining > policy.weekLowerBound { return .week }
        if remaining > policy.dayLowerBound { return .day }
        if remaining > policy.hourLowerBound { return .hour }
        if remaining >= policy.clockLowerBound { return .clock }
        return .min
    }

    /// Returns the display mode at `now` for a countdown ending at `deadline`.
    public static func mode(
        deadline: Date,
        now: Date,
        policy: CountdownModePolicy = .fallback
    ) -> CountdownDisplayMode {
        mode(remaining: deadline.timeIntervalSince(now), policy: policy)
    }

    // MARK: - Snapshot

    /// Computes the full display state at `now` for a countdown ending at
    /// `deadline`.
    ///
    /// - `primaryText` holds the formatted primary value: a `toFixed`-compatible
    ///   decimal for `week`/`day`/`hour`, `"H:mm"` for `clock`, a whole number
    ///   of minutes for `min`, and an empty string for `done` (the completion
    ///   screen's wording is template-driven, not computed here).
    /// - `clockHour` / `clockMinute` are populated only in `clock` mode.
    /// - `nextTransition` is the boundary date described on
    ///   ``nextTransition(deadline:now:policy:)``.
    public static func snapshot(
        deadline: Date,
        now: Date,
        policy: CountdownModePolicy = .fallback
    ) -> CountdownSnapshot {
        let remaining = deadline.timeIntervalSince(now)
        let mode = mode(remaining: remaining, policy: policy)
        let transition = nextTransition(deadline: deadline, mode: mode, policy: policy)

        switch mode {
        case .done:
            return CountdownSnapshot(
                mode: .done,
                primaryText: "",
                nextTransition: transition
            )

        case .week:
            return CountdownSnapshot(
                mode: .week,
                primaryText: format(remaining / secondsPerWeek, rule: policy.weekRounding),
                nextTransition: transition
            )

        case .day:
            return CountdownSnapshot(
                mode: .day,
                primaryText: format(remaining / secondsPerDay, rule: policy.dayRounding),
                nextTransition: transition
            )

        case .hour:
            return CountdownSnapshot(
                mode: .hour,
                primaryText: format(remaining / secondsPerHour, rule: policy.hourRounding),
                nextTransition: transition
            )

        case .clock:
            let components = clockComponents(remaining: remaining)
            return CountdownSnapshot(
                mode: .clock,
                primaryText: "\(components.hour):\(zeroPadded(components.minute, width: 2))",
                clockHour: components.hour,
                clockMinute: components.minute,
                nextTransition: transition
            )

        case .min:
            return CountdownSnapshot(
                mode: .min,
                primaryText: format(remaining / secondsPerMinute, rule: policy.minRounding),
                nextTransition: transition
            )
        }
    }

    // MARK: - Clock components

    /// Splits remaining seconds into whole hours and whole minutes, truncating
    /// the seconds first (`floor`), exactly like the Scriptable `splitHM`.
    ///
    /// In `clock` mode the remaining time never exceeds `24h + 30s`, so `hour`
    /// stays within `0...24`.
    public static func clockComponents(remaining: TimeInterval) -> (hour: Int, minute: Int) {
        let totalSeconds = safeInt(floor(max(0, remaining)))
        return (totalSeconds / 3600, (totalSeconds % 3600) / 60)
    }

    // MARK: - Transitions

    /// Returns the instant at which the countdown leaves its current mode, or
    /// `nil` once the deadline has passed.
    ///
    /// | current mode | returned boundary            |
    /// |--------------|------------------------------|
    /// | week         | `deadline - (12d + 30s)`     |
    /// | day          | `deadline - (120h + 30s)`    |
    /// | hour         | `deadline - (24h + 30s)`     |
    /// | clock        | `deadline - 120m`            |
    /// | min          | `deadline`                   |
    /// | done         | `nil`                        |
    ///
    /// For the strict (`>`) boundaries the *new* mode already applies at the
    /// returned instant. The `clock` lower bound is inclusive (`>=`), so at
    /// exactly `deadline - 120m` the mode is still `clock` and `min` begins
    /// immediately after; the returned date is still the boundary itself, which
    /// is what timeline generation needs.
    public static func nextTransition(
        deadline: Date,
        now: Date,
        policy: CountdownModePolicy = .fallback
    ) -> Date? {
        nextTransition(
            deadline: deadline,
            mode: mode(deadline: deadline, now: now, policy: policy),
            policy: policy
        )
    }

    /// Boundary date for an already-determined mode.
    public static func nextTransition(
        deadline: Date,
        mode: CountdownDisplayMode,
        policy: CountdownModePolicy = .fallback
    ) -> Date? {
        switch mode {
        case .done:
            return nil
        case .week:
            return deadline.addingTimeInterval(-policy.weekLowerBound)
        case .day:
            return deadline.addingTimeInterval(-policy.dayLowerBound)
        case .hour:
            return deadline.addingTimeInterval(-policy.hourLowerBound)
        case .clock:
            return deadline.addingTimeInterval(-policy.clockLowerBound)
        case .min:
            return deadline
        }
    }

    // MARK: - Formatting helpers

    /// Applies a policy rounding rule to an already-scaled numeric value.
    public static func format(_ value: Double, rule: CountdownModePolicy.RoundingRule) -> String {
        switch rule {
        case .toFixed2:
            return jsToFixed(value, digits: 2)
        case .toFixed1:
            return jsToFixed(value, digits: 1)
        case .floor:
            guard value.isFinite else { return jsToFixed(value, digits: 0) }
            return String(safeInt(floor(value)))
        }
    }

    private static func zeroPadded(_ value: Int, width: Int) -> String {
        let digits = String(value)
        guard digits.count < width else { return digits }
        return String(repeating: "0", count: width - digits.count) + digits
    }

    /// Clamps to `Int`'s range so that absurd inputs cannot trap.
    private static func safeInt(_ value: Double) -> Int {
        guard value.isFinite else { return value < 0 ? Int.min : Int.max }
        if value >= Double(Int.max) { return Int.max }
        if value <= Double(Int.min) { return Int.min }
        return Int(value)
    }
}
