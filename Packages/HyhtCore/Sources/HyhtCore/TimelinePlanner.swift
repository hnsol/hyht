import Foundation

/// How WidgetKit should behave after the last planned entry has been shown.
public enum TimelineReloadPolicy: Equatable, Sendable {
    /// Ask the system to request a new timeline once the last entry is
    /// consumed. The actual provider invocation time is OS-dependent, which
    /// is why boundary entries are pulled forward rather than relied upon
    /// being regenerated in time (see ``TimelinePlanner``).
    case atEnd
    /// Never request another timeline: the countdown has reached its
    /// deadline and the completion screen is final.
    case never
}

/// A planned widget timeline: the instants entries should be rendered for,
/// plus the reload policy to attach to them.
public struct TimelinePlan: Equatable, Sendable {
    /// Strictly ascending, duplicate-free instants. Always contains at least
    /// one entry (the planning instant) and never more than `maxEntries`.
    public var entryDates: [Date]

    /// The reload policy that goes with `entryDates`.
    public var policy: TimelineReloadPolicy

    public init(entryDates: [Date], policy: TimelineReloadPolicy) {
        self.entryDates = entryDates
        self.policy = policy
    }
}

/// Pure planning of a widget timeline for a countdown.
///
/// The plan is a function of `(deadline, now, policy, maxEntries)` only: it
/// reads no clock and touches no WidgetKit API, so it is fully testable.
///
/// The algorithm, in order:
///
/// 1. The planning instant `now` is always the first entry (it is *not*
///    grid-aligned, so the widget shows a correct value immediately).
/// 2. From the current entry's mode, the next *regular* update is the next
///    instant on that mode's interval grid: `week` = 1h, `day` = 15m,
///    `hour` = 6m, `clock`/`min` = 1m. Because the grid is anchored at the
///    Unix epoch and every interval divides an hour, regular updates land on
///    round wall-clock times; in particular `clock`/`min` updates land on
///    exact minutes (seconds = 0).
/// 3. The next *mode boundary* is the earliest of
///    `deadline - (12d + 30s)`, `deadline - (120h + 30s)`,
///    `deadline - (24h + 30s)`, `deadline - 120m` and `deadline` itself that
///    is strictly later than the current entry.
/// 4. The earlier of the two becomes the next entry (a tie is recorded as a
///    boundary), and the mode is recomputed from there. Entries are therefore
///    strictly ascending and never duplicated.
/// 5. Steps 2-4 repeat until `maxEntries` entries exist.
/// 6. On reaching `maxEntries`, the *next* candidate (the "301st") decides
///    the ending:
///    - a regular update: the plan ends as-is with ``TimelineReloadPolicy/atEnd``;
///    - a mode boundary or the deadline: the last regular-update entry is
///      dropped and that candidate is pulled forward as the final entry, so
///      the boundary is never missed while waiting for an OS-scheduled
///      reload. The policy is ``TimelineReloadPolicy/never`` when the pulled
///      forward candidate is the deadline (the completion screen is final)
///      and ``TimelineReloadPolicy/atEnd`` otherwise.
/// 7. Reaching the deadline before `maxEntries` ends the plan there with
///    ``TimelineReloadPolicy/never``.
/// 8. Planning at or after the deadline yields a single completion entry at
///    `now` with ``TimelineReloadPolicy/never``.
public enum TimelinePlanner {
    /// How a planned entry came to be, used only to implement the
    /// pull-forward rule in step 6.
    private enum EntryKind {
        /// The planning instant itself (`now`), never dropped.
        case start
        /// A scheduled refresh on the current mode's interval grid.
        case regular
        /// A mode-change boundary (not the deadline).
        case boundary
        /// The deadline: the countdown is complete from here on.
        case deadline
    }

    private struct PlannedEntry {
        var date: Date
        var kind: EntryKind
    }

    /// Regular update interval, in seconds, for each display mode.
    /// `done` has no regular updates; the value is unused.
    static func updateInterval(for mode: CountdownDisplayMode) -> TimeInterval {
        switch mode {
        case .week: return 60 * 60
        case .day: return 15 * 60
        case .hour: return 6 * 60
        case .clock, .min: return 60
        case .done: return 60
        }
    }

    /// Plans the timeline for a countdown ending at `deadline`, as seen from
    /// `now`.
    ///
    /// - Parameter maxEntries: Hard cap on the number of entries (an app
    ///   level limit, not a WidgetKit one). Values below 1 are treated as 1.
    public static func plan(
        deadline: Date,
        now: Date,
        policy: CountdownModePolicy,
        maxEntries: Int = 300
    ) -> TimelinePlan {
        let cap = max(1, maxEntries)

        // Step 8: already complete. One entry, and never regenerate.
        guard now < deadline else {
            return TimelinePlan(entryDates: [now], policy: .never)
        }

        var entries = [PlannedEntry(date: now, kind: .start)]

        while entries.count < cap {
            let candidate = nextCandidate(after: entries[entries.count - 1].date, deadline: deadline, policy: policy)
            entries.append(candidate)
            // Step 7: the deadline ends the plan for good.
            if candidate.kind == .deadline {
                return TimelinePlan(entryDates: entries.map(\.date), policy: .never)
            }
        }

        // Step 6: decide how to end a plan that hit the cap.
        let overflow = nextCandidate(after: entries[entries.count - 1].date, deadline: deadline, policy: policy)
        switch overflow.kind {
        case .regular, .start:
            return TimelinePlan(entryDates: entries.map(\.date), policy: .atEnd)

        case .boundary, .deadline:
            // Pull the boundary forward in place of the last regular update
            // so it is guaranteed to be rendered, whatever the OS decides to
            // do about the reload request. If there is no regular entry to
            // drop (only possible with a pathologically small `maxEntries`),
            // the plan is left untouched rather than exceeding the cap.
            guard let dropIndex = entries.lastIndex(where: { $0.kind == .regular }) else {
                return TimelinePlan(entryDates: entries.map(\.date), policy: .atEnd)
            }
            entries.remove(at: dropIndex)
            entries.append(overflow)
            return TimelinePlan(
                entryDates: entries.map(\.date),
                policy: overflow.kind == .deadline ? .never : .atEnd
            )
        }
    }

    // MARK: - Candidate selection

    /// The next entry after `date`: whichever of the next regular update and
    /// the next mode boundary comes first. A tie counts as the boundary,
    /// since the boundary is what must not be missed.
    private static func nextCandidate(
        after date: Date,
        deadline: Date,
        policy: CountdownModePolicy
    ) -> PlannedEntry {
        let mode = CountdownCalculator.mode(deadline: deadline, now: date, policy: policy)
        let regular = nextGridInstant(after: date, interval: updateInterval(for: mode))

        guard let boundary = nextBoundary(after: date, deadline: deadline, policy: policy) else {
            return PlannedEntry(date: regular, kind: .regular)
        }
        guard boundary <= regular else {
            return PlannedEntry(date: regular, kind: .regular)
        }
        return PlannedEntry(date: boundary, kind: boundary == deadline ? .deadline : .boundary)
    }

    /// The earliest mode-change instant strictly after `date`, including the
    /// deadline itself. `nil` once `date` is at or past the deadline.
    private static func nextBoundary(
        after date: Date,
        deadline: Date,
        policy: CountdownModePolicy
    ) -> Date? {
        let candidates = [
            deadline.addingTimeInterval(-policy.weekLowerBound),
            deadline.addingTimeInterval(-policy.dayLowerBound),
            deadline.addingTimeInterval(-policy.hourLowerBound),
            deadline.addingTimeInterval(-policy.clockLowerBound),
            deadline
        ]
        return candidates.filter { $0 > date }.min()
    }

    /// The first instant strictly after `date` that lies on the `interval`
    /// grid anchored at the Unix epoch.
    ///
    /// All intervals used here (1h / 15m / 6m / 1m) divide an hour, so the
    /// result is always a round wall-clock time, and minute-grid results
    /// always have seconds = 0.
    private static func nextGridInstant(after date: Date, interval: TimeInterval) -> Date {
        let seconds = date.timeIntervalSince1970
        guard interval > 0, seconds.isFinite else {
            return date.addingTimeInterval(max(interval, 1))
        }
        let steps = (seconds / interval).rounded(.down) + 1
        let aligned = Date(timeIntervalSince1970: steps * interval)
        // Defensive: floating point can only fail to advance for absurd
        // inputs, but the caller relies on strict monotonicity.
        return aligned > date ? aligned : date.addingTimeInterval(interval)
    }
}
