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
    @State private var path = NavigationPath()

    private var filtered: [Birthday] {
        guard !searchText.isEmpty else { return store.birthdays }
        return store.birthdays.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack(path: $path) {
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
            .toolbar(store.birthdays.isEmpty ? .hidden : .visible, for: .bottomBar)
            .navigationDestination(for: UUID.self) { id in
                BirthdayDetailView(id: id)
            }
        }
        .sheet(isPresented: $showingAdd) { BirthdayFormView(mode: .add) }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(item: $importKind) { kind in ImportView(kind: kind) }
        .onAppear { openDebugScreen() }
    }

    /// Debug only: `-screen detail|add|settings|contacts|calendar|text` opens that screen on launch.
    private func openDebugScreen() {
        #if DEBUG
        guard let index = CommandLine.arguments.firstIndex(of: "-screen"),
              CommandLine.arguments.indices.contains(index + 1) else { return }
        let screen = CommandLine.arguments[index + 1]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            switch screen {
            case "detail":
                if let first = BirthdaySections.build(from: store.birthdays).first?.birthdays.first { path.append(first.id) }
            case "add": showingAdd = true
            case "settings": showingSettings = true
            case "contacts": importKind = .contacts
            case "calendar": importKind = .calendar
            case "text": importKind = .text
            default: break
            }
        }
        #endif
    }

    private var list: some View {
        List {
            ForEach(BirthdaySections.build(from: filtered)) { section in
                Section(section.title) {
                    ForEach(section.birthdays) { birthday in
                        Button {
                            path.append(birthday.id)
                        } label: {
                            BirthdayRow(birthday: birthday, showsCountdown: !section.isRelative)
                        }
                        .foregroundStyle(.primary)
                        .listRowSeparator(.hidden, edges: .top)
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
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
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
                Button { showingAdd = true } label: {
                    Label("New Birthday", systemImage: "plus")
                }
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
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("New Birthday")
                            .fontWeight(.bold)
                    }
                }
                .padding(.leading, -8)
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
            Text("Import birthdays from Contacts, or add one from the menu.")
        } actions: {
            Button("Import from Contacts", action: onImport)
        }
    }
}
