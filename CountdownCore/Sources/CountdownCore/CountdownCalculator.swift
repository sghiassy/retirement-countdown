import Foundation

public struct CountdownCalculator {

    public enum State: Equatable {
        case unconfigured
        case counting(days: Int)
        case today
        case retired
    }

    /// Returns the countdown state for `retirementDate` relative to `now` in `timeZone`.
    /// Uses whole Gregorian calendar days — never time-interval arithmetic — so DST
    /// transitions cannot produce off-by-one errors.
    ///
    /// State determination (unconfigured/counting/today/retired) is always based on the
    /// calendar date comparison. The `days` value inside `.counting` reflects `mode`:
    /// `.calendarDays` returns the raw day count; `.workdays` returns Mon–Fri days
    /// remaining, excluding US federal holidays (observed).
    public static func state(
        for retirementDate: RetirementDate?,
        on now: Date = Date(),
        in timeZone: TimeZone = .current,
        mode: CountdownMode = .calendarDays
    ) -> State {
        guard let retirement = retirementDate else { return .unconfigured }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone

        let todayComps = cal.dateComponents([.year, .month, .day], from: now)
        let retirementComps = DateComponents(
            year: retirement.year, month: retirement.month, day: retirement.day
        )

        guard
            let todayStart      = cal.date(from: todayComps),
            let retirementStart = cal.date(from: retirementComps)
        else { return .unconfigured }

        let calDays = cal.dateComponents([.day], from: todayStart, to: retirementStart).day ?? 0

        switch calDays {
        case 1...:
            let days: Int
            switch mode {
            case .calendarDays:
                days = calDays
            case .workdays:
                days = workdaysBetween(after: todayStart, throughInclusive: retirementStart, calendar: cal)
            }
            return .counting(days: days)
        case 0:
            return .today
        default:
            return .retired
        }
    }

    /// Convenience: returns the raw day count for the given mode, or nil when not counting.
    public static func daysRemaining(
        for retirementDate: RetirementDate?,
        on now: Date = Date(),
        in timeZone: TimeZone = .current,
        mode: CountdownMode = .calendarDays
    ) -> Int? {
        guard case .counting(let d) = state(for: retirementDate, on: now, in: timeZone, mode: mode) else {
            return nil
        }
        return d
    }

    /// Counts US-observed workdays (Mon–Fri, excluding federal holidays) strictly after
    /// `start` up to and including `end`. Assumes both are day-start dates in `calendar`.
    private static func workdaysBetween(after start: Date, throughInclusive end: Date, calendar: Calendar) -> Int {
        let startYear = calendar.component(.year, from: start)
        let endYear = calendar.component(.year, from: end)
        var holidays = Set<Date>()
        for year in startYear...endYear {
            holidays.formUnion(USFederalHolidays.observedDates(inYear: year, calendar: calendar))
        }

        var count = 0
        guard var current = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
        while current <= end {
            let weekday = calendar.component(.weekday, from: current)
            let isWeekday = (2...6).contains(weekday)  // Mon=2 ... Fri=6
            if isWeekday && !holidays.contains(current) {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return count
    }
}
