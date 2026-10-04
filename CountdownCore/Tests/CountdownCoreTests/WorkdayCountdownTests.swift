import XCTest
@testable import CountdownCore

final class WorkdayCountdownTests: XCTestCase {

    let utc = TimeZone(secondsFromGMT: 0)!

    private func utcDate(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    private var workdaysPrefs: CountdownPreferences { CountdownPreferences(mode: .workdays) }
    private var calendarPrefs: CountdownPreferences { CountdownPreferences(mode: .calendarDays) }

    // MARK: - Basic mode-agnostic state transitions

    func testStateTodayWorksInWorkdayMode() {
        let retirement = RetirementDate(string: "2026-09-25")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: workdaysPrefs), .today)
    }

    func testStateRetiredWorksInWorkdayMode() {
        let retirement = RetirementDate(string: "2026-09-24")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: workdaysPrefs), .retired)
    }

    func testStateUnconfiguredWorksInWorkdayMode() {
        XCTAssertEqual(CountdownCalculator.state(for: nil, on: Date(), in: utc, preferences: workdaysPrefs), .unconfigured)
    }

    // MARK: - Simple workday counting

    func testFridayToMondayIsOneWorkday() {
        let retirement = RetirementDate(string: "2026-09-28")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: workdaysPrefs),
            .counting(days: 1)
        )
    }

    func testMondayToFridayIsFourWorkdays() {
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 28)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: workdaysPrefs),
            .counting(days: 4)
        )
    }

    func testFridayToSaturdayIsZeroWorkdays() {
        let retirement = RetirementDate(string: "2026-09-26")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: workdaysPrefs),
            .counting(days: 0)
        )
    }

    // MARK: - Holidays excluded

    func testWorkdaysExcludeThanksgiving() {
        let retirement = RetirementDate(string: "2026-11-27")!
        let now = utcDate(2026, 11, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: workdaysPrefs),
            .counting(days: 1)
        )
    }

    func testWorkdaysExcludeChristmasObserved() {
        let retirement = RetirementDate(string: "2027-12-27")!
        let now = utcDate(2027, 12, 23)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: workdaysPrefs),
            .counting(days: 1)
        )
    }

    // MARK: - Calendar-days mode still works

    func testCalendarDaysModeStillCountsAllDays() {
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: calendarPrefs),
            .counting(days: 7)
        )
    }

    func testDefaultPreferencesIsCalendarDays() {
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc),
            .counting(days: 7)
        )
    }

    func testWorkdaysOverAYear() {
        let retirement = RetirementDate(string: "2027-09-24")!
        let now = utcDate(2026, 9, 25)
        guard case .counting(let workdays) = CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: workdaysPrefs) else {
            return XCTFail("Expected counting state")
        }
        XCTAssertGreaterThan(workdays, 240)
        XCTAssertLessThan(workdays, 260)
    }

    // MARK: - PTO offset

    func testPTOReducesWorkdayCount() {
        // Mon → Fri = 4 workdays; PTO 2 → 2 workdays remaining.
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 28)
        let prefs = CountdownPreferences(mode: .workdays, ptoDays: 2)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: prefs),
            .counting(days: 2)
        )
    }

    func testPTOClampsAtZero() {
        // 4 workdays, PTO 10 → clamp at 0.
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 28)
        let prefs = CountdownPreferences(mode: .workdays, ptoDays: 10)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: prefs),
            .counting(days: 0)
        )
    }

    func testPTOIgnoredInCalendarDaysMode() {
        // 7 calendar days, PTO 3 → still 7.
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 25)
        let prefs = CountdownPreferences(mode: .calendarDays, ptoDays: 3)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: prefs),
            .counting(days: 7)
        )
    }

    // MARK: - Disabled federal holidays

    func testDisablingThanksgivingAddsItBackAsAWorkday() {
        // Same window as testWorkdaysExcludeThanksgiving (1 workday with Thanksgiving excluded).
        // Disable Thanksgiving → both Thu and Fri count = 2 workdays.
        let retirement = RetirementDate(string: "2026-11-27")!
        let now = utcDate(2026, 11, 25)
        let prefs = CountdownPreferences(mode: .workdays, disabledFederalHolidays: [.thanksgiving])
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: prefs),
            .counting(days: 2)
        )
    }

    // MARK: - Custom holidays

    func testCustomHolidayExcludedFromCount() {
        // Mon → Fri = 4 workdays. Add Wed as a custom holiday → 3 workdays.
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 28)
        let customDate = RetirementDate(string: "2026-09-30")! // Wed
        let prefs = CountdownPreferences(
            mode: .workdays,
            customHolidays: [Holiday(date: customDate, label: "Company Day")]
        )
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: prefs),
            .counting(days: 3)
        )
    }

    func testCustomHolidayDeduplicatesWithFederal() {
        // 2026-11-26 is Thanksgiving (already excluded). Adding it as a custom holiday is a no-op.
        let retirement = RetirementDate(string: "2026-11-27")!
        let now = utcDate(2026, 11, 25)
        let dup = RetirementDate(string: "2026-11-26")!
        let prefs = CountdownPreferences(
            mode: .workdays,
            customHolidays: [Holiday(date: dup, label: nil)]
        )
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: prefs),
            .counting(days: 1)
        )
    }

    // MARK: - Defensive edge cases

    func testNegativePTOIsClampedAndDoesNotIncreaseCount() {
        // Mon → Fri = 4 workdays. Negative PTO should be treated as 0, not add days.
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 28)
        let prefs = CountdownPreferences(mode: .workdays, ptoDays: -5)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: prefs),
            .counting(days: 4)
        )
    }

    func testCustomHolidayOnWeekendHasNoEffect() {
        // Window: Fri 2026-09-25 → Fri 2026-10-02. Weekdays in (start, end] = Mon 28, Tue 29,
        // Wed 30, Thu Oct 1, Fri Oct 2 = 5 workdays. Add Sat 2026-09-26 as a custom holiday —
        // it's already excluded as a weekend, so the count must still be 5 (not 4).
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 25)
        let saturdayInWindow = RetirementDate(string: "2026-09-26")!
        let prefs = CountdownPreferences(
            mode: .workdays,
            customHolidays: [Holiday(date: saturdayInWindow, label: "Weekend custom")]
        )
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: prefs),
            .counting(days: 5)
        )
    }

    // MARK: - Hybrid test from the plan

    func testHybridThanksgivingOffCustomHolidayPlusPTO() {
        // Window: Fri 2026-11-20 → Fri 2026-11-27 (one calendar week + 1 day)
        // Mon-Fri in that window: Mon Nov 23, Tue Nov 24, Wed Nov 25, Thu Nov 26, Fri Nov 27 = 5 workdays
        // Disable Thanksgiving (Thu Nov 26 counted) + custom holiday Mon Nov 23 (excluded) + 2 PTO:
        // 5 workdays - 1 (custom Mon) - 2 (PTO) = 2
        let retirement = RetirementDate(string: "2026-11-27")!
        let now = utcDate(2026, 11, 20)
        let custom = RetirementDate(string: "2026-11-23")!
        let prefs = CountdownPreferences(
            mode: .workdays,
            ptoDays: 2,
            disabledFederalHolidays: [.thanksgiving],
            customHolidays: [Holiday(date: custom, label: "Pre-holiday day off")]
        )
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, preferences: prefs),
            .counting(days: 2)
        )
    }
}
