import EventKit
import Foundation

enum CalendarImporter {
    static func requestAccess() async -> Bool {
        let store = EKEventStore()
        return (try? await store.requestFullAccessToEvents()) ?? false
    }

    static func fetchBirthdays() -> [Birthday] {
        let store = EKEventStore()
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        guard let end = cal.date(byAdding: .day, value: 366, to: start) else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        var seen = Set<String>()
        var result: [Birthday] = []
        for event in store.events(matching: predicate) {
            let title = event.title ?? ""
            let fromBirthdayCalendar = event.calendar.type == .birthday
            guard fromBirthdayCalendar || looksLikeBirthday(title) else { continue }
            let name = extractName(from: title)
            guard !name.isEmpty else { continue }
            let comps = cal.dateComponents([.month, .day, .year], from: event.startDate)
            guard let month = comps.month, let day = comps.day, let eventYear = comps.year else { continue }
            let key = "\(name.lowercased())|\(month)|\(day)"
            guard seen.insert(key).inserted else { continue }
            result.append(Birthday(
                name: name,
                month: month,
                day: day,
                year: extractYear(from: title, eventYear: eventYear),
                source: .calendar,
                contactIdentifier: event.birthdayContactIdentifier
            ))
        }
        return result.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static let keywords = ["birthday", "bday", "b-day", "geburtstag", "geburi", "anniversaire", "cumpleaños", "compleanno", "verjaardag"]

    static func looksLikeBirthday(_ title: String) -> Bool {
        let lower = title.lowercased()
        return keywords.contains { lower.contains($0) }
    }

    /// "Anna Meier's Birthday" -> "Anna Meier"
    static func extractName(from title: String) -> String {
        var text = title
        for word in keywords {
            text = text.replacingOccurrences(of: word, with: "", options: [.caseInsensitive])
        }
        text = text.replacingOccurrences(of: #"(?i)\b(of|von|de|di)\b"#, with: "", options: .regularExpression)
        // "Aylin Demir's 29th Birthday" -> drop "(…)", "[…]", "*1990", "29th"
        text = text.replacingOccurrences(of: #"\(.*?\)|\[.*?\]|\*?\d{4}|\d+(?:st|nd|rd|th)?\.?"#, with: "", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: #"['’]s\b|['’]$"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"[:,\-–—|!🎂🎉🎈🎁]"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Finds "(1990)", "*1990", "born 1990", or an age like "(30)".
    static func extractYear(from title: String, eventYear: Int) -> Int? {
        if let match = title.range(of: #"\b(19|20)\d{2}\b"#, options: .regularExpression),
           let year = Int(title[match]), year <= eventYear {
            return year
        }
        // "(30)" or "30th" is the age reached on that day.
        for pattern in [#"\((\d{1,3})\)"#, #"\b(\d{1,3})(?:st|nd|rd|th)\b"#] {
            if let match = title.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let digits = title[match].filter(\.isNumber)
                if let age = Int(digits), age > 0, age < 130 { return eventYear - age }
            }
        }
        return nil
    }
}
