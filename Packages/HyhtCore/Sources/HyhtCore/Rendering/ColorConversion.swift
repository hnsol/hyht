import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension RGBColor {
    /// This color as a SwiftUI `Color`, in the sRGB color space.
    public var color: Color {
        Color(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}

/// Converts the `"#RRGGBB"` hex strings carried by `ResolvedWidgetStyle`
/// into SwiftUI `Color`s.
public enum WidgetColor {
    /// Parses `hex` and returns the corresponding `Color`, or `fallback` if
    /// `hex` is not a valid `"#RRGGBB"` string. Rendering code must never
    /// crash on malformed style data, so this is total rather than
    /// throwing/optional.
    public static func color(fromHex hex: String, fallback: Color) -> Color {
        guard let rgb = HexColor.parse(hex) else { return fallback }
        return rgb.color
    }
}

extension Color {
    /// Builds a `Color` from a `"#RRGGBB"` hex string, used by editing UI
    /// (e.g. `ColorPicker` bindings). Falls back to `fallback` for malformed
    /// input so editing UI never crashes on bad style data.
    public init(hyhtHex hex: String, fallback: Color = .white) {
        self = WidgetColor.color(fromHex: hex, fallback: fallback)
    }

    /// This color as a `"#RRGGBB"` hex string, or `nil` if the color's RGB
    /// components could not be resolved (e.g. a non-RGB-representable
    /// color space). Used by editing UI to persist `ColorPicker` selections
    /// as the hex strings `StyleOverrides`/`CompletionStyle` store.
    public var hyhtHexString: String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        let rgb = RGBColor(
            red: UInt8(clamping: Int((red * 255).rounded())),
            green: UInt8(clamping: Int((green * 255).rounded())),
            blue: UInt8(clamping: Int((blue * 255).rounded()))
        )
        return rgb.hexString
        #else
        return nil
        #endif
    }
}
