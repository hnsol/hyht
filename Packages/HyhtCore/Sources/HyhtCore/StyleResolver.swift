import Foundation

/// Pure composition of a `WidgetTemplate` with user `StyleOverrides` (and,
/// for the completed state, `CompletionStyle`) into a single
/// `ResolvedWidgetStyle` a renderer can use directly.
///
/// Priority, lowest to highest:
/// 1. The template's shared `TemplateStyle`.
/// 2. The template's per-family `WidgetFamilyDefinition` (alignment, layout).
/// 3. User-wide `StyleOverrides` (colors, font sizes, alignment).
/// 4. User per-family alignment overrides.
/// 5. When completed: the template's standard `CompletionStyle`, then the
///    user's `CompletionStyle` overrides, applied on top of everything above.
///
/// Color overrides (steps 3-5) apply only to home-screen families
/// (`systemSmall`/`systemMedium`); accessory families keep the template's
/// own colors. Inputs are never mutated.
public enum StyleResolver {
    /// Resolves a template-led appearance for the simplified editor.
    /// Persisted appearance overrides are intentionally excluded, while the
    /// user's completion message and emoji remain editable.
    public static func resolveTemplateDriven(
        template: WidgetTemplate,
        completion: CompletionStyle?,
        family: WidgetFamilyKey,
        isCompleted: Bool
    ) -> ResolvedWidgetStyle {
        let completionContent = completion.map {
            CompletionStyle(message: $0.message, emoji: $0.emoji)
        }
        return resolve(
            template: template,
            overrides: .none,
            completion: completionContent,
            family: family,
            isCompleted: isCompleted
        )
    }

    public static func resolve(
        template: WidgetTemplate,
        overrides: StyleOverrides,
        completion: CompletionStyle?,
        family: WidgetFamilyKey,
        isCompleted: Bool
    ) -> ResolvedWidgetStyle {
        let familyDefinition = template.families[family] ?? defaultFamilyDefinition
        let isHomeFamily = family == .systemSmall || family == .systemMedium

        var backgroundColorHex = template.style.backgroundColorHex
        var primaryTextColorHex = template.style.primaryTextColorHex
        var secondaryTextColorHex = template.style.secondaryTextColorHex
        if isHomeFamily {
            backgroundColorHex = overrides.backgroundColorHex ?? backgroundColorHex
            primaryTextColorHex = overrides.primaryTextColorHex ?? primaryTextColorHex
            secondaryTextColorHex = overrides.secondaryTextColorHex ?? secondaryTextColorHex
        }

        let primaryValueFontSize = overrides.primaryValueFontSize ?? template.style.primaryValueFontSize
        let eventNameFontSize = overrides.eventNameFontSize ?? template.style.eventNameFontSize
        let emojiFontSize = overrides.emojiFontSize ?? template.style.emojiFontSize

        var alignment = familyDefinition.alignment
        alignment = overrides.alignment ?? alignment
        alignment = overrides.familyAlignmentOverrides[family] ?? alignment

        var resolved = ResolvedWidgetStyle(
            backgroundColorHex: backgroundColorHex,
            primaryTextColorHex: primaryTextColorHex,
            secondaryTextColorHex: secondaryTextColorHex,
            primaryValueFontSize: primaryValueFontSize,
            eventNameFontSize: eventNameFontSize,
            emojiFontSize: emojiFontSize,
            fontWeight: template.style.fontWeight,
            fontDesign: template.style.fontDesign,
            alignment: alignment,
            padding: familyDefinition.padding,
            spacing: familyDefinition.spacing,
            elementOrder: familyDefinition.elementOrder,
            showsEventName: familyDefinition.showsEventName,
            showsEmoji: familyDefinition.showsEmoji,
            showsUnit: familyDefinition.showsUnit
        )

        guard isCompleted else { return resolved }

        // Step 5: template completion defaults, then user completion
        // overrides, layered on top of the normal-state result.
        applyCompletionLayer(template.completion, to: &resolved, isHomeFamily: isHomeFamily)
        if let completion {
            applyCompletionLayer(completion, to: &resolved, isHomeFamily: isHomeFamily)
        }
        resolved.completionMessage = completion?.message ?? template.completion.message
        resolved.completionEmoji = completion?.emoji ?? template.completion.emoji

        return resolved
    }

    // MARK: - Private

    private static func applyCompletionLayer(
        _ style: CompletionStyle,
        to resolved: inout ResolvedWidgetStyle,
        isHomeFamily: Bool
    ) {
        if isHomeFamily {
            if let backgroundColorHex = style.backgroundColorHex {
                resolved.backgroundColorHex = backgroundColorHex
            }
            if let primaryTextColorHex = style.primaryTextColorHex {
                resolved.primaryTextColorHex = primaryTextColorHex
            }
            if let secondaryTextColorHex = style.secondaryTextColorHex {
                resolved.secondaryTextColorHex = secondaryTextColorHex
            }
        }
        if let eventNameFontSize = style.eventNameFontSize {
            resolved.eventNameFontSize = eventNameFontSize
        }
        if let messageFontSize = style.messageFontSize {
            resolved.messageFontSize = messageFontSize
        }
        if let emojiFontSize = style.emojiFontSize {
            resolved.emojiFontSize = emojiFontSize
        }
        if let alignment = style.alignment {
            resolved.alignment = alignment
        }
    }

    /// Used only when a supplied template is missing a definition for the
    /// requested family (should not happen for a validated template, but
    /// keeps this a total, crash-free function).
    private static let defaultFamilyDefinition = WidgetFamilyDefinition(
        alignment: .center,
        padding: 12,
        spacing: 4,
        elementOrder: [.primaryValue],
        showsEventName: false,
        showsEmoji: false,
        showsUnit: true
    )
}
