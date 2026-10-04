import XCTest
@testable import CountdownCore

final class CountdownDisplayModelTests: XCTestCase {

    let utc = TimeZone(secondsFromGMT: 0)!

    func utcNoon(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: iso + "T12:00:00Z")!
    }

    func testUnconfiguredWhenNilDate() {
        XCTAssertEqual(CountdownDisplayModel.make(from: nil, on: Date(), in: utc), .unconfigured)
    }

    func testCountingModel() {
        let retirement = RetirementDate(string: "2027-09-01")!
        let now = utcNoon("2026-09-25")
        let model = CountdownDisplayModel.make(from: retirement, on: now, in: utc)
        // 341 days, full date formatted with en_US locale
        guard case .counting(let days, _) = model else {
            return XCTFail("Expected .counting, got \(model)")
        }
        XCTAssertEqual(days, 341)
    }

    func testTodayModel() {
        let retirement = RetirementDate(string: "2026-09-25")!
        let now = utcNoon("2026-09-25")
        let model = CountdownDisplayModel.make(from: retirement, on: now, in: utc)
        guard case .today(let fullDate) = model else {
            return XCTFail("Expected .today, got \(model)")
        }
        XCTAssertFalse(fullDate.isEmpty)
    }

    func testRetiredModel() {
        let retirement = RetirementDate(string: "2026-09-24")!
        let now = utcNoon("2026-09-25")
        XCTAssertEqual(CountdownDisplayModel.make(from: retirement, on: now, in: utc), .retired)
    }

    func testFullDateFormat() {
        let rd = RetirementDate(string: "2027-09-01")!
        let result = CountdownFormatter.fullDateString(rd, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(result, "September 1, 2027")
    }

    func testDaysStringFormatting() {
        XCTAssertEqual(CountdownFormatter.daysString(341), "341")
        XCTAssertEqual(CountdownFormatter.daysString(1), "1")
        XCTAssertEqual(CountdownFormatter.daysString(0), "0")
    }

    func testAccessibilityLabelCounting() {
        XCTAssertEqual(
            CountdownFormatter.accessibilityLabel(for: .counting(days: 341, fullDate: "September 1, 2027")),
            "341 days until retirement"
        )
    }

    func testAccessibilityLabelToday() {
        XCTAssertEqual(
            CountdownFormatter.accessibilityLabel(for: .today(fullDate: "September 1, 2027")),
            "Today is the day"
        )
    }

    func testAccessibilityLabelRetired() {
        XCTAssertEqual(CountdownFormatter.accessibilityLabel(for: .retired), "Retired")
    }

    func testAccessibilityLabelUnconfigured() {
        XCTAssertEqual(CountdownFormatter.accessibilityLabel(for: .unconfigured), "Set retirement date")
    }

    // MARK: - Preferences flow through DisplayModel

    func testPreferencesFlowThroughMakeAppliesPTO() {
        // 4 workdays - 2 PTO = 2 workdays. Verifies preferences propagate all the way
        // through DisplayModel.make(), not just through CountdownCalculator.state().
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcNoon("2026-09-28")
        let prefs = CountdownPreferences(mode: .workdays, ptoDays: 2)
        let model = CountdownDisplayModel.make(from: retirement, on: now, in: utc, preferences: prefs)
        guard case .counting(let days, _) = model else {
            return XCTFail("Expected .counting, got \(model)")
        }
        XCTAssertEqual(days, 2)
    }

    func testAccessibilityLabelHonorsPreferencesMode() {
        let model: CountdownDisplayModel = .counting(days: 10, fullDate: "October 2, 2026")
        let workdaysPrefs = CountdownPreferences(mode: .workdays)
        XCTAssertEqual(
            CountdownFormatter.accessibilityLabel(for: model, preferences: workdaysPrefs),
            "10 workdays until retirement"
        )
    }
}
