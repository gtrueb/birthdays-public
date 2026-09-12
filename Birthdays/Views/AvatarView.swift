import SwiftUI

struct AvatarView: View {
    let birthday: Birthday
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let data = birthday.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [Color(.systemGray), Color(.darkGray)],
                                   startPoint: .top, endPoint: .bottom)
                    Text(birthday.initials)
                        .font(.system(size: size * 0.44, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
