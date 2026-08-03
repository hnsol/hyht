import XCTest
@testable import HyhtCore

final class DeepLinkTests: XCTestCase {
    func testEditURLRoutesToEditScreen() {
        XCTAssertEqual(DeepLink.route(URL(string: "hyht://edit")!), .edit)
        XCTAssertEqual(DeepLink.route(URL(string: "hyht://edit/")!), .edit)
        XCTAssertEqual(DeepLink.route(URL(string: "HYHT://EDIT")!), .edit)
    }

    func testWidgetURLIsTheEditRoute() {
        XCTAssertEqual(DeepLink.route(HyhtCore.editDeepLinkURL), .edit)
        XCTAssertEqual(HyhtCore.editDeepLinkURL.absoluteString, "hyht://edit")
    }

    func testUnknownURLsAreIgnored() {
        let ignored = [
            "hyht://",
            "hyht://settings",
            "hyht:edit",
            "https://example.com/edit",
            "hyhtx://edit",
            "otherapp://edit"
        ]
        for string in ignored {
            guard let url = URL(string: string) else { continue }
            XCTAssertNil(DeepLink.route(url), "\(string) must not be routed")
        }
    }
}
