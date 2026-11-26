import SwiftUI

struct TalkerCard: View {
    let report: ChatReport
    let number: String
    let theme: StoryTheme
    let compact: Bool

    var body: some View {
        let talker = report.talker
        let rows = Array(report.participants.prefix(compact ? 5 : 8))
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("story.award", number, L10n.tr("award.talker")))
            WinnerName(name: talker.name, size: compact ? 76 : 100)
                .padding(.top, 14)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: Format.number(talker.messages))
                    .displayStyle(46, tracking: -0.045)
                Text(verbatim: L10n.tr("cover.stat.messages"))
                    .font(.ui(21, .bold))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.top, 12)
            Text(verbatim: L10n.tr("talker.note", Format.percent(talker.sharePercent)))
                .font(.ui(16))
                .lineSpacing(3)
                .opacity(0.84)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            Spacer(minLength: 16)
            VStack(spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.offset) { position, person in
                    row(person, isTop: position == 0, top: max(1, talker.messages))
                }
            }
        }
        .foregroundStyle(theme.foreground)
    }

    private func row(_ person: ChatReport.Participant, isTop: Bool, top: Int) -> some View {
        HStack(spacing: 10) {
            Text(verbatim: person.name)
                .font(.ui(14, isTop ? .bold : .semibold))
                .lineLimit(1)
                .frame(width: 76, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.foreground.opacity(0.12))
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.accent.opacity(isTop ? 1 : 0.38))
                        .frame(width: max(8, proxy.size.width * CGFloat(person.messages) / CGFloat(top)))
                }
            }
            .frame(height: 24)
            Text(verbatim: Format.number(person.messages))
                .font(.ui(14, isTop ? .bold : .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 54, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
