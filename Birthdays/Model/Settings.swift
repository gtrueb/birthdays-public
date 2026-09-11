import Foundation

enum SettingsKey {
    static let notificationsEnabled = "notificationsEnabled"
    static let remindDayBefore = "remindDayBefore"
    static let remindWeekBefore = "remindWeekBefore"
    static let reminderMinutes = "reminderMinutes"
}

struct NotificationPreferences {
    var enabled: Bool
    var dayBefore: Bool
    var weekBefore: Bool
    /// Minutes after midnight. Default 9:00.
    var minutesSinceMidnight: Int

    static var current: NotificationPreferences {
        let d = UserDefaults.standard
        return NotificationPreferences(
            enabled: d.bool(forKey: SettingsKey.notificationsEnabled),
            dayBefore: d.object(forKey: SettingsKey.remindDayBefore) as? Bool ?? true,
            weekBefore: d.bool(forKey: SettingsKey.remindWeekBefore),
            minutesSinceMidnight: d.object(forKey: SettingsKey.reminderMinutes) as? Int ?? 540
        )
    }
}
