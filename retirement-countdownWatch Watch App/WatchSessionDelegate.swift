import Foundation
import WatchConnectivity
import WidgetKit
import CountdownCore
import SwiftUI
import Combine
import os

private let log = Logger(subsystem: "ghiassy.retirement-countdown.watch", category: "WatchSync")

final class WatchSessionDelegate: NSObject, ObservableObject {

    static let shared = WatchSessionDelegate()
    private override init() {
        super.init()
        record = WatchRetirementRepository.shared.load()
        log.info("init: loaded record from repo -> \(self.record?.retirementDate?.isoString ?? "nil")")
    }

    @Published var record: RetirementRecord?

    func activate() {
        log.info("activate() called")
        guard WCSession.isSupported() else {
            log.error("WCSession NOT supported")
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
        log.info("WCSession.activate() invoked")
    }
}

extension WatchSessionDelegate: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            log.error("activationDidComplete error: \(error.localizedDescription)")
        }
        log.info("activationDidComplete state=\(state.rawValue) companionReachable=\(session.isCompanionAppInstalled) reachable=\(session.isReachable)")
        guard state == .activated else { return }
        let context = session.receivedApplicationContext
        log.info("receivedApplicationContext at activation: keys=\(context.keys.sorted()) isEmpty=\(context.isEmpty)")
        guard !context.isEmpty else { return }
        applyAndReload(payload: context)
    }

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        log.info("didReceiveApplicationContext keys=\(context.keys.sorted())")
        applyAndReload(payload: context)
    }

    private func applyAndReload(payload: [String: Any]) {
        let incomingRev = payload["changeRevision"] as? Int ?? -1
        let incomingDate = payload["retirementDate"] as? String ?? "<none>"
        log.info("applyAndReload: incoming date=\(incomingDate) revision=\(incomingRev)")
        guard let updated = WatchRetirementRepository.shared.applyIfNewer(payload: payload) else {
            log.info("applyAndReload: applyIfNewer returned nil (revision not newer)")
            return
        }
        log.info("applyAndReload: applied. record now date=\(updated.retirementDate?.isoString ?? "nil") rev=\(updated.changeRevision)")
        DispatchQueue.main.async {
            self.record = updated
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
