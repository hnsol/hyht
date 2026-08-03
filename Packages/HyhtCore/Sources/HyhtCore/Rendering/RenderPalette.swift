import SwiftUI

/// The colors a widget family layout should draw with, already resolved for
/// the current `RenderingContext`.
///
/// Home-screen families (`systemSmall`/`systemMedium`) always carry
/// explicit colors taken from `ResolvedWidgetStyle`, since the user can
/// customize them and both the widget and the in-app preview render them
/// identically.
///
/// Accessory (lock-screen) families never carry style-driven colors: a real
/// widget hands coloring to the OS's tint (`.primary`/`.secondary` plus
/// `widgetAccentable()`), which this type represents with a `nil`
/// `backgroundColor` (nothing should be self-painted) and system colors. An
/// in-app preview has no OS tint to render, so it substitutes a monochrome
/// approximation (white content on black) purely so the layout is visible
/// during editing.
struct RenderPalette {
    let primaryColor: Color
    let secondaryColor: Color

    /// Background this family layout should paint for itself, or `nil` if
    /// it should leave its background transparent (real accessory widgets:
    /// `containerBackground` is applied by the widget extension in a later
    /// phase, and the OS renders its own lock-screen chrome besides).
    let backgroundColor: Color?

    static func forHomeFamily(style: ResolvedWidgetStyle) -> RenderPalette {
        RenderPalette(
            primaryColor: WidgetColor.color(fromHex: style.primaryTextColorHex, fallback: .primary),
            secondaryColor: WidgetColor.color(fromHex: style.secondaryTextColorHex, fallback: .secondary),
            backgroundColor: WidgetColor.color(fromHex: style.backgroundColorHex, fallback: Color(white: 1))
        )
    }

    static func forAccessoryFamily(renderingContext: RenderingContext) -> RenderPalette {
        switch renderingContext {
        case .widget:
            return RenderPalette(primaryColor: .primary, secondaryColor: .secondary, backgroundColor: nil)
        case .preview:
            return RenderPalette(primaryColor: .white, secondaryColor: .white.opacity(0.7), backgroundColor: .black)
        }
    }
}
