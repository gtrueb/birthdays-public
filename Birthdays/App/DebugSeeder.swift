#if DEBUG
import Contacts
import Foundation

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
    }

    static func sampleBirthdays() -> [Birthday] {
        people.map {
            Birthday(name: "\($0.given) \($0.family)", month: $0.month, day: $0.day, year: $0.year,
                     notes: $0.given == "Aylin" ? "Loves dark chocolate. Dinner at Kronenhalle last year." : "",
                     source: .contacts, contactIdentifier: nil,
                     phoneNumber: "+41 79 123 45 67",
                     email: $0.given == "Aylin" ? "aylin@example.com" : nil)
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
}
#endif
