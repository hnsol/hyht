import Foundation

/// Threshold and rounding definitions used to determine `CountdownDisplayMode`
/// and to format the primary numeric value for each mode.
///
/// The authoritative copy is a version-stamped JSON resource bundled with
/// `HyhtCore`. `CountdownModePolicy.fallback` is a safety fallback used only
/// when the resource is missing or fails validation; an automated test
/// guarantees the two stay semantically in sync.
///
/// Actual mode-determination and value-formatting logic (including
/// `toFixed`-compatible rounding) is implemented in a later phase; this type
/// only carries the data.
public struct CountdownModePolicy: Codable, Equatable, Sendable {
    /// The rounding/formatting rule applied to a mode's primary numeric value.
    public enum RoundingRule: String, Codable, Equatable, Sendable, CaseIterable {
        /// `Number.prototype.toFixed(2)`-compatible rounding, e.g. `"1.20"`.
        case toFixed2
        /// `Number.prototype.toFixed(1)`-compatible rounding, e.g. `"120.0"`.
        case toFixed1
        /// Integer floor, no decimal places.
        case floor
    }

    /// Schema version of this policy definition.
    public var version: Int

    /// Lower bound (in seconds of remaining time) for `.week` mode.
    /// Equal to 12 days + 30 seconds (`EPS`).
    public var weekLowerBound: TimeInterval

    /// Lower bound (in seconds of remaining time) for `.day` mode.
    /// Equal to 120 hours + 30 seconds (`EPS`).
    public var dayLowerBound: TimeInterval

    /// Lower bound (in seconds of remaining time) for `.hour` mode.
    /// Equal to 24 hours + 30 seconds (`EPS`).
    public var hourLowerBound: TimeInterval

    /// Lower bound (in seconds of remaining time) for `.clock` mode.
    /// Equal to 120 minutes.
    public var clockLowerBound: TimeInterval

    /// Rounding rule used to format the `.week` mode's numeric value.
    public var weekRounding: RoundingRule

    /// Rounding rule used to format the `.day` mode's numeric value.
    public var dayRounding: RoundingRule

    /// Rounding rule used to format the `.hour` mode's numeric value.
    public var hourRounding: RoundingRule

    /// Rounding rule used to format the `.min` mode's numeric value.
    public var minRounding: RoundingRule

    public init(
        version: Int,
        weekLowerBound: TimeInterval,
        dayLowerBound: TimeInterval,
        hourLowerBound: TimeInterval,
        clockLowerBound: TimeInterval,
        weekRounding: RoundingRule,
        dayRounding: RoundingRule,
        hourRounding: RoundingRule,
        minRounding: RoundingRule
    ) {
        self.version = version
        self.weekLowerBound = weekLowerBound
        self.dayLowerBound = dayLowerBound
        self.hourLowerBound = hourLowerBound
        self.clockLowerBound = clockLowerBound
        self.weekRounding = weekRounding
        self.dayRounding = dayRounding
        self.hourRounding = hourRounding
        self.minRounding = minRounding
    }

    /// Epsilon applied to mode-boundary comparisons, in seconds.
    public static let epsilon: TimeInterval = 30

    /// Current schema version for `CountdownModePolicy`.
    public static let currentVersion = 1

    /// Safety fallback used only when the bundled JSON resource is missing or
    /// fails validation. Must remain semantically identical to the bundled
    /// authoritative JSON (verified by an automated test).
    public static let fallback = CountdownModePolicy(
        version: currentVersion,
        weekLowerBound: 12 * 24 * 60 * 60 + epsilon,
        dayLowerBound: 120 * 60 * 60 + epsilon,
        hourLowerBound: 24 * 60 * 60 + epsilon,
        clockLowerBound: 120 * 60,
        weekRounding: .toFixed2,
        dayRounding: .toFixed2,
        hourRounding: .toFixed1,
        minRounding: .floor
    )

    // MARK: - Loading

    /// Loads the authoritative policy from `HyhtCore`'s bundled
    /// `mode-policy.json`.
    ///
    /// Returns ``fallback`` when the resource is missing, cannot be decoded, or
    /// fails ``isValid``. This never throws: a broken resource must not be able
    /// to break the widget.
    public static func loadBundled() -> CountdownModePolicy {
        guard let data = HyhtCoreResources.jsonData(named: HyhtCoreResources.modePolicyResourceName) else {
            return fallback
        }
        return load(from: data)
    }

    /// Decodes and validates a policy from raw JSON, falling back to
    /// ``fallback`` on any decoding or validation failure.
    ///
    /// This is the exact path ``loadBundled()`` takes once the resource bytes
    /// are in hand, exposed so that corrupt-input behaviour is testable.
    public static func load(from data: Data) -> CountdownModePolicy {
        guard
            let decoded = try? JSONDecoder().decode(CountdownModePolicy.self, from: data),
            decoded.isValid
        else {
            return fallback
        }
        return decoded
    }

    /// Structural validation applied to any externally supplied policy.
    ///
    /// A policy is valid when its schema version is the one this build
    /// understands and its thresholds are finite and strictly decreasing down
    /// to a positive `clock` lower bound — the ordering the mode-selection
    /// cascade relies on.
    public var isValid: Bool {
        guard version == Self.currentVersion else { return false }

        let bounds = [weekLowerBound, dayLowerBound, hourLowerBound, clockLowerBound]
        guard bounds.allSatisfy({ $0.isFinite }) else { return false }
        guard clockLowerBound > 0 else { return false }
        guard weekLowerBound > dayLowerBound,
              dayLowerBound > hourLowerBound,
              hourLowerBound > clockLowerBound
        else { return false }

        return true
    }
}
