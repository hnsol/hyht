import Foundation

/// User customizations layered on top of a `WidgetTemplate`. Every property
/// is optional: `nil` means "use the template's value".
public struct StyleOverrides: Codable, Equatable, Sendable {
    /// Background color override as a `"#RRGGBB"` hex string, if set.
    public var backgroundColorHex: String?

    /// Primary text color override as a `"#RRGGBB"` hex string, if set.
    public var primaryTextColorHex: String?

    /// Secondary text color override as a `"#RRGGBB"` hex string, if set.
    public var secondaryTextColorHex: String?

    /// Font size override for the primary numeric value, if set.
    public var primaryValueFontSize: Double?

    /// Font size override for the event name, if set.
    public var eventNameFontSize: Double?

    /// Font size override for the emoji, if set.
    public var emojiFontSize: Double?

    /// Alignment override applied to all families, if set.
    public var alignment: WidgetFamilyDefinition.Alignment?

    /// Per-family alignment overrides, applied on top of `alignment`.
    public var familyAlignmentOverrides: [WidgetFamilyKey: WidgetFamilyDefinition.Alignment]

    public init(
        backgroundColorHex: String? = nil,
        primaryTextColorHex: String? = nil,
        secondaryTextColorHex: String? = nil,
        primaryValueFontSize: Double? = nil,
        eventNameFontSize: Double? = nil,
        emojiFontSize: Double? = nil,
        alignment: WidgetFamilyDefinition.Alignment? = nil,
        familyAlignmentOverrides: [WidgetFamilyKey: WidgetFamilyDefinition.Alignment] = [:]
    ) {
        self.backgroundColorHex = backgroundColorHex
        self.primaryTextColorHex = primaryTextColorHex
        self.secondaryTextColorHex = secondaryTextColorHex
        self.primaryValueFontSize = primaryValueFontSize
        self.eventNameFontSize = eventNameFontSize
        self.emojiFontSize = emojiFontSize
        self.alignment = alignment
        self.familyAlignmentOverrides = familyAlignmentOverrides
    }

    /// No overrides applied; the template's own values are used everywhere.
    public static let none = StyleOverrides()
}
