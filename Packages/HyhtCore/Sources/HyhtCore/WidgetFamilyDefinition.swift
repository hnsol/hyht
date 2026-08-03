import Foundation

/// Preset layout definition for a single widget family within a
/// `WidgetTemplate`.
public struct WidgetFamilyDefinition: Codable, Equatable, Sendable {
    /// Alignment used both for a family's own layout and for style
    /// overrides elsewhere (`StyleOverrides`, `CompletionStyle`).
    public enum Alignment: String, Codable, Equatable, Sendable, CaseIterable {
        case leading
        case center
        case trailing
    }

    /// Overall content alignment for this family.
    public var alignment: Alignment

    /// Outer padding.
    public var padding: Double

    /// Spacing between elements.
    public var spacing: Double

    /// Order in which elements are laid out.
    public var elementOrder: [ElementKind]

    /// Whether the event name is shown for this family.
    public var showsEventName: Bool

    /// Whether the emoji is shown for this family.
    public var showsEmoji: Bool

    /// Whether the unit label (e.g. `"wk"`, `"d"`) is shown for this family.
    public var showsUnit: Bool

    public init(
        alignment: Alignment,
        padding: Double,
        spacing: Double,
        elementOrder: [ElementKind],
        showsEventName: Bool,
        showsEmoji: Bool,
        showsUnit: Bool
    ) {
        self.alignment = alignment
        self.padding = padding
        self.spacing = spacing
        self.elementOrder = elementOrder
        self.showsEventName = showsEventName
        self.showsEmoji = showsEmoji
        self.showsUnit = showsUnit
    }

    /// Whether this definition's padding/spacing fall within
    /// `WidgetTemplate`'s allowed range.
    public var isValid: Bool {
        WidgetTemplate.spacingRange.contains(padding) && WidgetTemplate.spacingRange.contains(spacing)
    }
}
