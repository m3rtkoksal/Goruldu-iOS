import SwiftUI

struct NightOwlCard: View {
    let report: ChatReport
    let owl: ChatReport.NightOwl
    let number: String
    let theme: StoryTheme
    let compact: Bool

    var body: some View {
        let ranked = ReportBoard.night(report)
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("story.award", number, L10n.tr("award.nightOwl")), symbol: Symbol.moon)
            WinnerName(name: owl.name, size: ranked.isEmpty ? (compact ? 76 : 100) : (compact ? 44 : 56))
                .padding(.top, ranked.isEmpty ? 14 : 8)
            Text(verbatim: Format.percent(owl.nightPercent))
                .displayStyle(ranked.isEmpty ? 46 : 32, tracking: -0.045)
                .lineLimit(1)
                .padding(.top, 6)
            if ranked.isEmpty {
                Text(verbatim: L10n.tr("night.note"))
                    .font(.ui(16))
                    .lineSpacing(3)
                    .opacity(0.84)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            }
            chart(short: !ranked.isEmpty)
                .padding(.top, compact ? 10 : 14)
            if !ranked.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(ranked.dropFirst().enumerated()), id: \.offset) { offset, person in
                        HStack(spacing: 8) {
                            Text(verbatim: "#\(offset + 2)")
                                .font(.ui(13, .bold))
                                .frame(width: 26, alignment: .leading)
                            Text(verbatim: person.name)
                                .font(.ui(14, .bold))
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(verbatim: Format.percent(person.nightPercent))
                                .font(.ui(15, .bold))
                        }
                        .padding(.horizontal, 10)
                        .frame(height: compact ? 28 : 32)
                        .background(theme.foreground.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.top, 12)
            }
            Spacer(minLength: 12)
            Callout(
                text: Emphasis.attributed(L10n.tr("night.peak", Format.clock(hour: owl.peakHour)), size: 15, strong: theme.accent),
                background: theme.foreground.opacity(0.11),
                foreground: theme.foreground
            )
        }
        .foregroundStyle(theme.foreground)
    }

    private func chart(short: Bool) -> some View {
        let height: CGFloat = short ? (compact ? 48 : 72) : (compact ? 96 : 150)
        let peak = max(1, owl.hours.max() ?? 1)
        return VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(owl.hours.enumerated()), id: \.offset) { hour, count in
                    UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 4)
                        .fill(hour < ReportRules.nightEndHour ? theme.accent : Color.white.opacity(0.22))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(3, height * CGFloat(count) / CGFloat(peak)))
                }
            }
            .frame(height: height, alignment: .bottom)
            HStack {
                ForEach(["00", "06", "12", "18", "24"], id: \.self) { label in
                    Text(verbatim: label)
                    if label != "24" { Spacer(minLength: 0) }
                }
            }
            .font(.ui(11.5, .semibold))
            .monospacedDigit()
            .opacity(0.6)
        }
        .accessibilityHidden(true)
    }
}
