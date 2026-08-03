import Foundation

/// A deep link the app knows how to act on.
///
/// `hyht://edit` is the only route in this version: it is what every widget
/// family attaches with `widgetURL`. Anything else must be ignored so that
/// an unexpected URL simply launches the app normally.
public enum DeepLink: Equatable, Sendable {
    /// Open the edit screen (`hyht://edit`).
    case edit

    /// Parses `url` into a known route, or returns `nil` when the URL is not
    /// one this build handles (wrong scheme, unknown host, or no host).
    ///
    /// `edit` is the URL's *host*, not its path: `hyht://edit` has an empty
    /// path.
    public static func route(_ url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == HyhtCore.urlScheme else { return nil }
        switch url.host?.lowercased() {
        case HyhtCore.editDeepLinkHost:
            return .edit
        default:
            return nil
        }
    }
}
