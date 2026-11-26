import SwiftUI

/// Bundled typefaces. The names are PostScript names of the files in `Resources/Fonts`.
enum Typeface {
    static let display = "BricolageGrotesque-ExtraBold"
    static let displayBold = "BricolageGrotesque-Bold"

    static func body(_ weight: BodyWeight) -> String {
        switch weight {
        case .regular: return "InstrumentSans-Regular"
        case .medium: return "InstrumentSans-Medium"
        case .semibold: return "InstrumentSans-SemiBold"
        case .bold: return "InstrumentSans-Bold"
        }
    }

    enum BodyWeight { case regular, medium, semibold, bold }
}

extension Font {
    /// Display face. Sizes are fixed on purpose: story cards are posters, not reading text.
    static func display(_ size: CGFloat) -> Font {
        .custom(Typeface.display, fixedSize: size)
    }

    static func ui(_ size: CGFloat, _ weight: Typeface.BodyWeight = .regular) -> Font {
        .custom(Typeface.body(weight), size: size)
    }
}

extension View {
    /// Display text with the tight tracking used across the design.
    func displayStyle(_ size: CGFloat, tracking: CGFloat = -0.04) -> some View {
        font(.display(size).leading(.tight)).tracking(size * tracking)
    }

    /// Small uppercase label.
    func labelStyle(_ size: CGFloat = 13, tracking: CGFloat = 0.07) -> some View {
        font(.ui(size, .bold)).tracking(size * tracking).textCase(.uppercase)
    }
}
