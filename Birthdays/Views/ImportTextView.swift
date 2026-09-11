import SwiftUI

struct ImportTextView: View {
    @Environment(BirthdayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    private var parsed: [TextImporter.ParsedLine] { TextImporter.parse(text) }
    private var found: [Birthday] { parsed.compactMap(\.birthday) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $text)
                        .focused($focused)
                        .frame(minHeight: 120)
                    PasteButton(payloadType: String.self) { strings in
                        text = strings.joined(separator: "\n")
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonBorderShape(.capsule)
                } header: {
                    Text("Paste a List")
                } footer: {
                    Text("One birthday per line. Name first, then the date.\nAnna Meier, 14 September 1990\nTom Weber 3.7.\nSam 1985-12-24")
                }

                if !parsed.isEmpty {
                    Section("Found \(found.count)") {
                        ForEach(parsed) { line in
                            if let birthday = line.birthday {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(birthday.name)
                                        Text(birthday.longDateText)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } else {
                                HStack(spacing: 12) {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundStyle(.secondary)
                                    Text(line.raw)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(found.isEmpty ? "Import" : "Import (\(found.count))") {
                        store.merge(found)
                        dismiss()
                    }
                    .disabled(found.isEmpty)
                }
            }
            .onAppear { focused = true }
        }
    }
}
