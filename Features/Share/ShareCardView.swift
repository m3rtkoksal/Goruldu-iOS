import SwiftUI

/// The 9:16 card that is exported as an image. Laid out at 360 x 640 pt and rendered at 3x.
struct ShareCardView: View {
    static let size = CGSize(width: 360, height: 640)

    let content: ShareContent

    var body: some View {
        let theme = StoryTheme.theme(for: content.card)
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: content.group)
                .labelStyle(16, tracking: 0.06)
                .lineLimit(2)
            Spacer(minLength: 24)
            Text(verbatim: content.label)
                .labelStyle(18, tracking: 0.07)
                .lineLimit(2)
            Text(verbatim: content.name)
                .displayStyle(94, tracking: -0.05)
                .lineLimit(content.card == .cover ? 2 : 1)
                .minimumScaleFactor(0.25)
                .padding(.top, 10)
            if !content.stat.isEmpty {
                Text(verbatim: content.stat)
                    .displayStyle(34, tracking: -0.03)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 12)
            }
            if !content.note.isEmpty {
                Text(verbatim: content.note)
                    .font(.custom(Typeface.body(.medium), fixedSize: 20))
                    .lineSpacing(5)
                    .lineLimit(8)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 8)
            }
            Rectangle()
                .fill(theme.foreground.opacity(0.9))
                .frame(height: 2)
                .padding(.top, 32)
            HStack(spacing: 8) {
                TicksIcon(size: 20)
                Text(verbatim: L10n.tr("share.mark"))
                    .font(.custom(Typeface.body(.bold), fixedSize: 17))
            }
            .padding(.top, 16)
        }
        .foregroundStyle(theme.foreground)
        .padding(30)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .leading)
        .background(theme.background)
        .dynamicTypeSize(.large)
    }
}
