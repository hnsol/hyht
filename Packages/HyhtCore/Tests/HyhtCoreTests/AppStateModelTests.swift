import XCTest
@testable import HyhtCore

final class AppStateModelTests: XCTestCase {
    // MARK: - Fixtures

    private func makeFullAppState() -> AppState {
        let event = CountdownEvent(
            id: UUID(),
            name: "Launch Day",
            emoji: "🚀",
            deadline: Date(timeIntervalSince1970: 1_893_456_000),
            timeZoneID: "Asia/Tokyo"
        )

        let overrides = StyleOverrides(
            backgroundColorHex: "#112233",
            primaryTextColorHex: "#445566",
            secondaryTextColorHex: "#778899",
            primaryValueFontSize: 48,
            eventNameFontSize: 16,
            emojiFontSize: 32,
            alignment: .center,
            familyAlignmentOverrides: [
                .systemSmall: .leading,
                .accessoryCircular: .trailing
            ]
        )

        let completion = CompletionStyle(
            message: "All done!",
            emoji: "🎉",
            backgroundColorHex: "#000000",
            primaryTextColorHex: "#ffffff",
            secondaryTextColorHex: "#cccccc",
            eventNameFontSize: 18,
            messageFontSize: 24,
            emojiFontSize: 40,
            alignment: .center
        )

        return AppState(
            schemaVersion: AppState.currentSchemaVersion,
            event: event,
            selectedTemplateID: "bold",
            overrides: overrides,
            completion: completion
        )
    }

    // MARK: - Round trip

    func testAppStateEncodeDecodeRoundTripIsExact() throws {
        let original = makeFullAppState()

        let data = try AppStateCoding.encoder.encode(original)
        let decoded = try AppStateCoding.decoder.decode(AppState.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testAppStateWithDefaultOverridesRoundTrips() throws {
        // `AppStateCoding` uses ISO 8601 date encoding, which is second-precision;
        // start from a whole-second `Date` so the round trip is exact.
        let now = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded())
        let original = AppState.makeDefault(now: now, timeZone: TimeZone(identifier: "UTC")!)

        let data = try AppStateCoding.encoder.encode(original)
        let decoded = try AppStateCoding.decoder.decode(AppState.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - WidgetTemplate round trip (exercises WidgetFamilyKey dictionary)

    func testWidgetTemplateEncodeDecodeRoundTrips() throws {
        let style = TemplateStyle(
            backgroundColorHex: "#ffffff",
            primaryTextColorHex: "#000000",
            secondaryTextColorHex: "#888888",
            primaryValueFontSize: 60,
            eventNameFontSize: 14,
            emojiFontSize: 28,
            fontWeight: .bold,
            fontDesign: .rounded
        )

        let familyDefinition = WidgetFamilyDefinition(
            alignment: .center,
            padding: 8,
            spacing: 4,
            elementOrder: [.emoji, .primaryValue, .unit, .eventName],
            showsEventName: true,
            showsEmoji: true,
            showsUnit: true
        )

        let completion = CompletionStyle(message: "Done", emoji: "✅")

        let template = WidgetTemplate(
            schemaVersion: 1,
            id: "minimal",
            displayName: "Minimal",
            style: style,
            families: [
                .systemSmall: familyDefinition,
                .systemMedium: familyDefinition,
                .accessoryCircular: familyDefinition,
                .accessoryRectangular: familyDefinition
            ],
            completion: completion
        )

        let data = try AppStateCoding.encoder.encode(template)
        let decoded = try AppStateCoding.decoder.decode(WidgetTemplate.self, from: data)

        XCTAssertEqual(template, decoded)
    }

    func testWidgetFamilyKeyDictionaryEncodesAsStringKeyedJSONObject() throws {
        let familyDefinition = WidgetFamilyDefinition(
            alignment: .leading,
            padding: 0,
            spacing: 0,
            elementOrder: [.primaryValue],
            showsEventName: false,
            showsEmoji: false,
            showsUnit: false
        )

        let dictionary: [WidgetFamilyKey: WidgetFamilyDefinition] = [
            .systemSmall: familyDefinition
        ]

        let data = try AppStateCoding.encoder.encode(dictionary)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["systemSmall"])

        let decoded = try AppStateCoding.decoder.decode([WidgetFamilyKey: WidgetFamilyDefinition].self, from: data)
        XCTAssertEqual(decoded, dictionary)
    }

    // MARK: - makeDefault

    func testMakeDefaultProducesReasonableValues() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let timeZone = TimeZone(identifier: "America/New_York")!

        let state = AppState.makeDefault(now: now, timeZone: timeZone)

        XCTAssertEqual(state.schemaVersion, AppState.currentSchemaVersion)
        XCTAssertFalse(state.event.name.isEmpty)
        XCTAssertFalse(state.event.emoji.isEmpty)
        XCTAssertEqual(state.event.timeZoneID, timeZone.identifier)
        XCTAssertGreaterThan(state.event.deadline, now)
        XCTAssertFalse(state.selectedTemplateID.isEmpty)
        XCTAssertEqual(state.overrides, StyleOverrides.none)
        XCTAssertFalse(state.completion.message.isEmpty)
        XCTAssertFalse(state.completion.emoji.isEmpty)
    }

    // MARK: - AppStateDecoder

    func testAppStateDecoderLoadsCurrentVersion() throws {
        let state = makeFullAppState()
        let data = try AppStateCoding.encoder.encode(state)

        let result = AppStateDecoder.decode(data)

        guard case let .loaded(decoded) = result else {
            return XCTFail("Expected .loaded, got \(result)")
        }
        XCTAssertEqual(decoded, state)
    }

    func testAppStateDecoderReturnsUnknownNewerVersionWithUnmodifiedRawData() throws {
        let json = """
        {"schemaVersion":999,"future":"field","nested":{"a":1}}
        """
        let data = Data(json.utf8)

        let result = AppStateDecoder.decode(data)

        guard case let .unknownNewerVersion(rawData, foundVersion) = result else {
            return XCTFail("Expected .unknownNewerVersion, got \(result)")
        }
        XCTAssertEqual(foundVersion, 999)
        XCTAssertEqual(rawData, data)
    }

    func testAppStateDecoderReturnsCorruptForInvalidJSON() {
        let data = Data("{not valid json".utf8)

        let result = AppStateDecoder.decode(data)

        XCTAssertEqual(result, .corrupt)
    }

    func testAppStateDecoderReturnsCorruptWhenSchemaVersionKeyIsMissing() {
        let json = """
        {"event":{}}
        """
        let data = Data(json.utf8)

        let result = AppStateDecoder.decode(data)

        XCTAssertEqual(result, .corrupt)
    }
}
