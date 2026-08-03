import Foundation

/// WCAG 2.x relative luminance and contrast ratio calculations, used to
/// verify that a template's text colors remain legible against its
/// background color.
public enum ColorContrast {
    /// The WCAG-recommended minimum contrast ratio for normal-size text.
    public static let minimumRatio: Double = 4.5

    /// The contrast ratio between two colors, per the WCAG 2.x formula.
    ///
    /// The result is symmetric and always `>= 1`: `1` means identical
    /// colors, `21` means pure black against pure white.
    public static func ratio(_ a: RGBColor, _ b: RGBColor) -> Double {
        let lighter = max(relativeLuminance(a), relativeLuminance(b))
        let darker = min(relativeLuminance(a), relativeLuminance(b))
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// The contrast ratio between two `"#RRGGBB"` hex colors. Returns `nil`
    /// if either string is not a valid hex color.
    public static func ratio(hexA: String, hexB: String) -> Double? {
        guard let a = HexColor.parse(hexA), let b = HexColor.parse(hexB) else { return nil }
        return ratio(a, b)
    }

    /// The WCAG relative luminance of `color`, in `0...1`.
    public static func relativeLuminance(_ color: RGBColor) -> Double {
        let r = linearize(color.red)
        let g = linearize(color.green)
        let b = linearize(color.blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Converts a single sRGB 8-bit channel to its linear-light value.
    private static func linearize(_ channel: UInt8) -> Double {
        let c = Double(channel) / 255
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
}
