import SwiftUI

struct WordsCard: View {
    let words: [ChatReport.WordCount]
    let theme: StoryTheme
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StoryHeadline(text: L10n.tr("words.eyebrow"), compact: compact)
            if words.count >= 2 {
                MedalPodium(
                    slots: words.prefix(3).enumerated().map { index, word in
                        MedalPodium.Slot(place: index + 1, name: word.word, value: Format.number(word.count))
                    },
                    compact: compact
                )
                .padding(.top, 12)
            }
            VStack(spacing: 8) {
                ForEach(Array(words.prefix(8).enumerated()), id: \.offset) { position, word in
                    HStack(spacing: 8) {
                        Text(verbatim: "#\(position + 1)")
                            .font(.ui(14, .bold))
                            .frame(width: 28, alignment: .leading)
                        Text(verbatim: word.word)
                            .font(.ui(16, .bold))
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(verbatim: Format.number(word.count))
                            .font(.ui(15, .bold))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: compact ? 32 : 36)
                    .background(theme.foreground.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.top, 14)
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
