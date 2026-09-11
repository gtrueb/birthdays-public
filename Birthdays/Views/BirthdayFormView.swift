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
    @State private var includeYear: Bool
    @State private var month: Int
    @State private var day: Int
    @State private var fullDate: Date
    @State private var confirmDelete = false

    init(mode: Mode) {
        self.mode = mode
        let cal = Calendar.current
        switch mode {
        case .add:
            let today = cal.dateComponents([.month, .day], from: .now)
            _name = State(initialValue: "")
            _notes = State(initialValue: "")
            _includeYear = State(initialValue: false)
            _month = State(initialValue: today.month ?? 1)
            _day = State(initialValue: today.day ?? 1)
            _fullDate = State(initialValue: .now)
        case .edit(let b):
            _name = State(initialValue: b.name)
            _notes = State(initialValue: b.notes)
            _includeYear = State(initialValue: b.year != nil)
            _month = State(initialValue: b.month)
            _day = State(initialValue: b.day)
            _fullDate = State(initialValue: b.birthDate ?? .now)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    if includeYear {
                        DatePicker("Birthday", selection: $fullDate, in: ...Date.now, displayedComponents: .date)
                    } else {
                        Picker("Month", selection: $month) {
                            ForEach(1...12, id: \.self) { m in
                                Text(monthName(m)).tag(m)
                            }
                        }
                        Picker("Day", selection: $day) {
                            ForEach(1...daysInMonth, id: \.self) { d in
                                Text("\(d)").tag(d)
                            }
                        }
                    }
                    Toggle("Include Year", isOn: $includeYear.animation())
                }

                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
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
            .onChange(of: includeYear) { _, on in
                let cal = Calendar.current
                if on {
                    var comps = DateComponents(year: cal.component(.year, from: .now), month: month, day: day)
                    if let date = cal.date(from: comps), date > .now {
                        comps.year = (comps.year ?? 0) - 1
                    }
                    fullDate = cal.date(from: comps) ?? .now
                } else {
                    let comps = cal.dateComponents([.month, .day], from: fullDate)
                    month = comps.month ?? month
                    day = comps.day ?? day
                }
            }
            .onChange(of: month) { _, _ in
                if day > daysInMonth { day = daysInMonth }
            }
        }
    }

    private var daysInMonth: Int {
        // Without a year, allow the 29th of February.
        let cal = Calendar.current
        let comps = DateComponents(year: 2024, month: month)
        guard let date = cal.date(from: comps), let range = cal.range(of: .day, in: .month, for: date) else { return 31 }
        return range.count
    }

    private func monthName(_ m: Int) -> String {
        Calendar.current.monthSymbols[m - 1]
    }

    private func save() {
        let cal = Calendar.current
        var year: Int?
        var m = month, d = day
        if includeYear {
            let comps = cal.dateComponents([.year, .month, .day], from: fullDate)
            year = comps.year
            m = comps.month ?? month
            d = comps.day ?? day
        }
        switch mode {
        case .add:
            store.add(Birthday(name: trimmedName, month: m, day: d, year: year, notes: notes))
        case .edit(var b):
            b.name = trimmedName
            b.month = m
            b.day = d
            b.year = year
            b.notes = notes
            store.update(b)
        }
        dismiss()
    }
}
