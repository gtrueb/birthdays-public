import Foundation
import UserNotifications

enum NotificationScheduler {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        return granted
    }

    /// Replaces all pending notifications with fresh ones for the nearest birthdays.
    static func reschedule(_ birthdays: [Birthday]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let prefs = NotificationPreferences.current
        guard prefs.enabled else { return }

        let cal = Calendar.current
        // iOS keeps at most 64 pending requests per app.
        let upcoming = birthdays.filter(\.notify).sorted { $0.daysUntil() < $1.daysUntil() }.prefix(20)

        for birthday in upcoming {
            let minutes = birthday.reminderMinutes ?? prefs.minutesSinceMidnight
            let hour = minutes / 60
            let minute = minutes % 60
            let next = birthday.nextOccurrence()
            let age = birthday.ageTurning()
            schedule(center, id: "\(birthday.id)-day", on: next, hour: hour, minute: minute,
                     title: "\(birthday.name)'s Birthday",
                     body: age.map { "\(birthday.name) turns \($0) today." } ?? "It's \(birthday.name)'s birthday today.")

            if prefs.dayBefore, let date = cal.date(byAdding: .day, value: -1, to: next) {
                schedule(center, id: "\(birthday.id)-1", on: date, hour: hour, minute: minute,
                         title: "\(birthday.name)'s Birthday Tomorrow",
                         body: age.map { "\(birthday.name) turns \($0) tomorrow." } ?? "\(birthday.name)'s birthday is tomorrow.")
            }
            if prefs.weekBefore, let date = cal.date(byAdding: .day, value: -7, to: next) {
                schedule(center, id: "\(birthday.id)-7", on: date, hour: hour, minute: minute,
                         title: "\(birthday.name)'s Birthday in a Week",
                         body: age.map { "\(birthday.name) turns \($0) in 7 days." } ?? "\(birthday.name)'s birthday is in 7 days.")
            }
        }
    }

    private static func schedule(_ center: UNUserNotificationCenter, id: String, on date: Date,
                                 hour: Int, minute: Int, title: String, body: String) {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        guard let fireDate = Calendar.current.date(from: comps), fireDate > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
