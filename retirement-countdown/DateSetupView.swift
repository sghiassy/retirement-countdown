import SwiftUI
import CountdownCore

struct DateSetupView: View {

    let existing: RetirementDate?
    let onSave: (RetirementDate) -> Void

    @State private var selectedDate: Date

    init(existing: RetirementDate?, onSave: @escaping (RetirementDate) -> Void) {
        self.existing = existing
        self.onSave = onSave
        var cal = Calendar(identifier: .gregorian)
        if let e = existing,
           let d = cal.date(from: DateComponents(year: e.year, month: e.month, day: e.day)) {
            _selectedDate = State(initialValue: d)
        } else {
            _selectedDate = State(initialValue: Date())
        }
    }

    private var preview: CountdownDisplayModel {
        CountdownDisplayModel.make(from: RetirementDate.from(date: selectedDate))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("When do you plan to retire?")
                    .font(.title2)
                    .multilineTextAlignment(.center)

                DatePicker(
                    "Retirement date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                previewLabel

                Button("Start countdown") {
                    onSave(RetirementDate.from(date: selectedDate))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle(existing == nil ? "Set Retirement Date" : "Edit Retirement Date")
        }
    }

    @ViewBuilder
    private var previewLabel: some View {
        if case .counting(let days, let fullDate) = preview {
            VStack(spacing: 4) {
                Text("\(days)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("days until retirement")
                    .foregroundStyle(.secondary)
                Text(fullDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
