import WidgetKit
import SwiftUI
import CountdownCore

// MARK: - Timeline Entry

struct WatchCountdownEntry: TimelineEntry {
    let date: Date
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
}

// MARK: - Timeline Provider

struct WatchCountdownTimelineProvider: TimelineProvider {

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

    func placeholder(in context: Context) -> WatchCountdownEntry {
        WatchCountdownEntry(
            date: .now,
            model: .counting(days: 342, fullDate: "September 1, 2027"),
            preferences: CountdownPreferences()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchCountdownEntry) -> Void) {
        let prefs = loadPreferences()
        let model = CountdownDisplayModel.make(from: loadRetirementDate(), preferences: prefs)
        completion(WatchCountdownEntry(date: .now, model: model, preferences: prefs))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchCountdownEntry>) -> Void) {
        let now  = Date()
        let retirementDate = loadRetirementDate()
        let prefs = loadPreferences()
        var entries = [WatchCountdownEntry(
            date: now,
            model: CountdownDisplayModel.make(from: retirementDate, on: now, preferences: prefs),
            preferences: prefs
        )]

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let startOfToday = cal.startOfDay(for: now)
        for offset in 1...7 {
            guard let nextDay = cal.date(byAdding: .day, value: offset, to: startOfToday) else { continue }
            entries.append(WatchCountdownEntry(
                date: nextDay,
                model: CountdownDisplayModel.make(from: retirementDate, on: nextDay, preferences: prefs),
                preferences: prefs
            ))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Complication Views

struct WatchInlineView: View {
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
    var body: some View {
        switch model {
        case .counting(let days, _):
            Text(preferences.mode == .workdays ? "\(days) workdays" : "\(days)d to retire")
        case .today:        Text("Retire today!")
        case .retired:      Text("Retired")
        case .unconfigured: Text("Set date")
        }
    }
}

struct WatchCircularView: View {
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

struct WatchRectangularView: View {
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
    var body: some View {
        switch model {
        case .counting(let days, _):
            VStack(alignment: .leading, spacing: 1) {
                Text("\(days)")
                    .font(.system(.title3, design: .rounded).bold())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(preferences.mode == .workdays ? "workdays to retire" : "until retirement")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model, preferences: preferences))
        case .today:
            Text("Today is the day").font(.caption)
        case .retired:
            Text("Retired").font(.headline)
        case .unconfigured:
            Text("Set date on iPhone").font(.caption2)
        }
    }
}

struct WatchCornerView: View {
    let model: CountdownDisplayModel
    let preferences: CountdownPreferences
    var body: some View {
        switch model {
        case .counting(let days, _):
            Text("\(days)")
                .font(.system(.body, design: .rounded).bold())
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .widgetLabel(preferences.mode == .workdays ? "workdays to retire" : "days to retire")
                .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model, preferences: preferences))
        case .today:
            Image(systemName: "party.popper")
                .widgetLabel("Today!")
        case .retired:
            Image(systemName: "checkmark.circle")
                .widgetLabel("Retired")
        case .unconfigured:
            Image(systemName: "calendar.badge.plus")
                .widgetLabel("Set date")
        }
    }
}

// MARK: - Widget Entry View

struct WatchCountdownWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WatchCountdownEntry

    var body: some View {
        switch family {
        case .accessoryInline:      WatchInlineView(model: entry.model, preferences: entry.preferences)
        case .accessoryCircular:    WatchCircularView(model: entry.model, preferences: entry.preferences)
        case .accessoryRectangular: WatchRectangularView(model: entry.model, preferences: entry.preferences)
        case .accessoryCorner:      WatchCornerView(model: entry.model, preferences: entry.preferences)
        default:                    WatchCircularView(model: entry.model, preferences: entry.preferences)
        }
    }
}

// MARK: - Widget Declaration

struct retirement_countdownWatchWidget: Widget {
    let kind = "retirement_countdownWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchCountdownTimelineProvider()) { entry in
            WatchCountdownWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Retirement Countdown")
        .description("Days until retirement on your wrist.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}
