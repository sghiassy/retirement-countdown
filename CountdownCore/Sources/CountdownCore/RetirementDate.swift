import Foundation

public struct RetirementDate: Equatable, Hashable, Codable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year; self.month = month; self.day = day
    }

    public init?(string: String) {
        let parts = string.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2])
        else { return nil }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let comps = DateComponents(year: y, month: m, day: d)
        guard let resolved = cal.date(from: comps),
              (1...12).contains(m),
              (1...31).contains(d)
        else { return nil }

        // Verify the date wasn't silently rolled over (e.g. Sep 31 → Oct 1)
        let back = cal.dateComponents([.year, .month, .day], from: resolved)
        guard back.year == y, back.month == m, back.day == d else { return nil }

        year = y; month = m; day = d
    }

    public var isoString: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func from(date: Date, calendar: Calendar = {
        var c = Calendar(identifier: .gregorian); c.timeZone = .current; return c
    }()) -> RetirementDate {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return RetirementDate(year: comps.year!, month: comps.month!, day: comps.day!)
    }
}
