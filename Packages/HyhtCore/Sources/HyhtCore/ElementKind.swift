import Foundation

/// A visual element that can appear within a widget family's layout.
public enum ElementKind: String, Codable, Equatable, Sendable, CaseIterable {
    case emoji
    case eventName
    case primaryValue
    case unit
}
