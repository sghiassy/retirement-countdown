import Foundation

/// US federal holidays with observed-date rules.
/// Returns dates on which federal offices are closed — the actual date if it's a weekday,
/// or the observed weekday if the actual date falls on a weekend.
public enum USFederalHolidays {

    /// Set of observed federal holiday dates falling on weekdays for `year`.
    /// Only holidays in `enabled` are included — defaults to all 11.
    /// Weekend-date holidays are shifted to the observed weekday (Sat→Fri, Sun→Mon).
    /// Juneteenth is only included from 2021 onward (when it was established).
    public static func observedDates(
        inYear year: Int,
        calendar: Calendar,
        enabled: Set<FederalHoliday> = Set(FederalHoliday.allCases)
    ) -> Set<Date> {
        var cal = calendar
        cal.timeZone = calendar.timeZone

        var dates = Set<Date>()
        for holiday in enabled {
            guard let d = date(for: holiday, year: year, calendar: cal) else { continue }
            dates.insert(d)
        }
        return dates
    }

    /// Returns the observed date for a given federal holiday in a given year, honoring
    /// weekend-shift rules for fixed-date holidays, and skipping Juneteenth pre-2021.
    private static func date(for holiday: FederalHoliday, year: Int, calendar: Calendar) -> Date? {
        switch holiday {
        case .newYearsDay:            return observedFixed(year: year, month: 1,  day: 1,  calendar: calendar)
        case .independenceDay:        return observedFixed(year: year, month: 7,  day: 4,  calendar: calendar)
        case .veteransDay:            return observedFixed(year: year, month: 11, day: 11, calendar: calendar)
        case .christmas:              return observedFixed(year: year, month: 12, day: 25, calendar: calendar)
        case .juneteenth:
            guard year >= 2021 else { return nil }
            return observedFixed(year: year, month: 6, day: 19, calendar: calendar)

        case .martinLutherKingJrDay:  return nthWeekday(year: year, month: 1,  weekday: 2, ordinal: 3,  calendar: calendar)
        case .presidentsDay:          return nthWeekday(year: year, month: 2,  weekday: 2, ordinal: 3,  calendar: calendar)
        case .memorialDay:            return nthWeekday(year: year, month: 5,  weekday: 2, ordinal: -1, calendar: calendar)
        case .laborDay:               return nthWeekday(year: year, month: 9,  weekday: 2, ordinal: 1,  calendar: calendar)
        case .columbusDay:            return nthWeekday(year: year, month: 10, weekday: 2, ordinal: 2,  calendar: calendar)
        case .thanksgiving:           return nthWeekday(year: year, month: 11, weekday: 5, ordinal: 4,  calendar: calendar)
        }
    }

    /// Returns the observed weekday date for a fixed-date holiday.
    /// If the date lands on Saturday, returns the Friday before; on Sunday, the Monday after.
    private static func observedFixed(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
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
