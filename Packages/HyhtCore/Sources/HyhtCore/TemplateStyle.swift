import Foundation

/// Font weight, expressed as data so it can be embedded in a template
/// definition. Not user-editable in the initial version.
public enum TemplateFontWeight: String, Codable, Equatable, Sendable, CaseIterable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black
}

/// Font design, expressed as data so it can be embedded in a template
/// definition. Not user-editable in the initial version.
public enum TemplateFontDesign: String, Codable, Equatable, Sendable, CaseIterable {
    case `default`
    case rounded
    case serif
    case monospaced
}

/// Style shared across all widget families for a given `WidgetTemplate`.
public struct TemplateStyle: Codable, Equatable, Sendable {
    /// Background color as a `"#RRGGBB"` hex string.
    public var backgroundColorHex: String

    /// Primary text color as a `"#RRGGBB"` hex string.
    public var primaryTextColorHex: String

    /// Secondary (auxiliary) text color as a `"#RRGGBB"` hex string.
    public var secondaryTextColorHex: String

    /// Font size for the primary numeric value.
    public var primaryValueFontSize: Double

    /// Font size for the event name.
    public var eventNameFontSize: Double

    /// Font size for the emoji.
    public var emojiFontSize: Double

    /// Fixed font weight for this template. Not user-editable.
    public var fontWeight: TemplateFontWeight

    /// Fixed font design for this template. Not user-editable.
    public var fontDesign: TemplateFontDesign

    public init(
        backgroundColorHex: String,
        primaryTextColorHex: String,
        secondaryTextColorHex: String,
        primaryValueFontSize: Double,
        eventNameFontSize: Double,
        emojiFontSize: Double,
        fontWeight: TemplateFontWeight,
        fontDesign: TemplateFontDesign
    ) {
        self.backgroundColorHex = backgroundColorHex
        self.primaryTextColorHex = primaryTextColorHex
        self.secondaryTextColorHex = secondaryTextColorHex
        self.primaryValueFontSize = primaryValueFontSize
        self.eventNameFontSize = eventNameFontSize
        self.emojiFontSize = emojiFontSize
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
    }

    /// Whether this style's colors and font sizes fall within
    /// `WidgetTemplate`'s allowed ranges.
    public var isValid: Bool {
        guard HexColor.isValid(backgroundColorHex),
              HexColor.isValid(primaryTextColorHex),
              HexColor.isValid(secondaryTextColorHex)
        else { return false }

        let sizes = [primaryValueFontSize, eventNameFontSize, emojiFontSize]
        return sizes.allSatisfy { WidgetTemplate.fontSizeRange.contains($0) }
    }
}
