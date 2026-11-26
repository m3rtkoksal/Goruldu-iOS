import Foundation

/// The paid-card copy. Only the already chosen lines leave the phone, with links and numbers removed.
struct ChatReading: Codable, Equatable, Sendable {
    struct Role: Codable, Equatable, Sendable {
        var name: String
        var title: String
        var line: String
    }

    struct Caption: Codable, Equatable, Sendable {
        var id: String
        var line: String
    }

    var source: String
    var vibeTitle: String
    var vibeLine: String
    var roles: [Role]
    var captions: [Caption]

    func role(named name: String) -> Role? {
        roles.first { $0.name == name }
    }

    func caption(_ id: String) -> String? {
        let line = captions.first { $0.id == id }?.line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let line, !line.isEmpty else { return nil }
        return line
    }
}

struct ReadingService: Sendable {
    enum Failure: Error, Equatable, Sendable {
        case notConfigured
        case offline
        case rejected
        case badResponse
    }

    static let edition = 1
    static let maxLines = 16
    static let maxText = 160

    var config: AppConfig = .current
    var session: URLSession = .shared

    func reading(for saved: SavedReport, locale: String) async throws -> ChatReading {
        guard let base = config.apiBaseURL else { throw Failure.notConfigured }
        let people = Array(saved.report.participants.prefix(RoastService.maxParticipants))
        let lines = Self.lines(from: saved.highlights)
        var request = URLRequest(url: base.appendingPathComponent("v1/reading"))
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = config.appKey { request.setValue(key, forHTTPHeaderField: "x-app-key") }
        request.httpBody = try JSONEncoder().encode(
            Body(
                locale: locale,
                viewer: String(saved.viewer().prefix(RoastService.maxNameLength)),
                chat: Body.Chat(
                    title: String(saved.report.title.prefix(RoastService.maxTitleLength)),
                    participantCount: saved.report.participantCount,
                    totalMessages: saved.report.totalMessages,
                    activeDays: saved.report.activeDays
                ),
                participants: people.map { person in
                    Body.Person(
                        name: String(person.name.prefix(RoastService.maxNameLength)),
                        messages: person.messages,
                        sharePercent: person.sharePercent,
                        avgReplyMinutes: person.avgReplyMinutes,
                        nightPercent: person.nightPercent
                    )
                },
                lines: lines
            )
        )

        let result: (data: Data, response: URLResponse)
        do {
            result = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw Failure.offline
        }
        guard let http = result.response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw Failure.rejected
        }
        guard let decoded = try? JSONDecoder().decode(ChatReading.self, from: result.data),
              decoded.roles.count == people.count,
              decoded.captions.count == lines.count,
              !decoded.vibeTitle.isEmpty
        else { throw Failure.badResponse }
        return ChatReading(
            source: decoded.source,
            vibeTitle: decoded.vibeTitle,
            vibeLine: decoded.vibeLine,
            roles: zip(people, decoded.roles).map { ChatReading.Role(name: $0.name, title: $1.title, line: $1.line) },
            captions: zip(lines, decoded.captions).map { ChatReading.Caption(id: $0.id, line: $1.line) }
        )
    }

    static func lines(from highlights: ChatHighlights?) -> [Body.Line] {
        guard let highlights else { return [] }
        var lines: [Body.Line] = []
        for (index, line) in highlights.drama.enumerated() {
            lines.append(make("d\(index)", kind: "drama", line: line))
        }
        for (index, line) in highlights.moments.enumerated() {
            lines.append(make("m\(index)", kind: "moment", line: line))
        }
        for (index, voice) in highlights.voices.enumerated() {
            guard let line = voice.line else { continue }
            lines.append(make("v\(index)", kind: "voice", line: line))
        }
        for (index, pair) in highlights.pairs.enumerated() {
            guard let line = pair.line else { continue }
            lines.append(make("c\(index)", kind: "clique", line: line))
        }
        return Array(lines.prefix(maxLines))
    }

    static func dramaID(_ index: Int) -> String { "d\(index)" }
    static func momentID(_ index: Int) -> String { "m\(index)" }
    static func cliqueID(_ index: Int) -> String { "c\(index)" }

    private static func make(_ id: String, kind: String, line: ChatHighlights.Line) -> Body.Line {
        let text = redact(line.text)
        return Body.Line(
            id: id,
            kind: kind,
            name: String(line.name.prefix(RoastService.maxNameLength)),
            replyTo: line.replyTo.map { String($0.prefix(RoastService.maxNameLength)) },
            text: text.isEmpty ? "…" : String(text.prefix(maxText))
        )
    }

    /// Same cuts the server applies, so a number never leaves the phone.
    static func redact(_ text: String) -> String {
        var cleaned = text
        if let links = try? NSRegularExpression(pattern: "(?i)https?://\\S+|\\bwww\\.\\S+") {
            cleaned = links.stringByReplacingMatches(
                in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: ""
            )
        }
        if let emails = try? NSRegularExpression(pattern: "[A-Za-z0-9._+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}") {
            cleaned = emails.stringByReplacingMatches(
                in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: ""
            )
        }
        guard let phones = try? NSRegularExpression(pattern: "\\+?\\d[\\d\\s().-]{8,}\\d") else {
            return cleaned.split { $0.isWhitespace }.joined(separator: " ")
        }
        let matches = phones.matches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)).reversed()
        for match in matches {
            guard let range = Range(match.range, in: cleaned) else { continue }
            let piece = String(cleaned[range])
            let digits = piece.filter(\.isNumber)
            if digits.count < 10 { continue }
            if piece.range(of: #"^\d{1,2}[./-]\d{1,2}[./-]\d{2,4}$"#, options: .regularExpression) != nil { continue }
            cleaned.replaceSubrange(range, with: "")
        }
        return cleaned.split { $0.isWhitespace }.joined(separator: " ")
    }

    struct Body: Encodable {
        var locale: String
        var viewer: String
        var chat: Chat
        var participants: [Person]
        var lines: [Line]

        struct Chat: Encodable {
            var title: String
            var participantCount: Int
            var totalMessages: Int
            var activeDays: Int
        }

        struct Person: Encodable {
            var name: String
            var messages: Int
            var sharePercent: Int
            var avgReplyMinutes: Int?
            var nightPercent: Int

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(name, forKey: .name)
                try container.encode(messages, forKey: .messages)
                try container.encode(sharePercent, forKey: .sharePercent)
                try container.encode(avgReplyMinutes, forKey: .avgReplyMinutes)
                try container.encode(nightPercent, forKey: .nightPercent)
            }

            enum CodingKeys: String, CodingKey {
                case name, messages, sharePercent, avgReplyMinutes, nightPercent
            }
        }

        struct Line: Encodable {
            var id: String
            var kind: String
            var name: String
            var replyTo: String?
            var text: String
        }
    }
}
