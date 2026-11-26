import SwiftUI

struct PremiumGateCard: View {
    let theme: StoryTheme
    let unlock: () -> Void

    private static let rows = [
        "premium.gate.role", "premium.gate.vibe", "premium.gate.cast", "premium.gate.fastest",
        "premium.gate.moments", "premium.gate.archetypes", "premium.gate.cliques",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: L10n.tr("premium.gate.lead"))
                .font(.ui(15))
                .foregroundStyle(theme.foreground.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 8) {
                ForEach(Self.rows, id: \.self) { key in
                    HStack {
                        Text(verbatim: L10n.tr(key))
                            .font(.ui(16, .bold))
                        Spacer(minLength: 8)
                        Image(systemName: Symbol.lock).font(.system(size: 14, weight: .bold)).foregroundStyle(theme.accent)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.top, 16)
            Spacer(minLength: 12)
            Button(action: unlock) {
                HStack(spacing: 8) {
                    Image(systemName: Symbol.lock).font(.system(size: 14, weight: .bold))
                    Text(verbatim: L10n.tr("premium.gate.unlock")).font(.ui(16, .bold))
                }
                .foregroundStyle(theme.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(theme.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(theme.foreground)
    }
}

struct RoleCard: View {
    let report: ChatReport
    let viewer: String
    let highlights: ChatHighlights?
    let reading: ChatReading?
    let theme: StoryTheme

    private var voice: ChatHighlights.Voice? {
        highlights?.voices.first { $0.name == viewer }
    }

    var body: some View {
        let person = PremiumFacts.person(named: viewer, in: report)
        let rank = PremiumFacts.rank(of: viewer, in: report)
        let named = reading?.role(named: viewer)
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("role.eyebrow"), symbol: nil)
            Text(verbatim: named?.title ?? viewer)
                .font(.ui(40, .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.top, 12)
            Text(verbatim: L10n.tr("role.place", String(rank), String(report.participantCount)))
                .font(.ui(22, .bold))
                .padding(.top, 4)
            Text(verbatim: named?.line ?? roleLine(person, rank: rank))
                .font(.ui(16))
                .lineSpacing(3)
                .opacity(0.88)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            if let line = voice?.line {
                QuoteBlock(line: line, theme: theme).padding(.top, 14)
            }
            Spacer(minLength: 16)
            HStack(alignment: .top) {
                fact(Format.number(person?.messages ?? 0), L10n.tr("role.fact.messages"))
                fact(person?.avgReplyMinutes.map(Format.duration(minutes:)) ?? L10n.tr("role.reply.none"), L10n.tr("role.fact.reply"))
                fact(Format.percent(person?.nightPercent ?? 0), L10n.tr("role.fact.night"))
            }
        }
        .foregroundStyle(theme.foreground)
    }

    private func roleLine(_ person: ChatReport.Participant?, rank: Int) -> String {
        if rank == 1 {
            return L10n.tr("role.lead.top", Format.percent(person?.sharePercent ?? report.talker.sharePercent))
        }
        return L10n.tr("role.lead.other", PremiumFacts.role(of: viewer, in: report).title)
    }

    private func fact(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: value).font(.ui(18, .bold)).lineLimit(1).minimumScaleFactor(0.6)
            Text(verbatim: caption).font(.ui(12, .bold)).opacity(0.75).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VibeCard: View {
    let report: ChatReport
    let highlights: ChatHighlights?
    let reading: ChatReading?
    let theme: StoryTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("vibe.eyebrow"), symbol: nil)
            Text(verbatim: reading?.vibeTitle ?? PremiumFacts.vibe(of: report).title)
                .font(.ui(34, .bold))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            Text(verbatim: reading?.vibeLine ?? L10n.tr("vibe.note"))
                .font(.ui(16))
                .opacity(0.84)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            if let lines = highlights?.moments.prefix(2), !lines.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        QuoteBlock(line: line, theme: theme)
                    }
                }
                .padding(.top, 12)
            }
            Spacer(minLength: 16)
            VStack(spacing: 10) {
                line(L10n.tr("vibe.activeDays"), Format.number(report.activeDays))
                line(L10n.tr("vibe.reply"), Format.duration(minutes: PremiumFacts.averageReplyMinutes(report)))
                line(L10n.tr("vibe.nightShare"), Format.percent(PremiumFacts.groupNightPercent(report)))
                if let hour = report.nightOwl?.peakHour {
                    line(L10n.tr("vibe.peak"), Format.clock(hour: hour))
                }
            }
        }
        .foregroundStyle(theme.foreground)
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack {
            Text(verbatim: label).font(.ui(15))
            Spacer()
            Text(verbatim: value).font(.ui(22, .bold))
        }
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) { Rectangle().frame(height: 2).opacity(0.22) }
    }
}

struct CastCard: View {
    let report: ChatReport
    let viewer: String
    let highlights: ChatHighlights?
    let reading: ChatReading?
    let theme: StoryTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("cast.eyebrow"), symbol: nil)
            Text(verbatim: L10n.tr("cast.title", String(report.participantCount)))
                .font(.ui(32, .bold))
                .padding(.top, 10)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(report.participants, id: \.name) { person in
                        let voice = highlights?.voices.first { $0.name == person.name }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(verbatim: person.name).font(.ui(16, .bold))
                                Text(verbatim: reading?.role(named: person.name)?.title
                                    ?? PremiumFacts.role(of: person.name, in: report).title)
                                    .font(.ui(13, .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(theme.foreground.opacity(0.1), in: Capsule())
                                Spacer(minLength: 8)
                                if person.name == viewer {
                                    Text(verbatim: L10n.tr("cast.you"))
                                        .font(.ui(11, .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Palette.lime, in: Capsule())
                                        .foregroundStyle(Palette.ink)
                                }
                            }
                            if let words = voice?.words, !words.isEmpty {
                                Text(verbatim: words.joined(separator: " · "))
                                    .font(.ui(13, .bold))
                                    .opacity(0.7)
                            }
                            if let line = reading?.role(named: person.name)?.line, !line.isEmpty {
                                Text(verbatim: line)
                                    .font(.ui(14))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if let text = voice?.line?.text {
                                Text(verbatim: "“\(text)”")
                                    .font(.ui(14))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.top, 14)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(theme.foreground)
    }
}

struct FastestCard: View {
    let report: ChatReport
    let theme: StoryTheme

    var body: some View {
        let ranked = Array(PremiumFacts.fastest(report).prefix(3))
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("fastest.eyebrow"), symbol: nil)
            Text(verbatim: ranked.first?.name ?? "")
                .font(.ui(40, .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .padding(.top, 12)
            if let minutes = ranked.first?.avgReplyMinutes {
                Text(verbatim: Format.duration(minutes: minutes))
                    .displayStyle(46, tracking: -0.045)
                    .padding(.top, 8)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(podium(ranked).enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 4) {
                        Text(verbatim: "#\(item.place)")
                            .font(.ui(13, .bold))
                        Text(verbatim: item.person.name)
                            .font(.ui(14, .bold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.center)
                        Text(verbatim: item.person.avgReplyMinutes.map(Format.duration(minutes:)) ?? "")
                            .font(.ui(18, .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.foreground.opacity(item.place == 1 ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.top, 16)
            Spacer(minLength: 12)
            if let slow = report.slowReplier {
                Text(verbatim: L10n.tr("fastest.compare", slow.name, Format.duration(minutes: slow.avgReplyMinutes)))
                    .font(.ui(15))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .foregroundStyle(theme.foreground)
    }

    /// Visual order is second, first, third, matching a podium.
    private func podium(_ ranked: [ChatReport.Participant]) -> [(place: Int, person: ChatReport.Participant)] {
        let indexed = ranked.enumerated().map { (place: $0.offset + 1, person: $0.element) }
        guard indexed.count >= 2 else { return indexed }
        var order = [indexed[1], indexed[0]]
        if indexed.count > 2 { order.append(indexed[2]) }
        return order
    }
}

struct MomentsCard: View {
    let report: ChatReport
    let highlights: ChatHighlights?
    let reading: ChatReading?
    let theme: StoryTheme

    var body: some View {
        let silence = report.participants.max { $0.longestSilenceDays < $1.longestSilenceDays }
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("moments.eyebrow"), symbol: nil)
            Text(verbatim: L10n.tr("moments.title"))
                .font(.ui(32, .bold))
                .padding(.top, 10)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let highlights {
                        ForEach(Array(highlights.moments.enumerated()), id: \.offset) { index, line in
                            QuoteBlock(line: line, caption: reading?.caption(ReadingService.momentID(index)), theme: theme)
                        }
                    }
                    if let highlights, highlights.busiestCount > 0 {
                        moment(Format.day(highlights.busiestDate), L10n.tr("moments.busy", Format.number(highlights.busiestCount)))
                    }
                    if let silence, silence.longestSilenceDays > 0 {
                        moment(silence.name, L10n.tr("moments.silence", Format.number(silence.longestSilenceDays)))
                    }
                }
                .padding(.top, 14)
            }
            .scrollIndicators(.hidden)
            Spacer(minLength: 12)
            Text(verbatim: L10n.tr("moments.fine"))
                .font(.ui(13, .semibold))
                .opacity(0.7)
        }
        .foregroundStyle(theme.foreground)
    }

    private func moment(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: title).font(.ui(18, .bold))
            Text(verbatim: detail).font(.ui(14)).opacity(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ArchetypeCard: View {
    let highlights: ChatHighlights?
    let reading: ChatReading?
    let theme: StoryTheme

    var body: some View {
        let lines = highlights?.drama ?? []
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("drama.eyebrow"), symbol: nil)
            Text(verbatim: L10n.tr("drama.title"))
                .font(.ui(32, .bold))
                .padding(.top, 10)
            if lines.isEmpty {
                Text(verbatim: L10n.tr("drama.empty"))
                    .font(.ui(16))
                    .opacity(0.8)
                    .padding(.top, 16)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            QuoteBlock(line: line, caption: reading?.caption(ReadingService.dramaID(index)), theme: theme)
                        }
                    }
                    .padding(.top, 14)
                }
                .scrollIndicators(.hidden)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.foreground)
    }
}

struct QuoteBlock: View {
    let line: ChatHighlights.Line
    var caption: String? = nil
    let theme: StoryTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: line.replyTo.map { L10n.tr("quote.reply", line.name, $0) } ?? line.name)
                    .font(.ui(14, .bold))
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text(verbatim: "\(Format.day(line.date)) \(line.clock)")
                    .font(.ui(12, .bold))
                    .opacity(0.65)
            }
            Text(verbatim: "“\(line.text)”")
                .font(.ui(16, .bold))
                .fixedSize(horizontal: false, vertical: true)
            if let caption, !caption.isEmpty {
                Text(verbatim: caption)
                    .font(.ui(14))
                    .opacity(0.82)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.foreground.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct CliquesCard: View {
    let pairs: [ChatHighlights.Pair]
    let reading: ChatReading?
    let theme: StoryTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("cliques.eyebrow"), symbol: Symbol.group)
            Text(verbatim: L10n.tr("cliques.title"))
                .font(.ui(34, .bold))
                .padding(.top, 10)
            if pairs.isEmpty {
                Text(verbatim: L10n.tr("cliques.empty"))
                    .font(.ui(16))
                    .opacity(0.8)
                    .padding(.top, 16)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: "\(pair.first)  ↔  \(pair.second)").font(.ui(18, .bold))
                            Text(verbatim: L10n.tr("cliques.count", Format.number(pair.count)))
                                .font(.ui(14))
                                .opacity(0.78)
                            if let text = pair.line?.text {
                                Text(verbatim: "“\(text)”")
                                    .font(.ui(15))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 2)
                            }
                            if let caption = reading?.caption(ReadingService.cliqueID(index)) {
                                Text(verbatim: caption)
                                    .font(.ui(14))
                                    .opacity(0.82)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.top, 16)
            }
            Spacer(minLength: 12)
            Text(verbatim: L10n.tr("cliques.note"))
                .font(.ui(15))
                .opacity(0.8)
        }
        .foregroundStyle(theme.foreground)
    }
}

extension PremiumFacts.Vibe {
    var title: String {
        switch self {
        case .nightSlow: L10n.tr("vibe.nightSlow")
        case .nightFast: L10n.tr("vibe.nightFast")
        case .daySlow: L10n.tr("vibe.daySlow")
        case .dayFast: L10n.tr("vibe.dayFast")
        }
    }
}

extension PremiumFacts.Role {
    var title: String {
        switch self {
        case .motor: L10n.tr("archetype.motor")
        case .flash: L10n.tr("archetype.flash")
        case .night: L10n.tr("archetype.night")
        case .planner: L10n.tr("archetype.planner")
        case .ghost: L10n.tr("archetype.ghost")
        case .caps: L10n.tr("archetype.caps")
        case .monologue: L10n.tr("archetype.monologue")
        case .drama: L10n.tr("archetype.drama")
        case .media: L10n.tr("archetype.media")
        case .laugh: L10n.tr("archetype.laugh")
        case .watcher: L10n.tr("archetype.watcher")
        }
    }
}
