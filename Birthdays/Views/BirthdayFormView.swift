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
    @State private var showingPicker = false
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
        case .edit(let b):
            _name = State(initialValue: b.name)
            _notes = State(initialValue: b.notes)
            _month = State(initialValue: b.month)
            _day = State(initialValue: b.day)
            _year = State(initialValue: b.year ?? 0)
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

    private var dateText: String {
        var comps = DateComponents(year: year == 0 ? 2024 : year, month: month, day: day)
        comps.hour = 12
        guard let date = Calendar.current.date(from: comps) else { return "" }
        return year == 0
            ? date.formatted(.dateTime.month(.wide).day())
            : date.formatted(.dateTime.month(.wide).day().year())
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
                        .lineLimit(3...6)
                }

                Section {
                    Button {
                        withAnimation(.snappy) { showingPicker.toggle() }
                        nameFocused = false
                    } label: {
                        LabeledContent("Birthday") {
                            // Styled like the compact system date picker.
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
            .onChange(of: month) { _, _ in clampDay() }
            .onChange(of: year) { _, _ in clampDay() }
            .onAppear {
                if !isEditing { nameFocused = true }
            }
        }
    }

    /// Month, day and year wheels side by side, like the birthday field in Contacts.
    private var datePicker: some View {
        HStack(spacing: 0) {
            Picker("Month", selection: $month) {
                ForEach(1...12, id: \.self) { m in
                    Text(Calendar.current.monthSymbols[m - 1]).tag(m)
                }
            }
            Picker("Day", selection: $day) {
                ForEach(1...daysInMonth, id: \.self) { d in
                    Text("\(d)").tag(d)
                }
            }
            Picker("Year", selection: $year) {
                Text("—").tag(0)
                ForEach((1900...currentYear).reversed(), id: \.self) { y in
                    Text(String(y)).tag(y)
                }
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 180)
        .listRowInsets(EdgeInsets())
    }

    private var daysInMonth: Int {
        // Without a year, allow the 29th of February.
        let cal = Calendar.current
        let comps = DateComponents(year: year == 0 ? 2024 : year, month: month)
        guard let date = cal.date(from: comps), let range = cal.range(of: .day, in: .month, for: date) else { return 31 }
        return range.count
    }

    private func clampDay() {
        if day > daysInMonth { day = daysInMonth }
    }

    private func save() {
        switch mode {
        case .add:
            store.add(Birthday(name: trimmedName, month: month, day: day, year: year == 0 ? nil : year, notes: notes))
        case .edit(var b):
            b.name = trimmedName
            b.month = month
            b.day = day
            b.year = year == 0 ? nil : year
            b.notes = notes
            store.update(b)
        }
        dismiss()
    }
}
