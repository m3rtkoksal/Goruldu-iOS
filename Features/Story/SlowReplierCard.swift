import SwiftUI

struct SlowReplierCard: View {
    let report: ChatReport
    let slow: ChatReport.SlowReplier
    let number: String
    let theme: StoryTheme
    let compact: Bool

    var body: some View {
        if ReportBoard.fastest(report).isEmpty {
            poster
        } else {
            race
        }
    }

    /// Reply times, fastest first. The podium is 2-1-3. The last strip is the slowest person.
    private var race: some View {
        let ranked = ReportBoard.fastest(report)
        return VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("fastest.eyebrow"))
            MedalPodium(
                slots: ranked.prefix(3).enumerated().map { index, person in
                    MedalPodium.Slot(
                        place: index + 1,
                        name: person.name,
                        value: person.avgReplyMinutes.map(Format.duration(minutes:)) ?? ""
                    )
                },
                compact: compact
            )
            .padding(.top, 12)
            VStack(spacing: 8) {
                ForEach(Array(ranked.enumerated()), id: \.offset) { position, person in
                    HStack(spacing: 8) {
                        Text(verbatim: "#\(position + 1)")
                            .font(.ui(14, .bold))
                            .frame(width: 28, alignment: .leading)
                        Text(verbatim: person.name)
                            .font(.ui(15, .bold))
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(verbatim: person.avgReplyMinutes.map(Format.duration(minutes:)) ?? "")
                            .font(.ui(15, .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: compact ? 32 : 36)
                    .background(theme.foreground.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.top, 14)
            Spacer(minLength: 12)
            HStack(spacing: 8) {
                Text(verbatim: L10n.tr("award.slowReplier"))
                    .font(.ui(14, .bold))
                Spacer(minLength: 8)
                Text(verbatim: slow.name)
                    .font(.ui(15, .bold))
                    .lineLimit(1)
                Text(verbatim: Format.duration(minutes: slow.avgReplyMinutes))
                    .font(.ui(15, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(theme.onAccent)
        }
        .foregroundStyle(theme.foreground)
    }

    private var poster: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("story.award", number, L10n.tr("award.slowReplier")))
            WinnerName(name: slow.name, size: compact ? 76 : 100)
                .padding(.top, 14)
            Text(verbatim: Format.duration(minutes: slow.avgReplyMinutes))
                .displayStyle(46, tracking: -0.045)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 12)
            Text(verbatim: L10n.tr("slow.note"))
                .font(.ui(16))
                .lineSpacing(3)
                .opacity(0.84)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            Spacer(minLength: 12)
            if !compact {
                illustration
                Spacer(minLength: 12)
            }
            HStack(alignment: .top, spacing: 14) {
                FactCell(value: Format.number(slow.slowReplies), caption: L10n.tr("slow.fact.late"), rule: theme.foreground)
                if let fastest = slow.fastestName, let minutes = slow.fastestAvgReplyMinutes {
                    FactCell(
                        value: Format.duration(minutes: minutes),
                        caption: L10n.tr("slow.fact.fastest", fastest),
                        rule: theme.foreground
                    )
                }
            }
        }
        .foregroundStyle(theme.foreground)
    }

    /// A picture of the average delay; the question is made up, the gap is the real number.
    private var illustration: some View {
        let asked = 14 * 60 + 2
        let answered = (asked + slow.avgReplyMinutes) % 1_440
        return VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(verbatim: L10n.tr("slow.question", slow.name))
                    .font(.ui(15.5, .medium))
                    .lineLimit(2)
                HStack(spacing: 3) {
                    Text(verbatim: Format.clock(hour: asked / 60, minute: asked % 60))
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Palette.paper.opacity(0.6))
                    TicksIcon(size: 14).foregroundStyle(Palette.tick)
                }
            }
            .foregroundStyle(Palette.paper)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Palette.ink,
                in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 5, topTrailingRadius: 20, style: .continuous)
            )
            .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(spacing: 6) {
                Image(systemName: Symbol.clock).font(.system(size: 11, weight: .bold))
                Text(verbatim: L10n.tr("slow.gap", Format.duration(minutes: slow.avgReplyMinutes)))
                    .labelStyle(12, tracking: 0.05)
                    .lineLimit(1)
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .overlay {
                Capsule().strokeBorder(Palette.ink, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(verbatim: L10n.tr("slow.answer"))
                    .font(.ui(15.5, .medium))
                Text(verbatim: Format.clock(hour: answered / 60, minute: answered % 60))
                    .font(.ui(11, .semibold))
                    .opacity(0.6)
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Palette.paper,
                in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 5, bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityHidden(true)
    }
}
