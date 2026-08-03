import Foundation

/// Shared JSON encoding/decoding configuration for `AppState` and related
/// types. All phases that persist or transmit `AppState` must use these
/// instances so date representations stay consistent.
public enum AppStateCoding {
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
