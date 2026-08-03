import XCTest
@testable import HyhtCore

final class CountdownUnitFormatterTests: XCTestCase {
    func testUnitLabelPerModeShort() {
        XCTAssertEqual(CountdownUnitFormatter.unitLabel(for: .week, style: .short), "wk")
        XCTAssertEqual(CountdownUnitFormatter.unitLabel(for: .day, style: .short), "d")
        XCTAssertEqual(CountdownUnitFormatter.unitLabel(for: .hour, style: .short), "h")
        XCTAssertEqual(CountdownUnitFormatter.unitLabel(for: .min, style: .short), "m")
        XCTAssertNil(CountdownUnitFormatter.unitLabel(for: .clock, style: .short))
        XCTAssertNil(CountdownUnitFormatter.unitLabel(for: .done, style: .short))
    }

    func testUnitLabelPerModeLong() {
        XCTAssertEqual(CountdownUnitFormatter.unitLabel(for: .week, style: .long), "weeks")
        XCTAssertEqual(CountdownUnitFormatter.unitLabel(for: .day, style: .long), "days")
        XCTAssertEqual(CountdownUnitFormatter.unitLabel(for: .hour, style: .long), "hours")
        XCTAssertEqual(CountdownUnitFormatter.unitLabel(for: .min, style: .long), "min")
        XCTAssertNil(CountdownUnitFormatter.unitLabel(for: .clock, style: .long))
        XCTAssertNil(CountdownUnitFormatter.unitLabel(for: .done, style: .long))
    }

    func testCoversAllModes() {
        // Guards against a future mode being added without updating the
        // unit table above: every case is exercised by name in this file,
        // for both label styles.
        for mode in CountdownDisplayMode.allCases {
            _ = CountdownUnitFormatter.unitLabel(for: mode, style: .short)
            _ = CountdownUnitFormatter.unitLabel(for: mode, style: .long)
        }
        XCTAssertEqual(CountdownDisplayMode.allCases.count, 6)
    }
}
