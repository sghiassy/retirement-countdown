import SwiftUI

@main
struct retirement_countdownApp: App {
    init() {
        WatchSyncManager.shared.activate()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
