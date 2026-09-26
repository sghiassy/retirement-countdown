import Foundation
import CountdownCore

final class WatchRetirementRepository {

    static let shared = WatchRetirementRepository()
    private init() {}

    private let appGroupID  = "group.ghiassy.retirement-countdown"
    private let dateKey     = "retirementDate.v1"
    private let revisionKey = "changeRevision.v1"
    private let schemaKey   = "schemaVersion.v1"

    private var defaults: UserDefaults {
        guard let ud = UserDefaults(suiteName: appGroupID) else {
            fatalError("App Group \(appGroupID) is not configured — check watch target entitlements")
        }
        return ud
    }

    func load() -> RetirementRecord? {
        guard
            let str  = defaults.string(forKey: dateKey),
            let date = RetirementDate(string: str)
        else { return nil }
        let revision = defaults.integer(forKey: revisionKey)
        let schema   = max(defaults.integer(forKey: schemaKey), 1)
        return RetirementRecord(retirementDate: date, changeRevision: revision, schemaVersion: schema)
    }

    /// Applies an incoming WCSession transfer only if its revision is newer than what's stored.
    @discardableResult
    func applyIfNewer(payload: [String: Any]) -> RetirementRecord? {
        let incomingRevision = payload["changeRevision"] as? Int ?? 0
        let currentRevision  = defaults.integer(forKey: revisionKey)
        guard incomingRevision > currentRevision else { return nil }

        let dateStr = payload["retirementDate"] as? String ?? ""
        let date    = RetirementDate(string: dateStr)
        let schema  = payload["schemaVersion"] as? Int ?? 1

        if let d = date {
            defaults.set(d.isoString, forKey: dateKey)
        } else {
            defaults.removeObject(forKey: dateKey)
        }
        defaults.set(incomingRevision, forKey: revisionKey)
        defaults.set(schema, forKey: schemaKey)

        return RetirementRecord(retirementDate: date, changeRevision: incomingRevision, schemaVersion: schema)
    }
}
