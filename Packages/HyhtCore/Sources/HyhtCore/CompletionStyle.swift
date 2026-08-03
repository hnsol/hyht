import Foundation

/// Styling for the "done" (completion) display. Used both as a template's
/// standard completion configuration and as the user-editable completion
/// settings stored in `AppState`.
public struct CompletionStyle: Codable, Equatable, Sendable {
    /// Completion message text.
    public var message: String

    /// Completion emoji.
    public var emoji: String

    /// Background color override as a `"#RRGGBB"` hex string, if set.
    public var backgroundColorHex: String?

    /// Primary text color override as a `"#RRGGBB"` hex string, if set.
    public var primaryTextColorHex: String?

    /// Secondary text color override as a `"#RRGGBB"` hex string, if set.
    public var secondaryTextColorHex: String?

    /// Font size override for the event name, if set.
    public var eventNameFontSize: Double?

    /// Font size override for the completion message, if set.
    public var messageFontSize: Double?

    /// Font size override for the emoji, if set.
    public var emojiFontSize: Double?

    /// Alignment override, if set.
    public var alignment: WidgetFamilyDefinition.Alignment?

    public init(
        message: String,
        emoji: String,
        backgroundColorHex: String? = nil,
        primaryTextColorHex: String? = nil,
        secondaryTextColorHex: String? = nil,
        eventNameFontSize: Double? = nil,
        messageFontSize: Double? = nil,
        emojiFontSize: Double? = nil,
        alignment: WidgetFamilyDefinition.Alignment? = nil
    ) {
        self.message = message
        self.emoji = emoji
        self.backgroundColorHex = backgroundColorHex
        self.primaryTextColorHex = primaryTextColorHex
        self.secondaryTextColorHex = secondaryTextColorHex
        self.eventNameFontSize = eventNameFontSize
        self.messageFontSize = messageFontSize
        self.emojiFontSize = emojiFontSize
        self.alignment = alignment
    }

    /// Whether this style's optional colors/font sizes, when present, fall
    /// within `WidgetTemplate`'s allowed ranges. Used when validating a
    /// template's standard completion configuration; not applied to
    /// user-entered `StyleOverrides`-style completion edits, which are
    /// validated at the point of entry instead.
    public var isValidAsTemplateDefault: Bool {
        for hex in [backgroundColorHex, primaryTextColorHex, secondaryTextColorHex] {
            if let hex, !HexColor.isValid(hex) { return false }
        }
        for size in [eventNameFontSize, messageFontSize, emojiFontSize] {
            if let size, !WidgetTemplate.fontSizeRange.contains(size) { return false }
        }
        return true
    }
}
