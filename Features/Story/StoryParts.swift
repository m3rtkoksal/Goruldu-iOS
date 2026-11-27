import SwiftUI

struct Eyebrow: View {
    let text: String
    var symbol: String?

    var body: some View {
        HStack(spacing: 7) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 13, weight: .bold))
            }
            Text(verbatim: text)
                .labelStyle(13, tracking: 0.07)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// Winner name set as large as the line allows; long names shrink instead of wrapping.
struct WinnerName: View {
    let name: String
    var size: CGFloat = 100

    var body: some View {
        Text(verbatim: name)
            .displayStyle(size, tracking: -0.06)
            .lineLimit(1)
            .minimumScaleFactor(0.22)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A number over a caption, separated from the content above by a rule.
struct FactCell: View {
    let value: String
    let caption: String
    let rule: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Rectangle().fill(rule).frame(height: 2)
            Text(verbatim: value)
                .displayStyle(34)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.top, 6)
            Text(verbatim: caption)
                .font(.ui(13))
                .opacity(0.84)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Medal stand. Second, first, third, with first tallest in the middle.
struct MedalPodium: View {
    struct Slot: Identifiable {
        var place: Int
        var name: String
        var value: String
        var id: Int { place }
    }

    var slots: [Slot]
    var compact: Bool = false

    var body: some View {
        let shown = Array(slots.prefix(3))
        HStack(alignment: .bottom, spacing: compact ? 6 : 8) {
            ForEach(podiumOrder(shown)) { slot in
                tile(slot)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func podiumOrder(_ ranked: [Slot]) -> [Slot] {
        guard ranked.count >= 2 else { return ranked }
        var order = [ranked[1], ranked[0]]
        if ranked.count > 2 { order.append(ranked[2]) }
        return order
    }

    private func tile(_ slot: Slot) -> some View {
        let fill = slot.place == 1 ? Palette.cardBlush : (slot.place == 2 ? Palette.cardMint : Palette.cardPeach)
        let height: CGFloat = slot.place == 1 ? (compact ? 132 : 168) : (slot.place == 2 ? (compact ? 112 : 142) : (compact ? 96 : 124))
        return VStack(spacing: compact ? 4 : 6) {
            Text(verbatim: "\(slot.place)")
                .font(.ui(compact ? 12 : 13, .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: compact ? 22 : 26, height: compact ? 22 : 26)
                .background(Color.white, in: Circle())
            Text(verbatim: slot.name)
                .font(.ui(compact ? 12 : 13, .bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(verbatim: slot.value)
                .font(.ui(compact ? 13 : 16, .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 6)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .bottom)
        .background(fill, in: RoundedRectangle(cornerRadius: compact ? 16 : 22, style: .continuous))
    }
}

/// Pill button laid over blurred, locked content.
struct LockedButton: View {
    let title: String
    var background: Color = Palette.ink
    var foreground: Color = Palette.paper
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: Symbol.lock).font(.system(size: 14, weight: .bold))
                Text(verbatim: title)
                    .font(.ui(15, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 20)
            .frame(height: 50)
            .background(background, in: Capsule())
            .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}
