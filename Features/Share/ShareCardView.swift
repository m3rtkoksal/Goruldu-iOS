import SwiftUI

/// The card that is exported as an image. Width stays 360. Height grows so every row on the screen fits.
struct ShareCardView: View {
    static let width: CGFloat = 360
    static let size = CGSize(width: 360, height: 640)

    let content: ShareContent

    private static let rankFills = [Palette.cardBlush, Palette.cardMint, Palette.cardPeach, Palette.cardLilac]

    static func canvasSize(for content: ShareContent) -> CGSize {
        CGSize(width: width, height: height(for: content))
    }

    /// Tall enough for every row. A short card stays a 9:16 story.
    static func height(for content: ShareContent) -> CGFloat {
        var used: CGFloat = 180
        used += CGFloat(content.stats.count) * 56
        if content.rows.count >= 2, content.card != .words { used += 130 }
        used += CGFloat(content.rows.count) * 44
        used += CGFloat(content.lines.count) * 140
        if content.card == .slowReplier, !content.name.isEmpty { used += 52 }
        if content.lines.isEmpty, content.rows.isEmpty, content.stats.isEmpty { used += 280 }
        if content.card == .words { used += 72 }
        return max(640, used)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: content.group)
                .font(.ui(14, .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            board
            Spacer(minLength: 8)
            footer
        }
        .padding(22)
        .frame(width: Self.width, height: Self.height(for: content), alignment: .topLeading)
        .background(Palette.paper)
        .dynamicTypeSize(.large)
    }

    @ViewBuilder private var board: some View {
        switch content.card {
        case .cover:
            summary
            if !content.rows.isEmpty {
                race(L10n.tr("award.talker"), rows: content.rows)
            }
        case .words:
            words
        case .ceremony, .roast, .cast, .moments, .archetypes, .cliques:
            if content.lines.isEmpty {
                statement
            } else {
                lineList
            }
        case .slowReplier, .nightOwl, .talker:
            if content.rows.isEmpty {
                statement
            } else {
                race(content.label, rows: content.rows)
            }
            if content.card == .slowReplier, !content.name.isEmpty {
                lastPlace
            }
        default:
            statement
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(content.stats.enumerated()), id: \.offset) { _, stat in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: stat.value)
                        .displayStyle(34, tracking: -0.04)
                    Text(verbatim: stat.caption)
                        .font(.ui(16, .bold))
                        .opacity(0.72)
                }
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.cardMint, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: content.label)
                .font(.ui(18, .bold))
                .foregroundStyle(Palette.ink)
            Text(verbatim: content.name)
                .displayStyle(36, tracking: -0.04)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if !content.stat.isEmpty {
                Text(verbatim: content.stat)
                    .font(.ui(16, .bold))
                    .foregroundStyle(Palette.ink.opacity(0.7))
            }
            ForEach(content.rows) { row in
                HStack {
                    Text(verbatim: row.name)
                    Spacer(minLength: 8)
                    Text(verbatim: row.value)
                }
                .font(.ui(14, .bold))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Palette.cardPeach, in: Capsule())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var lineList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: content.label)
                .font(.ui(18, .bold))
                .foregroundStyle(panelInk)
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
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .foregroundStyle(panelInk)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(lineFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func race(_ title: String, rows: [ShareContent.Row]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: title)
                .font(.ui(18, .bold))
                .foregroundStyle(Palette.ink)
            if rows.count >= 2 {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(podium(rows)) { row in
                        podiumTile(row)
                    }
                }
            }
            VStack(spacing: 6) {
                ForEach(rows) { row in
                    rankRow(row)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func podium(_ rows: [ShareContent.Row]) -> [ShareContent.Row] {
        let top = Array(rows.prefix(3))
        guard top.count >= 2 else { return top }
        var order = [top[1], top[0]]
        if top.count > 2 { order.append(top[2]) }
        return order
    }

    private func podiumTile(_ row: ShareContent.Row) -> some View {
        let fill = row.place == 1 ? Palette.cardBlush : (row.place == 2 ? Palette.cardMint : Palette.cardPeach)
        let height: CGFloat = row.place == 1 ? 96 : (row.place == 2 ? 82 : 72)
        return VStack(spacing: 4) {
            Text(verbatim: "\(row.place)")
                .font(.ui(11, .bold))
                .frame(width: 20, height: 20)
                .background(Color.white, in: Circle())
            Text(verbatim: row.name)
                .font(.ui(11, .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(verbatim: row.value)
                .font(.ui(13, .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .bottom)
        .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func rankRow(_ row: ShareContent.Row) -> some View {
        HStack(spacing: 8) {
            Text(verbatim: "#\(row.place)")
                .font(.ui(13, .bold))
                .frame(width: 28, alignment: .leading)
            Text(verbatim: row.name)
                .font(.ui(14, .bold))
                .lineLimit(1)
            if row.you {
                Text(verbatim: L10n.tr("cast.you"))
                    .font(.ui(11, .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Palette.lime, in: Capsule())
            }
            Spacer(minLength: 6)
            Text(verbatim: row.value)
                .font(.ui(14, .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(Self.rankFills[(row.place - 1) % Self.rankFills.count], in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Palette.cardApricot, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statement: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: content.label).labelStyle(13)
            Text(verbatim: content.name)
                .displayStyle(content.name.count > 22 ? 32 : 48, tracking: -0.04)
                .fixedSize(horizontal: false, vertical: true)
            if !content.stat.isEmpty {
                Text(verbatim: content.stat)
                    .displayStyle(28, tracking: -0.03)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
            if !content.note.isEmpty {
                Text(verbatim: content.note)
                    .font(.ui(16, .medium))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(panelInk)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
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
        .foregroundStyle(Palette.ink)
    }

    private var lineFill: Color {
        switch content.card {
        case .roast, .archetypes: return Palette.cardBlush
        case .moments: return Palette.cardMint
        case .cliques: return Color.white.opacity(0.55)
        default: return Color.white
        }
    }

    private var panelFill: Color {
        switch content.card {
        case .roast, .role, .archetypes: return Palette.cardBlush
        case .words, .moments: return Palette.cardPeach
        case .vibe: return Palette.cardApricot
        case .nightOwl, .cliques: return Palette.cardLilac
        case .ceremony, .cast: return .white
        default: return Palette.cardMint
        }
    }

    private var panelInk: Color {
        switch content.card {
        case .role, .roast, .archetypes: return Palette.roseInk
        case .vibe: return Palette.clayInk
        default: return Palette.ink
        }
    }
}
