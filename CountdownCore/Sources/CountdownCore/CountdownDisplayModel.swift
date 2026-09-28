import Foundation

public enum CountdownDisplayModel: Equatable {
    case unconfigured
    case counting(days: Int, fullDate: String)
    case today(fullDate: String)
    case retired

    public static func make(
        from retirementDate: RetirementDate?,
        on now: Date = Date(),
        in timeZone: TimeZone = .current,
        mode: CountdownMode = .calendarDays
    ) -> CountdownDisplayModel {
        guard let date = retirementDate else { return .unconfigured }
        let fullDate = CountdownFormatter.fullDateString(date)
        switch CountdownCalculator.state(for: date, on: now, in: timeZone, mode: mode) {
        case .unconfigured:        return .unconfigured
        case .counting(let days):  return .counting(days: days, fullDate: fullDate)
        case .today:               return .today(fullDate: fullDate)
        case .retired:             return .retired
        }
    }
}
