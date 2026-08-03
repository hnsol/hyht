import Foundation

/// A complete, versioned widget template definition: shared style, one
/// layout definition per widget family, and a standard completion style.
///
/// Template JSON is treated as immutable at runtime; user customization is
/// layered on top via `StyleOverrides` and `CompletionStyle` in `AppState`.
public struct WidgetTemplate: Codable, Equatable, Sendable {
    /// Schema version of this template definition.
    public var schemaVersion: Int

    /// Stable, unique template identifier (e.g. `"minimal"`).
    public var id: String

    /// Human-readable name shown in the template picker.
    public var displayName: String

    /// Style shared across all widget families.
    public var style: TemplateStyle

    /// Layout definition for each supported widget family.
    public var families: [WidgetFamilyKey: WidgetFamilyDefinition]

    /// Standard completion-screen configuration for this template.
    public var completion: CompletionStyle

    public init(
        schemaVersion: Int,
        id: String,
        displayName: String,
        style: TemplateStyle,
        families: [WidgetFamilyKey: WidgetFamilyDefinition],
        completion: CompletionStyle
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.displayName = displayName
        self.style = style
        self.families = families
        self.completion = completion
    }

    // MARK: - Validation

    /// Current schema version understood by this build.
    public static let currentSchemaVersion = 1

    /// Fixed range every template/style/override font size must fall into.
    public static let fontSizeRange: ClosedRange<Double> = 4...200

    /// Fixed range every template/style padding or spacing value must fall
    /// into.
    public static let spacingRange: ClosedRange<Double> = 0...100

    /// Structural validation applied to any externally supplied template
    /// (bundled or, in the future, imported).
    ///
    /// A template is valid when its schema version is one this build
    /// understands (or older), it defines a layout for every widget family,
    /// its colors are well-formed `"#RRGGBB"` hex strings, and its font
    /// sizes/padding/spacing values fall within their allowed ranges.
    public var isValid: Bool {
        guard schemaVersion >= 1, schemaVersion <= Self.currentSchemaVersion else { return false }
        guard !id.isEmpty else { return false }
        guard Set(families.keys) == Set(WidgetFamilyKey.allCases) else { return false }
        guard style.isValid else { return false }
        guard families.values.allSatisfy(\.isValid) else { return false }
        guard completion.isValidAsTemplateDefault else { return false }
        return true
    }

    /// A minimal, hard-coded template used only when the bundled `minimal`
    /// template JSON resource is itself missing or fails validation. This is
    /// the final line of defense against a crash: it never reads from disk.
    public static let fallback = WidgetTemplate(
        schemaVersion: currentSchemaVersion,
        id: "minimal",
        displayName: "Minimal",
        style: TemplateStyle(
            backgroundColorHex: "#FFFFFF",
            primaryTextColorHex: "#000000",
            secondaryTextColorHex: "#6E6E73",
            primaryValueFontSize: 38,
            eventNameFontSize: 13,
            emojiFontSize: 18,
            fontWeight: .regular,
            fontDesign: .monospaced
        ),
        families: [
            .systemSmall: WidgetFamilyDefinition(
                alignment: .leading,
                padding: 14,
                spacing: 6,
                elementOrder: [.eventName, .primaryValue, .unit, .emoji],
                showsEventName: true,
                showsEmoji: false,
                showsUnit: true
            ),
            .systemMedium: WidgetFamilyDefinition(
                alignment: .leading,
                padding: 16,
                spacing: 8,
                elementOrder: [.emoji, .eventName, .primaryValue, .unit],
                showsEventName: true,
                showsEmoji: false,
                showsUnit: true
            ),
            .accessoryCircular: WidgetFamilyDefinition(
                alignment: .center,
                padding: 4,
                spacing: 0,
                elementOrder: [.primaryValue, .unit],
                showsEventName: false,
                showsEmoji: false,
                showsUnit: true
            ),
            .accessoryRectangular: WidgetFamilyDefinition(
                alignment: .leading,
                padding: 6,
                spacing: 2,
                elementOrder: [.emoji, .eventName, .primaryValue, .unit],
                showsEventName: true,
                showsEmoji: false,
                showsUnit: true
            )
        ],
        completion: CompletionStyle(
            message: "Done",
            emoji: "✅",
            backgroundColorHex: "#FFFFFF",
            primaryTextColorHex: "#000000",
            secondaryTextColorHex: "#6E6E73",
            eventNameFontSize: 14,
            messageFontSize: 20,
            emojiFontSize: 32,
            alignment: .leading
        )
    )
}
