import SwiftUI
import CountdownCore

struct SettingsView: View {

    @Binding var preferences: CountdownPreferences
    let onChange: (CountdownPreferences) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingAddHoliday = false

    var body: some View {
        NavigationStack {
            Form {
                ptoSection
                federalHolidaysSection
                customHolidaysSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddHoliday) {
                AddHolidayView { newHoliday in
                    preferences.customHolidays.append(newHoliday)
                    preferences.customHolidays.sort { $0.date.isoString < $1.date.isoString }
                    onChange(preferences)
                }
            }
        }
    }

    // MARK: - PTO

    private var ptoSection: some View {
        Section {
            Stepper(value: Binding(
                get: { preferences.ptoDays },
                set: { newValue in
                    preferences.ptoDays = newValue
                    onChange(preferences)
                }
            ), in: 0...365) {
                HStack {
                    Text("PTO days")
                    Spacer()
                    Text("\(preferences.ptoDays)").foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("PTO")
        } footer: {
            Text("PTO days are subtracted from the Workdays count only. Doesn't affect the All days count.")
        }
    }

    // MARK: - Federal holidays

    private var federalHolidaysSection: some View {
        Section {
            ForEach(FederalHoliday.allCases, id: \.self) { holiday in
                Toggle(holiday.displayName, isOn: Binding(
                    get: { !preferences.disabledFederalHolidays.contains(holiday) },
                    set: { enabled in
                        if enabled {
                            preferences.disabledFederalHolidays.remove(holiday)
                        } else {
                            preferences.disabledFederalHolidays.insert(holiday)
                        }
                        onChange(preferences)
                    }
                ))
            }
        } header: {
            Text("US Federal Holidays")
        } footer: {
            Text("Uncheck any your company doesn't observe. Weekend observance follows federal rules (Sat → Fri, Sun → Mon).")
        }
    }

    // MARK: - Custom holidays

    private var customHolidaysSection: some View {
        Section {
            ForEach(preferences.customHolidays, id: \.self) { holiday in
                customHolidayRow(holiday)
            }
            .onDelete { indexSet in
                preferences.customHolidays.remove(atOffsets: indexSet)
                onChange(preferences)
            }
            Button {
                showingAddHoliday = true
            } label: {
                Label("Add Holiday", systemImage: "plus")
            }
        } header: {
            Text("Custom Holidays")
        } footer: {
            Text("Dates your company treats as off days beyond federal holidays.")
        }
    }

    private func customHolidayRow(_ holiday: Holiday) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formattedDate(holiday.date))
                .font(.body)
            if let label = holiday.label, !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedDate(_ date: RetirementDate) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = .current
        let comps = DateComponents(year: date.year, month: date.month, day: date.day)
        guard let d = cal.date(from: comps) else { return date.isoString }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: d)
    }
}

// MARK: - Add holiday sheet

private struct AddHolidayView: View {

    let onAdd: (Holiday) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date = Date()
    @State private var label: String = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                TextField("Label (optional)", text: $label)
            }
            .navigationTitle("New Holiday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let rd = RetirementDate.from(date: selectedDate)
                        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
                        onAdd(Holiday(date: rd, label: trimmed.isEmpty ? nil : trimmed))
                        dismiss()
                    }
                }
            }
        }
    }
}
