import SwiftUI

struct ImportView: View {
    let kind: ImportKind

    var body: some View {
        switch kind {
        case .contacts:
            ImportPickerView(
                title: "Contacts",
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
                title: "Calendar",
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

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(importTitle) { importSelected() }
                            .disabled(selected.isEmpty)
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
        let new = items.filter { !store.contains($0) }
        let existing = items.filter { store.contains($0) }
        return List {
            if !new.isEmpty {
                Section {
                    ForEach(new) { birthday in
                        row(birthday)
                    }
                } header: {
                    HStack {
                        Text("\(new.count) New")
                        Spacer()
                        Button(selected.count == new.count ? "Deselect All" : "Select All") {
                            if selected.count == new.count { selected.removeAll() } else { selected = Set(new.map(\.id)) }
                        }
                        .font(.footnote)
                        .textCase(nil)
                    }
                }
            }
            if !existing.isEmpty {
                Section("Already Added") {
                    ForEach(existing) { birthday in
                        HStack(spacing: 12) {
                            AvatarView(birthday: birthday, size: 40)
                            rowText(birthday)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func row(_ birthday: Birthday) -> some View {
        let isOn = selected.contains(birthday.id)
        return Button {
            if isOn { selected.remove(birthday.id) } else { selected.insert(birthday.id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn ? Color.accentColor : Color(.tertiaryLabel))
                AvatarView(birthday: birthday, size: 40)
                rowText(birthday)
                Spacer()
            }
        }
        .foregroundStyle(.primary)
    }

    private func rowText(_ birthday: Birthday) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(birthday.name)
            Text(birthday.longDateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var importTitle: String {
        selected.isEmpty ? "Import" : "Import (\(selected.count))"
    }

    private func loadItems() async {
        do {
            if let items = try await load() {
                let new = items.filter { !store.contains($0) }
                selected = Set(new.map(\.id))
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
