import SwiftUI

/// A share image in the same story colors as the screen, with the medal podium on ranking pages.
struct ShareCardView: View {
    static let width: CGFloat = 360
    static let size = CGSize(width: 360, height: 640)

    let content: ShareContent

    private var theme: StoryTheme { StoryTheme.theme(for: content.card) }

    static func canvasSize(for content: ShareContent) -> CGSize {
        CGSize(width: width, height: height(for: content))
    }

    /// Tall enough for the podium and every row. A short card stays a 9:16 story.
    static func height(for content: ShareContent) -> CGFloat {
        var used: CGFloat = 160
        used += CGFloat(content.stats.count) * 52
        if content.rows.count >= 2, content.card != .cover { used += 150 }
        used += CGFloat(content.rows.count) * 40
        used += CGFloat(content.lines.count) * 88
        if content.card == .slowReplier, !content.name.isEmpty { used += 52 }
        if content.lines.isEmpty, content.rows.isEmpty, content.stats.isEmpty { used += 220 }
        return max(640, used)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: content.group)
                .font(.ui(14, .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            board
            Spacer(minLength: 8)
            footer
        }
        .padding(20)
        .frame(width: Self.width, height: Self.height(for: content), alignment: .topLeading)
        .background(theme.background)
        .foregroundStyle(theme.foreground)
        .dynamicTypeSize(.large)
    }

    @ViewBuilder private var board: some View {
        switch content.card {
        case .cover:
            cover
        case .talker, .slowReplier, .nightOwl, .words:
            if let title = heading {
                Text(verbatim: title)
                    .displayStyle(34, tracking: -0.045)
                    .textCase(.uppercase)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if content.rows.count >= 2 {
                podium
            }
            if !content.rows.isEmpty {
                rankList(content.rows)
            }
            if content.card == .slowReplier, !content.name.isEmpty {
                lastPlace
            }
        case .ceremony, .roast, .cast, .moments, .archetypes, .cliques:
            if let title = heading {
                Text(verbatim: title).font(.ui(18, .bold))
            }
            if content.lines.isEmpty {
                statement
            } else {
                lineList
            }
        default:
            statement
        }
    }

    private var heading: String? {
        switch content.card {
        case .talker: return L10n.tr("award.talker")
        case .slowReplier: return L10n.tr("fastest.eyebrow")
        case .nightOwl: return L10n.tr("award.nightOwl")
        case .words: return L10n.tr("words.eyebrow")
        case .ceremony, .roast, .cast, .moments, .archetypes, .cliques, .role, .vibe:
            return content.label.isEmpty ? nil : content.label
        default:
            return nil
        }
    }

    private var cover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: content.name)
                .font(.display(content.name.count > 18 ? 34 : 56))
                .lineLimit(3)
                .minimumScaleFactor(0.6)
            ForEach(Array(content.stats.enumerated()), id: \.offset) { _, stat in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: stat.value)
                        .displayStyle(32, tracking: -0.04)
                    Text(verbatim: stat.caption)
                        .font(.ui(15, .bold))
                        .opacity(0.78)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
        }
        .padding(.top, 8)
    }

    private var podiumSlots: [MedalPodium.Slot] {
        content.rows.prefix(3).map { row in
            MedalPodium.Slot(place: row.place, name: row.name, value: row.value)
        }
    }

    @ViewBuilder private var podium: some View {
        if podiumSlots.count >= 2 {
            MedalPodium(slots: podiumSlots, compact: true)
        }
    }

    private func rankList(_ rows: [ShareContent.Row]) -> some View {
        VStack(spacing: 6) {
            ForEach(rows) { row in
                HStack(spacing: 8) {
                    Text(verbatim: "#\(row.place)")
                        .font(.ui(13, .bold))
                        .frame(width: 26, alignment: .leading)
                    Text(verbatim: row.name)
                        .font(.ui(14, .bold))
                        .lineLimit(1)
                    if row.you {
                        Text(verbatim: L10n.tr("cast.you"))
                            .font(.ui(11, .bold))
                            .foregroundStyle(theme.onAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.accent, in: Capsule())
                    }
                    Spacer(minLength: 6)
                    Text(verbatim: row.value)
                        .font(.ui(14, .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(theme.foreground.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var lastPlace: some View {
        HStack(spacing: 8) {
            Text(verbatim: content.note)
                .font(.ui(13, .bold))
            Spacer(minLength: 6)
            Text(verbatim: content.name)
                .font(.ui(14, .bold))
                .lineLimit(1)
            Text(verbatim: content.stat)
                .font(.ui(14, .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(theme.onAccent)
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var lineList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(content.lines) { line in
                VStack(alignment: .leading, spacing: 3) {
                    if !line.title.isEmpty {
                        Text(verbatim: line.title)
                            .font(.ui(14, .bold))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !line.text.isEmpty {
                        Text(verbatim: line.text)
                            .font(.ui(15, .bold))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !line.note.isEmpty {
                        Text(verbatim: line.note)
                            .font(.ui(13))
                            .opacity(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.foreground.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var statement: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !content.label.isEmpty, heading == nil {
                Text(verbatim: content.label).font(.ui(13, .bold))
            }
            if !content.name.isEmpty {
                Text(verbatim: content.name)
                    .displayStyle(content.name.count > 22 ? 32 : 44, tracking: -0.04)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !content.stat.isEmpty {
                Text(verbatim: content.stat)
                    .displayStyle(28, tracking: -0.03)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            if !content.note.isEmpty {
                Text(verbatim: content.note)
                    .font(.ui(16, .medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                TicksIcon(size: 18)
                Text(verbatim: L10n.tr("share.mark"))
                    .font(.ui(15, .bold))
            }
            Text(verbatim: StoreLink.display)
                .font(.ui(12, .bold))
        }
    }
}
