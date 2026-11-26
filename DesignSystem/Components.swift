import SwiftUI

struct BrandMark: View {
    enum Tone { case onDark, onLight }
    var tone: Tone = .onDark

    var body: some View {
        HStack(spacing: 9) {
            TicksIcon(size: 18)
                .foregroundStyle(tone == .onDark ? Palette.ink : Palette.lime)
                .frame(width: 30, height: 30)
                .background(tone == .onDark ? Palette.lime : Palette.ink, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(verbatim: "Görüldü")
                .displayStyle(20, tracking: -0.03)
                .foregroundStyle(tone == .onDark ? Palette.paper : Palette.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Görüldü"))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    enum Kind { case lime, ink, ghost }
    var kind: Kind = .lime

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(17, .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.horizontal, 16)
            .background(background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .lime: return Palette.ink
        case .ink, .ghost: return Palette.paper
        }
    }

    private var background: Color {
        switch kind {
        case .lime: return Palette.lime
        case .ink: return Palette.ink
        case .ghost: return Color.white.opacity(0.08)
        }
    }
}

struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(15, .semibold))
            .foregroundStyle(Palette.paper.opacity(configuration.isPressed ? 0.5 : 0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
    }
}

struct IconButton: View {
    enum Tone { case onDark, onLight }

    let symbol: String
    let label: String
    var tone: Tone = .onDark
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tone == .onDark ? Palette.paper : Palette.ink)
                .frame(width: 40, height: 40)
                .background(
                    tone == .onDark ? Color.white.opacity(0.08) : Palette.ink.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
    }
}

/// Top bar with a centered title, used by the dark screens.
struct NavBar: View {
    var title: String?
    var leading: IconButton?
    var trailing: IconButton?

    var body: some View {
        ZStack {
            if let title {
                Text(verbatim: title)
                    .font(.ui(17, .bold))
                    .foregroundStyle(Palette.paper)
                    .lineLimit(1)
                    .padding(.horizontal, 52)
            }
            HStack {
                if let leading { leading }
                Spacer(minLength: 0)
                if let trailing { trailing }
            }
        }
        .frame(height: 44)
    }
}

struct Sticker: View {
    let text: String
    var background: Color = Palette.lime
    var foreground: Color = Palette.ink

    var body: some View {
        Text(verbatim: text)
            .labelStyle(13, tracking: 0.06)
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(background, in: Capsule())
            .rotationEffect(.degrees(-4))
    }
}

struct Callout: View {
    let text: AttributedString
    var background: Color
    var foreground: Color

    var body: some View {
        Text(text)
            .font(.ui(15))
            .lineSpacing(3)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// Inline progress indicator tinted for the surrounding surface.
struct Spinner: View {
    var tint: Color = Palette.paper

    var body: some View {
        ProgressView().progressViewStyle(.circular).tint(tint)
    }
}

/// `**bold**` segments of a localized string become a second color and weight.
enum Emphasis {
    static func attributed(_ text: String, size: CGFloat, strong: Color) -> AttributedString {
        var result = AttributedString()
        let parts = text.components(separatedBy: "**")
        for (index, part) in parts.enumerated() where !part.isEmpty {
            var piece = AttributedString(part)
            if index % 2 == 1 {
                piece.font = .ui(size, .bold)
                piece.foregroundColor = strong
            }
            result.append(piece)
        }
        return result
    }
}
