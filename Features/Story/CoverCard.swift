import SwiftUI

struct CoverCard: View {
    let report: ChatReport
    let theme: StoryTheme
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Sticker(text: L10n.tr("story.yearReport", report.year), background: theme.accent, foreground: theme.onAccent)
                .padding(.top, 6)
            Text(verbatim: report.title)
                .displayStyle(compact ? 84 : 108, tracking: -0.06)
                .lineLimit(2)
                .minimumScaleFactor(0.3)
                .multilineTextAlignment(.leading)
                .padding(.top, 22)
                .accessibilityAddTraits(.isHeader)
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
