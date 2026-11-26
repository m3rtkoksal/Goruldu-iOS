import SwiftUI

struct CeremonyCard: View {
    let awards: [ChatReport.Award]
    let isPremium: Bool
    let theme: StoryTheme
    let unlock: () -> Void

    var body: some View {
        let open = isPremium ? awards : awards.filter { !$0.premium }
        let locked: [ChatReport.Award] = isPremium ? [] : awards.filter(\.premium)
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("ceremony.eyebrow"), symbol: Symbol.trophy)
            Text(verbatim: L10n.tr("ceremony.title"))
                .displayStyle(34)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(open) { award in
                        PrizeRow(kind: award.id, name: award.name, reason: AwardStyle.reason(award))
                    }
                    if !locked.isEmpty {
                        ZStack {
                            VStack(spacing: 8) {
                                ForEach(locked.prefix(2)) { award in
                                    PrizeRow(kind: award.id, name: award.name, reason: AwardStyle.reason(award))
                                }
                            }
                            .blur(radius: 7)
                            .opacity(0.8)
                            .accessibilityHidden(true)
                            LockedButton(
                                title: locked.count == 1
                                    ? L10n.tr("ceremony.locked.one")
                                    : L10n.tr("ceremony.locked.many", String(locked.count)),
                                action: unlock
                            )
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(theme.foreground)
    }
}

private struct PrizeRow: View {
    let kind: ChatReport.AwardKind
    let name: String
    let reason: String

    var body: some View {
        let colors = AwardStyle.colors(kind)
        HStack(spacing: 12) {
            Image(systemName: AwardStyle.symbol(kind))
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(colors.foreground)
                .frame(width: 46, height: 46)
                .background(colors.background, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: AwardStyle.title(kind))
                    .displayStyle(18, tracking: -0.025)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(who)
                    .font(.ui(13))
                    .foregroundStyle(Palette.ink.opacity(0.68))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var who: AttributedString {
        var winner = AttributedString(name)
        winner.font = .ui(13, .bold)
        winner.foregroundColor = Palette.ink
        return winner + AttributedString(" · " + reason)
    }
}
