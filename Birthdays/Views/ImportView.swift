import SwiftUI

struct ImportView: View {
    let kind: ImportKind

    var body: some View {
        switch kind {
        case .contacts:
            ImportPickerView(
                title: "Choose Contacts",
                newHeader: "New Contacts",
                emptyTitle: "No Birthdays Found",
                emptyMessage: "None of your contacts have a birthday saved.",
                deniedTitle: "No Access to Contacts",
                deniedMessage: "Allow Birthdays to read your contacts in Settings.",
                load: {
                    guard await ContactsImporter.requestAccess() else { return nil }
                    return try ContactsImporter.fetchBirthdays()
                }
            )
        case .calendar:
            ImportPickerView(
                title: "Choose Events",
                newHeader: "New Events",
                emptyTitle: "No Birthdays Found",
                emptyMessage: "There are no birthday events in your calendars for the next year.",
                deniedTitle: "No Access to Calendar",
                deniedMessage: "Allow Birthdays to read your calendars in Settings.",
                load: {
                    guard await CalendarImporter.requestAccess() else { return nil }
                    return CalendarImporter.fetchBirthdays()
                }
            )
        case .text:
            ImportTextView()
        }
    }
}

/// A list of found birthdays with checkmarks. Used for Contacts and Calendar.
struct ImportPickerView: View {
    enum Status {
        case loading
        case denied
        case loaded([Birthday])
        case failed(String)
    }

    let title: String
    let newHeader: String
    let emptyTitle: String
    let emptyMessage: String
    let deniedTitle: String
    let deniedMessage: String
    /// Returns nil when access was denied.
    let load: () async throws -> [Birthday]?

    @Environment(BirthdayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var status: Status = .loading
    @State private var selected = Set<UUID>()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(selected.isEmpty ? title : "\(selected.count) Selected")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .task { await loadItems() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch status {
        case .loading:
            ProgressView()
        case .denied:
            ContentUnavailableView {
                Label(deniedTitle, systemImage: "lock")
            } description: {
                Text(deniedMessage)
            } actions: {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .buttonStyle(.borderedProminent)
            }
        case .failed(let message):
            ContentUnavailableView(emptyTitle, systemImage: "exclamationmark.triangle", description: Text(message))
        case .loaded(let items) where items.isEmpty:
            ContentUnavailableView(emptyTitle, systemImage: "birthday.cake", description: Text(emptyMessage))
        case .loaded(let items):
            list(items)
        }
    }

    private func list(_ items: [Birthday]) -> some View {
        let new = items.filter { !store.contains($0) && matches($0) }
        let existing = items.filter { store.contains($0) && matches($0) }
        // Native multi-select: system circles, gray selected rows.
        return List(selection: $selected) {
            if !new.isEmpty {
                Section {
                    ForEach(new) { birthday in
                        rowText(birthday)
                            .tag(birthday.id)
                    }
                }
            }
            if !existing.isEmpty {
                Section("Already Added") {
                    ForEach(existing) { birthday in
                        HStack {
                            rowText(birthday)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.secondary)
                        .selectionDisabled()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(selected.count == new.count && !new.isEmpty ? "Deselect All" : "Select All") {
                    if selected.count == new.count { selected.removeAll() } else { selected = Set(new.map(\.id)) }
                }
                .disabled(new.isEmpty)
            }
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    Button("Import") { importSelected() }
                        .fontWeight(.semibold)
                        .disabled(selected.isEmpty)
                }
            }
        }
    }

    private func matches(_ birthday: Birthday) -> Bool {
        searchText.isEmpty || birthday.name.localizedCaseInsensitiveContains(searchText)
    }

    private func rowText(_ birthday: Birthday) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(birthday.name)
            Text(birthday.longDateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func loadItems() async {
        do {
            if let items = try await load() {
                status = .loaded(items)
            } else {
                status = .denied
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    private func importSelected() {
        guard case .loaded(let items) = status else { return }
        store.merge(items.filter { selected.contains($0.id) })
        dismiss()
    }
}
