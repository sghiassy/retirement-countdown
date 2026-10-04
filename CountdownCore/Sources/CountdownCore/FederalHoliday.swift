import Foundation

/// Identifies each of the 11 US federal holidays. The raw string value is the stable
/// identifier used for persistence; `displayName` is intended for user-facing UI.
public enum FederalHoliday: String, Codable, CaseIterable, Equatable, Hashable {
    case newYearsDay
    case martinLutherKingJrDay
    case presidentsDay
    case memorialDay
    case juneteenth
    case independenceDay
    case laborDay
    case columbusDay
    case veteransDay
    case thanksgiving
    case christmas

    public var displayName: String {
        switch self {
        case .newYearsDay:            return "New Year's Day"
        case .martinLutherKingJrDay:  return "Martin Luther King Jr. Day"
        case .presidentsDay:          return "Presidents Day"
        case .memorialDay:            return "Memorial Day"
        case .juneteenth:             return "Juneteenth"
        case .independenceDay:        return "Independence Day"
        case .laborDay:               return "Labor Day"
        case .columbusDay:            return "Columbus Day"
        case .veteransDay:            return "Veterans Day"
        case .thanksgiving:           return "Thanksgiving"
        case .christmas:              return "Christmas Day"
        }
    }
}
