import SwiftUI
import CountdownCore

struct ContentView: View {

    @StateObject private var sessionDelegate = WatchSessionDelegate.shared

    private var mode: CountdownMode {
        WatchRetirementRepository.shared.loadMode()
    }

    private var model: CountdownDisplayModel {
        CountdownDisplayModel.make(from: sessionDelegate.record?.retirementDate, mode: mode)
    }

    var body: some View {
        VStack(spacing: 4) {
            switch model {
            case .counting(let days, let fullDate):
                Text("\(days)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(mode == .workdays ? "workdays until retirement" : "days until retirement")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text(fullDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            case .today(let fullDate):
                Text("Today is the day")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(fullDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            case .retired:
                Text("Retired")
                    .font(.largeTitle).bold()
            case .unconfigured:
                Text("Set your retirement date on iPhone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model, mode: mode))
    }
}
