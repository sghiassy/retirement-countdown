import SwiftUI
import CountdownCore

struct ContentView: View {

    @State private var record: RetirementRecord? = iOSRetirementRepository.shared.load()
    @State private var mode: CountdownMode = iOSRetirementRepository.shared.loadMode()
    @State private var isEditing = false

    var body: some View {
        Group {
            if let record, !isEditing {
                CountdownView(
                    record: record,
                    mode: $mode,
                    onEdit: { isEditing = true },
                    onModeChange: { newMode in
                        iOSRetirementRepository.shared.save(mode: newMode)
                    }
                )
            } else {
                DateSetupView(existing: record?.retirementDate) { newDate in
                    iOSRetirementRepository.shared.save(date: newDate)
                    record = iOSRetirementRepository.shared.load()
                    isEditing = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            record = iOSRetirementRepository.shared.load()
            mode = iOSRetirementRepository.shared.loadMode()
        }
    }
}
