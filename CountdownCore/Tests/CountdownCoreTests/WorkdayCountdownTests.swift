import XCTest
@testable import CountdownCore

final class WorkdayCountdownTests: XCTestCase {

    let utc = TimeZone(secondsFromGMT: 0)!

    private func utcDate(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    // MARK: - Basic mode-agnostic state transitions

    func testStateTodayWorksInWorkdayMode() {
        let retirement = RetirementDate(string: "2026-09-25")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc, mode: .workdays), .today)
    }

    func testStateRetiredWorksInWorkdayMode() {
        let retirement = RetirementDate(string: "2026-09-24")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc, mode: .workdays), .retired)
    }

    func testStateUnconfiguredWorksInWorkdayMode() {
        XCTAssertEqual(CountdownCalculator.state(for: nil, on: Date(), in: utc, mode: .workdays), .unconfigured)
    }

    // MARK: - Simple workday counting

    func testFridayToMondayIsOneWorkday() {
        // Fri 2026-09-25 → Mon 2026-09-28 = 1 workday (Monday), excluding today
        let retirement = RetirementDate(string: "2026-09-28")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, mode: .workdays),
            .counting(days: 1)
        )
    }

    func testMondayToFridayIsFourWorkdays() {
        // Mon 2026-09-28 → Fri 2026-10-02 = Tue, Wed, Thu, Fri = 4 workdays
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 28)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, mode: .workdays),
            .counting(days: 4)
        )
    }

    func testFridayToSaturdayIsZeroWorkdays() {
        // Fri 2026-09-25 → Sat 2026-09-26 = 0 workdays (Sat is a weekend)
        let retirement = RetirementDate(string: "2026-09-26")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, mode: .workdays),
            .counting(days: 0)
        )
    }

    // MARK: - Holidays excluded

    func testWorkdaysExcludeThanksgiving() {
        // Wed 2026-11-25 → Fri 2026-11-27 = Thu Nov 26 (Thanksgiving), Fri Nov 27
        // Thanksgiving is excluded, so 1 workday (Fri).
        let retirement = RetirementDate(string: "2026-11-27")!
        let now = utcDate(2026, 11, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, mode: .workdays),
            .counting(days: 1)
        )
    }

    func testWorkdaysExcludeChristmasObserved() {
        // Dec 25 2027 is a Saturday — federal offices closed on Fri Dec 24.
        // Thu Dec 23 2027 → Mon Dec 27 2027: Fri (Dec 24 observed Christmas, excluded),
        // Sat/Sun (weekend), Mon Dec 27 = 1 workday.
        let retirement = RetirementDate(string: "2027-12-27")!
        let now = utcDate(2027, 12, 23)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, mode: .workdays),
            .counting(days: 1)
        )
    }

    // MARK: - Calendar-days mode still works after refactor

    func testCalendarDaysModeStillCountsAllDays() {
        // Fri 2026-09-25 → Fri 2026-10-02 = 7 calendar days
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc, mode: .calendarDays),
            .counting(days: 7)
        )
    }

    func testDefaultModeIsCalendarDays() {
        let retirement = RetirementDate(string: "2026-10-02")!
        let now = utcDate(2026, 9, 25)
        XCTAssertEqual(
            CountdownCalculator.state(for: retirement, on: now, in: utc),
            .counting(days: 7)
        )
    }

    // MARK: - Longer horizons

    func testWorkdaysOverAYear() {
        // Sep 25 2026 (Fri) → Sep 24 2027 (Fri) - approximately 250 workdays minus ~11 holidays
        // Total calendar days = 364. Weeks ≈ 52. Workdays ≈ 52 * 5 = 260 minus weekends already excluded.
        // Actual: count Mon-Fri days from Sep 26 2026 through Sep 24 2027, minus federal holidays in range.
        let retirement = RetirementDate(string: "2027-09-24")!
        let now = utcDate(2026, 9, 25)
        guard case .counting(let workdays) = CountdownCalculator.state(for: retirement, on: now, in: utc, mode: .workdays) else {
            return XCTFail("Expected counting state")
        }
        // Sanity range: not less than 240 and not more than 260 for a year of workdays.
        XCTAssertGreaterThan(workdays, 240)
        XCTAssertLessThan(workdays, 260)
    }
}
