import Foundation

public struct RetirementRecord: Equatable, Codable {
    public let retirementDate: RetirementDate?
    public let changeRevision: Int
    // Only schema version 1 is defined in v1. Future versions should validate this on decode.
    public let schemaVersion: Int

    public init(
        retirementDate: RetirementDate?,
        changeRevision: Int = 0,
        schemaVersion: Int = 1
    ) {
        self.retirementDate = retirementDate
        self.changeRevision = changeRevision
        self.schemaVersion = schemaVersion
    }

    public func incrementingRevision(with date: RetirementDate) -> RetirementRecord {
        RetirementRecord(
            retirementDate: date,
            changeRevision: changeRevision + 1,
            schemaVersion: schemaVersion
        )
    }
}
