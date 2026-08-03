import Foundation

/// The widget family a `WidgetTemplate` provides a definition for.
public enum WidgetFamilyKey: String, Codable, Equatable, Sendable, CaseIterable {
    case systemSmall
    case systemMedium
    case accessoryCircular
    case accessoryRectangular
}

/// Minimal `CodingKey` used to bridge `WidgetFamilyKey` (and any other
/// `String`-backed `RawRepresentable` type) to a string-keyed JSON object.
private struct StringCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }
}

// Conforming to `CodingKeyRepresentable` makes `Dictionary<WidgetFamilyKey, _>`
// encode/decode as a JSON object with string keys, instead of the default
// flat key/value array representation used for arbitrary `Hashable` keys.
extension WidgetFamilyKey: CodingKeyRepresentable {
    public var codingKey: CodingKey {
        StringCodingKey(stringValue: rawValue)
    }

    public init?<T>(codingKey: T) where T: CodingKey {
        self.init(rawValue: codingKey.stringValue)
    }
}
