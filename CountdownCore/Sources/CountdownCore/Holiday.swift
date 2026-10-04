import Foundation

/// A user-defined holiday — a specific calendar date, with an optional label like
/// "Company Shutdown". Custom holidays are stored as literal dates (no observed-weekend
/// shifting; the user tells us the exact day off).
public struct Holiday: Codable, Equatable, Hashable {
    public let date: RetirementDate
    public let label: String?

    public init(date: RetirementDate, label: String? = nil) {
        self.date = date
        self.label = label
    }
}
