import XCTest
@testable import HyhtCore

final class ColorContrastTests: XCTestCase {
    // MARK: - Known values

    func testBlackVsWhiteIsMaximumContrast() {
        let ratio = ColorContrast.ratio(hexA: "#FFFFFF", hexB: "#000000")
        XCTAssertEqual(ratio!, 21.0, accuracy: 0.001)
    }

    func testIdenticalColorsHaveRatioOne() {
        let ratio = ColorContrast.ratio(hexA: "#336699", hexB: "#336699")
        XCTAssertEqual(ratio!, 1.0, accuracy: 0.001)
    }

    func testRatioIsSymmetric() {
        let forward = ColorContrast.ratio(hexA: "#123456", hexB: "#FEDCBA")!
        let backward = ColorContrast.ratio(hexA: "#FEDCBA", hexB: "#123456")!
        XCTAssertEqual(forward, backward, accuracy: 0.0001)
    }

    func testInvalidHexReturnsNil() {
        XCTAssertNil(ColorContrast.ratio(hexA: "not-a-color", hexB: "#000000"))
        XCTAssertNil(ColorContrast.ratio(hexA: "#000000", hexB: "nope"))
    }

    // MARK: - Built-in templates

    func testAllBuiltinTemplatesMeetMinimumContrast() {
        let templates = TemplateStore.loadBuiltinTemplates()
        XCTAssertFalse(templates.isEmpty)

        for template in templates {
            let style = template.style
            let backgroundHex = style.backgroundColorHex
            for (label, textHex) in [
                ("primary", style.primaryTextColorHex),
                ("secondary", style.secondaryTextColorHex)
            ] {
                let ratio = ColorContrast.ratio(hexA: backgroundHex, hexB: textHex)
                XCTAssertNotNil(ratio, "\(template.id): \(label) or background hex is invalid")
                XCTAssertGreaterThanOrEqual(
                    ratio ?? 0,
                    ColorContrast.minimumRatio,
                    "\(template.id): \(label) text (\(textHex)) on background (\(backgroundHex)) is below \(ColorContrast.minimumRatio):1"
                )
            }

            let completion = template.completion
            let completionBackgroundHex = completion.backgroundColorHex ?? backgroundHex
            for (label, textHex) in [
                ("completion primary", completion.primaryTextColorHex ?? style.primaryTextColorHex),
                ("completion secondary", completion.secondaryTextColorHex ?? style.secondaryTextColorHex)
            ] {
                let ratio = ColorContrast.ratio(hexA: completionBackgroundHex, hexB: textHex)
                XCTAssertNotNil(ratio, "\(template.id): \(label) or background hex is invalid")
                XCTAssertGreaterThanOrEqual(
                    ratio ?? 0,
                    ColorContrast.minimumRatio,
                    "\(template.id): \(label) text (\(textHex)) on background (\(completionBackgroundHex)) is below \(ColorContrast.minimumRatio):1"
                )
            }
        }
    }
}
