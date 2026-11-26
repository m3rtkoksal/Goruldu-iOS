import SwiftUI

struct NightOwlCard: View {
    let owl: ChatReport.NightOwl
    let number: String
    let theme: StoryTheme
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("story.award", number, L10n.tr("award.nightOwl")), symbol: Symbol.moon)
            WinnerName(name: owl.name, size: compact ? 76 : 100)
                .padding(.top, 14)
            Text(verbatim: Format.percent(owl.nightPercent))
                .displayStyle(46, tracking: -0.045)
                .lineLimit(1)
                .padding(.top, 12)
            Text(verbatim: L10n.tr("night.note"))
                .font(.ui(16))
                .lineSpacing(3)
                .opacity(0.84)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            chart
                .padding(.top, compact ? 16 : 28)
            Spacer(minLength: 12)
            Callout(
                text: Emphasis.attributed(L10n.tr("night.peak", Format.clock(hour: owl.peakHour)), size: 15, strong: theme.accent),
                background: theme.foreground.opacity(0.11),
                foreground: theme.foreground
            )
        }
        .foregroundStyle(theme.foreground)
    }

    private var chart: some View {
        let height: CGFloat = compact ? 96 : 150
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
