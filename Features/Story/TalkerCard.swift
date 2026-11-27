import SwiftUI

struct TalkerCard: View {
    let report: ChatReport
    let number: String
    let theme: StoryTheme
    let compact: Bool
    var viewer: String = ""

    var body: some View {
        let rows = ReportBoard.talkers(report)
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("story.award", number, L10n.tr("award.talker")))
            MedalPodium(
                slots: rows.prefix(3).enumerated().map { index, person in
                    MedalPodium.Slot(place: index + 1, name: person.name, value: Format.percent(person.sharePercent))
                },
                compact: compact
            )
            .padding(.top, 12)
            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { position, person in
                    rankRow(person.name, place: position + 1, value: Format.percent(person.sharePercent), you: person.name == viewer)
                }
            }
            .padding(.top, 14)
            Spacer(minLength: 8)
        }
        .foregroundStyle(theme.foreground)
    }

    private func rankRow(_ name: String, place: Int, value: String, you: Bool) -> some View {
        HStack(spacing: 8) {
            Text(verbatim: "#\(place)")
                .font(.ui(14, .bold))
                .frame(width: 28, alignment: .leading)
            Text(verbatim: name)
                .font(.ui(15, .bold))
                .lineLimit(1)
            if you {
                Text(verbatim: L10n.tr("cast.you"))
                    .font(.ui(11, .bold))
                    .foregroundStyle(theme.onAccent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.accent, in: Capsule())
            }
            Spacer(minLength: 8)
            Text(verbatim: value)
                .font(.ui(15, .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 12)
        .frame(height: compact ? 32 : 36)
        .background(theme.foreground.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
