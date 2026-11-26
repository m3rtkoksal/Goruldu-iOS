import Foundation

/// The computed report. Field names match `fixtures/*.expected.json` and the Android model.
struct ChatReport: Codable, Equatable, Sendable {
    var title: String
    var turkish: Bool
    var totalMessages: Int
    var participantCount: Int
    var activeDays: Int
    var firstDate: String
    var lastDate: String
    var participants: [Participant]
    var talker: Talker
    var slowReplier: SlowReplier?
    var nightOwl: NightOwl?
    var topWords: [WordCount]
    var awards: [Award]

    struct Participant: Codable, Equatable, Sendable {
        var name: String
        var messages: Int
        var sharePercent: Int
        var avgReplyMinutes: Int?
        var replyCount: Int
        var slowReplies: Int
        var nightPercent: Int
        var capsCount: Int
        var mediaCount: Int
        var longestSilenceDays: Int
        var longestMonologue: Int
        var planBreaks: Int
        var dramaCount: Int
        var laughCount: Int
    }

    struct Talker: Codable, Equatable, Sendable {
        var name: String
        var messages: Int
        var sharePercent: Int
    }

    struct SlowReplier: Codable, Equatable, Sendable {
        var name: String
        var avgReplyMinutes: Int
        var slowReplies: Int
        var fastestName: String?
        var fastestAvgReplyMinutes: Int?
    }

    struct NightOwl: Codable, Equatable, Sendable {
        var name: String
        var nightPercent: Int
        var peakHour: Int
        var hours: [Int]
    }

    struct WordCount: Codable, Equatable, Sendable {
        var word: String
        var count: Int
    }

    struct Award: Codable, Equatable, Sendable, Identifiable {
        var id: AwardKind
        var name: String
        var value: Int
        var premium: Bool
    }

    enum AwardKind: String, Codable, Sendable, CaseIterable {
        case planBreaker, ghost, capsLock, monologue, drama, mediaSpammer, laugher
    }

    /// Year shown on the cover: the year of the last message.
    var year: String { String(lastDate.prefix(4)) }
}

enum ReportError: String, Error, Equatable, Sendable {
    /// The file does not look like a WhatsApp export.
    case unrecognized
    /// Fewer than 20 messages, or a single sender.
    case tooShort
}

struct ChatMessage: Equatable, Sendable {
    enum Kind: Sendable { case text, media, deleted }

    var sender: String
    var time: ChatTime
    var kind: Kind
    var text: String
}

/// A wall-clock timestamp without a time zone, as written in the export.
struct ChatTime: Equatable, Comparable, Sendable {
    var year: Int
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int
    var second: Int

    init?(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) {
        guard (1...9999).contains(year), (1...12).contains(month),
              (0...23).contains(hour), (0...59).contains(minute), (0...59).contains(second),
              day >= 1, day <= ChatTime.daysInMonth(year: year, month: month)
        else { return nil }
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    /// Days since 1970-01-01 in the proleptic Gregorian calendar.
    var dayNumber: Int {
        let shiftedYear = month <= 2 ? year - 1 : year
        let era = (shiftedYear >= 0 ? shiftedYear : shiftedYear - 399) / 400
        let yearOfEra = shiftedYear - era * 400
        let shiftedMonth = month > 2 ? month - 3 : month + 9
        let dayOfYear = (153 * shiftedMonth + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097 + dayOfEra - 719_468
    }

    var totalSeconds: Int { dayNumber * 86_400 + hour * 3_600 + minute * 60 + second }

    var isoDate: String {
        let paddedYear = String(repeating: "0", count: max(0, 4 - String(year).count)) + String(year)
        return "\(paddedYear)-\(month < 10 ? "0" : "")\(month)-\(day < 10 ? "0" : "")\(day)"
    }

    static func < (lhs: ChatTime, rhs: ChatTime) -> Bool { lhs.totalSeconds < rhs.totalSeconds }

    static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 4, 6, 9, 11: return 30
        case 2: return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 ? 29 : 28
        default: return 31
        }
    }
}
