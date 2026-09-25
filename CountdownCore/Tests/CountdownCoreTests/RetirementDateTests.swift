import XCTest
@testable import CountdownCore

final class RetirementDateTests: XCTestCase {

    func testParseValidDate() {
        let d = RetirementDate(string: "2027-09-01")!
        XCTAssertEqual(d.year, 2027)
        XCTAssertEqual(d.month, 9)
        XCTAssertEqual(d.day, 1)
    }

    func testRoundTrip() {
        let d = RetirementDate(string: "2027-09-01")!
        XCTAssertEqual(d.isoString, "2027-09-01")
    }

    func testLeapDayValid() {
        XCTAssertNotNil(RetirementDate(string: "2028-02-29"))
    }

    func testInvalidMonth() {
        XCTAssertNil(RetirementDate(string: "2027-13-01"))
    }

    func testInvalidDay() {
        XCTAssertNil(RetirementDate(string: "2027-09-31"))
    }

    func testMalformedString() {
        XCTAssertNil(RetirementDate(string: "not-a-date"))
        XCTAssertNil(RetirementDate(string: "2027/09/01"))
        XCTAssertNil(RetirementDate(string: ""))
    }

    func testFromDate() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = DateComponents(year: 2027, month: 9, day: 1)
        let date = cal.date(from: comps)!
        let rd = RetirementDate.from(date: date, calendar: cal)
        XCTAssertEqual(rd.isoString, "2027-09-01")
    }

    func testFromDateTimezoneEdge() {
        // A date at 00:30 UTC is still "Aug 31" in UTC-1 — confirm from() uses the provided calendar's timezone
        var utcMinus1 = Calendar(identifier: .gregorian)
        utcMinus1.timeZone = TimeZone(secondsFromGMT: -3600)!

        // 2027-09-01 00:30 UTC = 2027-08-31 23:30 in UTC-1
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let dateUTC = formatter.date(from: "2027-09-01T00:30:00Z")!

        let rd = RetirementDate.from(date: dateUTC, calendar: utcMinus1)
        XCTAssertEqual(rd.isoString, "2027-08-31")
    }

    func testRetirementRecordCoding() throws {
        let record = RetirementRecord(
            retirementDate: RetirementDate(string: "2027-09-01"),
            changeRevision: 3,
            schemaVersion: 1
        )
        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(RetirementRecord.self, from: data)
        XCTAssertEqual(decoded.retirementDate?.isoString, "2027-09-01")
        XCTAssertEqual(decoded.changeRevision, 3)
    }

    func testIncrementingRevision() {
        let record = RetirementRecord(retirementDate: nil, changeRevision: 2, schemaVersion: 1)
        let updated = record.incrementingRevision(with: RetirementDate(string: "2027-09-01")!)
        XCTAssertEqual(updated.changeRevision, 3)
        XCTAssertEqual(updated.retirementDate?.isoString, "2027-09-01")
    }
}
