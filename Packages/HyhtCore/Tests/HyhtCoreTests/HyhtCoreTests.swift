import XCTest
@testable import HyhtCore

final class HyhtCoreTests: XCTestCase {
    func testAppGroupIDIsExpectedValue() {
        XCTAssertEqual(HyhtCore.appGroupID, "group.com.masatora.hyht")
    }

    func testContainerURLThrowsOrResolvesWithoutCrashing() {
        // This only resolves meaningfully in an environment with App Group
        // entitlements (e.g. an iOS Simulator running the app/widget
        // target). Under plain `swift test`, we simply confirm the expected
        // error is thrown instead of crashing.
        do {
            _ = try HyhtCore.containerURL()
        } catch HyhtCore.ContainerError.containerUnavailable {
            // Expected when running without App Group entitlements.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
