import Foundation

public enum CountdownFormatter {

    public static func daysString(_ days: Int) -> String {
        "\(days)"
    }

    public static func fullDateString(_ date: RetirementDate, locale: Locale = .current) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = locale
        let comps = DateComponents(year: date.year, month: date.month, day: date.day)
        guard let d = cal.date(from: comps) else { return date.isoString }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = locale
        return formatter.string(from: d)
    }

    public static func accessibilityLabel(for model: CountdownDisplayModel) -> String {
        switch model {
        case .counting(let days, _): return "\(days) days until retirement"
        case .today:                 return "Today is the day"
        case .retired:               return "Retired"
        case .unconfigured:          return "Set retirement date"
        }
    }
}
