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
    public static func state(
        for retirementDate: RetirementDate?,
        on now: Date = Date(),
        in timeZone: TimeZone = .current
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

        let days = cal.dateComponents([.day], from: todayStart, to: retirementStart).day ?? 0

        switch days {
        case 1...: return .counting(days: days)
        case 0:    return .today
        default:   return .retired
        }
    }

    /// Convenience: returns the raw day count, or nil when unconfigured.
    public static func daysRemaining(
        for retirementDate: RetirementDate?,
        on now: Date = Date(),
        in timeZone: TimeZone = .current
    ) -> Int? {
        guard case .counting(let d) = state(for: retirementDate, on: now, in: timeZone) else {
            return nil
        }
        return d
    }
}
