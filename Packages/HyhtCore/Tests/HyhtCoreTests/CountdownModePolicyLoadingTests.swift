import XCTest
@testable import HyhtCore

final class CountdownModePolicyLoadingTests: XCTestCase {
    // MARK: - Bundled resource

    func testBundledResourceExists() {
        XCTAssertNotNil(
            HyhtCoreResources.jsonData(named: HyhtCoreResources.modePolicyResourceName),
            "mode-policy.json is missing from HyhtCore's resource bundle"
        )
    }

    func testLoadBundledDecodesTheAuthoritativeJSON() throws {
        let data = try XCTUnwrap(
            HyhtCoreResources.jsonData(named: HyhtCoreResources.modePolicyResourceName)
        )
        let decoded = try JSONDecoder().decode(CountdownModePolicy.self, from: data)

        XCTAssertTrue(decoded.isValid)
        // Proves `loadBundled()` really returned the resource and did not
        // silently fall back.
        XCTAssertEqual(CountdownModePolicy.loadBundled(), decoded)
    }

    /// The bundled JSON is authoritative and the in-code definition is only a
    /// safety net; every field must agree.
    func testBundledPolicyMatchesCodeFallbackFieldByField() {
        let bundled = CountdownModePolicy.loadBundled()
        let fallback = CountdownModePolicy.fallback

        XCTAssertEqual(bundled.version, fallback.version)
        XCTAssertEqual(bundled.weekLowerBound, fallback.weekLowerBound)
        XCTAssertEqual(bundled.dayLowerBound, fallback.dayLowerBound)
        XCTAssertEqual(bundled.hourLowerBound, fallback.hourLowerBound)
        XCTAssertEqual(bundled.clockLowerBound, fallback.clockLowerBound)
        XCTAssertEqual(bundled.weekRounding, fallback.weekRounding)
        XCTAssertEqual(bundled.dayRounding, fallback.dayRounding)
        XCTAssertEqual(bundled.hourRounding, fallback.hourRounding)
        XCTAssertEqual(bundled.minRounding, fallback.minRounding)

        XCTAssertEqual(bundled, fallback)
    }

    func testBundledPolicyHoldsTheSpecifiedThresholds() {
        let policy = CountdownModePolicy.loadBundled()
        XCTAssertEqual(policy.weekLowerBound, 12 * 24 * 3600 + 30)
        XCTAssertEqual(policy.dayLowerBound, 120 * 3600 + 30)
        XCTAssertEqual(policy.hourLowerBound, 24 * 3600 + 30)
        XCTAssertEqual(policy.clockLowerBound, 120 * 60)
        XCTAssertEqual(policy.weekRounding, .toFixed2)
        XCTAssertEqual(policy.dayRounding, .toFixed2)
        XCTAssertEqual(policy.hourRounding, .toFixed1)
        XCTAssertEqual(policy.minRounding, .floor)
    }

    /// The bundled policy must drive the calculator identically to the fallback.
    func testBundledAndFallbackPoliciesProduceIdenticalSnapshots() {
        let deadline = Date(timeIntervalSince1970: 1_800_000_000)
        var remaining: TimeInterval = 40 * 86_400
        while remaining > -86_400 {
            let now = deadline.addingTimeInterval(-remaining)
            XCTAssertEqual(
                CountdownCalculator.snapshot(deadline: deadline, now: now, policy: .loadBundled()),
                CountdownCalculator.snapshot(deadline: deadline, now: now, policy: .fallback),
                "remaining \(remaining)"
            )
            remaining -= 7_919
        }
    }

    // MARK: - Validation path

    private func data(_ json: String) -> Data {
        Data(json.utf8)
    }

    func testMalformedJSONFallsBack() {
        XCTAssertEqual(CountdownModePolicy.load(from: data("{ this is not json")), .fallback)
        XCTAssertEqual(CountdownModePolicy.load(from: Data()), .fallback)
        XCTAssertEqual(CountdownModePolicy.load(from: data("[]")), .fallback)
    }

    func testMissingFieldsFallBack() {
        XCTAssertEqual(CountdownModePolicy.load(from: data(#"{"version": 1}"#)), .fallback)
    }

    func testUnknownRoundingRuleFallsBack() {
        XCTAssertEqual(CountdownModePolicy.load(from: validJSON(weekRounding: "toFixed7")), .fallback)
    }

    func testUnknownVersionFallsBack() {
        XCTAssertEqual(CountdownModePolicy.load(from: validJSON(version: 99)), .fallback)
    }

    func testOutOfOrderThresholdsFallBack() {
        // day bound above the week bound breaks the cascade.
        XCTAssertEqual(CountdownModePolicy.load(from: validJSON(dayLowerBound: 9_999_999)), .fallback)
        // hour bound below the clock bound breaks the cascade.
        XCTAssertEqual(CountdownModePolicy.load(from: validJSON(hourLowerBound: 100)), .fallback)
    }

    func testNonPositiveClockBoundFallsBack() {
        XCTAssertEqual(CountdownModePolicy.load(from: validJSON(clockLowerBound: 0)), .fallback)
        XCTAssertEqual(CountdownModePolicy.load(from: validJSON(clockLowerBound: -1)), .fallback)
    }

    func testValidJSONIsAcceptedUnchanged() {
        let loaded = CountdownModePolicy.load(from: validJSON())
        XCTAssertEqual(loaded, .fallback)

        // A valid but *different* policy must survive: this proves the previous
        // assertions fail validation rather than merely round-tripping.
        let custom = CountdownModePolicy.load(from: validJSON(clockLowerBound: 3_600))
        XCTAssertEqual(custom.clockLowerBound, 3_600)
        XCTAssertNotEqual(custom, .fallback)
    }

    private func validJSON(
        version: Int = 1,
        weekLowerBound: Double = 1_036_830,
        dayLowerBound: Double = 432_030,
        hourLowerBound: Double = 86_430,
        clockLowerBound: Double = 7_200,
        weekRounding: String = "toFixed2",
        dayRounding: String = "toFixed2",
        hourRounding: String = "toFixed1",
        minRounding: String = "floor"
    ) -> Data {
        data(
            """
            {
              "version": \(version),
              "weekLowerBound": \(weekLowerBound),
              "dayLowerBound": \(dayLowerBound),
              "hourLowerBound": \(hourLowerBound),
              "clockLowerBound": \(clockLowerBound),
              "weekRounding": "\(weekRounding)",
              "dayRounding": "\(dayRounding)",
              "hourRounding": "\(hourRounding)",
              "minRounding": "\(minRounding)"
            }
            """
        )
    }
}
