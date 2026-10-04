import XCTest
@testable import CountdownCore

final class HolidayTests: XCTestCase {

    func testHolidayWithoutLabelRoundTrip() throws {
        let h = Holiday(date: RetirementDate(string: "2026-07-04")!, label: nil)
        let data = try JSONEncoder().encode(h)
        let decoded = try JSONDecoder().decode(Holiday.self, from: data)
        XCTAssertEqual(h, decoded)
        XCTAssertNil(decoded.label)
    }

    func testHolidayWithLabelRoundTrip() throws {
        let h = Holiday(date: RetirementDate(string: "2026-12-24")!, label: "Christmas Eve")
        let data = try JSONEncoder().encode(h)
        let decoded = try JSONDecoder().decode(Holiday.self, from: data)
        XCTAssertEqual(h, decoded)
        XCTAssertEqual(decoded.label, "Christmas Eve")
    }

    func testHolidayHashable() {
        let d = RetirementDate(string: "2026-12-24")!
        let a = Holiday(date: d, label: "A")
        let b = Holiday(date: d, label: "A")
        var set: Set<Holiday> = []
        set.insert(a)
        set.insert(b)
        XCTAssertEqual(set.count, 1)
    }

    func testDifferentLabelsAreDifferentHolidays() {
        let d = RetirementDate(string: "2026-12-24")!
        XCTAssertNotEqual(Holiday(date: d, label: "A"), Holiday(date: d, label: "B"))
    }
}
