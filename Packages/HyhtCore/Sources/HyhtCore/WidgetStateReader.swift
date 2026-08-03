import Foundation

/// Read-only access to the persisted `AppState` for use by the widget
/// extension. Contains no code path that writes to disk: on any failure it
/// returns `nil` and leaves the file untouched, letting the caller fall back
/// to a safe default display.
public enum WidgetStateReader {
    private static let stateFileName = "state.json"

    /// Reads and decodes the state file inside `containerURL`. Returns `nil`
    /// if the file is missing, unreadable, corrupt, or was written by a
    /// newer, unsupported `schemaVersion`.
    public static func read(containerURL: URL) -> AppState? {
        let fileURL = containerURL.appendingPathComponent(stateFileName)
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        guard case .loaded(let state) = AppStateDecoder.decode(data) else {
            return nil
        }
        return state
    }

    /// Reads and decodes the state file from the real App Group container.
    /// Returns `nil` if the container is unavailable or the state could not
    /// be read (see `read(containerURL:)`).
    public static func read() -> AppState? {
        guard let containerURL = try? HyhtCore.containerURL() else {
            return nil
        }
        return read(containerURL: containerURL)
    }
}
