import WidgetKit
import SwiftUI
import CountdownCore

// MARK: - Timeline Entry

struct CountdownEntry: TimelineEntry {
    let date: Date
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
}

// MARK: - Timeline Provider

struct CountdownTimelineProvider: TimelineProvider {

    private let appGroupID     = "group.ghiassy.retirement-countdown"
    private let dateKey        = "retirementDate.v1"
    private let preferencesKey = "preferences.v1"
    private let legacyModeKey  = "countdownMode.v1"

    private var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    private func loadRetirementDate() -> RetirementDate? {
        guard
            let str  = defaults?.string(forKey: dateKey),
            let date = RetirementDate(string: str)
        else { return nil }
        return date
    }

    private func loadPreferences() -> CountdownPreferences {
        if let json = defaults?.string(forKey: preferencesKey),
           let prefs = CountdownPreferences(json: json) {
            return prefs
        }
        if let legacyMode = defaults?.string(forKey: legacyModeKey),
           let mode = CountdownMode(rawValue: legacyMode) {
            return CountdownPreferences(mode: mode)
        }
        return CountdownPreferences()
    }

    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: .now,
            model: .counting(days: 342, fullDate: "September 1, 2027"),
            preferences: CountdownPreferences()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let prefs = loadPreferences()
        let model = CountdownDisplayModel.make(from: loadRetirementDate(), preferences: prefs)
        completion(CountdownEntry(date: .now, model: model, preferences: prefs))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let now  = Date()
        let retirementDate = loadRetirementDate()
        let prefs = loadPreferences()
        var entries = [CountdownEntry(
            date: now,
            model: CountdownDisplayModel.make(from: retirementDate, on: now, preferences: prefs),
            preferences: prefs
        )]

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let startOfToday = cal.startOfDay(for: now)
        for offset in 1...30 {
            guard let nextDay = cal.date(byAdding: .day, value: offset, to: startOfToday) else { continue }
            entries.append(CountdownEntry(
                date: nextDay,
                model: CountdownDisplayModel.make(from: retirementDate, on: nextDay, preferences: prefs),
                preferences: prefs
            ))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - System Widget Views

struct SystemSmallView: View {
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
    var body: some View {
        VStack(spacing: 4) {
            switch model {
            case .counting(let days, _):
                Text(CountdownFormatter.daysString(days))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(preferences.mode == .workdays ? "workdays" : "days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .today:
                Text("Today is the day")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            case .retired:
                Text("Retired")
                    .font(.title2).bold()
            case .unconfigured:
                Text("Set retirement date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(8)
        .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model, preferences: preferences))
    }
}

struct SystemMediumView: View {
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
    var body: some View {
        HStack {
            SystemSmallView(model: model, preferences: preferences)
            if case .counting(_, let fullDate) = model {
                Spacer()
                Text(fullDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing)
            }
        }
        .padding()
        .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model, preferences: preferences))
    }
}

struct SystemLargeView: View {
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            SystemSmallView(model: model, preferences: preferences)
            if case .counting(_, let fullDate) = model {
                Text(fullDate)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model, preferences: preferences))
    }
}

// MARK: - Accessory (Lock Screen) Widget Views

struct AccessoryInlineView: View {
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
    var body: some View {
        switch model {
        case .counting(let days, _):
            Text(preferences.mode == .workdays ? "Retire in \(days) workdays" : "Retire in \(days)d")
        case .today:        Text("Today is the day")
        case .retired:      Text("Retired")
        case .unconfigured: Text("Set date on iPhone")
        }
    }
}

struct AccessoryCircularView: View {
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
    var body: some View {
        switch model {
        case .counting(let days, _):
            VStack(spacing: 0) {
                Text("\(days)")
                    .font(.system(.headline, design: .rounded).bold())
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(preferences.mode == .workdays ? "wd" : "d")
                    .font(.caption2)
            }
            .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model, preferences: preferences))
        case .today:
            Image(systemName: "party.popper")
        case .retired:
            Image(systemName: "checkmark.circle")
        case .unconfigured:
            Image(systemName: "calendar.badge.plus")
        }
    }
}

struct AccessoryRectangularView: View {
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
    var body: some View {
        switch model {
        case .counting(let days, _):
            VStack(alignment: .leading, spacing: 2) {
                Text("\(days)")
                    .font(.system(.title2, design: .rounded).bold())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(preferences.mode == .workdays ? "workdays to retire" : "until retirement")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model, preferences: preferences))
        case .today:
            Text("Today is the day").font(.headline)
        case .retired:
            Text("Retired").font(.headline)
        case .unconfigured:
            Text("Set retirement date").font(.caption)
        }
    }
}

// MARK: - Widget Entry View

private let widgetOpenURL = URL(string: "retirementcountdown://open")!

struct CountdownWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CountdownEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:          SystemSmallView(model: entry.model, preferences: entry.preferences)
            case .systemMedium:         SystemMediumView(model: entry.model, preferences: entry.preferences)
            case .systemLarge:          SystemLargeView(model: entry.model, preferences: entry.preferences)
            case .accessoryInline:      AccessoryInlineView(model: entry.model, preferences: entry.preferences)
            case .accessoryCircular:    AccessoryCircularView(model: entry.model, preferences: entry.preferences)
            case .accessoryRectangular: AccessoryRectangularView(model: entry.model, preferences: entry.preferences)
            default:                    SystemSmallView(model: entry.model, preferences: entry.preferences)
            }
        }
        .widgetURL(widgetOpenURL)
    }
}

// MARK: - Widget Declaration

struct retirement_countdownWidget: Widget {
    let kind = "retirement_countdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownTimelineProvider()) { entry in
            CountdownWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Retirement Countdown")
        .description("Days until your retirement date.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryInline, .accessoryCircular, .accessoryRectangular
        ])
    }
}
