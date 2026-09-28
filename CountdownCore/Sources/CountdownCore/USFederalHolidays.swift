import Foundation

/// US federal holidays with observed-date rules.
/// Returns dates on which federal offices are closed — the actual date if it's a weekday,
/// or the observed weekday if the actual date falls on a weekend.
public enum USFederalHolidays {

    /// Set of observed federal holiday dates falling on weekdays for `year`.
    /// Weekend-date holidays are shifted to the observed weekday (Sat→Fri, Sun→Mon).
    /// Juneteenth is only included from 2021 onward (when it was established).
    public static func observedDates(inYear year: Int, calendar: Calendar) -> Set<Date> {
        var cal = calendar
        cal.timeZone = calendar.timeZone

        var dates = Set<Date>()

        // Fixed-date holidays — apply observed rule if they fall on Sat/Sun.
        var fixed: [(month: Int, day: Int)] = [
            (1, 1),     // New Year's Day
            (7, 4),     // Independence Day
            (11, 11),   // Veterans Day
            (12, 25),   // Christmas Day
        ]
        if year >= 2021 { fixed.append((6, 19)) } // Juneteenth
        for h in fixed {
            if let d = observedDate(year: year, month: h.month, day: h.day, calendar: cal) {
                dates.insert(d)
            }
        }

        // Nth-weekday holidays — always fall on a weekday, no observed rule needed.
        // ordinal: positive N = Nth occurrence, -1 = last occurrence.
        // weekday: 1=Sun, 2=Mon, ..., 5=Thu, 7=Sat.
        let nth: [(month: Int, weekday: Int, ordinal: Int)] = [
            (1, 2, 3),    // MLK Day        — 3rd Monday of January
            (2, 2, 3),    // Presidents Day — 3rd Monday of February
            (5, 2, -1),   // Memorial Day   — last Monday of May
            (9, 2, 1),    // Labor Day      — 1st Monday of September
            (10, 2, 2),   // Columbus Day   — 2nd Monday of October
            (11, 5, 4),   // Thanksgiving   — 4th Thursday of November
        ]
        for h in nth {
            if let d = nthWeekday(year: year, month: h.month, weekday: h.weekday, ordinal: h.ordinal, calendar: cal) {
                dates.insert(d)
            }
        }

        return dates
    }

    /// Returns the observed weekday date for a fixed-date holiday.
    /// If the date lands on Saturday, returns the Friday before; on Sunday, the Monday after.
    private static func observedDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        let comps = DateComponents(year: year, month: month, day: day)
        guard let actual = calendar.date(from: comps) else { return nil }
        let weekday = calendar.component(.weekday, from: actual)
        switch weekday {
        case 7: return calendar.date(byAdding: .day, value: -1, to: actual)  // Sat → Fri
        case 1: return calendar.date(byAdding: .day, value: 1, to: actual)   // Sun → Mon
        default: return actual
        }
    }

    /// Returns the Nth weekday of a given month. Pass `-1` for the last occurrence.
    private static func nthWeekday(year: Int, month: Int, weekday: Int, ordinal: Int, calendar: Calendar) -> Date? {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.weekday = weekday
        comps.weekdayOrdinal = ordinal
        return calendar.date(from: comps)
    }
}
