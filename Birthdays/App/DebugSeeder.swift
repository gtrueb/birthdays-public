#if DEBUG
import Contacts
import EventKit
import UIKit

/// Fills the simulator with sample data. Only runs with launch arguments.
enum DebugSeeder {
    struct Person {
        let given: String
        let family: String
        let month: Int
        let day: Int
        let year: Int?
        let hue: CGFloat?
    }

    static let people: [Person] = [
        Person(given: "Lena", family: "Huber", month: 9, day: 12, year: 1994, hue: 0.58),
        Person(given: "Marco", family: "Bianchi", month: 9, day: 13, year: 1988, hue: nil),
        Person(given: "Sophie", family: "Keller", month: 9, day: 16, year: nil, hue: 0.05),
        Person(given: "Jonas", family: "Weber", month: 9, day: 18, year: 1991, hue: nil),
        Person(given: "Aylin", family: "Demir", month: 9, day: 27, year: 1997, hue: 0.83),
        Person(given: "David", family: "Frei", month: 10, day: 3, year: 1960, hue: nil),
        Person(given: "Nora", family: "Steiner", month: 10, day: 21, year: 2019, hue: 0.33),
        Person(given: "Tom", family: "Schmid", month: 11, day: 8, year: 1985, hue: nil),
        Person(given: "Elena", family: "Rossi", month: 12, day: 24, year: 1990, hue: 0.12),
        Person(given: "Samuel", family: "Brunner", month: 1, day: 15, year: nil, hue: nil),
        Person(given: "Mia", family: "Graf", month: 2, day: 29, year: 2000, hue: 0.72),
        Person(given: "Luca", family: "Meier", month: 4, day: 2, year: 1979, hue: nil),
        Person(given: "Hannah", family: "Zimmermann", month: 6, day: 30, year: 1993, hue: 0.48),
    ]

    static func runIfRequested() async {
        let args = CommandLine.arguments
        if args.contains("-seedContacts") { await seedContacts() }
        if args.contains("-seedReminders") { await seedReminders() }
    }

    static func sampleBirthdays() -> [Birthday] {
        people.map {
            Birthday(name: "\($0.given) \($0.family)", month: $0.month, day: $0.day, year: $0.year,
                     source: .contacts, contactIdentifier: nil,
                     phoneNumber: "+41 79 123 45 67",
                     imageData: $0.hue.map { avatar(hue: $0).pngData() } ?? nil)
        }
    }

    static func seedContacts() async {
        let store = CNContactStore()
        guard (try? await store.requestAccess(for: .contacts)) == true else { return }
        let request = CNSaveRequest()
        for p in people {
            let c = CNMutableContact()
            c.givenName = p.given
            c.familyName = p.family
            var comps = DateComponents(month: p.month, day: p.day)
            comps.year = p.year
            c.birthday = comps
            c.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "+41 79 123 45 67"))]
            if let hue = p.hue { c.imageData = avatar(hue: hue).pngData() }
            request.add(c, toContainerWithIdentifier: nil)
        }
        // A few contacts without birthdays, so the picker has something to skip.
        for (g, f) in [("Peter", "Schneider"), ("Julia", "Fischer")] {
            let c = CNMutableContact()
            c.givenName = g
            c.familyName = f
            request.add(c, toContainerWithIdentifier: nil)
        }
        try? store.execute(request)
    }

    static func seedReminders() async {
        let store = EKEventStore()
        guard (try? await store.requestFullAccessToReminders()) == true else { return }
        let cal = Calendar.current
        func due(_ days: Int, hour: Int) -> DateComponents {
            let date = cal.date(byAdding: .day, value: days, to: cal.startOfDay(for: .now))!
            return cal.dateComponents([.year, .month, .day], from: cal.date(bySettingHour: hour, minute: 0, second: 0, of: date)!) 
                .merging(hour: hour)
        }
        let list = store.defaultCalendarForNewReminders() ?? store.calendars(for: .reminder).first
        let items: [(String, Int, Int, String?)] = [
            ("Call the dentist", 0, 9, nil),
            ("Pick up dry cleaning", 0, 17, nil),
            ("Pay rent", 1, 9, "Transfer before noon"),
            ("Water the plants", 2, 8, nil),
            ("Book flights to Lisbon", 4, 12, nil),
            ("Renew passport", 6, 10, "Bring two photos"),
            ("Dentist check-up", 15, 14, nil),
            ("Car service", 23, 9, nil),
            ("Renew gym membership", 40, 9, nil),
        ]
        for (title, days, hour, note) in items {
            let r = EKReminder(eventStore: store)
            r.title = title
            r.notes = note
            r.calendar = list
            r.dueDateComponents = due(days, hour: hour)
            r.addAlarm(EKAlarm(absoluteDate: cal.date(from: due(days, hour: hour))!))
            try? store.save(r, commit: false)
        }
        try? store.commit()
    }

    /// A soft gradient image that stands in for a contact photo.
    static func avatar(hue: CGFloat) -> UIImage {
        let size = CGSize(width: 240, height: 240)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor(hue: hue, saturation: 0.45, brightness: 0.95, alpha: 1).cgColor,
                          UIColor(hue: hue + 0.08, saturation: 0.6, brightness: 0.7, alpha: 1).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            let config = UIImage.SymbolConfiguration(pointSize: 150, weight: .regular)
            let symbol = UIImage(systemName: "person.fill", withConfiguration: config)!
                .withTintColor(UIColor.white.withAlphaComponent(0.85), renderingMode: .alwaysOriginal)
            let rect = CGRect(x: (size.width - symbol.size.width) / 2, y: size.height - symbol.size.height + 20,
                              width: symbol.size.width, height: symbol.size.height)
            symbol.draw(in: rect)
        }
    }
}

private extension DateComponents {
    func merging(hour: Int) -> DateComponents {
        var c = self
        c.hour = hour
        c.minute = 0
        return c
    }
}
#endif
