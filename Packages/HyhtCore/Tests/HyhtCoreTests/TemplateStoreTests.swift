import XCTest
@testable import HyhtCore

final class TemplateStoreTests: XCTestCase {
    // MARK: - Loading built-in templates

    func testLoadsAllThreeBuiltinTemplates() {
        let templates = TemplateStore.loadBuiltinTemplates()
        let ids = Set(templates.map(\.id))
        XCTAssertEqual(ids, ["minimal", "bold", "soft"])
    }

    func testEveryBuiltinTemplateDefinesAllFourFamilies() {
        for template in TemplateStore.loadBuiltinTemplates() {
            XCTAssertEqual(
                Set(template.families.keys),
                Set(WidgetFamilyKey.allCases),
                "\(template.id) is missing a family definition"
            )
        }
    }

    func testEveryBuiltinTemplateIsValid() {
        for template in TemplateStore.loadBuiltinTemplates() {
            XCTAssertTrue(template.isValid, "\(template.id) failed validation")
        }
    }

    func testTemplateByIDReturnsMatchingTemplate() {
        XCTAssertEqual(TemplateStore.template(id: "bold").id, "bold")
        XCTAssertEqual(TemplateStore.template(id: "soft").id, "soft")
        XCTAssertEqual(TemplateStore.template(id: "minimal").id, "minimal")
    }

    func testUnknownIDFallsBackToMinimal() {
        XCTAssertEqual(TemplateStore.template(id: "does-not-exist").id, "minimal")
        XCTAssertEqual(TemplateStore.template(id: "").id, "minimal")
    }

    func testMinimalTemplateMatchesFallbackShapeWhenResourceIsHealthy() {
        // The bundled resource is healthy in this test target, so
        // `minimalTemplate()` should reflect it (not silently substitute
        // `WidgetTemplate.fallback`), while still validating successfully.
        let minimal = TemplateStore.minimalTemplate()
        XCTAssertEqual(minimal.id, "minimal")
        XCTAssertTrue(minimal.isValid)
    }

    // MARK: - Validation of raw/corrupt data

    private func encode(_ template: WidgetTemplate) -> Data {
        try! AppStateCoding.encoder.encode(template)
    }

    private var baseTemplate: WidgetTemplate { WidgetTemplate.fallback }

    func testMalformedJSONIsRejected() {
        XCTAssertNil(TemplateStore.decodeTemplate(from: Data("{ not json".utf8)))
        XCTAssertNil(TemplateStore.decodeTemplate(from: Data()))
        XCTAssertNil(TemplateStore.decodeTemplate(from: Data("[]".utf8)))
    }

    func testMissingFamilyIsRejected() {
        var template = baseTemplate
        template.families.removeValue(forKey: .accessoryRectangular)
        XCTAssertNil(TemplateStore.decodeTemplate(from: encode(template)))
    }

    func testFutureSchemaVersionIsRejected() {
        var template = baseTemplate
        template.schemaVersion = WidgetTemplate.currentSchemaVersion + 1
        XCTAssertNil(TemplateStore.decodeTemplate(from: encode(template)))
    }

    func testInvalidHexColorIsRejected() {
        var template = baseTemplate
        template.style.backgroundColorHex = "#GGGGGG"
        XCTAssertNil(TemplateStore.decodeTemplate(from: encode(template)))
    }

    func testOutOfRangeFontSizeIsRejected() {
        var template = baseTemplate
        template.style.primaryValueFontSize = 999
        XCTAssertNil(TemplateStore.decodeTemplate(from: encode(template)))

        var tooSmall = baseTemplate
        tooSmall.style.emojiFontSize = 1
        XCTAssertNil(TemplateStore.decodeTemplate(from: encode(tooSmall)))
    }

    func testOutOfRangePaddingOrSpacingIsRejected() {
        var template = baseTemplate
        template.families[.systemSmall]?.padding = 500
        XCTAssertNil(TemplateStore.decodeTemplate(from: encode(template)))

        var negative = baseTemplate
        negative.families[.systemMedium]?.spacing = -1
        XCTAssertNil(TemplateStore.decodeTemplate(from: encode(negative)))
    }

    func testValidTemplateRoundTrips() {
        let template = baseTemplate
        let decoded = TemplateStore.decodeTemplate(from: encode(template))
        XCTAssertEqual(decoded, template)
    }

    // MARK: - Distinct template roles

    func testMinimalIsSparseMonospacedAndLeadingAligned() throws {
        let minimal = TemplateStore.template(id: "minimal")
        let small = try XCTUnwrap(minimal.families[.systemSmall])
        let medium = try XCTUnwrap(minimal.families[.systemMedium])

        XCTAssertEqual(minimal.style.fontDesign, .monospaced)
        XCTAssertEqual(minimal.style.primaryValueFontSize, 38)
        XCTAssertEqual(small.alignment, .leading)
        XCTAssertEqual(small.padding, 14)
        XCTAssertEqual(small.spacing, 6)
        XCTAssertEqual(small.elementOrder, [.eventName, .primaryValue, .unit, .emoji])
        XCTAssertFalse(small.showsEmoji)
        XCTAssertEqual(medium.alignment, .leading)
        XCTAssertFalse(medium.showsEmoji)
    }

    func testBoldMakesTheNumberLargestAndKeepsEverySmallElement() throws {
        let bold = TemplateStore.template(id: "bold")
        let small = try XCTUnwrap(bold.families[.systemSmall])
        let medium = try XCTUnwrap(bold.families[.systemMedium])

        XCTAssertEqual(bold.style.fontWeight, .black)
        XCTAssertEqual(bold.style.primaryValueFontSize, 52)
        XCTAssertEqual(small.alignment, .center)
        XCTAssertEqual(small.padding, 8)
        XCTAssertEqual(small.spacing, 2)
        XCTAssertEqual(small.elementOrder, [.primaryValue, .unit, .eventName, .emoji])
        XCTAssertTrue(small.showsEventName)
        XCTAssertTrue(small.showsEmoji)
        XCTAssertTrue(small.showsUnit)
        XCTAssertEqual(medium.alignment, .center)
        XCTAssertEqual(medium.spacing, 2)
    }

    func testSoftLeadsWithALargeEmojiAndRoundedTypography() throws {
        let soft = TemplateStore.template(id: "soft")
        let small = try XCTUnwrap(soft.families[.systemSmall])
        let medium = try XCTUnwrap(soft.families[.systemMedium])

        XCTAssertEqual(soft.style.fontDesign, .rounded)
        XCTAssertEqual(soft.style.primaryValueFontSize, 32)
        XCTAssertEqual(soft.style.emojiFontSize, 30)
        XCTAssertEqual(small.alignment, .center)
        XCTAssertEqual(small.padding, 12)
        XCTAssertEqual(small.spacing, 5)
        XCTAssertEqual(small.elementOrder, [.emoji, .eventName, .primaryValue, .unit])
        XCTAssertTrue(small.showsEmoji)
        XCTAssertEqual(medium.alignment, .center)
        XCTAssertEqual(medium.spacing, 10)
    }

    func testFallbackMirrorsMinimalAppearanceAndFamilies() {
        let minimal = TemplateStore.template(id: "minimal")
        XCTAssertEqual(WidgetTemplate.fallback.style, minimal.style)
        XCTAssertEqual(WidgetTemplate.fallback.families, minimal.families)
        XCTAssertEqual(WidgetTemplate.fallback.completion, minimal.completion)
    }

    func testAccessoryCircularShowsOnlyValueAndUnit() {
        for template in TemplateStore.loadBuiltinTemplates() {
            guard let definition = template.families[.accessoryCircular] else {
                XCTFail("\(template.id) is missing accessoryCircular")
                continue
            }
            XCTAssertFalse(definition.showsEventName)
            XCTAssertFalse(definition.showsEmoji)
            XCTAssertTrue(definition.showsUnit)
            XCTAssertEqual(definition.elementOrder, [.primaryValue, .unit])
            XCTAssertEqual(definition.alignment, .center)
        }
    }
}
