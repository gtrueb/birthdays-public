import SwiftUI

struct BirthdayDetailView: View {
    @Environment(BirthdayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let id: UUID
    @State private var editing = false

    var body: some View {
        if let birthday = store.birthday(id: id) {
            List {
                Section {
                    header(birthday)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                if hasContactActions(birthday) {
                    Section {
                        actionTiles(birthday)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    Button { openCalendar(birthday) } label: {
                        field("birthday", value: birthday.longDateText, tinted: true)
                    }
                }

                if !birthday.notes.isEmpty {
                    Section {
                        field("notes", value: birthday.notes)
                    }
                }

                Section {
                    ShareLink(item: shareText(birthday)) {
                        Text("Share Birthday")
                    }
                }

            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(16)
            .environment(\.defaultMinListRowHeight, 44)
            .contentMargins(.top, 16, for: .scrollContent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { editing = true }
                }
            }
            .sheet(isPresented: $editing) {
                BirthdayFormView(mode: .edit(birthday))
            }
        } else {
            Color.clear.onAppear { dismiss() }
        }
    }

    // MARK: - Header

    private func header(_ birthday: Birthday) -> some View {
        VStack(spacing: 4) {
            AvatarView(birthday: birthday, size: 96)
                .padding(.bottom, 8)
            Text(birthday.name)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(headline(birthday))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    /// "Turns 29 in 15 days, Sunday, September 27" — one secondary line, like Contacts.
    private func headline(_ birthday: Birthday) -> String {
        let lead = birthday.ageTurning().map { "Turns \($0) \(birthday.relativeText())" } ?? "Birthday \(birthday.relativeText())"
        return birthday.daysUntil() > 1 ? "\(lead), \(nextText(birthday))" : lead
    }

    private func nextText(_ birthday: Birthday) -> String {
        switch birthday.daysUntil() {
        case 1: return "Tomorrow"
        default: return birthday.nextOccurrence().formatted(.dateTime.weekday(.wide).month(.wide).day())
        }
    }

    private func shareText(_ birthday: Birthday) -> String {
        "\(birthday.name)'s birthday is on \(birthday.nextOccurrence().formatted(.dateTime.weekday(.wide).month(.wide).day()))."
    }

    /// Opens Calendar on the next occurrence, like tapping a birthday in Contacts.
    private func openCalendar(_ birthday: Birthday) {
        let seconds = birthday.nextOccurrence().timeIntervalSinceReferenceDate
        open("calshow:\(Int(seconds))")
    }

    // MARK: - Contacts-style action tiles

    private func hasContactActions(_ birthday: Birthday) -> Bool {
        !(birthday.phoneNumber ?? "").isEmpty || !(birthday.email ?? "").isEmpty
    }

    private func actionTiles(_ birthday: Birthday) -> some View {
        let phone = birthday.phoneNumber?.filter { $0.isNumber || $0 == "+" } ?? ""
        let email = birthday.email ?? ""
        return HStack(spacing: 8) {
            tile("message", systemImage: "message.fill", enabled: !phone.isEmpty) { open("sms:" + phone) }
            tile("call", systemImage: "phone.fill", enabled: !phone.isEmpty) { open("tel:" + phone) }
            tile("video", systemImage: "video.fill", enabled: !phone.isEmpty) { open("facetime:" + phone) }
            tile("mail", systemImage: "envelope.fill", enabled: !email.isEmpty) { open("mailto:" + email) }
        }
    }

    private func tile(_ title: String, systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 21, weight: .regular))
                    .frame(width: 26, height: 24)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? Color.accentColor : Color(.tertiaryLabel))
        .disabled(!enabled)
    }

    private func open(_ string: String) {
        if let url = URL(string: string) { openURL(url) }
    }

    // MARK: - Contacts-style stacked field

    private func field(_ label: String, value: String, tinted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Color(.secondaryLabel))
            Text(value)
                .font(.body)
                .foregroundStyle(tinted ? Color.accentColor : Color(.label))
        }
        .padding(.vertical, 2)
    }
}
