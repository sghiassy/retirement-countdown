import Foundation
import WatchConnectivity
import WidgetKit
import CountdownCore
import SwiftUI
import Combine

final class WatchSessionDelegate: NSObject, ObservableObject {

    static let shared = WatchSessionDelegate()
    private override init() {
        super.init()
        record = WatchRetirementRepository.shared.load()
    }

    @Published var record: RetirementRecord?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

extension WatchSessionDelegate: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        guard state == .activated else { return }
        // Apply any context that arrived while the session was inactive
        let context = session.receivedApplicationContext
        guard !context.isEmpty else { return }
        applyAndReload(payload: context)
    }

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        applyAndReload(payload: context)
    }

    private func applyAndReload(payload: [String: Any]) {
        guard let updated = WatchRetirementRepository.shared.applyIfNewer(payload: payload) else { return }
        DispatchQueue.main.async {
            self.record = updated
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

