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
    let theme: StoryTheme

    var body: some View {
        let person = PremiumFacts.person(named: viewer, in: report)
        let rank = PremiumFacts.rank(of: viewer, in: report)
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("role.eyebrow"), symbol: nil)
            Text(verbatim: viewer)
                .font(.ui(40, .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.top, 12)
            Text(verbatim: L10n.tr("role.place", String(rank), String(report.participantCount)))
                .font(.ui(22, .bold))
                .padding(.top, 4)
            Text(verbatim: roleLine(person, rank: rank))
                .font(.ui(16))
                .lineSpacing(3)
                .opacity(0.88)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
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
    let theme: StoryTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("vibe.eyebrow"), symbol: nil)
            Text(verbatim: PremiumFacts.vibe(of: report).title)
                .font(.ui(34, .bold))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            Text(verbatim: L10n.tr("vibe.note"))
                .font(.ui(16))
                .opacity(0.84)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
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
                        HStack {
                            Text(verbatim: person.name).font(.ui(16, .bold))
                            Text(verbatim: PremiumFacts.role(of: person.name, in: report).title)
                                .font(.ui(14))
                                .opacity(0.75)
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
    let slow: ChatReport.SlowReplier
    let theme: StoryTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("fastest.eyebrow"), symbol: nil)
            Text(verbatim: slow.fastestName ?? "")
                .font(.ui(44, .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .padding(.top, 12)
            if let minutes = slow.fastestAvgReplyMinutes {
                Text(verbatim: Format.duration(minutes: minutes))
                    .displayStyle(46, tracking: -0.045)
                    .padding(.top, 8)
            }
            Text(verbatim: L10n.tr("fastest.note"))
                .font(.ui(16))
                .opacity(0.84)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            Spacer(minLength: 12)
            Text(verbatim: L10n.tr(
                "fastest.compare",
                slow.name,
                Format.duration(minutes: slow.avgReplyMinutes)
            ))
            .font(.ui(15))
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .foregroundStyle(theme.foreground)
    }
}

struct MomentsCard: View {
    let report: ChatReport
    let highlights: ChatHighlights?
    let theme: StoryTheme

    var body: some View {
        let silence = report.participants.max { $0.longestSilenceDays < $1.longestSilenceDays }
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("moments.eyebrow"), symbol: nil)
            Text(verbatim: L10n.tr("moments.title"))
                .font(.ui(32, .bold))
                .padding(.top, 10)
            VStack(alignment: .leading, spacing: 12) {
                if let highlights, highlights.busiestCount > 0 {
                    moment(Format.day(highlights.busiestDate), L10n.tr("moments.busy", Format.number(highlights.busiestCount)))
                }
                if let silence, silence.longestSilenceDays > 0 {
                    moment(silence.name, L10n.tr("moments.silence", Format.number(silence.longestSilenceDays)))
                }
                if let spike = highlights?.nightSpike, spike.count > 0 {
                    moment(spike.name, L10n.tr("moments.night", Format.day(spike.date), Format.number(spike.count)))
                }
            }
            .padding(.top, 16)
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
    let report: ChatReport
    let theme: StoryTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: L10n.tr("archetype.eyebrow"), symbol: nil)
            Text(verbatim: L10n.tr("archetype.title"))
                .font(.ui(32, .bold))
                .padding(.top, 10)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(report.participants, id: \.name) { person in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: person.name).font(.ui(16, .bold)).lineLimit(1)
                        Text(verbatim: PremiumFacts.role(of: person.name, in: report).title)
                            .font(.ui(13, .bold))
                            .opacity(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.top, 14)
            Spacer(minLength: 0)
        }
        .foregroundStyle(theme.foreground)
    }
}

struct CliquesCard: View {
    let pairs: [ChatHighlights.Pair]
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
                    ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: "\(pair.first)  ↔  \(pair.second)").font(.ui(18, .bold))
                            Text(verbatim: L10n.tr("cliques.count", Format.number(pair.count)))
                                .font(.ui(14))
                                .opacity(0.78)
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
