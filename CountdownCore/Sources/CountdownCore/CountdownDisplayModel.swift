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
        preferences: CountdownPreferences = CountdownPreferences()
    ) -> CountdownDisplayModel {
        guard let date = retirementDate else { return .unconfigured }
        let fullDate = CountdownFormatter.fullDateString(date)
        switch CountdownCalculator.state(for: date, on: now, in: timeZone, preferences: preferences) {
        case .unconfigured:        return .unconfigured
        case .counting(let days):  return .counting(days: days, fullDate: fullDate)
        case .today:               return .today(fullDate: fullDate)
        case .retired:             return .retired
        }
    }
}
