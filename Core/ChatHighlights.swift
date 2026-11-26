import Foundation

/// Extra counts the paid cards need. Not part of the karne fixture: messages are still dropped
/// after this is built.
struct ChatHighlights: Codable, Equatable, Sendable {
    struct Pair: Codable, Equatable, Sendable {
        var first: String
        var second: String
        var count: Int
    }

    struct Spike: Codable, Equatable, Sendable {
        var name: String
        var date: String
        var count: Int
    }

    var busiestDate: String
    var busiestCount: Int
    var nightSpike: Spike?
    var pairs: [Pair]

    static func build(messages: [ChatMessage]) -> ChatHighlights {
        var dayCounts: [String: Int] = [:]
        var nightCounts: [String: (name: String, date: String, count: Int)] = [:]
        var pairCounts: [String: Int] = [:]

        for (index, message) in messages.enumerated() {
            let date = message.time.isoDate
            dayCounts[date, default: 0] += 1
            if message.time.hour < ReportRules.nightEndHour {
                let key = message.sender + "\u{1}" + date
                var entry = nightCounts[key] ?? (message.sender, date, 0)
                entry.count += 1
                nightCounts[key] = entry
            }
            if index == 0 { continue }
            let previous = messages[index - 1]
            if previous.sender == message.sender { continue }
            let delay = message.time.totalSeconds - previous.time.totalSeconds
            guard delay >= 0, delay <= ReportRules.replyWindowSeconds else { continue }
            let names = [previous.sender, message.sender].sorted()
            let key = names[0] + "\u{1}" + names[1]
            pairCounts[key, default: 0] += 1
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
            return Pair(first: names[0], second: names.count > 1 ? names[1] : "", count: count)
        }
        .sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            if lhs.first != rhs.first { return lhs.first < rhs.first }
            return lhs.second < rhs.second
        }

        return ChatHighlights(
            busiestDate: busiest?.key ?? "",
            busiestCount: busiest?.value ?? 0,
            nightSpike: spike.map { Spike(name: $0.name, date: $0.date, count: $0.count) },
            pairs: Array(pairs.prefix(3))
        )
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
