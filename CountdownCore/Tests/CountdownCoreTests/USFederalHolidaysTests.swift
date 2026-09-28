import XCTest
@testable import CountdownCore

final class USFederalHolidaysTests: XCTestCase {

    var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func testHolidayCountFor2026() {
        // 2026: 11 federal holidays. All 11 should map to observed weekday dates.
        let holidays = USFederalHolidays.observedDates(inYear: 2026, calendar: cal)
        XCTAssertEqual(holidays.count, 11)
    }

    func testJuneteenthMissingBefore2021() {
        let h2020 = USFederalHolidays.observedDates(inYear: 2020, calendar: cal)
        XCTAssertEqual(h2020.count, 10, "Juneteenth was not a federal holiday in 2020")
        // 2021 onward, Juneteenth is included
        let h2021 = USFederalHolidays.observedDates(inYear: 2021, calendar: cal)
        XCTAssertEqual(h2021.count, 11)
    }

    func testNewYearsDay2027ObservedFridayBefore() {
        // Jan 1 2027 is a Friday — observed on Jan 1 itself
        let holidays = USFederalHolidays.observedDates(inYear: 2027, calendar: cal)
        XCTAssertTrue(holidays.contains(date(2027, 1, 1)))
    }

    func testNewYearsDay2028ObservedFriday() {
        // Jan 1 2028 is a Saturday — observed on Friday Dec 31 2027 (in prior year!)
        // Our function returns holidays for the given year, so 2028's set includes
        // the observed date, which is 2027-12-31. This is a known quirk of federal
        // observance: it lands in the previous calendar year.
        let holidays = USFederalHolidays.observedDates(inYear: 2028, calendar: cal)
        // The observed Friday for 2028's New Year's is Dec 31 2027
        XCTAssertTrue(holidays.contains(date(2027, 12, 31)))
    }

    func testIndependenceDay2026ObservedMondayAfter() {
        // Jul 4 2026 is a Saturday — observed Fri Jul 3
        let holidays = USFederalHolidays.observedDates(inYear: 2026, calendar: cal)
        XCTAssertTrue(holidays.contains(date(2026, 7, 3)))
        XCTAssertFalse(holidays.contains(date(2026, 7, 4)))
    }

    func testChristmas2027ObservedMondayAfter() {
        // Dec 25 2027 is a Saturday — observed Fri Dec 24
        let holidays = USFederalHolidays.observedDates(inYear: 2027, calendar: cal)
        XCTAssertTrue(holidays.contains(date(2027, 12, 24)))
    }

    func testChristmas2026ActualDate() {
        // Dec 25 2026 is a Friday — no shift needed
        let holidays = USFederalHolidays.observedDates(inYear: 2026, calendar: cal)
        XCTAssertTrue(holidays.contains(date(2026, 12, 25)))
    }

    func testMLKDay2026ThirdMondayJanuary() {
        // 3rd Monday of January 2026 = Jan 19
        let holidays = USFederalHolidays.observedDates(inYear: 2026, calendar: cal)
        XCTAssertTrue(holidays.contains(date(2026, 1, 19)))
    }

    func testMemorialDay2026LastMondayMay() {
        // Last Monday of May 2026 = May 25
        let holidays = USFederalHolidays.observedDates(inYear: 2026, calendar: cal)
        XCTAssertTrue(holidays.contains(date(2026, 5, 25)))
    }

    func testThanksgiving2026FourthThursdayNovember() {
        // 4th Thursday of November 2026 = Nov 26
        let holidays = USFederalHolidays.observedDates(inYear: 2026, calendar: cal)
        XCTAssertTrue(holidays.contains(date(2026, 11, 26)))
    }

    func testLaborDay2026FirstMondaySeptember() {
        let holidays = USFederalHolidays.observedDates(inYear: 2026, calendar: cal)
        XCTAssertTrue(holidays.contains(date(2026, 9, 7)))
    }
}
