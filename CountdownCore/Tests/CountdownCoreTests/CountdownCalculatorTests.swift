import XCTest
@testable import CountdownCore

final class CountdownCalculatorTests: XCTestCase {

    let eastern = TimeZone(identifier: "America/New_York")!
    let pacific = TimeZone(identifier: "America/Los_Angeles")!
    let utc     = TimeZone(secondsFromGMT: 0)!

    func isoDate(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: iso)!
    }

    // MARK: - Basic states

    func testCountingDays() {
        let retirement = RetirementDate(string: "2027-09-01")!
        // 2026-09-25T12:00:00Z = noon UTC, which is still Sep 25 in Eastern (-4h)
        let now = isoDate("2026-09-25T16:00:00Z")
        // 2026-09-25 → 2027-09-01 = 341 days
        let state = CountdownCalculator.state(for: retirement, on: now, in: eastern)
        XCTAssertEqual(state, .counting(days: 341))
    }

    func testTodayIsTheDay() {
        let retirement = RetirementDate(string: "2027-09-01")!
        let now = isoDate("2027-09-01T12:00:00Z")
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc), .today)
    }

    func testRetired() {
        let retirement = RetirementDate(string: "2027-09-01")!
        let now = isoDate("2027-09-02T12:00:00Z")
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc), .retired)
    }

    func testUnconfigured() {
        XCTAssertEqual(CountdownCalculator.state(for: nil, on: Date(), in: utc), .unconfigured)
    }

    func testTomorrow() {
        let retirement = RetirementDate(string: "2027-09-02")!
        let now = isoDate("2027-09-01T12:00:00Z")
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc), .counting(days: 1))
    }

    func testDaysRemainingConvenience() {
        let retirement = RetirementDate(string: "2027-09-01")!
        let now = isoDate("2027-08-31T12:00:00Z")
        XCTAssertEqual(CountdownCalculator.daysRemaining(for: retirement, on: now, in: utc), 1)
    }

    func testDaysRemainingNilWhenToday() {
        let retirement = RetirementDate(string: "2027-09-01")!
        let now = isoDate("2027-09-01T12:00:00Z")
        XCTAssertNil(CountdownCalculator.daysRemaining(for: retirement, on: now, in: utc))
    }

    // MARK: - Calendar edge cases

    func testLeapDay() {
        let retirement = RetirementDate(string: "2028-02-29")!
        let now = isoDate("2028-02-28T12:00:00Z")
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc), .counting(days: 1))
    }

    func testLeapDayIsTheDay() {
        let retirement = RetirementDate(string: "2028-02-29")!
        let now = isoDate("2028-02-29T06:00:00Z")
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc), .today)
    }

    func testEndOfMonthTransition() {
        let retirement = RetirementDate(string: "2027-03-01")!
        let now = isoDate("2027-02-28T12:00:00Z")
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc), .counting(days: 1))
    }

    func testEndOfYearTransition() {
        let retirement = RetirementDate(string: "2027-01-01")!
        let now = isoDate("2026-12-31T12:00:00Z")
        XCTAssertEqual(CountdownCalculator.state(for: retirement, on: now, in: utc), .counting(days: 1))
    }

    func testLargeFutureValue() {
        let retirement = RetirementDate(string: "2099-12-31")!
        let now = isoDate("2026-01-01T12:00:00Z")
        guard case .counting(let days) = CountdownCalculator.state(for: retirement, on: now, in: utc) else {
            return XCTFail("Expected counting state")
        }
        XCTAssertGreaterThan(days, 20_000)
    }

    // MARK: - DST correctness (calendar days, not seconds)

    func testDSTSpringForward() {
        // US Eastern DST spring-forward: 2027-03-14 02:00 → 03:00
        // Noon on Mar 13 Eastern = 17:00 UTC
        let beforeDST = isoDate("2027-03-13T17:00:00Z")
        // Noon on Mar 15 Eastern = 16:00 UTC (now on EDT, UTC-4)
        let afterDST  = isoDate("2027-03-15T16:00:00Z")
        let retirement = RetirementDate(string: "2027-09-01")!

        guard case .counting(let before) = CountdownCalculator.state(for: retirement, on: beforeDST, in: eastern),
              case .counting(let after)  = CountdownCalculator.state(for: retirement, on: afterDST,  in: eastern)
        else { return XCTFail("Expected counting in both cases") }

        // Two calendar days passed, count must differ by exactly 2
        XCTAssertEqual(before - after, 2)
    }

    func testDSTFallBack() {
        // US Eastern fall-back: 2027-11-07 02:00 → 01:00
        // Noon on Oct 31 Eastern (EDT, UTC-4) = 16:00 UTC
        let beforeFall = isoDate("2027-10-31T16:00:00Z")
        // Noon on Nov 2 Eastern (EST, UTC-5) = 17:00 UTC
        let afterFall  = isoDate("2027-11-02T17:00:00Z")
        let retirement = RetirementDate(string: "2028-09-01")!

        guard case .counting(let before) = CountdownCalculator.state(for: retirement, on: beforeFall, in: eastern),
              case .counting(let after)  = CountdownCalculator.state(for: retirement, on: afterFall,  in: eastern)
        else { return XCTFail("Expected counting in both cases") }

        XCTAssertEqual(before - after, 2)
    }

    // MARK: - Time zone travel

    func testTimeZoneTravelDiffersAtMostOneDay() {
        let retirement = RetirementDate(string: "2027-09-01")!
        // 11:30 PM Eastern = already next calendar day in Tokyo (UTC+9)
        let instant = isoDate("2027-03-01T04:30:00Z") // 11:30 PM ET (UTC-5)
        let tokyo   = TimeZone(identifier: "Asia/Tokyo")!

        guard case .counting(let daysET) = CountdownCalculator.state(for: retirement, on: instant, in: eastern),
              case .counting(let daysTK) = CountdownCalculator.state(for: retirement, on: instant, in: tokyo)
        else { return XCTFail("Expected counting in both TZs") }

        XCTAssertLessThanOrEqual(abs(daysET - daysTK), 1)
    }
}
