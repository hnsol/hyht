import XCTest
@testable import HyhtCore

final class StyleResolverTests: XCTestCase {
    private let minimal = TemplateStore.template(id: "minimal")
    private let bold = TemplateStore.template(id: "bold")

    // MARK: - Template switching

    func testSwitchingTemplateChangesResolvedStyle() {
        let minimalResolved = StyleResolver.resolve(
            template: minimal,
            overrides: .none,
            completion: nil,
            family: .systemSmall,
            isCompleted: false
        )
        let boldResolved = StyleResolver.resolve(
            template: bold,
            overrides: .none,
            completion: nil,
            family: .systemSmall,
            isCompleted: false
        )
        XCTAssertNotEqual(minimalResolved, boldResolved)
    }

    // MARK: - Color-only overrides preserve layout

    func testColorOnlyOverridePreservesAlignmentAndLayout() {
        let base = StyleResolver.resolve(
            template: minimal,
            overrides: .none,
            completion: nil,
            family: .systemMedium,
            isCompleted: false
        )
        let colorOnly = StyleResolver.resolve(
            template: minimal,
            overrides: StyleOverrides(backgroundColorHex: "#FF00FF"),
            completion: nil,
            family: .systemMedium,
            isCompleted: false
        )

        XCTAssertEqual(colorOnly.backgroundColorHex, "#FF00FF")
        XCTAssertNotEqual(colorOnly.backgroundColorHex, base.backgroundColorHex)

        XCTAssertEqual(colorOnly.alignment, base.alignment)
        XCTAssertEqual(colorOnly.padding, base.padding)
        XCTAssertEqual(colorOnly.spacing, base.spacing)
        XCTAssertEqual(colorOnly.elementOrder, base.elementOrder)
        XCTAssertEqual(colorOnly.primaryValueFontSize, base.primaryValueFontSize)
    }

    // MARK: - Accessory families ignore color overrides

    func testColorOverrideIsIgnoredForAccessoryFamiliesButAppliesToSystemSmall() {
        let overrides = StyleOverrides(
            backgroundColorHex: "#123456",
            primaryTextColorHex: "#654321",
            secondaryTextColorHex: "#ABCDEF"
        )

        let small = StyleResolver.resolve(
            template: minimal, overrides: overrides, completion: nil,
            family: .systemSmall, isCompleted: false
        )
        XCTAssertEqual(small.backgroundColorHex, "#123456")
        XCTAssertEqual(small.primaryTextColorHex, "#654321")
        XCTAssertEqual(small.secondaryTextColorHex, "#ABCDEF")

        let circular = StyleResolver.resolve(
            template: minimal, overrides: overrides, completion: nil,
            family: .accessoryCircular, isCompleted: false
        )
        XCTAssertEqual(circular.backgroundColorHex, minimal.style.backgroundColorHex)
        XCTAssertEqual(circular.primaryTextColorHex, minimal.style.primaryTextColorHex)
        XCTAssertEqual(circular.secondaryTextColorHex, minimal.style.secondaryTextColorHex)

        let rectangular = StyleResolver.resolve(
            template: minimal, overrides: overrides, completion: nil,
            family: .accessoryRectangular, isCompleted: false
        )
        XCTAssertEqual(rectangular.backgroundColorHex, minimal.style.backgroundColorHex)
        XCTAssertEqual(rectangular.primaryTextColorHex, minimal.style.primaryTextColorHex)
        XCTAssertEqual(rectangular.secondaryTextColorHex, minimal.style.secondaryTextColorHex)
    }

    // MARK: - Family-specific alignment overrides win over the common override

    func testFamilyAlignmentOverrideBeatsCommonOverride() {
        let overrides = StyleOverrides(
            alignment: .leading,
            familyAlignmentOverrides: [.systemMedium: .trailing]
        )

        let small = StyleResolver.resolve(
            template: minimal, overrides: overrides, completion: nil,
            family: .systemSmall, isCompleted: false
        )
        XCTAssertEqual(small.alignment, .leading)

        let medium = StyleResolver.resolve(
            template: minimal, overrides: overrides, completion: nil,
            family: .systemMedium, isCompleted: false
        )
        XCTAssertEqual(medium.alignment, .trailing)
    }

    // MARK: - Completion overrides

    func testCompletionOverrideAppliesOnlyWhenCompleted() {
        let userCompletion = CompletionStyle(
            message: "Custom done",
            emoji: "🥳",
            backgroundColorHex: "#00FF00",
            messageFontSize: 99
        )

        let notCompleted = StyleResolver.resolve(
            template: minimal,
            overrides: .none,
            completion: userCompletion,
            family: .systemSmall,
            isCompleted: false
        )
        XCTAssertNil(notCompleted.completionMessage)
        XCTAssertNil(notCompleted.completionEmoji)
        XCTAssertNil(notCompleted.messageFontSize)
        XCTAssertEqual(notCompleted.backgroundColorHex, minimal.style.backgroundColorHex)

        let completed = StyleResolver.resolve(
            template: minimal,
            overrides: .none,
            completion: userCompletion,
            family: .systemSmall,
            isCompleted: true
        )
        XCTAssertEqual(completed.completionMessage, "Custom done")
        XCTAssertEqual(completed.completionEmoji, "🥳")
        XCTAssertEqual(completed.backgroundColorHex, "#00FF00")
        XCTAssertEqual(completed.messageFontSize, 99)
    }

    func testCompletionWithoutUserOverrideUsesTemplateCompletionDefaults() {
        let completed = StyleResolver.resolve(
            template: minimal,
            overrides: .none,
            completion: nil,
            family: .systemSmall,
            isCompleted: true
        )
        XCTAssertEqual(completed.completionMessage, minimal.completion.message)
        XCTAssertEqual(completed.completionEmoji, minimal.completion.emoji)
        XCTAssertEqual(completed.backgroundColorHex, minimal.completion.backgroundColorHex)
    }

    func testCompletionColorOverrideIgnoredForAccessoryFamilies() {
        let userCompletion = CompletionStyle(
            message: "Custom done",
            emoji: "🥳",
            backgroundColorHex: "#00FF00"
        )

        let completed = StyleResolver.resolve(
            template: minimal,
            overrides: .none,
            completion: userCompletion,
            family: .accessoryCircular,
            isCompleted: true
        )
        XCTAssertEqual(completed.backgroundColorHex, minimal.style.backgroundColorHex)
        // Message/emoji are not colors and still apply to accessory families.
        XCTAssertEqual(completed.completionMessage, "Custom done")
    }

    // MARK: - Template immutability

    func testResolvingDoesNotMutateTheTemplate() {
        let before = minimal
        _ = StyleResolver.resolve(
            template: minimal,
            overrides: StyleOverrides(backgroundColorHex: "#FF00FF", alignment: .trailing),
            completion: CompletionStyle(message: "x", emoji: "y", backgroundColorHex: "#000000"),
            family: .systemSmall,
            isCompleted: true
        )
        XCTAssertEqual(before, minimal)
    }
}
