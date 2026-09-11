import SwiftUI

struct BirthdayRow: View {
    let birthday: Birthday
    /// Off in the Today / Next 7 Days sections, where the header already says when.
    var showsCountdown = true

    private var subtitle: String {
        let date = birthday.nextOccurrence().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        if let age = birthday.ageTurning() {
            return "\(date) · Turns \(age)"
        }
        return date
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(birthday: birthday, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(birthday.name)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            if showsCountdown {
                Text(birthday.countdownText())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
        .padding(.vertical, 2)
        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] + 52 }
    }
}
