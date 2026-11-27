import Foundation

/// The text of a shareable card, derived from one story page.
struct ShareContent: Equatable {
    struct Row: Equatable, Identifiable {
        var place: Int
        var name: String
        var value: String
        var id: Int { place }
    }

    var card: StoryCard
    var group: String
    var label: String
    var name: String
    var stat: String
    var note: String
    var rows: [Row] = []

    var spoken: String {
        let ranks = rows.map { "#\($0.place) \($0.name) \($0.value)" }.joined(separator: ", ")
        return [label, name, stat, note, ranks].filter { !$0.isEmpty }.joined(separator: ". ")
    }

    /// The last story card shares the whole set. Every earlier card shares only itself.
    static func pages(
        for card: StoryCard, report: ChatReport, roasts: [Roast], hideNames: Bool,
        premium: Bool = false, viewerName: String = "", highlights: ChatHighlights? = nil
    ) -> [ShareContent] {
        let shown = StoryCard.cards(for: report, premium: premium)
        let single = make(
            card: card, report: report, roasts: roasts, hideNames: hideNames,
            viewerName: viewerName, highlights: highlights
        )
        guard card == .premiumGate || shown.last == card else { return [single] }
        let all = deck(
            report: report, roasts: roasts, hideNames: hideNames,
            premium: card != .premiumGate && premium, viewerName: viewerName, highlights: highlights
        )
        return all.isEmpty ? [single] : all
    }

    /// One image per story card, in story order. The roast card is left out until its lines exist,
    /// so a missing roast is not replaced by a second copy of the talker card.
    static func deck(
        report: ChatReport, roasts: [Roast], hideNames: Bool, premium: Bool = false,
        viewerName: String = "", highlights: ChatHighlights? = nil
    ) -> [ShareContent] {
        StoryCard.cards(for: report, premium: premium).compactMap { card in
            // The cover already carries the message ranking. The speed board covers fastest.
            if card == .premiumGate || card == .talker || card == .fastest { return nil }
            let content = make(
                card: card, report: report, roasts: roasts, hideNames: hideNames,
                viewerName: viewerName, highlights: highlights
            )
            if card == .roast && content.card != .roast { return nil }
            return content
        }
    }

    /// - Parameter hideNames: Replaces every participant name with its first letter.
    static func make(
        card: StoryCard, report: ChatReport, roasts: [Roast], hideNames: Bool,
        viewerName: String = "", highlights: ChatHighlights? = nil
    ) -> ShareContent {
        func shown(_ name: String) -> String { hideNames ? Format.masked(name) : name }
        let group = L10n.tr("share.group", report.title, report.year)

        switch card {
        case .slowReplier:
            if let slow = report.slowReplier {
                let ranked = PremiumFacts.fastest(report)
                let racing = ranked.count >= 2
                return ShareContent(
                    card: card, group: group,
                    label: L10n.tr(racing ? "fastest.eyebrow" : "award.slowReplier"),
                    name: shown(slow.name),
                    stat: Format.duration(minutes: slow.avgReplyMinutes),
                    note: L10n.tr(racing ? "award.slowReplier" : "slow.note"),
                    rows: racing ? rankRows(ranked, hideNames: hideNames, value: { person in
                        person.avgReplyMinutes.map(Format.duration(minutes:)) ?? ""
                    }) : []
                )
            }
        case .nightOwl:
            if let owl = report.nightOwl {
                return ShareContent(
                    card: card, group: group, label: L10n.tr("award.nightOwl"), name: shown(owl.name),
                    stat: Format.percent(owl.nightPercent), note: "",
                    rows: rankRows(nightRank(report), hideNames: hideNames, value: { Format.percent($0.nightPercent) })
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
        case .premiumGate, .role, .vibe, .cast, .fastest, .moments, .archetypes, .cliques:
            let viewer = viewerName.isEmpty ? report.talker.name : viewerName
            let page = premiumShare(card, report: report, viewer: viewer, highlights: highlights, hideNames: hideNames)
            return ShareContent(
                card: card, group: group, label: L10n.tr("share.premium.\(card.rawValue)"),
                name: page.name, stat: page.stat, note: page.note
            )
        case .cover:
            return ShareContent(
                card: card, group: group, label: L10n.tr("share.cover.label"), name: report.title,
                stat: L10n.tr("common.messages", Format.number(report.totalMessages)),
                note: L10n.tr("share.cover.note", Format.number(report.participantCount), Format.number(report.activeDays)),
                rows: rankRows(report.participants, hideNames: hideNames, value: { Format.percent($0.sharePercent) })
            )
        case .talker:
            break
        }
        // The talker page, and the fallback when a page has nothing to show yet.
        return ShareContent(
            card: .talker, group: group, label: L10n.tr("award.talker"), name: shown(report.talker.name),
            stat: L10n.tr("common.messages", Format.number(report.talker.messages)),
            note: L10n.tr("talker.note", Format.percent(report.talker.sharePercent)),
            rows: rankRows(report.participants, hideNames: hideNames, value: { Format.percent($0.sharePercent) })
        )
    }

    private static func rankRows(
        _ people: [ChatReport.Participant], hideNames: Bool, value: (ChatReport.Participant) -> String
    ) -> [Row] {
        people.prefix(6).enumerated().map { index, person in
            Row(
                place: index + 1,
                name: hideNames ? Format.masked(person.name) : person.name,
                value: value(person)
            )
        }
    }

    private static func nightRank(_ report: ChatReport) -> [ChatReport.Participant] {
        report.participants
            .filter { $0.nightPercent > 0 }
            .sorted { lhs, rhs in
                if lhs.nightPercent != rhs.nightPercent { return lhs.nightPercent > rhs.nightPercent }
                return lhs.name < rhs.name
            }
    }

    private static func premiumShare(
        _ card: StoryCard, report: ChatReport, viewer: String, highlights: ChatHighlights?, hideNames: Bool
    ) -> (name: String, stat: String, note: String) {
        let shown: (String) -> String = { hideNames ? Format.masked($0) : $0 }
        switch card {
        case .role:
            let person = PremiumFacts.person(named: viewer, in: report)
            return (
                shown(viewer),
                L10n.tr("role.place", String(PremiumFacts.rank(of: viewer, in: report)), String(report.participantCount)),
                PremiumFacts.role(of: viewer, in: report).title
                    + " · " + Format.percent(person?.sharePercent ?? 0)
            )
        case .vibe:
            return (
                PremiumFacts.vibe(of: report).title,
                Format.percent(PremiumFacts.groupNightPercent(report)),
                L10n.tr("vibe.nightShare")
            )
        case .cast:
            return (
                L10n.tr("cast.title", String(report.participantCount)),
                "",
                report.participants.map { shown($0.name) }.joined(separator: " · ")
            )
        case .fastest:
            let slow = report.slowReplier
            return (
                shown(slow?.fastestName ?? viewer),
                slow?.fastestAvgReplyMinutes.map(Format.duration(minutes:)) ?? "",
                slow.map { L10n.tr("fastest.compare", shown($0.name), Format.duration(minutes: $0.avgReplyMinutes)) } ?? ""
            )
        case .moments:
            let quote = highlights?.moments.first?.text ?? ""
            return (
                highlights.map { Format.day($0.busiestDate) } ?? "",
                Format.number(highlights?.busiestCount ?? 0),
                quote
            )
        case .archetypes:
            let quote = highlights?.drama.first.map { "\($0.name): \($0.text)" } ?? ""
            return (L10n.tr("drama.title"), "", quote)
        case .cliques:
            let line = (highlights?.pairs ?? []).map {
                "\(shown($0.first)) ↔ \(shown($0.second))"
            }.joined(separator: " · ")
            return (L10n.tr("cliques.title"), "", line.isEmpty ? L10n.tr("cliques.empty") : line)
        case .cover, .talker, .slowReplier, .nightOwl, .words, .ceremony, .roast, .premiumGate:
            return (shown(viewer), "", "")
        }
    }
}
