import SwiftUI

/// `accessoryCircular` layout: two centered lines (value, then unit),
/// small enough to always fit the circular lock-screen frame.
///
/// Design decision: accessory families intentionally do **not** use
/// `style`'s font sizes (those are tuned for home-screen widgets, which are
/// far larger). Instead this layout uses small, fixed sizes chosen to fit
/// the circular frame reliably, with `minimumScaleFactor` as a further
/// safety net for unusually long primary text.
struct AccessoryCircularLayout: View {
    let snapshot: CountdownSnapshot
    let style: ResolvedWidgetStyle
    let palette: RenderPalette

    private static let topFontSize: CGFloat = 15
    private static let bottomFontSize: CGFloat = 11

    var body: some View {
        VStack(spacing: 0) {
            Text(topText)
                .font(.system(size: Self.topFontSize, weight: .semibold, design: style.fontDesign.swiftUIDesign))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(bottomText)
                .font(.system(size: Self.bottomFontSize, weight: .regular, design: style.fontDesign.swiftUIDesign))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .foregroundColor(palette.primaryColor)
    }

    private var topText: String {
        if snapshot.mode == .clock, let hour = snapshot.clockHour {
            return "\(hour)h"
        }
        return snapshot.primaryText
    }

    /// The bottom row is always a unit row (all three bundled templates set
    /// `showsUnit: true` for `accessoryCircular`); the guard below only
    /// covers a hypothetical future/imported template that sets it `false`,
    /// falling back to a blank second line rather than special-casing away
    /// the two-row structure.
    private var bottomText: String {
        if snapshot.mode == .clock, let minute = snapshot.clockMinute {
            return "\(minute)m"
        }
        guard style.showsUnit, let unit = CountdownUnitFormatter.unitLabel(for: snapshot.mode, style: .short) else {
            return ""
        }
        return unit
    }
}
