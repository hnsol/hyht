import XCTest
@testable import HyhtCore

/// Golden tests proving `jsToFixed(_:digits:)` matches JavaScript's
/// `Number.prototype.toFixed` on every case in the Node.js-generated fixture.
///
/// Regenerate the fixture with `node Scripts/generate-tofixed-fixture.mjs`.
final class JSToFixedGoldenTests: XCTestCase {
    private struct Fixture: Decodable {
        struct Case: Decodable {
            let note: String
            let value: Double
            let bitsHex: String
            let digits: Int
            let expected: String
        }

        let caseCount: Int
        let cases: [Case]
    }

    private func loadFixture() throws -> Fixture {
        let data = try XCTUnwrap(
            HyhtCoreResources.jsonData(named: HyhtCoreResources.toFixedFixtureResourceName),
            "tofixed-fixture.json is missing from HyhtCore's resource bundle"
        )
        return try JSONDecoder().decode(Fixture.self, from: data)
    }

    func testFixtureIsPresentAndNonTrivial() throws {
        let fixture = try loadFixture()
        XCTAssertEqual(fixture.caseCount, fixture.cases.count)
        XCTAssertGreaterThan(fixture.cases.count, 100)
    }

    func testEveryFixtureCaseMatchesJavaScriptToFixed() throws {
        let fixture = try loadFixture()

        for testCase in fixture.cases {
            // Reconstruct the exact Double from its IEEE-754 bits so the check
            // cannot be weakened by JSON number parsing differences.
            let bits = try XCTUnwrap(
                UInt64(testCase.bitsHex, radix: 16),
                "malformed bitsHex \(testCase.bitsHex)"
            )
            let value = Double(bitPattern: bits)

            XCTAssertEqual(
                value,
                testCase.value,
                "JSON-parsed value disagrees with the recorded bit pattern for \(testCase.bitsHex)"
            )

            XCTAssertEqual(
                jsToFixed(value, digits: testCase.digits),
                testCase.expected,
                "toFixed(\(testCase.value), \(testCase.digits)) [\(testCase.note)]"
            )
        }
    }

    // MARK: - Documented traps, asserted explicitly

    func testRepresentationTrapsDoNotRoundUp() {
        // The stored Doubles are just below the decimal literal, so ECMAScript
        // rounds them down even though they "look" like half-way cases.
        XCTAssertEqual(jsToFixed(9.995, digits: 2), "9.99")
        XCTAssertEqual(jsToFixed(1.005, digits: 2), "1.00")
        XCTAssertEqual(jsToFixed(2.675, digits: 2), "2.67")
        XCTAssertEqual(jsToFixed(1.115, digits: 2), "1.11")
    }

    func testExactBinaryTiesRoundUpNotToEven() {
        // `%.2f` would render 0.125 as "0.12" (half-to-even). ECMAScript rounds
        // half-way cases up, so this is the case that rules `String(format:)` out.
        XCTAssertEqual(jsToFixed(0.125, digits: 2), "0.13")
        XCTAssertEqual(jsToFixed(0.375, digits: 2), "0.38")
        XCTAssertEqual(jsToFixed(0.5, digits: 0), "1")
        XCTAssertEqual(jsToFixed(2.5, digits: 0), "3")
    }

    func testTrailingZerosAndDecimalPointArePreserved() {
        XCTAssertEqual(jsToFixed(1.2, digits: 2), "1.20")
        XCTAssertEqual(jsToFixed(120, digits: 1), "120.0")
        XCTAssertEqual(jsToFixed(0, digits: 2), "0.00")
        XCTAssertEqual(jsToFixed(0.1, digits: 1), "0.1")
    }

    func testCarryPropagates() {
        XCTAssertEqual(jsToFixed(9.999, digits: 2), "10.00")
        XCTAssertEqual(jsToFixed(0.999, digits: 2), "1.00")
        XCTAssertEqual(jsToFixed(99.999, digits: 1), "100.0")
    }

    func testSmallMagnitudesPadWithLeadingZeros() {
        XCTAssertEqual(jsToFixed(0.0001, digits: 2), "0.00")
        XCTAssertEqual(jsToFixed(0.009, digits: 2), "0.01")
        XCTAssertEqual(jsToFixed(5e-7, digits: 2), "0.00")
    }

    // MARK: - Out-of-domain inputs must not crash

    func testNonFiniteValuesUseJavaScriptSpellings() {
        XCTAssertEqual(jsToFixed(.nan, digits: 2), "NaN")
        XCTAssertEqual(jsToFixed(.infinity, digits: 2), "Infinity")
        XCTAssertEqual(jsToFixed(-.infinity, digits: 2), "-Infinity")
    }

    func testNegativeZeroHasNoSign() {
        XCTAssertEqual(jsToFixed(-0.0, digits: 2), "0.00")
    }

    func testNegativeValuesKeepTheirSign() {
        XCTAssertEqual(jsToFixed(-1.005, digits: 2), "-1.00")
        XCTAssertEqual(jsToFixed(-0.5, digits: 0), "-1")
    }

    func testExtremeInputsDoNotCrash() {
        XCTAssertFalse(jsToFixed(1e300, digits: 2).isEmpty)
        XCTAssertFalse(jsToFixed(-1e300, digits: 2).isEmpty)
        XCTAssertFalse(jsToFixed(.leastNonzeroMagnitude, digits: 100).isEmpty)
        XCTAssertFalse(jsToFixed(1.5, digits: -3).isEmpty)
        XCTAssertFalse(jsToFixed(1.5, digits: 1000).isEmpty)
    }

    func testNegativeDigitsClampToZero() {
        XCTAssertEqual(jsToFixed(1.5, digits: -1), "2")
    }
}
