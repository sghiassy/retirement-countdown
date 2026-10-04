import XCTest
@testable import CountdownCore

final class CountdownPreferencesTests: XCTestCase {

    func testDefaultsAreCalendarDaysWithNoAdjustments() {
        let prefs = CountdownPreferences()
        XCTAssertEqual(prefs.mode, .calendarDays)
        XCTAssertEqual(prefs.ptoDays, 0)
        XCTAssertTrue(prefs.disabledFederalHolidays.isEmpty)
        XCTAssertTrue(prefs.customHolidays.isEmpty)
    }

    func testEnabledFederalHolidaysExcludesDisabled() {
        let prefs = CountdownPreferences(disabledFederalHolidays: [.columbusDay, .veteransDay])
        XCTAssertEqual(prefs.enabledFederalHolidays.count, 9)
        XCTAssertFalse(prefs.enabledFederalHolidays.contains(.columbusDay))
        XCTAssertFalse(prefs.enabledFederalHolidays.contains(.veteransDay))
    }

    func testJSONRoundTripDefault() {
        let prefs = CountdownPreferences()
        guard let json = prefs.encodedJSON(),
              let decoded = CountdownPreferences(json: json) else {
            return XCTFail("Encode/decode failed")
        }
        XCTAssertEqual(prefs, decoded)
    }

    func testJSONRoundTripFullyPopulated() {
        let holiday = Holiday(
            date: RetirementDate(string: "2026-12-24")!,
            label: "Christmas Eve Office Closed"
        )
        let prefs = CountdownPreferences(
            mode: .workdays,
            ptoDays: 15,
            disabledFederalHolidays: [.columbusDay, .presidentsDay],
            customHolidays: [holiday]
        )
        guard let json = prefs.encodedJSON(),
              let decoded = CountdownPreferences(json: json) else {
            return XCTFail("Encode/decode failed")
        }
        XCTAssertEqual(prefs, decoded)
        XCTAssertEqual(decoded.ptoDays, 15)
        XCTAssertEqual(decoded.customHolidays.first?.label, "Christmas Eve Office Closed")
    }

    func testJSONInvalidReturnsNil() {
        XCTAssertNil(CountdownPreferences(json: "{not valid json"))
    }
}
