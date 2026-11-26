import SwiftUI

struct CoverCard: View {
    let report: ChatReport
    let theme: StoryTheme
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Sticker(text: L10n.tr("story.yearReport", report.year), background: theme.accent, foreground: theme.onAccent)
                .padding(.top, 6)
            CoverTitle(text: report.title, compact: compact)
                .padding(.top, 22)
            Text(verbatim: L10n.tr("cover.lead"))
                .font(.ui(17))
                .lineSpacing(4)
                .opacity(0.88)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 22)
            Spacer(minLength: 16)
            Rectangle().fill(theme.foreground).frame(height: 2)
            HStack(alignment: .top, spacing: 12) {
                stat(Format.number(report.totalMessages), L10n.tr("cover.stat.messages"))
                stat(Format.number(report.participantCount), L10n.tr("cover.stat.people"))
                stat(Format.number(report.activeDays), L10n.tr("cover.stat.days"))
            }
            .padding(.top, 16)
        }
        .foregroundStyle(theme.foreground)
    }

    private func stat(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: value)
                .displayStyle(34)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(verbatim: caption)
                .labelStyle(12, tracking: 0.06)
                .opacity(0.78)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Long WhatsApp titles stay in the text face. The poster face is only for a short name.
struct CoverTitle: View {
    let text: String
    let compact: Bool

    private var isLong: Bool { text.count > 18 }

    var body: some View {
        Text(verbatim: text)
            .font(isLong ? .ui(compact ? 30 : 34, .bold) : .display(compact ? 84 : 100))
            .tracking(isLong ? -0.4 : (compact ? -3.4 : -4))
            .lineSpacing(isLong ? 3 : 0)
            .lineLimit(isLong ? 3 : 2)
            .minimumScaleFactor(isLong ? 0.8 : 0.5)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}
