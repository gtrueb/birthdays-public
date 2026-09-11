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
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))

                if let phone = birthday.phoneNumber, !phone.isEmpty {
                    Section {
                        HStack(spacing: 8) {
                            actionButton("Message", systemImage: "message.fill") {
                                open("sms:", phone)
                            }
                            actionButton("Call", systemImage: "phone.fill") {
                                open("tel:", phone)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    LabeledContent("Birthday", value: birthday.longDateText)
                    if let age = birthday.currentAge() {
                        LabeledContent("Age", value: "\(age)")
                    }
                    LabeledContent("Next Birthday", value: nextText(birthday))
                }

                if !birthday.notes.isEmpty {
                    Section("Notes") {
                        Text(birthday.notes)
                    }
                }
            }
            .listStyle(.insetGrouped)
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

    private func header(_ birthday: Birthday) -> some View {
        VStack(spacing: 6) {
            AvatarView(birthday: birthday, size: 100)
                .padding(.bottom, 6)
            Text(birthday.name)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(headline(birthday))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func headline(_ birthday: Birthday) -> String {
        if let age = birthday.ageTurning() {
            return "Turns \(age) \(birthday.relativeText())"
        }
        return "Birthday \(birthday.relativeText())"
    }

    private func nextText(_ birthday: Birthday) -> String {
        birthday.nextOccurrence().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
    }

    private func open(_ scheme: String, _ phone: String) {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: scheme + digits) { openURL(url) }
    }
}
