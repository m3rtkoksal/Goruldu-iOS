import Foundation

/// The pages of a report. A page only exists when the chat has data for it.
enum StoryCard: String, Hashable, CaseIterable, Identifiable, Sendable {
    case cover
    case talker
    case slowReplier
    case nightOwl
    case words
    case ceremony
    case roast
    case premiumGate
    case role
    case vibe
    case cast
    case fastest
    case moments
    case archetypes
    case cliques

    var id: String { rawValue }

    /// Free cards, then either the paywall gate or the paid cards.
    static func cards(for report: ChatReport, premium: Bool = false) -> [StoryCard] {
        var cards: [StoryCard] = [.cover, .talker]
        if report.slowReplier != nil { cards.append(.slowReplier) }
        if report.nightOwl != nil { cards.append(.nightOwl) }
        if !report.topWords.isEmpty { cards.append(.words) }
        if !report.awards.isEmpty { cards.append(.ceremony) }
        cards.append(.roast)
        if premium {
            cards.append(.role)
            cards.append(.vibe)
            cards.append(.cast)
            if report.slowReplier?.fastestName != nil { cards.append(.fastest) }
            cards.append(.moments)
            cards.append(.archetypes)
            cards.append(.cliques)
        } else {
            cards.append(.premiumGate)
        }
        return cards
    }

    /// "01", "02"… for the single-winner pages, in the order they are shown.
    static func awardNumber(of card: StoryCard, in cards: [StoryCard]) -> String {
        let numbered = cards.filter { $0 == .talker || $0 == .slowReplier || $0 == .nightOwl }
        let position = (numbered.firstIndex(of: card) ?? 0) + 1
        return position < 10 ? "0\(position)" : String(position)
    }
}

/// State of the roast for one report.
enum RoastState: Equatable, Sendable {
    case loading
    case loaded([Roast])
    case failed(RoastService.Failure)
}
