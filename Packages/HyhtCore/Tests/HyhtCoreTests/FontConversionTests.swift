import XCTest
import SwiftUI
@testable import HyhtCore

final class FontConversionTests: XCTestCase {
    func testTemplateFontWeightMapsEveryCase() {
        let expected: [TemplateFontWeight: Font.Weight] = [
            .ultraLight: .ultraLight,
            .thin: .thin,
            .light: .light,
            .regular: .regular,
            .medium: .medium,
            .semibold: .semibold,
            .bold: .bold,
            .heavy: .heavy,
            .black: .black
        ]

        for weight in TemplateFontWeight.allCases {
            XCTAssertEqual(weight.swiftUIWeight, expected[weight], "missing/incorrect mapping for \(weight)")
        }
        XCTAssertEqual(expected.count, TemplateFontWeight.allCases.count)
    }

    func testTemplateFontDesignMapsEveryCase() {
        let expected: [TemplateFontDesign: Font.Design] = [
            .default: .default,
            .rounded: .rounded,
            .serif: .serif,
            .monospaced: .monospaced
        ]

        for design in TemplateFontDesign.allCases {
            XCTAssertEqual(design.swiftUIDesign, expected[design], "missing/incorrect mapping for \(design)")
        }
        XCTAssertEqual(expected.count, TemplateFontDesign.allCases.count)
    }

    func testAlignmentMapsEveryCase() {
        let horizontal: [WidgetFamilyDefinition.Alignment: HorizontalAlignment] = [
            .leading: .leading,
            .center: .center,
            .trailing: .trailing
        ]
        for (alignment, expected) in horizontal {
            XCTAssertEqual(alignment.horizontalAlignment, expected)
        }

        let frame: [WidgetFamilyDefinition.Alignment: Alignment] = [
            .leading: .leading,
            .center: .center,
            .trailing: .trailing
        ]
        for (alignment, expected) in frame {
            XCTAssertEqual(alignment.frameAlignment, expected)
        }
        XCTAssertEqual(WidgetFamilyDefinition.Alignment.allCases.count, 3)
    }
}
