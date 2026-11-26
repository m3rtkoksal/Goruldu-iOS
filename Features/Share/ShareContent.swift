import Foundation

/// The text of a shareable card, derived from one story page.
struct ShareContent: Equatable {
    var card: StoryCard
    var group: String
    var label: String
    var name: String
    var stat: String
    var note: String

    /// The last story card shares the whole set. Every earlier card shares only itself.
    static func pages(for card: StoryCard, report: ChatReport, roasts: [Roast], hideNames: Bool) -> [ShareContent] {
        let shown = StoryCard.cards(for: report)
        guard shown.last == card else {
            return [make(card: card, report: report, roasts: roasts, hideNames: hideNames)]
        }
        let all = deck(report: report, roasts: roasts, hideNames: hideNames)
        return all.isEmpty ? [make(card: card, report: report, roasts: roasts, hideNames: hideNames)] : all
    }

    /// One image per story card, in story order. The roast card is left out until its lines exist,
    /// so a missing roast is not replaced by a second copy of the talker card.
    static func deck(report: ChatReport, roasts: [Roast], hideNames: Bool) -> [ShareContent] {
        StoryCard.cards(for: report).compactMap { card in
            let content = make(card: card, report: report, roasts: roasts, hideNames: hideNames)
            if card == .roast && content.card != .roast { return nil }
            return content
        }
    }

    /// - Parameter hideNames: Replaces every participant name with its first letter.
    static func make(card: StoryCard, report: ChatReport, roasts: [Roast], hideNames: Bool) -> ShareContent {
        func shown(_ name: String) -> String { hideNames ? Format.masked(name) : name }
        let group = L10n.tr("share.group", report.title, report.year)

        switch card {
        case .slowReplier:
            if let slow = report.slowReplier {
                return ShareContent(
                    card: card, group: group, label: L10n.tr("award.slowReplier"), name: shown(slow.name),
                    stat: Format.duration(minutes: slow.avgReplyMinutes), note: L10n.tr("slow.note")
                )
            }
        case .nightOwl:
            if let owl = report.nightOwl {
                return ShareContent(
                    card: card, group: group, label: L10n.tr("award.nightOwl"), name: shown(owl.name),
                    stat: Format.percent(owl.nightPercent), note: L10n.tr("night.note")
                )
            }
        case .words:
            if let top = report.topWords.first {
                let others = report.topWords.dropFirst().map(\.word).joined(separator: ", ")
                return ShareContent(
                    card: card, group: group, label: L10n.tr("words.eyebrow"), name: top.word,
                    stat: L10n.tr("share.words.stat", Format.number(top.count)), note: others
                )
            }
        case .ceremony:
            if let award = report.awards.first {
                return ShareContent(
                    card: card, group: group, label: L10n.tr("ceremony.eyebrow"), name: shown(award.name),
                    stat: AwardStyle.title(award.id), note: AwardStyle.reason(award)
                )
            }
        case .roast:
            if let roast = roasts.first {
                var line = roast.line
                if hideNames {
                    for person in report.participants.sorted(by: { $0.name.count > $1.name.count }) {
                        line = line.replacingOccurrences(of: person.name, with: Format.masked(person.name))
                    }
                }
                return ShareContent(
                    card: card, group: group, label: L10n.tr("roast.eyebrow"), name: shown(roast.name),
                    stat: "", note: line
                )
            }
        case .cover:
            return ShareContent(
                card: card, group: group, label: L10n.tr("share.cover.label"), name: report.title,
                stat: L10n.tr("common.messages", Format.number(report.totalMessages)),
                note: L10n.tr("share.cover.note", Format.number(report.participantCount), Format.number(report.activeDays))
            )
        case .talker:
            break
        }
        // The talker page, and the fallback when a page has nothing to show yet.
        return ShareContent(
            card: .talker, group: group, label: L10n.tr("award.talker"), name: shown(report.talker.name),
            stat: L10n.tr("common.messages", Format.number(report.talker.messages)),
            note: L10n.tr("talker.note", Format.percent(report.talker.sharePercent))
        )
    }
}
