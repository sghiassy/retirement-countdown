import Foundation
import WatchConnectivity
import CountdownCore

final class WatchSyncManager: NSObject {

    static let shared = WatchSyncManager()
    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendCurrentRecord() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated
        else { return }
        guard let record = iOSRetirementRepository.shared.load() else { return }
        let payload: [String: Any] = [
            "retirementDate": record.retirementDate?.isoString ?? "",
            "changeRevision": record.changeRevision,
            "schemaVersion":  record.schemaVersion
        ]
        do {
            try WCSession.default.updateApplicationContext(payload)
        } catch {
            print("WatchSyncManager: updateApplicationContext failed: \(error)")
        }
    }
}

extension WatchSyncManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        guard state == .activated else { return }
        DispatchQueue.main.async { self.sendCurrentRecord() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async { WCSession.default.activate() }
    }
}
