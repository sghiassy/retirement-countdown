import Foundation
import WatchConnectivity
import CountdownCore
import os

private let log = Logger(subsystem: "ghiassy.retirement-countdown", category: "WatchSync")

final class WatchSyncManager: NSObject {

    static let shared = WatchSyncManager()
    private override init() { super.init() }

    func activate() {
        log.info("activate() called")
        guard WCSession.isSupported() else {
            log.error("WCSession NOT supported on this device")
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
        log.info("WCSession.activate() invoked, current state=\(WCSession.default.activationState.rawValue)")
    }

    func sendCurrentRecord() {
        log.info("sendCurrentRecord() called")
        guard WCSession.isSupported() else {
            log.error("sendCurrentRecord: WCSession not supported")
            return
        }
        let session = WCSession.default
        log.info("session state: activation=\(session.activationState.rawValue) paired=\(session.isPaired) watchAppInstalled=\(session.isWatchAppInstalled) reachable=\(session.isReachable)")

        guard session.activationState == .activated else {
            log.error("sendCurrentRecord: session not activated yet")
            return
        }
        guard let record = iOSRetirementRepository.shared.load() else {
            log.error("sendCurrentRecord: no record in repository (nothing to send)")
            return
        }
        let mode = iOSRetirementRepository.shared.loadMode()
        let payload: [String: Any] = [
            "retirementDate": record.retirementDate?.isoString ?? "",
            "changeRevision": record.changeRevision,
            "schemaVersion":  record.schemaVersion,
            "countdownMode":  mode.rawValue
        ]
        log.info("sending payload: date=\(record.retirementDate?.isoString ?? "nil") revision=\(record.changeRevision) schema=\(record.schemaVersion) mode=\(mode.rawValue)")
        do {
            try session.updateApplicationContext(payload)
            log.info("updateApplicationContext succeeded")
        } catch {
            log.error("updateApplicationContext FAILED: \(error.localizedDescription)")
        }
    }
}

extension WatchSyncManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            log.error("activationDidComplete error: \(error.localizedDescription)")
        }
        log.info("activationDidComplete state=\(state.rawValue) paired=\(session.isPaired) watchAppInstalled=\(session.isWatchAppInstalled)")
        guard state == .activated else { return }
        DispatchQueue.main.async { self.sendCurrentRecord() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        log.info("sessionDidBecomeInactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        log.info("sessionDidDeactivate -- reactivating")
        DispatchQueue.main.async { WCSession.default.activate() }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        log.info("sessionWatchStateDidChange paired=\(session.isPaired) watchAppInstalled=\(session.isWatchAppInstalled)")
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        log.info("sessionReachabilityDidChange reachable=\(session.isReachable)")
    }
}
