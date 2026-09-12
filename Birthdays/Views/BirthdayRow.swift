import SwiftUI

struct BirthdayRow: View {
    let birthday: Birthday
    /// Off in the Today section, where the header already says when.
    var showsDate = true

    private var subtitle: String? {
        guard showsDate else { return nil }
        return birthday.nextOccurrence().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        HStack(spacing: 16) {
            AvatarView(birthday: birthday, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(birthday.name)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            if let age = birthday.ageTurning() {
                Text("Turns \(age)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
        .padding(.vertical, 0)
        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] + 56 }
    }
}
