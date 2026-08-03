import Foundation

/// A single countdown target: name, emoji, and an absolute deadline.
public struct CountdownEvent: Codable, Equatable, Sendable {
    /// Stable identifier for this event.
    public var id: UUID

    /// Display name of the event.
    public var name: String

    /// Emoji associated with the event.
    public var emoji: String

    /// Absolute deadline, stored as a UTC instant.
    public var deadline: Date

    /// Identifier of the time zone used for date-picking and localized display
    /// (e.g. `"Asia/Tokyo"`). Captured at creation time so that moving to a
    /// different time zone does not change the meaning of the deadline.
    public var timeZoneID: String

    public init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        deadline: Date,
        timeZoneID: String
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.deadline = deadline
        self.timeZoneID = timeZoneID
    }
}
