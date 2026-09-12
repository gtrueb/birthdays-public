import SwiftUI

struct BirthdayFormView: View {
    enum Mode {
        case add
        case edit(Birthday)
    }

    @Environment(BirthdayStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    @State private var name: String
    @State private var notes: String
    @State private var month: Int
    @State private var day: Int
    /// 0 means "no year", like the dashes in the Contacts birthday wheel.
    @State private var year: Int
    @State private var notify: Bool
    @State private var reminderTime: Date
    @State private var showingPicker: Bool
    @State private var confirmDelete = false
    @FocusState private var nameFocused: Bool

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            let today = Calendar.current.dateComponents([.month, .day], from: .now)
            _name = State(initialValue: "")
            _notes = State(initialValue: "")
            _month = State(initialValue: today.month ?? 1)
            _day = State(initialValue: today.day ?? 1)
            _year = State(initialValue: 0)
            _notify = State(initialValue: true)
            _reminderTime = State(initialValue: Self.time(minutes: NotificationPreferences.current.minutesSinceMidnight))
            _showingPicker = State(initialValue: false)
        case .edit(let b):
            _name = State(initialValue: b.name)
            _notes = State(initialValue: b.notes)
            _month = State(initialValue: b.month)
            _day = State(initialValue: b.day)
            _year = State(initialValue: b.year ?? 0)
            _notify = State(initialValue: b.notify)
            _reminderTime = State(initialValue: Self.time(minutes: b.reminderMinutes ?? NotificationPreferences.current.minutesSinceMidnight))
            _showingPicker = State(initialValue: false)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    private static func time(minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    }

    /// Nil when the chosen time equals the app-wide default.
    private var reminderMinutesOverride: Int? {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let minutes = (comps.hour ?? 9) * 60 + (comps.minute ?? 0)
        return minutes == NotificationPreferences.current.minutesSinceMidnight ? nil : minutes
    }

    private var dateText: String {
        var comps = DateComponents(year: year == 0 ? 2024 : year, month: month, day: day)
        comps.hour = 12
        guard let date = Calendar.current.date(from: comps) else { return "" }
        return year == 0
            ? date.formatted(.dateTime.month(.abbreviated).day())
            : date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .focused($nameFocused)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section {
                    Button {
                        withAnimation(.snappy) { showingPicker.toggle() }
                        nameFocused = false
                    } label: {
                        HStack(spacing: 16) {
                            badge("calendar", color: .red, size: 16)
                            Text("Date")
                            Spacer()
                            Text(dateText)
                                .foregroundStyle(showingPicker ? Color.accentColor : Color.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .foregroundStyle(.primary)

                    if showingPicker {
                        datePicker
                    }

                    Toggle(isOn: $notify.animation()) {
                        HStack(spacing: 16) {
                            badge("bell.fill", color: .orange, size: 17)
                            Text("Remind Me")
                        }
                    }
                    if notify {
                        DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                            HStack(spacing: 16) {
                                badge("clock.fill", color: .blue, size: 17)
                                Text("Time")
                            }
                        }
                    }
                } footer: {
                    if notify {
                        Text("You'll be notified at \(reminderTime.formatted(date: .omitted, time: .shortened)) on the day.")
                    }
                }

                if isEditing {
                    Section {
                        Button("Delete Birthday", role: .destructive) {
                            confirmDelete = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .listSectionSpacing(16)
            .contentMargins(.top, 8, for: .scrollContent)
            .navigationTitle(isEditing ? "Edit Birthday" : "New Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Done" : "Add") { save() }
                        .disabled(trimmedName.isEmpty)
                }
            }
            .confirmationDialog("Delete this birthday?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete Birthday", role: .destructive) {
                    if case .edit(let b) = mode { store.delete(b) }
                    dismiss()
                }
            }
            .onAppear {
                if !isEditing { nameFocused = true }
            }
        }
    }

    /// The 29pt tinted square Apple puts in front of rows in Reminders and Settings.
    private func badge(_ systemImage: String, color: Color, size: CGFloat = 17) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var datePicker: some View {
        BirthdayWheelPicker(month: $month, day: $day, year: $year)
            .frame(maxWidth: .infinity)
            .frame(height: 216)
            .listRowInsets(EdgeInsets())
    }

    private var daysInMonth: Int {
        // Without a year, allow the 29th of February.
        let cal = Calendar.current
        let comps = DateComponents(year: year == 0 ? 2024 : year, month: month)
        guard let date = cal.date(from: comps), let range = cal.range(of: .day, in: .month, for: date) else { return 31 }
        return range.count
    }

    private func save() {
        switch mode {
        case .add:
            store.add(Birthday(name: trimmedName, month: month, day: day, year: year == 0 ? nil : year, notes: notes,
                               notify: notify, reminderMinutes: reminderMinutesOverride))
        case .edit(var b):
            b.name = trimmedName
            b.month = month
            b.day = day
            b.year = year == 0 ? nil : year
            b.notes = notes
            b.notify = notify
            b.reminderMinutes = reminderMinutesOverride
            store.update(b)
        }
        dismiss()
    }
}
