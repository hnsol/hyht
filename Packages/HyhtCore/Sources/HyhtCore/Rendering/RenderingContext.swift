import Foundation

/// Which context a `CountdownWidgetView` is being rendered in.
///
/// This never changes *what* is shown (both contexts render the same
/// `CountdownSnapshot`/`ResolvedWidgetStyle`), only *how* accessory
/// (lock-screen) families are colored: a real widget hands tinting to the
/// OS, while an in-app preview has no OS tint to rely on and instead draws a
/// monochrome approximation so the user can see roughly what the layout
/// looks like.
public enum RenderingContext: Equatable, Sendable {
    case widget
    case preview
}
