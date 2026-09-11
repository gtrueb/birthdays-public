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
    }

    static let people: [Person] = [
        Person(given: "Lena", family: "Huber", month: 9, day: 12, year: 1994),
        Person(given: "Marco", family: "Bianchi", month: 9, day: 13, year: 1988),
        Person(given: "Sophie", family: "Keller", month: 9, day: 16, year: nil),
        Person(given: "Jonas", family: "Weber", month: 9, day: 18, year: 1991),
        Person(given: "Aylin", family: "Demir", month: 9, day: 27, year: 1997),
        Person(given: "David", family: "Frei", month: 10, day: 3, year: 1960),
        Person(given: "Nora", family: "Steiner", month: 10, day: 21, year: 2019),
        Person(given: "Tom", family: "Schmid", month: 11, day: 8, year: 1985),
        Person(given: "Elena", family: "Rossi", month: 12, day: 24, year: 1990),
        Person(given: "Samuel", family: "Brunner", month: 1, day: 15, year: nil),
        Person(given: "Mia", family: "Graf", month: 2, day: 29, year: 2000),
        Person(given: "Luca", family: "Meier", month: 4, day: 2, year: 1979),
        Person(given: "Hannah", family: "Zimmermann", month: 6, day: 30, year: 1993),
    ]

    static func runIfRequested() async {
        let args = CommandLine.arguments
        if args.contains("-seedContacts") { await seedContacts() }
        if args.contains("-seedReminders") { await seedReminders() }
        if args.contains("-stripContactPhotos") { await stripContactPhotos() }
    }

    /// Removes photos from every contact, so the picker shows monograms only.
    static func stripContactPhotos() async {
        let store = CNContactStore()
        guard (try? await store.requestAccess(for: .contacts)) == true else { return }
        let keys = [CNContactImageDataAvailableKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        let save = CNSaveRequest()
        try? store.enumerateContacts(with: request) { contact, _ in
            guard contact.imageDataAvailable, let mutable = contact.mutableCopy() as? CNMutableContact else { return }
            mutable.imageData = nil
            save.update(mutable)
        }
        try? store.execute(save)
    }

    static func sampleBirthdays() -> [Birthday] {
        people.map {
            Birthday(name: "\($0.given) \($0.family)", month: $0.month, day: $0.day, year: $0.year,
                     source: .contacts, contactIdentifier: nil,
                     phoneNumber: "+41 79 123 45 67")
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
