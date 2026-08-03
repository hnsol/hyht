import XCTest
@testable import HyhtCore

final class HexColorTests: XCTestCase {
    func testParsesValidHexColors() {
        XCTAssertEqual(HexColor.parse("#000000"), RGBColor(red: 0, green: 0, blue: 0))
        XCTAssertEqual(HexColor.parse("#FFFFFF"), RGBColor(red: 255, green: 255, blue: 255))
        XCTAssertEqual(HexColor.parse("#FF3B30"), RGBColor(red: 0xFF, green: 0x3B, blue: 0x30))
        XCTAssertEqual(HexColor.parse("#ff3b30"), RGBColor(red: 0xFF, green: 0x3B, blue: 0x30))
    }

    func testRejectsInvalidHexColors() {
        XCTAssertNil(HexColor.parse("#GGGGGG"))
        XCTAssertNil(HexColor.parse("12345"))
        XCTAssertNil(HexColor.parse(""))
        XCTAssertNil(HexColor.parse("#12345"))
        XCTAssertNil(HexColor.parse("#1234567"))
        XCTAssertNil(HexColor.parse("000000"))
        XCTAssertNil(HexColor.parse("#12345Z"))
    }

    func testIsValidMatchesParse() {
        XCTAssertTrue(HexColor.isValid("#ABCDEF"))
        XCTAssertFalse(HexColor.isValid("#GGGGGG"))
        XCTAssertFalse(HexColor.isValid("12345"))
        XCTAssertFalse(HexColor.isValid(""))
    }
}
