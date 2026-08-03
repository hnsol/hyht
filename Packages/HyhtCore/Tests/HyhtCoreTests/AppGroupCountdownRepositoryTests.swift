import XCTest
@testable import HyhtCore

final class AppGroupCountdownRepositoryTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HyhtRepositoryTests-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        super.tearDown()
    }

    private var stateFileURL: URL {
        tempDirectory.appendingPathComponent("state.json")
    }

    private func makeRepository(now: @escaping @Sendable () -> Date = Date.init) -> AppGroupCountdownRepository {
        AppGroupCountdownRepository(containerURL: tempDirectory, now: now)
    }

    func testFirstLoadInitializesDefaultAndWritesFile() async {
        let repository = makeRepository()

        let result = await repository.load()

        guard case .emptyInitialized(let state) = result else {
            return XCTFail("Expected .emptyInitialized, got \(result)")
        }
        XCTAssertEqual(state.schemaVersion, AppState.currentSchemaVersion)
        XCTAssertTrue(FileManager.default.fileExists(atPath: stateFileURL.path))
    }

    func testSaveThenLoadRoundTrips() async throws {
        let repository = makeRepository()
        _ = await repository.load() // establishes default file + save-enabled state

        // Use a whole-second `Date`: iso8601 encoding drops sub-second
        // precision, so a round trip through JSON must start from one.
        let now = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded())
        var state = AppState.makeDefault(now: now, timeZone: .current)
        state.event.name = "Launch Day"

        try await repository.save(state)

        let result = await repository.load()
        guard case .loaded(let loaded) = result else {
            return XCTFail("Expected .loaded, got \(result)")
        }
        XCTAssertEqual(loaded, state)
    }

    func testCorruptFileIsMovedAsideAndDefaultRecreated() async throws {
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        try Data("not valid json".utf8).write(to: stateFileURL)

        let repository = makeRepository(now: { Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded()) })
        let result = await repository.load()

        guard case .recoveredFromCorruption(let state) = result else {
            return XCTFail("Expected .recoveredFromCorruption, got \(result)")
        }
        XCTAssertEqual(state.schemaVersion, AppState.currentSchemaVersion)

        let contents = try FileManager.default.contentsOfDirectory(atPath: tempDirectory.path)
        let corruptFiles = contents.filter { $0.hasPrefix("state.corrupt-") && $0.hasSuffix(".json") }
        XCTAssertEqual(corruptFiles.count, 1, "Expected exactly one corrupt backup file, found: \(contents)")

        // state.json should now hold the freshly-written default state.
        let currentData = try Data(contentsOf: stateFileURL)
        let decoded = AppStateDecoder.decode(currentData)
        guard case .loaded(let reloaded) = decoded else {
            return XCTFail("Expected recreated state.json to decode as .loaded")
        }
        XCTAssertEqual(reloaded, state)
    }

    func testUnknownNewerSchemaVersionLeavesFileByteExactAndRejectsSave() async throws {
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let futureJSON = """
        {"schemaVersion":999,"future":"data"}
        """
        let originalBytes = Data(futureJSON.utf8)
        try originalBytes.write(to: stateFileURL)

        let repository = makeRepository()
        let result = await repository.load()

        guard case .unknownNewerVersion(let foundVersion) = result else {
            return XCTFail("Expected .unknownNewerVersion, got \(result)")
        }
        XCTAssertEqual(foundVersion, 999)

        let bytesAfterLoad = try Data(contentsOf: stateFileURL)
        XCTAssertEqual(bytesAfterLoad, originalBytes)

        let state = AppState.makeDefault(now: Date(), timeZone: .current)
        do {
            try await repository.save(state)
            XCTFail("Expected save to throw after unknownNewerVersion load")
        } catch {
            // expected
        }

        let bytesAfterRejectedSave = try Data(contentsOf: stateFileURL)
        XCTAssertEqual(bytesAfterRejectedSave, originalBytes)
    }
}
