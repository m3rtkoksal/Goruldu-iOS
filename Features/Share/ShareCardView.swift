import SwiftUI

/// The 9:16 card that is exported as an image. Laid out at 360 x 640 pt and rendered at 3x.
struct ShareCardView: View {
    static let size = CGSize(width: 360, height: 640)

    let content: ShareContent

    private static let rankFills = [Palette.cardBlush, Palette.cardMint, Palette.cardPeach, Palette.cardLilac]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: content.group)
                .font(.ui(14, .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            if content.card == .cover {
                cover
            } else if !content.rows.isEmpty {
                race(content.label, rows: content.rows)
                if content.card == .slowReplier {
                    lastPlace
                }
            } else {
                statement
            }
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                TicksIcon(size: 18)
                Text(verbatim: L10n.tr("share.mark"))
                    .font(.ui(15, .bold))
            }
            .foregroundStyle(Palette.ink)
        }
        .padding(22)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .background(Palette.paper)
        .dynamicTypeSize(.large)
    }

    private var cover: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: content.label).labelStyle(12)
                Text(verbatim: content.stat)
                    .displayStyle(32, tracking: -0.04)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(verbatim: content.note)
                    .font(.ui(15, .semibold))
                    .lineLimit(2)
            }
            .foregroundStyle(Palette.ink)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.cardMint, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            if !content.rows.isEmpty {
                race(L10n.tr("award.talker"), rows: Array(content.rows.prefix(5)))
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
                .lineLimit(4)
                .minimumScaleFactor(0.6)
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
                    .lineLimit(8)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(panelInk)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
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
