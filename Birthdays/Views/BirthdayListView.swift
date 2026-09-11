import SwiftUI

enum ImportKind: String, Identifiable {
    case contacts, calendar, text
    var id: String { rawValue }
}

struct BirthdayListView: View {
    @Environment(BirthdayStore.self) private var store
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var importKind: ImportKind?

    private var filtered: [Birthday] {
        guard !searchText.isEmpty else { return store.birthdays }
        return store.birthdays.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.birthdays.isEmpty {
                    EmptyBirthdaysView(
                        onImport: { importKind = .contacts },
                        onAdd: { showingAdd = true }
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Birthdays")
            .toolbar { toolbarContent }
            .navigationDestination(for: UUID.self) { id in
                BirthdayDetailView(id: id)
            }
        }
        .sheet(isPresented: $showingAdd) { BirthdayFormView(mode: .add) }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(item: $importKind) { kind in ImportView(kind: kind) }
    }

    private var list: some View {
        List {
            ForEach(BirthdaySections.build(from: filtered)) { section in
                Section(section.title) {
                    ForEach(section.birthdays) { birthday in
                        NavigationLink(value: birthday.id) {
                            BirthdayRow(birthday: birthday)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.delete(birthday)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search")
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Import") {
                    Button { importKind = .contacts } label: {
                        Label("From Contacts", systemImage: "person.crop.circle")
                    }
                    Button { importKind = .calendar } label: {
                        Label("From Calendar", systemImage: "calendar")
                    }
                    Button { importKind = .text } label: {
                        Label("From Text", systemImage: "text.alignleft")
                    }
                }
                Button { showingSettings = true } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .bottomBar) {
            HStack {
                Button { showingAdd = true } label: {
                    Label("New Birthday", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                }
                Spacer()
            }
        }
    }
}

struct EmptyBirthdaysView: View {
    var onImport: () -> Void
    var onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Birthdays", systemImage: "birthday.cake")
        } description: {
            Text("Import the birthdays saved with your contacts, or add one yourself.")
        } actions: {
            Button("Import from Contacts", action: onImport)
                .buttonStyle(.borderedProminent)
            Button("Add Birthday", action: onAdd)
        }
    }
}
