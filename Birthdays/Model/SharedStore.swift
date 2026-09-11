import Foundation

/// Where the app and the widget both read the birthday list.
enum SharedStore {
    static let appGroup = "group.com.giantrub.Birthdays"

    static var fileURL: URL {
        let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("birthdays.json")
    }

    static func load() -> [Birthday] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Birthday].self, from: data)) ?? []
    }
}
