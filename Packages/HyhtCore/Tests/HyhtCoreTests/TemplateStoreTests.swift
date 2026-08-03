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

    // MARK: - "Show everything" template policy regression tests
    //
    // All bundled templates (and `WidgetTemplate.fallback`, which mirrors
    // `minimal`) are expected to follow the same "show every element"
    // policy. `systemMedium` and `accessoryRectangular` use a fixed layout
    // (a horizontal split and a fixed two-line stack, respectively) rather
    // than `elementOrder`, so `elementOrder` is not asserted for them here
    // -- their display requirements are covered by layout-level visual
    // confirmation instead (see the plan's 目視確認 section).

    /// All four family definitions under test: the three bundled templates
    /// plus `WidgetTemplate.fallback` (which must mirror `minimal`'s shape).
    private var allTemplateDefinitions: [(name: String, template: WidgetTemplate)] {
        TemplateStore.loadBuiltinTemplates().map { ($0.id, $0) } + [("fallback", WidgetTemplate.fallback)]
    }

    func testSystemSmallElementOrderContainsEachElementExactlyOnce() {
        for (name, template) in allTemplateDefinitions {
            let order = template.families[.systemSmall]?.elementOrder ?? []
            for kind: ElementKind in [.emoji, .eventName, .primaryValue, .unit] {
                XCTAssertEqual(
                    order.filter { $0 == kind }.count, 1,
                    "\(name) systemSmall elementOrder should contain \(kind) exactly once, got \(order)"
                )
            }
        }
    }

    func testSystemSmallAndMediumShowAllThreeElements() {
        for (name, template) in allTemplateDefinitions {
            for family: WidgetFamilyKey in [.systemSmall, .systemMedium] {
                guard let definition = template.families[family] else {
                    XCTFail("\(name) is missing \(family)")
                    continue
                }
                XCTAssertTrue(definition.showsEventName, "\(name) \(family) should show event name")
                XCTAssertTrue(definition.showsEmoji, "\(name) \(family) should show emoji")
                XCTAssertTrue(definition.showsUnit, "\(name) \(family) should show unit")
            }
        }
    }

    func testAllTemplatesUseCenterAlignmentForSystemMedium() {
        for (name, template) in allTemplateDefinitions {
            XCTAssertEqual(
                template.families[.systemMedium]?.alignment, .center,
                "\(name) systemMedium alignment should be center"
            )
        }
    }

    func testBoldSystemMediumAlignmentIsCenter() {
        let bold = TemplateStore.template(id: "bold")
        XCTAssertEqual(bold.families[.systemMedium]?.alignment, .center)
    }

    func testAccessoryCircularShowsUnitOnlyWithFixedElementOrderAndCenterAlignment() {
        for (name, template) in allTemplateDefinitions {
            guard let definition = template.families[.accessoryCircular] else {
                XCTFail("\(name) is missing accessoryCircular")
                continue
            }
            XCTAssertFalse(definition.showsEventName, "\(name) accessoryCircular should not show event name")
            XCTAssertFalse(definition.showsEmoji, "\(name) accessoryCircular should not show emoji")
            XCTAssertTrue(definition.showsUnit, "\(name) accessoryCircular should show unit")
            XCTAssertEqual(definition.elementOrder, [.primaryValue, .unit], "\(name) accessoryCircular elementOrder")
            XCTAssertEqual(definition.alignment, .center, "\(name) accessoryCircular alignment")
        }
    }

    func testAccessoryRectangularShowsAllThreeElements() {
        for (name, template) in allTemplateDefinitions {
            guard let definition = template.families[.accessoryRectangular] else {
                XCTFail("\(name) is missing accessoryRectangular")
                continue
            }
            XCTAssertTrue(definition.showsEventName, "\(name) accessoryRectangular should show event name")
            XCTAssertTrue(definition.showsEmoji, "\(name) accessoryRectangular should show emoji")
            XCTAssertTrue(definition.showsUnit, "\(name) accessoryRectangular should show unit")
        }
    }
}
