import SwiftUI

struct SettingsView: View {
    @Environment(BirthdayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(SettingsKey.notificationsEnabled) private var notificationsEnabled = false
    @AppStorage(SettingsKey.remindDayBefore) private var remindDayBefore = true
    @AppStorage(SettingsKey.remindWeekBefore) private var remindWeekBefore = false
    @AppStorage(SettingsKey.reminderMinutes) private var reminderMinutes = 540
    @State private var showDenied = false
    @State private var confirmDeleteAll = false

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminderMinutes / 60, minute: reminderMinutes % 60, second: 0, of: .now) ?? .now
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderMinutes = (comps.hour ?? 9) * 60 + (comps.minute ?? 0)
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Birthday Reminders", isOn: $notificationsEnabled)
                    if notificationsEnabled {
                        DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get notified on the morning of each birthday.")
                }

                if notificationsEnabled {
                    Section {
                        Toggle("1 Day Before", isOn: $remindDayBefore)
                        Toggle("1 Week Before", isOn: $remindWeekBefore)
                    } header: {
                        Text("Also Notify")
                    } footer: {
                        Text("Extra notifications ahead of the day, at the same time.")
                    }
                }

                Section {
                    Button("Delete All Birthdays", role: .destructive) {
                        confirmDeleteAll = true
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(store.birthdays.isEmpty)
                } footer: {
                    Text("Removes every birthday from this app. Your contacts won't be affected.")
                }
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .environment(\.defaultMinListRowHeight, 44)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: notificationsEnabled) { _, on in
                guard on else { reschedule(); return }
                Task {
                    if await NotificationScheduler.requestAuthorization() {
                        reschedule()
                    } else {
                        notificationsEnabled = false
                        showDenied = true
                    }
                }
            }
            .onChange(of: remindDayBefore) { _, _ in reschedule() }
            .onChange(of: remindWeekBefore) { _, _ in reschedule() }
            .onChange(of: reminderMinutes) { _, _ in reschedule() }
            .alert("Notifications Are Off", isPresented: $showDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Allow notifications for Birthdays in Settings.")
            }
            .confirmationDialog("Delete all \(store.birthdays.count) birthdays?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    store.deleteAll()
                    dismiss()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
        .presentationDetents([.height(notificationsEnabled ? 486 : 278)])
        .presentationDragIndicator(.visible)
    }

    private func reschedule() {
        NotificationScheduler.reschedule(store.birthdays)
    }
}
