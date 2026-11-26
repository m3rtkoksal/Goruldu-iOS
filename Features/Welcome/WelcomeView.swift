import SwiftUI

struct WelcomeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            fan
                .frame(maxWidth: .infinity)
                .frame(height: 296)
                .accessibilityHidden(true)
            Spacer(minLength: 12)
            BrandMark()
            Text(verbatim: L10n.tr("welcome.title"))
                .displayStyle(44, tracking: -0.045)
                .foregroundStyle(Palette.paper)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 18)
            Text(verbatim: L10n.tr("welcome.lead"))
                .font(.ui(16))
                .lineSpacing(4)
                .foregroundStyle(Palette.paper.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            Button {
                model.showImport()
            } label: {
                HStack(spacing: 10) {
                    Text(verbatim: L10n.tr("welcome.cta"))
                    Image(systemName: Symbol.arrowRight).font(.system(size: 17, weight: .bold))
                }
            }
            .buttonStyle(PrimaryButtonStyle(kind: .lime))
            .padding(.top, 24)
            Button(L10n.tr("welcome.toHome")) { model.showHome() }
                .buttonStyle(TextButtonStyle())
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Palette.ink.ignoresSafeArea())
    }

    private var fan: some View {
        ZStack {
            FanCard(
                label: L10n.tr("award.slowReplier"),
                name: "Deniz",
                stat: Format.duration(minutes: 554),
                background: Palette.pink,
                foreground: Palette.ink
            )
            .rotationEffect(.degrees(-12))
            .offset(x: -102, y: 18)
            FanCard(
                label: L10n.tr("award.talker"),
                name: "Burak",
                stat: L10n.tr("common.messages", Format.number(9_812)),
                background: Palette.lime,
                foreground: Palette.ink
            )
            .rotationEffect(.degrees(12))
            .offset(x: 102, y: 18)
            FanCard(
                label: L10n.tr("award.nightOwl"),
                name: "Can",
                stat: Format.clock(hour: 2),
                background: Palette.blue,
                foreground: .white
            )
        }
        .padding(.top, 34)
    }
}

private struct FanCard: View {
    let label: String
    let name: String
    let stat: String
    let background: Color
    let foreground: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: label)
                .labelStyle(11.5, tracking: 0.06)
                .lineLimit(2)
            Spacer(minLength: 0)
            Text(verbatim: name)
                .displayStyle(36)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(verbatim: stat)
                .font(.ui(15, .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 4)
        }
        .foregroundStyle(foreground)
        .padding(16)
        .frame(width: 168, height: 224, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 18)
    }
}
