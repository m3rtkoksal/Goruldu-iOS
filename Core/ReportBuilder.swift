import Foundation

enum ReportRules {
    static let maxSenderLength = 50
    static let minMessages = 20
    static let replyWindowSeconds = 72 * 3_600
    static let slowReplySeconds = 6 * 3_600
    static let replyMinCount = 3
    static let replyEligibleCount = 10
    static let nightEligibleMessages = 20
    static let nightEndHour = 4
    static let topWords = 5
    static let minWordLength = 3
    static let minWordCount = 2
    static let capsMinLetters = 5

    /// Award order is the order of the ceremony. Free awards come first.
    static let awards: [(kind: ChatReport.AwardKind, threshold: Int, premium: Bool)] = [
        (.planBreaker, 2, false),
        (.ghost, 7, false),
        (.capsLock, 3, false),
        (.monologue, 5, true),
        (.drama, 3, true),
        (.mediaSpammer, 5, true),
        (.laugher, 3, true),
    ]
}

/// Turns parsed messages into the report. Follows `reference/report.py` line by line.
enum ReportBuilder {
    private typealias Scalars = TextRules.Scalars

    private struct Tally {
        var name: String
        var messages = 0
        var replySeconds = 0
        var replyCount = 0
        var slowReplies = 0
        var night = 0
        var hours = [Int](repeating: 0, count: 24)
        var capsCount = 0
        var mediaCount = 0
        var planBreaks = 0
        var dramaCount = 0
        var laughCount = 0
        var longestMonologue = 0
        var days: [Int] = []
    }

    static func build(messages: [ChatMessage], title: String, stopwords: Set<String> = Stopwords.all) throws -> ChatReport {
        var indexByName: [String: Int] = [:]
        var people: [Tally] = []
        for message in messages where indexByName[message.sender] == nil {
            indexByName[message.sender] = people.count
            people.append(Tally(name: message.sender))
        }
        guard messages.count >= ReportRules.minMessages, people.count >= 2 else { throw ReportError.tooShort }

        var textMessageCount = 0
        var turkishMarkers = 0
        for message in messages where message.kind == .text {
            textMessageCount += 1
            for scalar in message.text.unicodeScalars where TextRules.isTurkishMarker(scalar) {
                turkishMarkers += 1
            }
        }
        let turkish = turkishMarkers >= 3 && turkishMarkers * 50 >= textMessageCount

        var wordCounts: [String: Int] = [:]
        var runSender: String?
        var runLength = 0
        var activeDaySet = Set<Int>()
        var firstTime = messages[0].time
        var lastTime = messages[0].time

        for (index, message) in messages.enumerated() {
            guard let personIndex = indexByName[message.sender] else { continue }
            let time = message.time
            let day = time.dayNumber
            activeDaySet.insert(day)
            if time < firstTime { firstTime = time }
            if time > lastTime { lastTime = time }

            people[personIndex].messages += 1
            people[personIndex].hours[time.hour] += 1
            if time.hour < ReportRules.nightEndHour { people[personIndex].night += 1 }
            if people[personIndex].days.last != day { people[personIndex].days.append(day) }

            if message.sender == runSender {
                runLength += 1
            } else {
                runSender = message.sender
                runLength = 1
            }
            people[personIndex].longestMonologue = max(people[personIndex].longestMonologue, runLength)

            if index > 0, messages[index - 1].sender != message.sender {
                let delay = time.totalSeconds - messages[index - 1].time.totalSeconds
                if delay >= 0, delay <= ReportRules.replyWindowSeconds {
                    people[personIndex].replySeconds += delay
                    people[personIndex].replyCount += 1
                    if delay >= ReportRules.slowReplySeconds { people[personIndex].slowReplies += 1 }
                }
            }

            if message.kind == .media { people[personIndex].mediaCount += 1 }
            guard message.kind == .text else { continue }

            let body = TextRules.scalars(message.text)
            let lowered = TextRules.lower(body, turkish: turkish)

            var upper = 0
            var lowerCount = 0
            for scalar in body {
                if let lowScalar = TextRules.lowerFirstScalar(scalar, turkish: turkish) {
                    if TextRules.isTokenScalar(lowScalar) { upper += 1 }
                } else if TextRules.isTokenScalar(scalar) {
                    lowerCount += 1
                }
            }
            if upper >= ReportRules.capsMinLetters, lowerCount == 0 { people[personIndex].capsCount += 1 }
            if TextRules.containsAny(lowered, TextRules.planPhrases) { people[personIndex].planBreaks += 1 }
            if TextRules.containsAny(body, TextRules.dramaMarks) { people[personIndex].dramaCount += 1 }

            let messageTokens = TextRules.tokens(lowered)
            if TextRules.containsAny(body, TextRules.laughEmoji)
                || TextRules.containsAny(lowered, TextRules.laughParts)
                || messageTokens.contains(where: TextRules.isKeysmash) {
                people[personIndex].laughCount += 1
            }
            for token in messageTokens where token.count >= ReportRules.minWordLength {
                let word = TextRules.string(token)
                if !stopwords.contains(word) { wordCounts[word, default: 0] += 1 }
            }
        }

        let total = messages.count
        let lastDay = lastTime.dayNumber

        // Stable sort: ties keep the order of first appearance.
        let ranked = people.enumerated()
            .sorted { $0.element.messages != $1.element.messages ? $0.element.messages > $1.element.messages : $0.offset < $1.offset }
            .map(\.element)

        let participants: [ChatReport.Participant] = ranked.map { person in
            let days = Array(Set(person.days)).sorted()
            var silence = lastDay - (days.last ?? lastDay)
            for position in days.indices.dropFirst() {
                silence = max(silence, days[position] - days[position - 1] - 1)
            }
            return ChatReport.Participant(
                name: person.name,
                messages: person.messages,
                sharePercent: TextRules.roundDiv(person.messages * 100, total),
                avgReplyMinutes: person.replyCount >= ReportRules.replyMinCount
                    ? TextRules.roundDiv(person.replySeconds, person.replyCount * 60) : nil,
                replyCount: person.replyCount,
                slowReplies: person.slowReplies,
                nightPercent: TextRules.roundDiv(person.night * 100, person.messages),
                capsCount: person.capsCount,
                mediaCount: person.mediaCount,
                longestSilenceDays: silence,
                longestMonologue: person.longestMonologue,
                planBreaks: person.planBreaks,
                dramaCount: person.dramaCount,
                laughCount: person.laughCount
            )
        }

        let words = wordCounts
            .filter { $0.value >= ReportRules.minWordCount }
            .map { (scalars: TextRules.scalars($0.key), count: $0.value) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : TextRules.precedes($0.scalars, $1.scalars) }
            .prefix(ReportRules.topWords)
            .map { ChatReport.WordCount(word: TextRules.string($0.scalars), count: $0.count) }

        var awards: [ChatReport.Award] = []
        for rule in ReportRules.awards {
            var winner = participants[0]
            for candidate in participants.dropFirst() where value(of: rule.kind, in: candidate) > value(of: rule.kind, in: winner) {
                winner = candidate
            }
            let winnerValue = value(of: rule.kind, in: winner)
            if winnerValue >= rule.threshold {
                awards.append(ChatReport.Award(id: rule.kind, name: winner.name, value: winnerValue, premium: rule.premium))
            }
        }

        return ChatReport(
            title: title,
            turkish: turkish,
            totalMessages: total,
            participantCount: participants.count,
            activeDays: activeDaySet.count,
            firstDate: firstTime.isoDate,
            lastDate: lastTime.isoDate,
            participants: participants,
            talker: ChatReport.Talker(
                name: participants[0].name,
                messages: participants[0].messages,
                sharePercent: participants[0].sharePercent
            ),
            slowReplier: slowReplier(participants),
            nightOwl: nightOwl(ranked),
            topWords: Array(words),
            awards: awards
        )
    }

    /// Highest average reply delay among eligible people; ties go to the earlier participant.
    private static func slowReplier(_ participants: [ChatReport.Participant]) -> ChatReport.SlowReplier? {
        typealias Entry = (index: Int, person: ChatReport.Participant, average: Int)
        func pool(minimum: Int) -> [Entry] {
            participants.enumerated().compactMap { index, person in
                guard person.replyCount >= minimum, let average = person.avgReplyMinutes else { return nil }
                return (index, person, average)
            }
        }
        var eligible = pool(minimum: ReportRules.replyEligibleCount)
        if eligible.count < 2 { eligible = pool(minimum: ReportRules.replyMinCount) }
        guard var slowest = eligible.first else { return nil }
        for candidate in eligible.dropFirst() where candidate.average > slowest.average {
            slowest = candidate
        }
        var fastest: Entry?
        for candidate in eligible where candidate.index != slowest.index {
            if let current = fastest, candidate.average >= current.average { continue }
            fastest = candidate
        }
        return ChatReport.SlowReplier(
            name: slowest.person.name,
            avgReplyMinutes: slowest.average,
            slowReplies: slowest.person.slowReplies,
            fastestName: fastest?.person.name,
            fastestAvgReplyMinutes: fastest?.average
        )
    }

    /// Highest share of messages sent between 00:00 and 04:00.
    private static func nightOwl(_ ranked: [Tally]) -> ChatReport.NightOwl? {
        let eligible = ranked.filter { $0.messages >= ReportRules.nightEligibleMessages }
        let pool = eligible.isEmpty ? ranked : eligible
        guard var owl = pool.first else { return nil }
        for candidate in pool.dropFirst() where candidate.night * owl.messages > owl.night * candidate.messages {
            owl = candidate
        }
        guard owl.night > 0 else { return nil }
        let peak = owl.hours.max() ?? 0
        return ChatReport.NightOwl(
            name: owl.name,
            nightPercent: TextRules.roundDiv(owl.night * 100, owl.messages),
            peakHour: owl.hours.firstIndex(of: peak) ?? 0,
            hours: owl.hours
        )
    }

    private static func value(of kind: ChatReport.AwardKind, in person: ChatReport.Participant) -> Int {
        switch kind {
        case .planBreaker: return person.planBreaks
        case .ghost: return person.longestSilenceDays
        case .capsLock: return person.capsCount
        case .monologue: return person.longestMonologue
        case .drama: return person.dramaCount
        case .mediaSpammer: return person.mediaCount
        case .laugher: return person.laughCount
        }
    }
}
