import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import HyhtCore

final class ColorConversionTests: XCTestCase {
    func testRGBColorToColorMatchesComponents() {
        assertColor(RGBColor(red: 0, green: 0, blue: 0).color, red: 0, green: 0, blue: 0)
        assertColor(RGBColor(red: 255, green: 255, blue: 255).color, red: 1, green: 1, blue: 1)
        assertColor(RGBColor(red: 0xFF, green: 0x3B, blue: 0x30).color, red: 1, green: 0x3B / 255.0, blue: 0x30 / 255.0)
    }

    func testWidgetColorParsesValidHex() {
        assertColor(WidgetColor.color(fromHex: "#FF3B30", fallback: .black), red: 1, green: 0x3B / 255.0, blue: 0x30 / 255.0)
    }

    func testWidgetColorFallsBackOnInvalidHex() {
        XCTAssertEqual(WidgetColor.color(fromHex: "not-a-color", fallback: .red), Color.red)
        XCTAssertEqual(WidgetColor.color(fromHex: "", fallback: .blue), Color.blue)
    }

    // MARK: - Helpers

    private func assertColor(_ color: Color, red: Double, green: Double, blue: Double, accuracy: Double = 0.01) {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(Double(r), red, accuracy: accuracy)
        XCTAssertEqual(Double(g), green, accuracy: accuracy)
        XCTAssertEqual(Double(b), blue, accuracy: accuracy)
        #endif
    }
}
