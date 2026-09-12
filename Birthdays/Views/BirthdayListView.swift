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
                let all = BirthdaySections.build(from: store.birthdays).flatMap(\.birthdays)
                if let pick = all.first(where: { $0.daysUntil() > 7 }) ?? all.first { path.append(pick.id) }
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
            // Headers are plain rows, so the spacing around them is exact.
            let sections = BirthdaySections.build(from: filtered)
            ForEach(sections) { section in
                // Like Reminders: the first group is loud, later groups are quiet.
                Text(section.title)
                    .font(section.id == sections.first?.id ? .title2.weight(.bold) : .headline)
                    .foregroundStyle(section.id == sections.first?.id ? Color(.label) : Color(.secondaryLabel))
                    .listRowInsets(EdgeInsets(top: section.id == sections.first?.id ? 4 : 24, leading: 20, bottom: 6, trailing: 20))
                    .listRowSeparator(.hidden)
                ForEach(section.birthdays) { birthday in
                    // A hidden NavigationLink keeps the native press-and-push feel without the chevron.
                    ZStack {
                        NavigationLink(value: birthday.id) { EmptyView() }
                            .opacity(0)
                        BirthdayRow(birthday: birthday, showsDate: section.id != "today")
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .listRowSeparator(birthday.id == section.birthdays.first?.id ? .hidden : .visible, edges: .top)
                    .listRowSeparator(.visible, edges: .bottom)
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
        .listStyle(.plain)
        .contentMargins(.top, 0, for: .scrollContent)
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
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 21))
                        Text("New Birthday")
                            .fontWeight(.semibold)
                    }
                }
                .padding(.leading, -10)
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
            Text("Birthdays you add will appear here.")
        } actions: {
            Button("Import from Contacts", action: onImport)
        }
    }
}
