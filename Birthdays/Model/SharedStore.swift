import Foundation

/// Where the app and the widget both read the birthday list.
enum SharedStore {
    static let appGroup = "group.com.giantrub.Birthdays"

    private static var legacyURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("birthdays.json")
    }

    static var fileURL: URL {
        let fm = FileManager.default
        guard let group = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            try? fm.createDirectory(at: legacyURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            return legacyURL
        }
        let url = group.appendingPathComponent("birthdays.json")
        // Data saved before the app group existed moves over once.
        if !fm.fileExists(atPath: url.path), fm.fileExists(atPath: legacyURL.path) {
            try? fm.copyItem(at: legacyURL, to: url)
        }
        return url
    }

    static func load() -> [Birthday] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Birthday].self, from: data)) ?? []
    }
}
