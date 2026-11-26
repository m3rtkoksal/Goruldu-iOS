import SwiftUI

struct RoastCard: View {
    let state: RoastState
    let isPremium: Bool
    let theme: StoryTheme
    let unlock: () -> Void
    let retry: () -> Void

    private static let nameColors = [Palette.lime, Palette.pink, Palette.tick, Palette.orange]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("roast.eyebrow"), symbol: Symbol.sparkles)
            Text(verbatim: L10n.tr("roast.title"))
                .displayStyle(34)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            switch state {
            case .loading:
                status(showsSpinner: true, text: L10n.tr("roast.loading"), showsRetry: false)
            case .failed(let failure):
                status(showsSpinner: false, text: message(for: failure), showsRetry: failure != .notConfigured)
            case .loaded(let roasts):
                if roasts.isEmpty {
                    status(showsSpinner: false, text: L10n.tr("roast.empty"), showsRetry: true)
                } else {
                    lines(roasts)
                }
            }
        }
        .foregroundStyle(theme.foreground)
    }

    private func lines(_ roasts: [Roast]) -> some View {
        let open = isPremium ? roasts : Array(roasts.prefix(1))
        let locked: [Roast] = isPremium ? [] : Array(roasts.dropFirst())
        return ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(open.enumerated()), id: \.offset) { position, roast in
                    line(roast, position: position)
                }
                if !locked.isEmpty {
                    ZStack {
                        VStack(spacing: 8) {
                            ForEach(Array(locked.prefix(2).enumerated()), id: \.offset) { position, roast in
                                line(roast, position: position + 1)
                            }
                        }
                        .blur(radius: 8)
                        .opacity(0.75)
                        .accessibilityHidden(true)
                        LockedButton(
                            title: locked.count == 1
                                ? L10n.tr("roast.locked.one")
                                : L10n.tr("roast.locked.many", String(locked.count)),
                            background: Palette.lime,
                            foreground: Palette.ink,
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

    private func line(_ roast: Roast, position: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: roast.name)
                .labelStyle(12, tracking: 0.07)
                .foregroundStyle(Self.nameColors[position % Self.nameColors.count])
                .lineLimit(1)
            Text(verbatim: roast.line)
                .font(.ui(16))
                .lineSpacing(3)
                .foregroundStyle(Palette.paper)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Palette.ink2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func status(showsSpinner: Bool, text: String, showsRetry: Bool) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            if showsSpinner { Spinner(tint: Palette.lime) }
            Text(verbatim: text)
                .font(.ui(16))
                .lineSpacing(3)
                .foregroundStyle(Palette.paper.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if showsRetry {
                Button(action: retry) {
                    HStack(spacing: 8) {
                        Image(systemName: Symbol.retry).font(.system(size: 14, weight: .bold))
                        Text(verbatim: L10n.tr("common.retry")).font(.ui(15, .bold))
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 20)
                    .frame(height: 46)
                    .background(Palette.lime, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func message(for failure: RoastService.Failure) -> String {
        switch failure {
        case .notConfigured: return L10n.tr("roast.error.notConfigured")
        case .offline: return L10n.tr("roast.error.offline")
        case .rejected, .badResponse: return L10n.tr("roast.error.server")
        }
    }
}
