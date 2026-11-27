import Foundation

/// The text of a shareable card. The rows and lines are the same lists the results screen shows.
struct ShareContent: Equatable {
    struct Stat: Equatable {
        var value: String
        var caption: String
    }

    struct Row: Equatable, Identifiable {
        var place: Int
        var name: String
        var value: String
        var you: Bool = false
        var id: Int { place }
    }

    struct Line: Equatable, Identifiable {
        var title: String
        var text: String
        var note: String = ""
        var id: Int
    }

    var card: StoryCard
    var group: String
    var label: String
    var name: String
    var stat: String
    var note: String
    var stats: [Stat] = []
    var rows: [Row] = []
    var lines: [Line] = []

    var spoken: String {
        let figures = stats.map { "\($0.value) \($0.caption)" }.joined(separator: ", ")
        let ranks = rows.map { "#\($0.place) \($0.name) \($0.value)" }.joined(separator: ", ")
        let blocks = lines.map { [$0.title, $0.text, $0.note].filter { !$0.isEmpty }.joined(separator: " ") }
        return [label, name, figures, stat, note, ranks, blocks.joined(separator: ". "), StoreLink.url.absoluteString]
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    /// The last story card shares the whole set. Every earlier card shares only itself.
    static func pages(
        for card: StoryCard, report: ChatReport, roasts: [Roast], hideNames: Bool,
        premium: Bool = false, viewerName: String = "", highlights: ChatHighlights? = nil,
        reading: ChatReading? = nil
    ) -> [ShareContent] {
        let shown = StoryCard.cards(for: report, premium: premium)
        let single = make(
            card: card, report: report, roasts: roasts, hideNames: hideNames,
            premium: premium, viewerName: viewerName, highlights: highlights, reading: reading
        )
        guard card == .premiumGate || shown.last == card else { return [single] }
        let all = deck(
            report: report, roasts: roasts, hideNames: hideNames,
            premium: card != .premiumGate && premium, viewerName: viewerName,
            highlights: highlights, reading: reading
        )
        return all.isEmpty ? [single] : all
    }

    /// One image per block on the results screen, in the same order, with the same rows.
    static func deck(
        report: ChatReport, roasts: [Roast], hideNames: Bool, premium: Bool = false,
        viewerName: String = "", highlights: ChatHighlights? = nil, reading: ChatReading? = nil
    ) -> [ShareContent] {
        StoryCard.cards(for: report, premium: premium).compactMap { card in
            // Speed lives on the slow card. The talker card is its own story.
            if card == .premiumGate || card == .fastest { return nil }
            if card == .slowReplier, ReportBoard.fastest(report).isEmpty { return nil }
            if card == .nightOwl, ReportBoard.night(report).isEmpty { return nil }
            if card == .ceremony, ReportBoard.awards(report, premium: premium).isEmpty { return nil }
            if card == .moments, (highlights?.moments ?? []).isEmpty { return nil }
            if card == .archetypes, (highlights?.drama ?? []).isEmpty { return nil }
            if card == .cliques, (highlights?.pairs ?? []).isEmpty { return nil }
            let content = make(
                card: card, report: report, roasts: roasts, hideNames: hideNames,
                premium: premium, viewerName: viewerName, highlights: highlights, reading: reading
            )
            if card == .roast && content.card != .roast { return nil }
            return content
        }
    }

    /// - Parameter hideNames: Replaces every participant name with its first letter.
    static func make(
        card: StoryCard, report: ChatReport, roasts: [Roast], hideNames: Bool,
        premium: Bool = false, viewerName: String = "", highlights: ChatHighlights? = nil,
        reading: ChatReading? = nil
    ) -> ShareContent {
        func shown(_ name: String) -> String { hideNames ? Format.masked(name) : name }
        let group = report.title
        let viewer = viewerName.isEmpty ? report.talker.name : viewerName

        switch card {
        case .slowReplier:
            let ranked = ReportBoard.fastest(report)
            if !ranked.isEmpty {
                let slow = report.slowReplier
                return ShareContent(
                    card: card, group: group,
                    label: L10n.tr("fastest.eyebrow"),
                    name: slow.map { shown($0.name) } ?? "",
                    stat: slow.map { Format.duration(minutes: $0.avgReplyMinutes) } ?? "",
                    note: slow == nil ? "" : L10n.tr("award.slowReplier"),
                    rows: rankRows(ranked, viewer: viewer, hideNames: hideNames) { person in
                        person.avgReplyMinutes.map(Format.duration(minutes:)) ?? ""
                    }
                )
            }
        case .nightOwl:
            let ranked = ReportBoard.night(report)
            if !ranked.isEmpty {
                return ShareContent(
                    card: card, group: group, label: L10n.tr("award.nightOwl"),
                    name: shown(ranked[0].name),
                    stat: Format.percent(ranked[0].nightPercent), note: "",
                    rows: rankRows(ranked, viewer: viewer, hideNames: hideNames) { Format.percent($0.nightPercent) }
                )
            }
        case .words:
            if let top = report.topWords.first {
                return ShareContent(
                    card: card, group: group, label: L10n.tr("words.eyebrow"), name: top.word,
                    stat: Format.number(top.count), note: "",
                    rows: report.topWords.prefix(8).enumerated().map { index, word in
                        Row(place: index + 1, name: word.word, value: Format.number(word.count))
                    }
                )
            }
        case .ceremony:
            let awards = ReportBoard.awards(report, premium: premium)
            if let first = awards.first {
                return ShareContent(
                    card: card, group: group, label: L10n.tr("ceremony.eyebrow"),
                    name: shown(first.name),
                    stat: AwardStyle.title(first.id), note: AwardStyle.reason(first),
                    lines: awards.enumerated().map { index, award in
                        Line(
                            title: AwardStyle.title(award.id),
                            text: "\(shown(award.name)) · \(AwardStyle.reason(award))",
                            id: index
                        )
                    }
                )
            }
        case .roast:
            let shownRoasts = ShownRoasts.lines(roasts, premium: premium)
            if let roast = shownRoasts.first {
                return ShareContent(
                    card: card, group: group, label: L10n.tr("roast.title"),
                    name: shown(roast.name), stat: "", note: mask(roast.line, report: report, hideNames: hideNames),
                    lines: shownRoasts.enumerated().map { index, roast in
                        Line(
                            title: shown(roast.name),
                            text: mask(roast.line, report: report, hideNames: hideNames),
                            id: index
                        )
                    }
                )
            }
        case .premiumGate, .role, .vibe, .cast, .fastest, .moments, .archetypes, .cliques:
            return premiumShare(
                card, report: report, viewer: viewer, highlights: highlights, reading: reading,
                hideNames: hideNames, group: group
            )
        case .cover:
            return ShareContent(
                card: card, group: group, label: "", name: report.title, stat: "", note: "",
                stats: [
                    Stat(value: Format.number(report.totalMessages), caption: L10n.tr("cover.stat.messages")),
                    Stat(value: Format.number(report.participantCount), caption: L10n.tr("cover.stat.people")),
                    Stat(value: Format.number(report.activeDays), caption: L10n.tr("cover.stat.days")),
                ]
            )
        case .talker:
            break
        }
        return ShareContent(
            card: .talker, group: group, label: L10n.tr("award.talker"), name: shown(report.talker.name),
            stat: L10n.tr("common.messages", Format.number(report.talker.messages)),
            note: L10n.tr("talker.note", Format.percent(report.talker.sharePercent)),
            rows: rankRows(ReportBoard.talkers(report), viewer: viewer, hideNames: hideNames) {
                Format.percent($0.sharePercent)
            }
        )
    }

    private static func rankRows(
        _ people: [ChatReport.Participant], viewer: String, hideNames: Bool,
        value: (ChatReport.Participant) -> String
    ) -> [Row] {
        people.enumerated().map { index, person in
            Row(
                place: index + 1,
                name: hideNames ? Format.masked(person.name) : person.name,
                value: value(person),
                you: person.name == viewer
            )
        }
    }

    private static func mask(_ text: String, report: ChatReport, hideNames: Bool) -> String {
        guard hideNames else { return text }
        var line = text
        for person in report.participants.sorted(by: { $0.name.count > $1.name.count }) {
            line = line.replacingOccurrences(of: person.name, with: Format.masked(person.name))
        }
        return line
    }

    private static func premiumShare(
        _ card: StoryCard, report: ChatReport, viewer: String, highlights: ChatHighlights?,
        reading: ChatReading?, hideNames: Bool, group: String
    ) -> ShareContent {
        func shown(_ name: String) -> String { hideNames ? Format.masked(name) : name }
        switch card {
        case .role:
            let person = PremiumFacts.person(named: viewer, in: report)
            let named = reading?.role(named: viewer)
            let title = named?.title ?? PremiumFacts.role(of: viewer, in: report).title
            let place = L10n.tr(
                "role.place",
                String(PremiumFacts.rank(of: viewer, in: report)),
                String(report.participantCount)
            )
            let percent = Format.percent(person?.sharePercent ?? report.talker.sharePercent)
            return ShareContent(
                card: card, group: group, label: L10n.tr("role.eyebrow"),
                name: title, stat: percent, note: [place, named?.line ?? ""].filter { !$0.isEmpty }.joined(separator: "\n")
            )
        case .vibe:
            return ShareContent(
                card: card, group: group, label: L10n.tr("vibe.eyebrow"),
                name: reading?.vibeTitle ?? PremiumFacts.vibe(of: report).title,
                stat: "", note: reading?.vibeLine ?? L10n.tr("vibe.note")
            )
        case .cast:
            let lines = report.participants.enumerated().map { index, person in
                let named = reading?.role(named: person.name)
                return Line(
                    title: shown(person.name),
                    text: named?.title ?? PremiumFacts.role(of: person.name, in: report).title,
                    note: mask(named?.line ?? "", report: report, hideNames: hideNames),
                    id: index
                )
            }
            return ShareContent(
                card: card, group: group, label: L10n.tr("cast.eyebrow"),
                name: "", stat: "", note: "", lines: lines
            )
        case .moments:
            let moments = highlights?.moments ?? []
            return ShareContent(
                card: card, group: group, label: L10n.tr("moments.eyebrow"),
                name: "", stat: "", note: "",
                lines: moments.enumerated().map { index, line in
                    quoteLine(line, caption: reading?.caption(ReadingService.momentID(index)), report: report, hideNames: hideNames, id: index)
                }
            )
        case .archetypes:
            let drama = highlights?.drama ?? []
            return ShareContent(
                card: card, group: group, label: L10n.tr("drama.eyebrow"),
                name: "", stat: "", note: "",
                lines: drama.enumerated().map { index, line in
                    quoteLine(line, caption: reading?.caption(ReadingService.dramaID(index)), report: report, hideNames: hideNames, id: index)
                }
            )
        case .cliques:
            let pairs = highlights?.pairs ?? []
            return ShareContent(
                card: card, group: group, label: L10n.tr("cliques.eyebrow"),
                name: "", stat: "", note: "",
                lines: pairs.enumerated().map { index, pair in
                    Line(
                        title: "\(shown(pair.first)) · \(shown(pair.second))",
                        text: L10n.tr("cliques.count", Format.number(pair.count)),
                        note: mask(
                            reading?.caption(ReadingService.cliqueID(index)) ?? "",
                            report: report, hideNames: hideNames
                        ),
                        id: index
                    )
                }
            )
        case .fastest:
            let slow = report.slowReplier
            return ShareContent(
                card: card, group: group, label: L10n.tr("fastest.eyebrow"),
                name: shown(slow?.fastestName ?? viewer),
                stat: slow?.fastestAvgReplyMinutes.map(Format.duration(minutes:)) ?? "",
                note: slow.map { L10n.tr("fastest.compare", shown($0.name), Format.duration(minutes: $0.avgReplyMinutes)) } ?? ""
            )
        case .cover, .talker, .slowReplier, .nightOwl, .words, .ceremony, .roast, .premiumGate:
            return ShareContent(card: card, group: group, label: "", name: shown(viewer), stat: "", note: "")
        }
    }

    private static func quoteLine(
        _ line: ChatHighlights.Line, caption: String?, report: ChatReport, hideNames: Bool, id: Int
    ) -> Line {
        let who = line.replyTo.map { L10n.tr("quote.reply", line.name, $0) } ?? line.name
        return Line(
            title: mask(who, report: report, hideNames: hideNames),
            text: "“\(mask(line.text, report: report, hideNames: hideNames))”",
            note: [Format.day(line.date), mask(caption ?? "", report: report, hideNames: hideNames)]
                .filter { !$0.isEmpty }
                .joined(separator: " · "),
            id: id
        )
    }
}
