import WidgetKit
import SwiftUI
import CountdownCore

// MARK: - Timeline Entry

struct CountdownEntry: TimelineEntry {
    let date: Date
    let model: CountdownDisplayModel
}

// MARK: - Timeline Provider

struct CountdownTimelineProvider: TimelineProvider {

    private let appGroupID = "group.ghiassy.retirement-countdown"
    private let dateKey    = "retirementDate.v1"

    private func loadRetirementDate() -> RetirementDate? {
        guard
            let str  = UserDefaults(suiteName: appGroupID)?.string(forKey: dateKey),
            let date = RetirementDate(string: str)
        else { return nil }
        return date
    }

    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, model: .counting(days: 342, fullDate: "September 1, 2027"))
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let model = CountdownDisplayModel.make(from: loadRetirementDate())
        completion(CountdownEntry(date: .now, model: model))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let now  = Date()
        let retirementDate = loadRetirementDate()
        var entries = [CountdownEntry(date: now,
                                      model: CountdownDisplayModel.make(from: retirementDate, on: now))]

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let startOfToday = cal.startOfDay(for: now)
        for offset in 1...30 {
            guard let nextDay = cal.date(byAdding: .day, value: offset, to: startOfToday) else { continue }
            entries.append(CountdownEntry(date: nextDay,
                                          model: CountdownDisplayModel.make(from: retirementDate, on: nextDay)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - System Widget Views

struct SystemSmallView: View {
    let model: CountdownDisplayModel
    var body: some View {
        VStack(spacing: 4) {
            switch model {
            case .counting(let days, _):
                Text(CountdownFormatter.daysString(days))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("days")
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
        .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model))
    }
}

struct SystemMediumView: View {
    let model: CountdownDisplayModel
    var body: some View {
        HStack {
            SystemSmallView(model: model)
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
        .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model))
    }
}

struct SystemLargeView: View {
    let model: CountdownDisplayModel
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            SystemSmallView(model: model)
            if case .counting(_, let fullDate) = model {
                Text(fullDate)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model))
    }
}

// MARK: - Accessory (Lock Screen) Widget Views

struct AccessoryInlineView: View {
    let model: CountdownDisplayModel
    var body: some View {
        switch model {
        case .counting(let days, _): Text("Retire in \(days)d")
        case .today:                 Text("Today is the day")
        case .retired:               Text("Retired")
        case .unconfigured:          Text("Set date on iPhone")
        }
    }
}

struct AccessoryCircularView: View {
    let model: CountdownDisplayModel
    var body: some View {
        switch model {
        case .counting(let days, _):
            VStack(spacing: 0) {
                Text("\(days)")
                    .font(.system(.headline, design: .rounded).bold())
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text("d")
                    .font(.caption2)
            }
            .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model))
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
    var body: some View {
        switch model {
        case .counting(let days, _):
            VStack(alignment: .leading, spacing: 2) {
                Text("\(days)")
                    .font(.system(.title2, design: .rounded).bold())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("until retirement")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(CountdownFormatter.accessibilityLabel(for: model))
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
            case .systemSmall:          SystemSmallView(model: entry.model)
            case .systemMedium:         SystemMediumView(model: entry.model)
            case .systemLarge:          SystemLargeView(model: entry.model)
            case .accessoryInline:      AccessoryInlineView(model: entry.model)
            case .accessoryCircular:    AccessoryCircularView(model: entry.model)
            case .accessoryRectangular: AccessoryRectangularView(model: entry.model)
            default:                    SystemSmallView(model: entry.model)
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
