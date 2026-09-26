import Foundation
import WidgetKit
import CountdownCore

final class iOSRetirementRepository {

    static let shared = iOSRetirementRepository()
    private init() {}

    private let appGroupID  = "group.ghiassy.retirement-countdown"
    private let dateKey     = "retirementDate.v1"
    private let revisionKey = "changeRevision.v1"
    private let schemaKey   = "schemaVersion.v1"

    private var defaults: UserDefaults {
        guard let ud = UserDefaults(suiteName: appGroupID) else {
            fatalError("App Group \(appGroupID) is not configured — check target entitlements")
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

    func save(date: RetirementDate) {
        let revision = defaults.integer(forKey: revisionKey) + 1
        defaults.set(date.isoString, forKey: dateKey)
        defaults.set(revision, forKey: revisionKey)
        defaults.set(1, forKey: schemaKey)
        WidgetCenter.shared.reloadAllTimelines()
        WatchSyncManager.shared.sendCurrentRecord()
    }
}
