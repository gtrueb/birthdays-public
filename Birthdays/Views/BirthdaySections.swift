import Foundation

struct BirthdaySection: Identifiable {
    let id: String
    let title: String
    var birthdays: [Birthday]
}

enum BirthdaySections {
    static func build(from birthdays: [Birthday], now: Date = .now) -> [BirthdaySection] {
        let sorted = birthdays.sorted { a, b in
            let da = a.daysUntil(from: now), db = b.daysUntil(from: now)
            if da != db { return da < db }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: now)
        var today: [Birthday] = []
        var week: [Birthday] = []
        var months: [BirthdaySection] = []

        for birthday in sorted {
            let days = birthday.daysUntil(from: now)
            if days == 0 {
                today.append(birthday)
            } else if days <= 7 {
                week.append(birthday)
            } else {
                let next = birthday.nextOccurrence(after: now)
                let comps = cal.dateComponents([.year, .month], from: next)
                let key = "\(comps.year ?? 0)-\(comps.month ?? 0)"
                if let index = months.firstIndex(where: { $0.id == key }) {
                    months[index].birthdays.append(birthday)
                } else {
                    var title = next.formatted(.dateTime.month(.wide))
                    if comps.year != currentYear { title = next.formatted(.dateTime.month(.wide).year()) }
                    months.append(BirthdaySection(id: key, title: title, birthdays: [birthday]))
                }
            }
        }

        var result: [BirthdaySection] = []
        if !today.isEmpty { result.append(BirthdaySection(id: "today", title: "Today", birthdays: today)) }
        if !week.isEmpty { result.append(BirthdaySection(id: "week", title: "Next 7 Days", birthdays: week)) }
        result.append(contentsOf: months)
        return result
    }
}
