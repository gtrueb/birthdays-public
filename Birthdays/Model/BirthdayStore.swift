import Foundation
import Observation
import WidgetKit

@Observable
final class BirthdayStore {
    private(set) var birthdays: [Birthday] = []
    @ObservationIgnored private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? SharedStore.fileURL
        load()
    }

    func birthday(id: UUID) -> Birthday? {
        birthdays.first { $0.id == id }
    }

    func add(_ birthday: Birthday) {
        birthdays.append(birthday)
        save()
    }

    func update(_ birthday: Birthday) {
        guard let index = birthdays.firstIndex(where: { $0.id == birthday.id }) else { return }
        birthdays[index] = birthday
        save()
    }

    func delete(_ birthday: Birthday) {
        birthdays.removeAll { $0.id == birthday.id }
        save()
    }

    func deleteAll() {
        birthdays.removeAll()
        save()
    }

    /// Adds birthdays that are not already present. Returns the number added.
    @discardableResult
    func merge(_ incoming: [Birthday]) -> Int {
        var added = 0
        for birthday in incoming where !contains(birthday) {
            birthdays.append(birthday)
            added += 1
        }
        if added > 0 { save() }
        return added
    }

    func contains(_ candidate: Birthday) -> Bool {
        birthdays.contains { existing in
            if let cid = candidate.contactIdentifier, cid == existing.contactIdentifier { return true }
            return existing.name.caseInsensitiveCompare(candidate.name) == .orderedSame
                && existing.month == candidate.month
                && existing.day == candidate.day
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        birthdays = (try? JSONDecoder().decode([Birthday].self, from: data)) ?? []
    }

    private func save() {
        if let data = try? JSONEncoder().encode(birthdays) {
            try? data.write(to: fileURL, options: .atomic)
        }
        NotificationScheduler.reschedule(birthdays)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
