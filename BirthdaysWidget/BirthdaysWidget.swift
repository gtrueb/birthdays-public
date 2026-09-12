import SwiftUI
import WidgetKit

struct BirthdayEntry: TimelineEntry {
    let date: Date
    let birthdays: [Birthday]
}

struct BirthdayProvider: TimelineProvider {
    func placeholder(in context: Context) -> BirthdayEntry {
        BirthdayEntry(date: .now, birthdays: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (BirthdayEntry) -> Void) {
        let loaded = SharedStore.load()
        completion(BirthdayEntry(date: .now, birthdays: loaded.isEmpty && context.isPreview ? Self.sample : loaded))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BirthdayEntry>) -> Void) {
        let entry = BirthdayEntry(date: .now, birthdays: SharedStore.load())
        // Refresh just after midnight, when "today" changes.
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: .now)) ?? .now
        completion(Timeline(entries: [entry], policy: .after(tomorrow.addingTimeInterval(60))))
    }

    static let sample: [Birthday] = [
        Birthday(name: "Lena Huber", month: 9, day: 12, year: 1994),
        Birthday(name: "Marco Bianchi", month: 9, day: 13, year: 1988),
        Birthday(name: "Sophie Keller", month: 9, day: 16),
        Birthday(name: "Jonas Weber", month: 9, day: 18, year: 1991),
    ]
}

struct BirthdaysWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BirthdayEntry

    private var upcoming: [Birthday] {
        entry.birthdays.sorted { a, b in
            let da = a.daysUntil(from: entry.date), db = b.daysUntil(from: entry.date)
            return da != db ? da < db : a.name < b.name
        }
    }

    var body: some View {
        Group {
            if upcoming.isEmpty {
                empty
            } else if family == .systemSmall {
                small(upcoming[0])
            } else {
                medium(Array(upcoming.prefix(3)))
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: "birthday.cake.fill")
            Text("Birthdays")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.pink)
    }

    private func small(_ birthday: Birthday) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Spacer(minLength: 0)
            Text(birthday.name)
                .font(.headline)
                .lineLimit(2)
            Text(line(for: birthday))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(birthday.countdownText(from: entry.date))
                .font(.title2.weight(.semibold))
                .foregroundStyle(birthday.daysUntil(from: entry.date) == 0 ? .pink : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func medium(_ birthdays: [Birthday]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            ForEach(birthdays) { birthday in
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(birthday.name)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Text(line(for: birthday))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(birthday.countdownText(from: entry.date))
                        .font(.subheadline)
                        .foregroundStyle(birthday.daysUntil(from: entry.date) == 0 ? .pink : .secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Spacer()
            Text("No Birthdays")
                .font(.headline)
            Text("Add birthdays in the app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func line(for birthday: Birthday) -> String {
        let date = birthday.nextOccurrence(after: entry.date).formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        if let age = birthday.ageTurning(from: entry.date) { return "\(date) · Turns \(age)" }
        return date
    }
}

@main
struct BirthdaysWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BirthdaysWidget", provider: BirthdayProvider()) { entry in
            BirthdaysWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Birthdays")
        .description("See who has a birthday coming up.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
