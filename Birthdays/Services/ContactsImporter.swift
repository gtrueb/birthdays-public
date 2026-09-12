import Contacts
import Foundation

enum ContactsImporter {
    static func requestAccess() async -> Bool {
        let store = CNContactStore()
        return (try? await store.requestAccess(for: .contacts)) ?? false
    }

    static func fetchBirthdays() throws -> [Birthday] {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault
        var result: [Birthday] = []
        try store.enumerateContacts(with: request) { contact, _ in
            guard let bday = contact.birthday, let month = bday.month, let day = bday.day else { return }
            var name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            if name.isEmpty { name = contact.organizationName }
            guard !name.isEmpty else { return }
            var year: Int? = bday.year
            // Contacts without a year use nil, 1604, or an undefined marker.
            if let y = year, y == NSDateComponentUndefined || y <= 1604 { year = nil }
            result.append(Birthday(
                name: name,
                month: month,
                day: day,
                year: year,
                source: .contacts,
                contactIdentifier: contact.identifier,
                phoneNumber: contact.phoneNumbers.first?.value.stringValue,
                email: contact.emailAddresses.first.map { String($0.value) },
                imageData: contact.thumbnailImageData
            ))
        }
        return result
    }
}
