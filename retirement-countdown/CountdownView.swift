import SwiftUI
import CountdownCore

struct CountdownView: View {

    let record: RetirementRecord
    @Binding var mode: CountdownMode
    let onEdit: () -> Void
    let onModeChange: (CountdownMode) -> Void

    private var model: CountdownDisplayModel {
        CountdownDisplayModel.make(from: record.retirementDate, mode: mode)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                mainContent
                if case .counting = model {
                    modePicker
                }
                Spacer()
                WidgetHelpView()
            }
            .padding()
            .navigationTitle("Retirement Countdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit", action: onEdit)
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch model {
        case .counting(let days, let fullDate):
            VStack(spacing: 8) {
                Text("\(days)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model, mode: mode))
                Text(mode == .workdays ? "workdays until retirement" : "days until retirement")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(fullDate)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        case .today(let fullDate):
            VStack(spacing: 8) {
                Text("Today is the day")
                    .font(.largeTitle).bold()
                Text(fullDate)
                    .foregroundStyle(.secondary)
            }
        case .retired:
            Text("Retired")
                .font(.largeTitle).bold()
        case .unconfigured:
            Text("Set your retirement date to begin.")
                .foregroundStyle(.secondary)
        }
    }

    private var modePicker: some View {
        Picker("Countdown mode", selection: $mode) {
            Text("All days").tag(CountdownMode.calendarDays)
            Text("Workdays").tag(CountdownMode.workdays)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 300)
        .onChange(of: mode) { _, newValue in
            onModeChange(newValue)
        }
    }
}
