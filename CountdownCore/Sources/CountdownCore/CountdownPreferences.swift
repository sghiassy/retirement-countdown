import Foundation

/// User configuration for how the countdown is displayed and computed.
/// Serialized as JSON into the shared App Group and over WCSession.
public struct CountdownPreferences: Codable, Equatable {
    public var mode: CountdownMode
    public var ptoDays: Int
    public var disabledFederalHolidays: Set<FederalHoliday>
    public var customHolidays: [Holiday]

    public init(
        mode: CountdownMode = .calendarDays,
        ptoDays: Int = 0,
        disabledFederalHolidays: Set<FederalHoliday> = [],
        customHolidays: [Holiday] = []
    ) {
        self.mode = mode
        self.ptoDays = ptoDays
        self.disabledFederalHolidays = disabledFederalHolidays
        self.customHolidays = customHolidays
    }

    public var enabledFederalHolidays: Set<FederalHoliday> {
        Set(FederalHoliday.allCases).subtracting(disabledFederalHolidays)
    }

    public func encodedJSON() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public init?(json: String) {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(CountdownPreferences.self, from: data)
        else { return nil }
        self = decoded
    }
}
