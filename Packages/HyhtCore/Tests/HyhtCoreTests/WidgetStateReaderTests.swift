import XCTest
@testable import HyhtCore

final class WidgetStateReaderTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HyhtWidgetStateReaderTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        super.tearDown()
    }

    private var stateFileURL: URL {
        tempDirectory.appendingPathComponent("state.json")
    }

    func testReadsValidStateFile() throws {
        // Use a whole-second `Date`: iso8601 encoding drops sub-second
        // precision, so a round trip through JSON must start from one.
        let now = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded())
        let state = AppState.makeDefault(now: now, timeZone: .current)
        let data = try AppStateCoding.encoder.encode(state)
        try data.write(to: stateFileURL)

        let result = WidgetStateReader.read(containerURL: tempDirectory)
        XCTAssertEqual(result, state)
    }

    func testReturnsNilForCorruptFileAndLeavesItUnchanged() throws {
        let originalBytes = Data("not valid json".utf8)
        try originalBytes.write(to: stateFileURL)

        let result = WidgetStateReader.read(containerURL: tempDirectory)
        XCTAssertNil(result)

        let bytesAfterRead = try Data(contentsOf: stateFileURL)
        XCTAssertEqual(bytesAfterRead, originalBytes)
    }

    func testReturnsNilWhenFileMissing() {
        let result = WidgetStateReader.read(containerURL: tempDirectory)
        XCTAssertNil(result)
    }
}
