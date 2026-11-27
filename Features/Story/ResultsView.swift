import SwiftUI

/// One scrolling report. Full-bleed posters stay on the share images; this is the screen you read.
struct ResultsView: View {
    let report: ChatReport
    let viewer: String
    let highlights: ChatHighlights?
    let reading: ChatReading?
    let isPremium: Bool
    let roastState: RoastState
    let unlock: () -> Void
    let retryRoast: () -> Void
    let close: () -> Void
    let share: () -> Void

    private static let rankFills = [Palette.cardBlush, Palette.cardMint, Palette.cardPeach, Palette.cardLilac]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                summary
                talkers
                if !ReportBoard.fastest(report).isEmpty {
                    speed
                }
                if !ReportBoard.night(report).isEmpty {
                    night
                }
                if !report.topWords.isEmpty {
                    words
                }
                if !report.awards.isEmpty {
                    awards
                }
                roast
                if isPremium {
                    paid
                } else {
                    locked
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Palette.paper.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: close) {
                Image(systemName: Symbol.back)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: L10n.tr("story.close")))
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                TicksIcon(size: 16, lineWidth: 2.4)
                    .foregroundStyle(Palette.ink)
                    .frame(width: 28, height: 28)
                    .background(Palette.lime, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(verbatim: report.title)
                    .font(.ui(16, .bold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
            }
            .padding(.leading, 4)
            .padding(.trailing, 12)
            .padding(.vertical, 4)
            .background(Color.white, in: Capsule())
            Spacer(minLength: 8)
            Button(action: share) {
                Image(systemName: Symbol.upload)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: L10n.tr("story.share")))
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(verbatim: report.title)
                .font(.display(28))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            stat(Format.number(report.participantCount), L10n.tr("cover.stat.people"))
            Rectangle().fill(Palette.ink.opacity(0.12)).frame(height: 1)
            stat(Format.number(report.totalMessages), L10n.tr("cover.stat.messages"))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.cardMint, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func stat(_ value: String, _ caption: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(verbatim: value)
                .displayStyle(42, tracking: -0.045)
                .foregroundStyle(Palette.ink)
            Text(verbatim: caption)
                .font(.ui(18, .bold))
                .foregroundStyle(Palette.ink.opacity(0.72))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    private var talkers: some View {
        race(
            title: L10n.tr("award.talker"),
            people: ReportBoard.talkers(report),
            value: { Format.percent($0.sharePercent) }
        )
    }

    private var speed: some View {
        let ranked = ReportBoard.fastest(report)
        return VStack(alignment: .leading, spacing: 12) {
            race(
                title: L10n.tr("fastest.eyebrow"),
                people: ranked,
                value: { $0.avgReplyMinutes.map(Format.duration(minutes:)) ?? "" }
            )
            if let slow = report.slowReplier {
                HStack {
                    Text(verbatim: L10n.tr("award.slowReplier"))
                        .font(.ui(14, .bold))
                    Spacer(minLength: 8)
                    Text(verbatim: slow.name)
                        .font(.ui(15, .bold))
                        .lineLimit(1)
                    Text(verbatim: Format.duration(minutes: slow.avgReplyMinutes))
                        .font(.ui(15, .bold))
                }
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Palette.cardApricot, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var night: some View {
        race(
            title: L10n.tr("award.nightOwl"),
            people: ReportBoard.night(report),
            value: { Format.percent($0.nightPercent) }
        )
    }

    private func race(
        title: String,
        people: [ChatReport.Participant],
        value: @escaping (ChatReport.Participant) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: title)
                .font(.ui(20, .bold))
                .foregroundStyle(Palette.ink)
            if people.count >= 2 {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(podiumOrder(Array(people.prefix(3))).enumerated()), id: \.offset) { _, item in
                        podiumTile(item.person, place: item.place, value: value(item.person))
                    }
                }
            }
            VStack(spacing: 8) {
                ForEach(Array(people.enumerated()), id: \.offset) { position, person in
                    rankRow(person, place: position + 1, value: value(person))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func rankRow(_ person: ChatReport.Participant, place: Int, value: String) -> some View {
        HStack(spacing: 10) {
            Text(verbatim: "#\(place)")
                .font(.ui(15, .bold))
                .frame(width: 32, alignment: .leading)
            Text(verbatim: person.name)
                .font(.ui(16, .bold))
                .lineLimit(1)
            if person.name == viewer {
                Text(verbatim: L10n.tr("cast.you"))
                    .font(.ui(11, .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Palette.lime, in: Capsule())
            }
            Spacer(minLength: 8)
            Text(verbatim: value)
                .displayStyle(26, tracking: -0.04)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Self.rankFills[(place - 1) % Self.rankFills.count], in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: L10n.tr("words.eyebrow"))
                .font(.ui(20, .bold))
                .foregroundStyle(Palette.ink)
            if let top = report.topWords.first {
                Text(verbatim: top.word)
                    .displayStyle(36, tracking: -0.04)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(verbatim: Format.number(top.count))
                    .font(.ui(16, .bold))
                    .foregroundStyle(Palette.ink.opacity(0.7))
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(ReportBoard.extraWords(report).enumerated()), id: \.offset) { _, word in
                        Text(verbatim: "\(word.word)  \(Format.number(word.count))")
                            .font(.ui(14, .bold))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Palette.cardPeach, in: Capsule())
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var awards: some View {
        let open = ReportBoard.awards(report, premium: isPremium)
        let locked = isPremium ? [] : report.awards.filter(\.premium)
        return VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: L10n.tr("ceremony.eyebrow"))
                .font(.ui(20, .bold))
                .foregroundStyle(Palette.ink)
            ForEach(open) { award in
                PrizeRow(kind: award.id, name: award.name, reason: AwardStyle.reason(award))
            }
            if !locked.isEmpty {
                Button(action: unlock) {
                    HStack(spacing: 8) {
                        Image(systemName: Symbol.lock).font(.system(size: 13, weight: .bold))
                        Text(verbatim: locked.count == 1
                            ? L10n.tr("ceremony.locked.one")
                            : L10n.tr("ceremony.locked.many", String(locked.count)))
                            .font(.ui(15, .bold))
                    }
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Palette.lime, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var roast: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: L10n.tr("roast.title"))
                .font(.ui(20, .bold))
                .foregroundStyle(Palette.ink)
            switch roastState {
            case .loading:
                HStack(spacing: 10) {
                    Spinner(tint: Palette.ink)
                    Text(verbatim: L10n.tr("roast.loading"))
                        .font(.ui(15))
                        .foregroundStyle(Palette.ink.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            case .failed(let failure):
                Text(verbatim: roastMessage(failure))
                    .font(.ui(15))
                    .foregroundStyle(Palette.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                if failure != .notConfigured {
                    Button(action: retryRoast) {
                        Text(verbatim: L10n.tr("common.retry"))
                            .font(.ui(15, .bold))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 16)
                            .frame(height: 40)
                            .background(Palette.lime, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            case .loaded(let roasts):
                if roasts.isEmpty {
                    Text(verbatim: L10n.tr("roast.empty"))
                        .font(.ui(15))
                        .foregroundStyle(Palette.ink.opacity(0.75))
                } else {
                    let open = ShownRoasts.lines(roasts, premium: isPremium)
                    ForEach(Array(open.enumerated()), id: \.offset) { _, roast in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: roast.name).labelStyle(12).foregroundStyle(Palette.roseInk)
                            Text(verbatim: roast.line)
                                .font(.ui(16, .bold))
                                .foregroundStyle(Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.cardBlush, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    if !isPremium, roasts.count > 1 {
                        Button(action: unlock) {
                            Text(verbatim: L10n.tr("roast.locked.many", String(roasts.count - 1)))
                                .font(.ui(15, .bold))
                                .foregroundStyle(Palette.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Palette.lime, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private var paid: some View {
        role
        vibe
        cast
        if !(highlights?.moments ?? []).isEmpty { moments }
        if !(highlights?.drama ?? []).isEmpty { drama }
        if !(highlights?.pairs ?? []).isEmpty { cliques }
    }

    private var role: some View {
        let person = PremiumFacts.person(named: viewer, in: report)
        let rank = PremiumFacts.rank(of: viewer, in: report)
        let named = reading?.role(named: viewer)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(verbatim: L10n.tr("role.eyebrow")).labelStyle(12)
                Spacer()
                Text(verbatim: L10n.tr("role.place", String(rank), String(report.participantCount)))
                    .font(.ui(13, .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.55), in: Capsule())
            }
            Text(verbatim: named?.title ?? PremiumFacts.role(of: viewer, in: report).title)
                .displayStyle(34, tracking: -0.04)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: Format.percent(person?.sharePercent ?? report.talker.sharePercent))
                    .displayStyle(56, tracking: -0.05)
                Text(verbatim: L10n.tr("cover.stat.messages"))
                    .font(.ui(16, .bold))
                    .opacity(0.8)
            }
            if let line = named?.line, !line.isEmpty {
                Text(verbatim: line)
                    .font(.ui(16))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(Palette.roseInk)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.cardBlush, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var vibe: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: L10n.tr("vibe.eyebrow")).labelStyle(12)
            Text(verbatim: reading?.vibeTitle ?? PremiumFacts.vibe(of: report).title)
                .displayStyle(32, tracking: -0.04)
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: reading?.vibeLine ?? L10n.tr("vibe.note"))
                .font(.ui(16))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Palette.clayInk)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.cardApricot, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func podiumTile(_ person: ChatReport.Participant, place: Int, value: String) -> some View {
        let fill = place == 1 ? Palette.cardBlush : (place == 2 ? Palette.cardMint : Palette.cardPeach)
        let height: CGFloat = place == 1 ? 168 : (place == 2 ? 142 : 124)
        return VStack(spacing: 6) {
            Text(verbatim: "\(place)")
                .font(.ui(13, .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 26, height: 26)
                .background(Color.white, in: Circle())
            Text(verbatim: person.name)
                .font(.ui(13, .bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(verbatim: value)
                .displayStyle(place == 1 ? 28 : 22, tracking: -0.04)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 6)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .bottom)
        .background(fill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func podiumOrder(_ ranked: [ChatReport.Participant]) -> [(place: Int, person: ChatReport.Participant)] {
        let indexed = ranked.enumerated().map { (place: $0.offset + 1, person: $0.element) }
        guard indexed.count >= 2 else { return indexed }
        var order = [indexed[1], indexed[0]]
        if indexed.count > 2 { order.append(indexed[2]) }
        return order
    }

    private var cast: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(verbatim: L10n.tr("cast.eyebrow"))
                .font(.ui(20, .bold))
                .foregroundStyle(Palette.ink)
            ForEach(Array(report.participants.enumerated()), id: \.offset) { position, person in
                let fill = Self.rankFills[position % Self.rankFills.count]
                let named = reading?.role(named: person.name)
                HStack(alignment: .top, spacing: 12) {
                    Text(verbatim: Format.initials(person.name))
                        .font(.ui(13, .bold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 40, height: 40)
                        .background(fill, in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: person.name)
                            .font(.ui(16, .bold))
                            .foregroundStyle(Palette.ink)
                        Text(verbatim: named?.title ?? PremiumFacts.role(of: person.name, in: report).title)
                            .font(.ui(12, .bold))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(fill, in: Capsule())
                        if let line = named?.line, !line.isEmpty {
                            Text(verbatim: line)
                                .font(.ui(14))
                                .foregroundStyle(Palette.ink.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var moments: some View {
        let lines = highlights?.moments ?? []
        return VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: L10n.tr("moments.eyebrow"))
                .font(.ui(20, .bold))
                .foregroundStyle(Palette.ink)
            if lines.isEmpty {
                Text(verbatim: L10n.tr("moments.fine"))
                    .font(.ui(15))
                    .foregroundStyle(Palette.ink.opacity(0.7))
            } else {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    quote(line, caption: reading?.caption(ReadingService.momentID(index)), fill: Palette.cardMint)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var drama: some View {
        let lines = highlights?.drama ?? []
        return VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: L10n.tr("drama.eyebrow"))
                .font(.ui(20, .bold))
                .foregroundStyle(Palette.roseInk)
            if lines.isEmpty {
                Text(verbatim: L10n.tr("drama.empty"))
                    .font(.ui(15))
                    .foregroundStyle(Palette.roseInk.opacity(0.75))
            } else {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    quote(line, caption: reading?.caption(ReadingService.dramaID(index)), fill: Color.white.opacity(0.55))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.cardBlush, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func quote(_ line: ChatHighlights.Line, caption: String?, fill: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: line.replyTo.map { L10n.tr("quote.reply", line.name, $0) } ?? line.name)
                    .font(.ui(14, .bold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(verbatim: Format.day(line.date))
                    .font(.ui(12, .bold))
                    .opacity(0.6)
            }
            Text(verbatim: "“\(line.text)”")
                .font(.ui(16, .bold))
                .fixedSize(horizontal: false, vertical: true)
            if let caption, !caption.isEmpty {
                Text(verbatim: caption)
                    .font(.ui(14))
                    .opacity(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var cliques: some View {
        let pairs = highlights?.pairs ?? []
        return VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: L10n.tr("cliques.eyebrow"))
                .font(.ui(20, .bold))
                .foregroundStyle(Palette.ink)
            if pairs.isEmpty {
                Text(verbatim: L10n.tr("cliques.empty"))
                    .font(.ui(15))
                    .foregroundStyle(Palette.ink.opacity(0.7))
            } else {
                ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: "\(pair.first) · \(pair.second)")
                            .font(.ui(16, .bold))
                        Text(verbatim: L10n.tr("cliques.count", Format.number(pair.count)))
                            .font(.ui(13, .bold))
                            .opacity(0.7)
                        if let caption = reading?.caption(ReadingService.cliqueID(index)), !caption.isEmpty {
                            Text(verbatim: caption)
                                .font(.ui(14))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.cardLilac, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var locked: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: L10n.tr("premium.gate.lead"))
                .font(.ui(15))
                .foregroundStyle(Palette.ink.opacity(0.7))
            ForEach(["premium.gate.role", "premium.gate.vibe", "premium.gate.cast"], id: \.self) { key in
                HStack {
                    Text(verbatim: L10n.tr(key)).font(.ui(16, .bold))
                    Spacer()
                    Image(systemName: Symbol.lock).font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            Button(action: unlock) {
                Text(verbatim: L10n.tr("premium.gate.unlock"))
                    .font(.ui(16, .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Palette.lime, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func roastMessage(_ failure: RoastService.Failure) -> String {
        switch failure {
        case .notConfigured: return L10n.tr("roast.error.notConfigured")
        case .offline: return L10n.tr("roast.error.offline")
        case .rejected, .badResponse: return L10n.tr("roast.error.server")
        }
    }
}
