import Foundation

/// The fully-resolved style for rendering a single widget family in either
/// its normal or completed state. Produced by `StyleResolver.resolve` by
/// layering a `WidgetTemplate` with user `StyleOverrides`/`CompletionStyle`;
/// carries everything a renderer needs without any further lookups.
public struct ResolvedWidgetStyle: Equatable, Sendable {
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

    /// Font size for the completion message. `nil` unless resolved for the
    /// completed state.
    public var messageFontSize: Double?

    /// Fixed font weight, from the template.
    public var fontWeight: TemplateFontWeight

    /// Fixed font design, from the template.
    public var fontDesign: TemplateFontDesign

    /// Overall content alignment.
    public var alignment: WidgetFamilyDefinition.Alignment

    /// Outer padding.
    public var padding: Double

    /// Spacing between elements.
    public var spacing: Double

    /// Order in which elements are laid out.
    public var elementOrder: [ElementKind]

    /// Whether the event name is shown.
    public var showsEventName: Bool

    /// Whether the emoji is shown.
    public var showsEmoji: Bool

    /// Whether the unit label is shown.
    public var showsUnit: Bool

    /// Completion message text. `nil` unless resolved for the completed
    /// state.
    public var completionMessage: String?

    /// Completion emoji. `nil` unless resolved for the completed state.
    public var completionEmoji: String?

    public init(
        backgroundColorHex: String,
        primaryTextColorHex: String,
        secondaryTextColorHex: String,
        primaryValueFontSize: Double,
        eventNameFontSize: Double,
        emojiFontSize: Double,
        messageFontSize: Double? = nil,
        fontWeight: TemplateFontWeight,
        fontDesign: TemplateFontDesign,
        alignment: WidgetFamilyDefinition.Alignment,
        padding: Double,
        spacing: Double,
        elementOrder: [ElementKind],
        showsEventName: Bool,
        showsEmoji: Bool,
        showsUnit: Bool,
        completionMessage: String? = nil,
        completionEmoji: String? = nil
    ) {
        self.backgroundColorHex = backgroundColorHex
        self.primaryTextColorHex = primaryTextColorHex
        self.secondaryTextColorHex = secondaryTextColorHex
        self.primaryValueFontSize = primaryValueFontSize
        self.eventNameFontSize = eventNameFontSize
        self.emojiFontSize = emojiFontSize
        self.messageFontSize = messageFontSize
        self.fontWeight = fontWeight
        self.fontDesign = fontDesign
        self.alignment = alignment
        self.padding = padding
        self.spacing = spacing
        self.elementOrder = elementOrder
        self.showsEventName = showsEventName
        self.showsEmoji = showsEmoji
        self.showsUnit = showsUnit
        self.completionMessage = completionMessage
        self.completionEmoji = completionEmoji
    }
}
