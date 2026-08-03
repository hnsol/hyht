import Foundation

/// Outcome of attempting to decode a persisted `AppState`.
public enum AppStateDecodeResult: Equatable, Sendable {
    /// Successfully decoded a supported `AppState`.
    case loaded(AppState)

    /// The data declares a `schemaVersion` newer than this build supports.
    /// `rawData` is preserved verbatim so callers can avoid overwriting it.
    case unknownNewerVersion(rawData: Data, foundVersion: Int)

    /// The data is not valid JSON, has no readable `schemaVersion`, or fails
    /// to decode as `AppState` despite a supported version.
    case corrupt
}

/// Decodes persisted `AppState` data with version-aware fallback behavior.
public enum AppStateDecoder {
    private struct SchemaVersionProbe: Decodable {
        let schemaVersion: Int
    }

    /// Decodes `data` into an `AppStateDecodeResult`.
    ///
    /// Decoding proceeds in two steps:
    /// 1. A lightweight probe reads only `schemaVersion`. If this fails
    ///    (invalid JSON, or the key is missing/not an `Int`), the result is
    ///    `.corrupt`.
    /// 2. If the probed version is newer than `AppState.currentSchemaVersion`,
    ///    the result is `.unknownNewerVersion`. Otherwise the full `AppState`
    ///    is decoded; failure yields `.corrupt`.
    public static func decode(_ data: Data) -> AppStateDecodeResult {
        guard let probe = try? JSONDecoder().decode(SchemaVersionProbe.self, from: data) else {
            return .corrupt
        }

        guard probe.schemaVersion <= AppState.currentSchemaVersion else {
            return .unknownNewerVersion(rawData: data, foundVersion: probe.schemaVersion)
        }

        guard let state = try? AppStateCoding.decoder.decode(AppState.self, from: data) else {
            return .corrupt
        }

        return .loaded(state)
    }
}
