import Foundation

/// The rendered state of a countdown at a particular instant.
public struct CountdownSnapshot: Codable, Equatable, Sendable {
    /// The display mode this snapshot was computed in.
    public var mode: CountdownDisplayMode

    /// The primary formatted text for this snapshot (e.g. `"1.20"`, `"42"`).
    public var primaryText: String

    /// Hour component, populated only when `mode == .clock`.
    public var clockHour: Int?

    /// Minute component, populated only when `mode == .clock`.
    public var clockMinute: Int?

    /// The next instant at which this snapshot becomes stale and should be
    /// recomputed, if known.
    public var nextTransition: Date?

    public init(
        mode: CountdownDisplayMode,
        primaryText: String,
        clockHour: Int? = nil,
        clockMinute: Int? = nil,
        nextTransition: Date? = nil
    ) {
        self.mode = mode
        self.primaryText = primaryText
        self.clockHour = clockHour
        self.clockMinute = clockMinute
        self.nextTransition = nextTransition
    }
}
