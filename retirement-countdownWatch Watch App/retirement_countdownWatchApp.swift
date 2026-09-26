import SwiftUI

@main
struct retirement_countdownWatch_Watch_AppApp: App {
    init() {
        WatchSessionDelegate.shared.activate()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
