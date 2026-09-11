import Foundation

enum BirthdaySource: String, Codable {
    case manual, contacts, calendar, text
}

struct Birthday: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var month: Int
    var day: Int
    var year: Int?
    var notes: String
    var source: BirthdaySource
    var contactIdentifier: String?
    var phoneNumber: String?
    var email: String?
    var imageData: Data?

    init(id: UUID = UUID(),
         name: String,
         month: Int,
         day: Int,
         year: Int? = nil,
         notes: String = "",
         source: BirthdaySource = .manual,
         contactIdentifier: String? = nil,
         phoneNumber: String? = nil,
         email: String? = nil,
         imageData: Data? = nil) {
        self.id = id
        self.name = name
        self.month = month
        self.day = day
        self.year = year
        self.notes = notes
        self.source = source
        self.contactIdentifier = contactIdentifier
        self.phoneNumber = phoneNumber
        self.email = email
        self.imageData = imageData
    }
}

extension Birthday {
    /// The next date this birthday falls on. Today counts.
    func nextOccurrence(after reference: Date = .now) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: reference)
        let todayComps = cal.dateComponents([.month, .day], from: today)
        if todayComps.month == month && todayComps.day == day { return today }
        var match = DateComponents()
        match.month = month
        match.day = day
        return cal.nextDate(after: today, matching: match, matchingPolicy: .nextTime, direction: .forward) ?? today
    }

    func daysUntil(from reference: Date = .now) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: reference)
        return cal.dateComponents([.day], from: start, to: nextOccurrence(after: reference)).day ?? 0
    }

    /// Age reached at the next occurrence. Nil when the year is unknown.
    func ageTurning(from reference: Date = .now) -> Int? {
        guard let year else { return nil }
        let nextYear = Calendar.current.component(.year, from: nextOccurrence(after: reference))
        return nextYear - year
    }

    /// Current age. Nil when the year is unknown.
    func currentAge(from reference: Date = .now) -> Int? {
        guard let turning = ageTurning(from: reference) else { return nil }
        return daysUntil(from: reference) == 0 ? turning : turning - 1
    }

    var birthDate: Date? {
        guard let year else { return nil }
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    var initials: String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        return (first + last).uppercased()
    }

    /// "Today", "Tomorrow", "12 days"
    func countdownText(from reference: Date = .now) -> String {
        switch daysUntil(from: reference) {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case let d: return "\(d) days"
        }
    }

    /// "in 12 days", "today", "tomorrow"
    func relativeText(from reference: Date = .now) -> String {
        switch daysUntil(from: reference) {
        case 0: return "today"
        case 1: return "tomorrow"
        case let d: return "in \(d) days"
        }
    }

    /// "September 14" or "September 14, 1990"
    var longDateText: String {
        if let birthDate {
            return birthDate.formatted(.dateTime.month(.wide).day().year())
        }
        return nextOccurrence().formatted(.dateTime.month(.wide).day())
    }
}
