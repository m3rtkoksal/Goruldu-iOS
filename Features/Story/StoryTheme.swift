import SwiftUI

/// Colors of one story page: surface, text, accent and text on the accent.
struct StoryTheme: Equatable {
    var background: Color
    var foreground: Color
    var accent: Color
    var onAccent: Color

    static func theme(for card: StoryCard) -> StoryTheme {
        switch card {
        case .cover:
            return StoryTheme(background: Palette.violet, foreground: .white, accent: Palette.lime, onAccent: Palette.ink)
        case .talker:
            return StoryTheme(background: Palette.lime, foreground: Palette.ink, accent: Palette.ink, onAccent: Palette.lime)
        case .slowReplier:
            return StoryTheme(background: Palette.pink, foreground: Palette.ink, accent: Palette.ink, onAccent: Palette.paper)
        case .nightOwl:
            return StoryTheme(background: Palette.navy, foreground: .white, accent: Palette.lime, onAccent: Palette.ink)
        case .words:
            return StoryTheme(background: Palette.orange, foreground: Palette.ink, accent: Palette.ink, onAccent: Palette.paper)
        case .ceremony:
            return StoryTheme(background: Palette.paper, foreground: Palette.ink, accent: Palette.ink, onAccent: Palette.paper)
        case .roast, .cliques:
            return StoryTheme(background: Palette.ink, foreground: Palette.paper, accent: Palette.lime, onAccent: Palette.ink)
        case .premiumGate:
            return StoryTheme(background: Palette.ink, foreground: Palette.paper, accent: Palette.lime, onAccent: Palette.ink)
        case .role:
            return StoryTheme(background: Palette.violet, foreground: .white, accent: Palette.lime, onAccent: Palette.ink)
        case .vibe:
            return StoryTheme(background: Palette.navy, foreground: .white, accent: Palette.lime, onAccent: Palette.ink)
        case .cast:
            return StoryTheme(background: Palette.paper, foreground: Palette.ink, accent: Palette.ink, onAccent: Palette.paper)
        case .fastest:
            return StoryTheme(background: Palette.lime, foreground: Palette.ink, accent: Palette.ink, onAccent: Palette.lime)
        case .moments:
            return StoryTheme(background: Palette.orange, foreground: Palette.ink, accent: Palette.ink, onAccent: Palette.paper)
        case .archetypes:
            return StoryTheme(background: Palette.pink, foreground: Palette.ink, accent: Palette.ink, onAccent: Palette.paper)
        }
    }
}

/// Texts and looks of the seven awards of the ceremony.
enum AwardStyle {
    static func title(_ kind: ChatReport.AwardKind) -> String {
        L10n.tr("award.\(kind.rawValue).title")
    }

    static func reason(_ award: ChatReport.Award) -> String {
        L10n.tr("award.\(award.id.rawValue).reason", Format.number(award.value))
    }

    static func symbol(_ kind: ChatReport.AwardKind) -> String {
        switch kind {
        case .planBreaker: return "calendar.badge.minus"
        case .ghost: return "eye.slash.fill"
        case .capsLock: return "capslock.fill"
        case .monologue: return "text.bubble.fill"
        case .drama: return "theatermasks.fill"
        case .mediaSpammer: return "photo.on.rectangle.angled"
        case .laugher: return "keyboard.fill"
        }
    }

    static func colors(_ kind: ChatReport.AwardKind) -> (background: Color, foreground: Color) {
        switch kind {
        case .planBreaker, .mediaSpammer: return (Palette.pink, Palette.ink)
        case .ghost: return (Palette.violet, .white)
        case .capsLock, .laugher: return (Palette.orange, Palette.ink)
        case .monologue: return (Palette.lime, Palette.ink)
        case .drama: return (Palette.blue, .white)
        }
    }
}
