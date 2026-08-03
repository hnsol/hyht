import Foundation

/// An RGB color parsed from a `"#RRGGBB"` hex string.
public struct RGBColor: Equatable, Sendable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

/// Parsing and validation for the `"#RRGGBB"` hex color strings used
/// throughout template and style data.
public enum HexColor {
    /// Parses a strict `"#RRGGBB"` hex string (uppercase or lowercase hex
    /// digits) into its RGB components. Returns `nil` for any other format,
    /// including missing `#`, wrong length, or non-hex-digit characters.
    public static func parse(_ hex: String) -> RGBColor? {
        guard hex.count == 7, hex.hasPrefix("#") else { return nil }
        let digits = hex.dropFirst()
        guard digits.allSatisfy({ $0.isHexDigit }) else { return nil }
        guard let value = UInt32(digits, radix: 16) else { return nil }

        let red = UInt8((value >> 16) & 0xFF)
        let green = UInt8((value >> 8) & 0xFF)
        let blue = UInt8(value & 0xFF)
        return RGBColor(red: red, green: green, blue: blue)
    }

    /// Whether `hex` is a valid `"#RRGGBB"` string.
    public static func isValid(_ hex: String) -> Bool {
        parse(hex) != nil
    }
}

extension RGBColor {
    /// This color as an uppercase `"#RRGGBB"` hex string.
    public var hexString: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }
}
