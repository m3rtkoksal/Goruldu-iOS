import Foundation

/// Asks the API for one roast line per person. Only names and numbers leave the phone.
struct RoastService: Sendable {
    enum Failure: Error, Equatable, Sendable {
        /// The build has no API address configured.
        case notConfigured
        case offline
        case rejected
        case badResponse
    }

    static let maxParticipants = 12
    static let maxNameLength = 40
    static let maxTitleLength = 80
    static let maxWords = 10

    var config: AppConfig = .current
    var session: URLSession = .shared

    func roasts(for report: ChatReport, locale: String) async throws -> [Roast] {
        guard let base = config.apiBaseURL else { throw Failure.notConfigured }
        let people = Array(report.participants.prefix(Self.maxParticipants))
        var request = URLRequest(url: base.appendingPathComponent("v1/roasts"))
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = config.appKey { request.setValue(key, forHTTPHeaderField: "x-app-key") }
        request.httpBody = try JSONEncoder().encode(Self.body(report: report, people: people, locale: locale))

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
        let data = result.data
        let response = result.response
        guard let http = response as? HTTPURLResponse else { throw Failure.badResponse }
        guard (200..<300).contains(http.statusCode) else { throw Failure.rejected }
        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
              decoded.roasts.count == people.count,
              decoded.roasts.allSatisfy({ !$0.line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw Failure.badResponse }
        // The API answers in request order; our own names are kept so a shortened name cannot leak back.
        return zip(people, decoded.roasts).map { Roast(name: $0.name, line: $1.line) }
    }

    static func body(report: ChatReport, people: [ChatReport.Participant], locale: String) -> RequestBody {
        RequestBody(
            locale: locale,
            chat: RequestBody.Chat(
                title: String(report.title.prefix(maxTitleLength)),
                participantCount: report.participantCount,
                totalMessages: report.totalMessages,
                activeDays: report.activeDays,
                topWords: report.topWords.prefix(maxWords).map { RequestBody.Word(word: $0.word, count: $0.count) }
            ),
            participants: people.map { person in
                RequestBody.Person(
                    name: String(person.name.prefix(maxNameLength)),
                    messages: person.messages,
                    sharePercent: person.sharePercent,
                    avgReplyMinutes: person.avgReplyMinutes,
                    nightPercent: person.nightPercent,
                    capsCount: person.capsCount,
                    mediaCount: person.mediaCount,
                    longestSilenceDays: person.longestSilenceDays,
                    longestMonologue: person.longestMonologue,
                    planBreaks: person.planBreaks,
                    dramaCount: person.dramaCount,
                    laughCount: person.laughCount
                )
            }
        )
    }

    struct RequestBody: Encodable, Equatable {
        var locale: String
        var chat: Chat
        var participants: [Person]

        struct Chat: Encodable, Equatable {
            var title: String
            var participantCount: Int
            var totalMessages: Int
            var activeDays: Int
            var topWords: [Word]
        }

        struct Word: Encodable, Equatable {
            var word: String
            var count: Int
        }

        struct Person: Encodable, Equatable {
            var name: String
            var messages: Int
            var sharePercent: Int
            var avgReplyMinutes: Int?
            var nightPercent: Int
            var capsCount: Int
            var mediaCount: Int
            var longestSilenceDays: Int
            var longestMonologue: Int
            var planBreaks: Int
            var dramaCount: Int
            var laughCount: Int

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(name, forKey: .name)
                try container.encode(messages, forKey: .messages)
                try container.encode(sharePercent, forKey: .sharePercent)
                // The contract wants an explicit null rather than a missing key.
                try container.encode(avgReplyMinutes, forKey: .avgReplyMinutes)
                try container.encode(nightPercent, forKey: .nightPercent)
                try container.encode(capsCount, forKey: .capsCount)
                try container.encode(mediaCount, forKey: .mediaCount)
                try container.encode(longestSilenceDays, forKey: .longestSilenceDays)
                try container.encode(longestMonologue, forKey: .longestMonologue)
                try container.encode(planBreaks, forKey: .planBreaks)
                try container.encode(dramaCount, forKey: .dramaCount)
                try container.encode(laughCount, forKey: .laughCount)
            }

            enum CodingKeys: String, CodingKey {
                case name, messages, sharePercent, avgReplyMinutes, nightPercent, capsCount, mediaCount
                case longestSilenceDays, longestMonologue, planBreaks, dramaCount, laughCount
            }
        }
    }

    private struct ResponseBody: Decodable {
        var roasts: [Line]

        struct Line: Decodable {
            var name: String
            var line: String
        }
    }
}
