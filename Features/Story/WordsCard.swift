import SwiftUI

struct WordsCard: View {
    let words: [ChatReport.WordCount]
    let theme: StoryTheme
    let compact: Bool

    private static let sizes: [CGFloat] = [78, 62, 50, 40, 34]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("words.eyebrow"))
            Text(verbatim: L10n.tr("words.title"))
                .displayStyle(40, tracking: -0.045)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(words.prefix(Self.sizes.count).enumerated()), id: \.offset) { position, word in
                    HStack(alignment: .center, spacing: 12) {
                        Text(verbatim: word.word)
                            .displayStyle(Self.sizes[position] * (compact ? 0.78 : 1), tracking: -0.05)
                            .lineLimit(1)
                            .minimumScaleFactor(0.35)
                        Text(verbatim: Format.number(word.count))
                            .font(.ui(12.5, .bold))
                            .monospacedDigit()
                            .foregroundStyle(theme.background)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(theme.accent, in: Capsule())
                            .fixedSize()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, compact ? 14 : 24)
            Spacer(minLength: 12)
            if let top = words.first {
                Callout(
                    text: AttributedString(L10n.tr("words.callout", top.word, Format.number(top.count))),
                    background: Palette.ink,
                    foreground: Palette.paper
                )
            }
        }
        .foregroundStyle(theme.foreground)
    }
}
