import Foundation

/// Extra counts the paid cards need. Not part of the karne fixture: messages are still dropped
/// after this is built.
struct ChatHighlights: Codable, Equatable, Sendable {
    /// One kept line. The rest of the chat is dropped.
    struct Line: Codable, Equatable, Sendable {
        var name: String
        var replyTo: String?
        var date: String
        var clock: String
        var text: String
    }

    struct Pair: Codable, Equatable, Sendable {
        var first: String
        var second: String
        var count: Int
        /// A line one of them sent the other. Missing on reports saved before quotes existed.
        var line: Line?
    }

    struct Spike: Codable, Equatable, Sendable {
        var name: String
        var date: String
        var count: Int
    }

    /// What one person actually wrote: their longest line and the words they repeat.
    struct Voice: Codable, Equatable, Sendable {
        var name: String
        var words: [String]
        var line: Line?
    }

    var busiestDate: String
    var busiestCount: Int
    var nightSpike: Spike?
    var pairs: [Pair]
    /// Lines with !! ?? ?! !?, longest first. Empty when the chat has none.
    var drama: [Line]
    /// A line from the busiest day, one from the night spike, and the longest line left.
    var moments: [Line]
    var voices: [Voice]

    static let quoteLimit = 160

    static func build(messages: [ChatMessage]) -> ChatHighlights {
        var dayCounts: [String: Int] = [:]
        var nightCounts: [String: (name: String, date: String, count: Int)] = [:]
        var pairCounts: [String: Int] = [:]
        var pairLines: [String: Line] = [:]
        var dramaLines: [Line] = []
        var spoken: [Line] = []
        var wordCounts: [String: [String: Int]] = [:]
        let turkish = usesTurkish(messages)

        for (index, message) in messages.enumerated() {
            let date = message.time.isoDate
            dayCounts[date, default: 0] += 1
            if message.time.hour < ReportRules.nightEndHour {
                let key = message.sender + "\u{1}" + date
                var entry = nightCounts[key] ?? (message.sender, date, 0)
                entry.count += 1
                nightCounts[key] = entry
            }
            var replyTo: String?
            if index > 0 {
                let previous = messages[index - 1]
                if previous.sender != message.sender {
                    let delay = message.time.totalSeconds - previous.time.totalSeconds
                    if delay >= 0, delay <= ReportRules.replyWindowSeconds {
                        replyTo = previous.sender
                        let names = [previous.sender, message.sender].sorted()
                        let key = names[0] + "\u{1}" + names[1]
                        pairCounts[key, default: 0] += 1
                    }
                }
            }
            guard message.kind == .text, let line = makeLine(message, replyTo: replyTo) else { continue }
            spoken.append(line)
            if isDrama(line.text) { dramaLines.append(line) }
            if let replyTo {
                let names = [replyTo, message.sender].sorted()
                let key = names[0] + "\u{1}" + names[1]
                if let current = pairLines[key], current.text.count >= line.text.count { } else {
                    pairLines[key] = line
                }
            }
            let lowered = TextRules.lower(TextRules.scalars(line.text), turkish: turkish)
            var own = wordCounts[message.sender] ?? [:]
            for token in TextRules.tokens(lowered) where token.count >= ReportRules.minWordLength {
                let word = TextRules.string(token)
                if !Stopwords.all.contains(word) { own[word, default: 0] += 1 }
            }
            wordCounts[message.sender] = own
        }

        let busiest = dayCounts.max { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            return lhs.key > rhs.key
        }
        let spike = nightCounts.values.max { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count < rhs.count }
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            return lhs.name > rhs.name
        }
        let pairs = pairCounts.map { key, count -> Pair in
            let names = key.split(separator: "\u{1}", maxSplits: 1).map(String.init)
            return Pair(
                first: names[0],
                second: names.count > 1 ? names[1] : "",
                count: count,
                line: pairLines[key]
            )
        }
        .sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            if lhs.first != rhs.first { return lhs.first < rhs.first }
            return lhs.second < rhs.second
        }

        let busiestDate = busiest?.key ?? ""
        let night = spike.map { Spike(name: $0.name, date: $0.date, count: $0.count) }
        return ChatHighlights(
            busiestDate: busiestDate,
            busiestCount: busiest?.value ?? 0,
            nightSpike: night,
            pairs: Array(pairs.prefix(3)),
            drama: pickDrama(dramaLines),
            moments: pickMoments(spoken, busiestDate: busiestDate, night: night),
            voices: pickVoices(spoken, words: wordCounts)
        )
    }

    init(
        busiestDate: String, busiestCount: Int, nightSpike: Spike?, pairs: [Pair],
        drama: [Line] = [], moments: [Line] = [], voices: [Voice] = []
    ) {
        self.busiestDate = busiestDate
        self.busiestCount = busiestCount
        self.nightSpike = nightSpike
        self.pairs = pairs
        self.drama = drama
        self.moments = moments
        self.voices = voices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        busiestDate = try container.decode(String.self, forKey: .busiestDate)
        busiestCount = try container.decode(Int.self, forKey: .busiestCount)
        nightSpike = try container.decodeIfPresent(Spike.self, forKey: .nightSpike)
        pairs = try container.decodeIfPresent([Pair].self, forKey: .pairs) ?? []
        drama = try container.decodeIfPresent([Line].self, forKey: .drama) ?? []
        moments = try container.decodeIfPresent([Line].self, forKey: .moments) ?? []
        voices = try container.decodeIfPresent([Voice].self, forKey: .voices) ?? []
    }

    private static func usesTurkish(_ messages: [ChatMessage]) -> Bool {
        var textCount = 0
        var markers = 0
        for message in messages where message.kind == .text {
            textCount += 1
            for scalar in message.text.unicodeScalars where TextRules.isTurkishMarker(scalar) {
                markers += 1
            }
        }
        return markers >= 3 && markers * 50 >= textCount
    }

    private static func makeLine(_ message: ChatMessage, replyTo: String?) -> Line? {
        let collapsed = message.text.split { $0.isWhitespace }.joined(separator: " ")
        guard collapsed.count >= 8 else { return nil }
        let text = collapsed.count > quoteLimit ? String(collapsed.prefix(quoteLimit - 1)) + "…" : collapsed
        let hour = message.time.hour < 10 ? "0\(message.time.hour)" : "\(message.time.hour)"
        let minute = message.time.minute < 10 ? "0\(message.time.minute)" : "\(message.time.minute)"
        return Line(name: message.sender, replyTo: replyTo, date: message.time.isoDate, clock: "\(hour):\(minute)", text: text)
    }

    private static func isDrama(_ text: String) -> Bool {
        let body = TextRules.scalars(text)
        return TextRules.containsAny(body, TextRules.dramaMarks)
    }

    /// Long outbursts beat "tamam??". One line per person until three are filled.
    private static func pickDrama(_ lines: [Line]) -> [Line] {
        let ranked = lines.sorted { lhs, rhs in
            if lhs.text.count != rhs.text.count { return lhs.text.count > rhs.text.count }
            if lhs.date != rhs.date { return lhs.date < rhs.date }
            return lhs.name < rhs.name
        }
        var picked: [Line] = []
        var used = Set<String>()
        for line in ranked where picked.count < 3 && !used.contains(line.name) {
            picked.append(line)
            used.insert(line.name)
        }
        if picked.count < 3 {
            for line in ranked where picked.count < 3 && !picked.contains(line) {
                picked.append(line)
            }
        }
        return picked
    }

    private static func pickMoments(_ lines: [Line], busiestDate: String, night: Spike?) -> [Line] {
        func longest(_ pool: [Line]) -> Line? {
            pool.max { lhs, rhs in
                if lhs.text.count != rhs.text.count { return lhs.text.count < rhs.text.count }
                return lhs.date > rhs.date
            }
        }
        var picked: [Line] = []
        if let line = longest(lines.filter { $0.date == busiestDate }) { picked.append(line) }
        if let night, let line = longest(lines.filter { $0.name == night.name && $0.date == night.date && $0 != picked.first }) {
            picked.append(line)
        }
        if let line = longest(lines.filter { !picked.contains($0) }) { picked.append(line) }
        return picked
    }

    private static func pickVoices(_ lines: [Line], words: [String: [String: Int]]) -> [Voice] {
        let names = Set(lines.map(\.name)).union(words.keys).sorted()
        return names.map { name in
            let line = lines.filter { $0.name == name }.max { lhs, rhs in
                if lhs.text.count != rhs.text.count { return lhs.text.count < rhs.text.count }
                return lhs.date > rhs.date
            }
            let top = (words[name] ?? [:])
                .filter { $0.value >= 2 }
                .sorted { lhs, rhs in
                    if lhs.value != rhs.value { return lhs.value > rhs.value }
                    return lhs.key < rhs.key
                }
                .prefix(3)
                .map(\.key)
            return Voice(name: name, words: Array(top), line: line)
        }
    }
}

/// Labels and ranks the paid cards read off a finished report. No message text.
enum PremiumFacts {
    enum Role: String, Equatable, Sendable {
        case motor, flash, night, planner, ghost, caps, monologue, drama, media, laugh, watcher
    }

    enum Vibe: String, Equatable, Sendable {
        case nightSlow, nightFast, daySlow, dayFast
    }

    /// Fastest repliers first. Same eligibility as the Görüldü Kralı card.
    static func fastest(_ report: ChatReport) -> [ChatReport.Participant] {
        func pool(minimum: Int) -> [ChatReport.Participant] {
            report.participants.filter { $0.replyCount >= minimum && $0.avgReplyMinutes != nil }
        }
        var eligible = pool(minimum: ReportRules.replyEligibleCount)
        if eligible.count < 2 { eligible = pool(minimum: ReportRules.replyMinCount) }
        return eligible.sorted { lhs, rhs in
            let left = lhs.avgReplyMinutes ?? 0
            let right = rhs.avgReplyMinutes ?? 0
            if left != right { return left < right }
            return lhs.name < rhs.name
        }
    }

    static func rank(of name: String, in report: ChatReport) -> Int {
        (report.participants.firstIndex { $0.name == name } ?? 0) + 1
    }

    static func person(named name: String, in report: ChatReport) -> ChatReport.Participant? {
        report.participants.first { $0.name == name }
    }

    static func role(of name: String, in report: ChatReport) -> Role {
        if name == report.talker.name { return .motor }
        if name == report.slowReplier?.fastestName { return .flash }
        if name == report.nightOwl?.name { return .night }
        if let award = report.awards.first(where: { $0.name == name }) {
            switch award.id {
            case .planBreaker: return .planner
            case .ghost: return .ghost
            case .capsLock: return .caps
            case .monologue: return .monologue
            case .drama: return .drama
            case .mediaSpammer: return .media
            case .laugher: return .laugh
            }
        }
        return .watcher
    }

    static func vibe(of report: ChatReport) -> Vibe {
        let peak = report.nightOwl?.peakHour ?? 12
        let night = peak >= 22 || peak < ReportRules.nightEndHour
        let replies = report.participants.reduce(0) { $0 + $1.replyCount }
        let minutes = report.participants.reduce(0) { partial, person in
            partial + (person.avgReplyMinutes ?? 0) * person.replyCount
        }
        let average = replies > 0 ? minutes / replies : 0
        let slow = average >= 30
        switch (night, slow) {
        case (true, true): return .nightSlow
        case (true, false): return .nightFast
        case (false, true): return .daySlow
        case (false, false): return .dayFast
        }
    }

    /// Night messages as a share of the whole chat, from each person's own night share.
    static func groupNightPercent(_ report: ChatReport) -> Int {
        guard report.totalMessages > 0 else { return 0 }
        let weighted = report.participants.reduce(0) { $0 + $1.nightPercent * $1.messages }
        return (weighted * 2 + report.totalMessages) / (report.totalMessages * 2)
    }

    static func averageReplyMinutes(_ report: ChatReport) -> Int {
        let replies = report.participants.reduce(0) { $0 + $1.replyCount }
        guard replies > 0 else { return 0 }
        let minutes = report.participants.reduce(0) { $0 + ($1.avgReplyMinutes ?? 0) * $1.replyCount }
        return minutes / replies
    }
}
