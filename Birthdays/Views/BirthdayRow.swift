import SwiftUI

struct BirthdayRow: View {
    let birthday: Birthday

    private var isToday: Bool { birthday.daysUntil() == 0 }

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
            }
            Spacer(minLength: 8)
            Text(birthday.countdownText())
                .font(.subheadline)
                .foregroundStyle(isToday ? Color.accentColor : Color.secondary)
        }
        .padding(.vertical, 2)
    }
}
