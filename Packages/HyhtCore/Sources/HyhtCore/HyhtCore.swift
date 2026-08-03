import Foundation

/// Hyht app's shared constants and App Group helpers.
public enum HyhtCore {
    /// The App Group identifier shared between the main app and the widget extension.
    public static let appGroupID = "group.com.masatora.hyht"

    /// The single widget `kind` shared by all four supported families. The
    /// widget extension declares it and the app passes it to
    /// `WidgetCenter.reloadTimelines(ofKind:)`.
    public static let widgetKind = "HyhtWidget"

    /// URL scheme used for deep links into the app (`hyht://edit`).
    public static let urlScheme = "hyht"

    /// Deep link host that opens the edit screen.
    public static let editDeepLinkHost = "edit"

    /// The deep link attached to every widget family via `widgetURL`.
    public static let editDeepLinkURL = URL(string: "\(urlScheme)://\(editDeepLinkHost)")!

    /// Errors that can occur while accessing the App Group container.
    public enum ContainerError: Error, LocalizedError, Sendable {
        case containerUnavailable

        public var errorDescription: String? {
            switch self {
            case .containerUnavailable:
                return "App Group container is unavailable for identifier: \(HyhtCore.appGroupID)"
            }
        }
    }

    /// Returns the URL of the shared App Group container.
    public static func containerURL() throws -> URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw ContainerError.containerUnavailable
        }
        return url
    }
}
