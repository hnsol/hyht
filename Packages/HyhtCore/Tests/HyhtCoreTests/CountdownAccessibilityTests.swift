import XCTest
@testable import HyhtCore

final class CountdownAccessibilityTests: XCTestCase {
    private let en = Locale(identifier: "en")
    private let ja = Locale(identifier: "ja")

    private func snapshot(
        mode: CountdownDisplayMode,
        primaryText: String,
        clockHour: Int? = nil,
        clockMinute: Int? = nil
    ) -> CountdownSnapshot {
        CountdownSnapshot(mode: mode, primaryText: primaryText, clockHour: clockHour, clockMinute: clockMinute)
    }

    // MARK: - week

    func testWeekEnglish() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .week, primaryText: "4.28"),
            eventName: "Grandma's Party",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "4.28 weeks until Grandma's Party")
    }

    func testWeekJapanese() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .week, primaryText: "4.28"),
            eventName: "おばあちゃんのパーティー",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "おばあちゃんのパーティーまで残り4.28週間")
    }

    // MARK: - day

    func testDayEnglish() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .day, primaryText: "3.50"),
            eventName: "Trip",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "3.50 days until Trip")
    }

    func testDayJapanese() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .day, primaryText: "3.50"),
            eventName: "旅行",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "旅行まで残り3.50日")
    }

    // MARK: - hour

    func testHourEnglish() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .hour, primaryText: "30.5"),
            eventName: "Meeting",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "30.5 hours until Meeting")
    }

    func testHourJapanese() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .hour, primaryText: "30.5"),
            eventName: "会議",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "会議まで残り30.5時間")
    }

    // MARK: - clock

    func testClockEnglish() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .clock, primaryText: "3:07", clockHour: 3, clockMinute: 7),
            eventName: "Dinner",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "Dinner, 3 hours 7 minutes remaining")
    }

    func testClockJapanese() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .clock, primaryText: "3:07", clockHour: 3, clockMinute: 7),
            eventName: "夕食",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "夕食、残り3時間7分")
    }

    // MARK: - min

    func testMinEnglish() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .min, primaryText: "45"),
            eventName: "Call",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "Call, 45 minutes remaining")
    }

    func testMinJapanese() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .min, primaryText: "45"),
            eventName: "通話",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "通話、残り45分")
    }

    // MARK: - done

    func testDoneEnglishWithMessage() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .done, primaryText: ""),
            eventName: "Birthday",
            completionMessage: "Done",
            locale: en
        )
        XCTAssertEqual(label, "Birthday is complete. Done")
    }

    func testDoneJapaneseWithMessage() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .done, primaryText: ""),
            eventName: "誕生日",
            completionMessage: "やったね！",
            locale: ja
        )
        XCTAssertEqual(label, "誕生日は完了。やったね！")
    }

    func testDoneEnglishWithoutMessage() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .done, primaryText: ""),
            eventName: "Birthday",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "Birthday is complete.")
    }

    func testDoneJapaneseWithBlankMessage() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .done, primaryText: ""),
            eventName: "誕生日",
            completionMessage: "   ",
            locale: ja
        )
        XCTAssertEqual(label, "誕生日は完了。")
    }

    // MARK: - empty event name

    func testWeekEnglishEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .week, primaryText: "4.12"),
            eventName: "   ",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "4.12 weeks remaining")
    }

    func testWeekJapaneseEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .week, primaryText: "4.12"),
            eventName: "",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "残り4.12週間")
    }

    func testDayEnglishEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .day, primaryText: "3.50"),
            eventName: "",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "3.50 days remaining")
    }

    func testDayJapaneseEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .day, primaryText: "3.50"),
            eventName: "",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "残り3.50日")
    }

    func testHourEnglishEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .hour, primaryText: "30.5"),
            eventName: "",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "30.5 hours remaining")
    }

    func testHourJapaneseEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .hour, primaryText: "30.5"),
            eventName: "",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "残り30.5時間")
    }

    func testClockEnglishEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .clock, primaryText: "3:07", clockHour: 3, clockMinute: 7),
            eventName: "",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "3 hours 7 minutes remaining")
    }

    func testClockJapaneseEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .clock, primaryText: "3:07", clockHour: 3, clockMinute: 7),
            eventName: "",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "残り3時間7分")
    }

    func testMinEnglishEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .min, primaryText: "45"),
            eventName: "",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "45 minutes remaining")
    }

    func testMinJapaneseEmptyName() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .min, primaryText: "45"),
            eventName: "",
            completionMessage: nil,
            locale: ja
        )
        XCTAssertEqual(label, "残り45分")
    }

    func testDoneEnglishEmptyNameWithMessage() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .done, primaryText: ""),
            eventName: "",
            completionMessage: "Done",
            locale: en
        )
        XCTAssertEqual(label, "Complete. Done")
    }

    func testDoneJapaneseEmptyNameWithMessage() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .done, primaryText: ""),
            eventName: "",
            completionMessage: "やったね！",
            locale: ja
        )
        XCTAssertEqual(label, "完了。やったね！")
    }

    func testDoneEnglishEmptyNameWithoutMessage() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .done, primaryText: ""),
            eventName: "   ",
            completionMessage: nil,
            locale: en
        )
        XCTAssertEqual(label, "Complete.")
    }

    func testDoneJapaneseEmptyNameWithoutMessage() {
        let label = CountdownAccessibility.label(
            snapshot: snapshot(mode: .done, primaryText: ""),
            eventName: "",
            completionMessage: "   ",
            locale: ja
        )
        XCTAssertEqual(label, "完了。")
    }
}
