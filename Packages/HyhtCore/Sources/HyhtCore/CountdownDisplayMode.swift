import Foundation

/// The display mode a countdown is rendered in, based on remaining time.
public enum CountdownDisplayMode: String, Codable, Equatable, Sendable, CaseIterable {
    case week
    case day
    case hour
    case clock
    case min
    case done
}
