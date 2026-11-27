import Foundation

/// One roast line for one participant, as returned by the API.
struct Roast: Codable, Equatable, Identifiable, Sendable {
    var name: String
    var line: String

    var id: String { name }
}

/// What is kept on the phone for a chat: the computed report and the roast, never the messages.
struct SavedReport: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var createdAt: Date
    var report: ChatReport
    var roasts: [Roast]?
    /// Bumped when the roast wording changes, so an older saved line is fetched again.
    var roastEdition: Int?
    /// The participant the phone owner picked. Nil on reports saved before that question existed.
    var viewerName: String?
    var highlights: ChatHighlights?
    /// Paid-card copy. Nil until the subscription asks for it.
    var reading: ChatReading?
    var readingEdition: Int?
    /// Language the saved roast lines were written in. Nil on reports saved before the setting existed.
    var roastLocale: String?
    var readingLocale: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        report: ChatReport,
        roasts: [Roast]? = nil,
        roastEdition: Int? = nil,
        viewerName: String? = nil,
        highlights: ChatHighlights? = nil,
        reading: ChatReading? = nil,
        readingEdition: Int? = nil,
        roastLocale: String? = nil,
        readingLocale: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.report = report
        self.roasts = roasts
        self.roastEdition = roastEdition
        self.viewerName = viewerName
        self.highlights = highlights
        self.reading = reading
        self.readingEdition = readingEdition
        self.roastLocale = roastLocale
        self.readingLocale = readingLocale
    }

    /// Older files have no language fields. A missing key stays nil and the lines are fetched again.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        report = try container.decode(ChatReport.self, forKey: .report)
        roasts = try container.decodeIfPresent([Roast].self, forKey: .roasts)
        roastEdition = try container.decodeIfPresent(Int.self, forKey: .roastEdition)
        viewerName = try container.decodeIfPresent(String.self, forKey: .viewerName)
        highlights = try container.decodeIfPresent(ChatHighlights.self, forKey: .highlights)
        reading = try container.decodeIfPresent(ChatReading.self, forKey: .reading)
        readingEdition = try container.decodeIfPresent(Int.self, forKey: .readingEdition)
        roastLocale = try container.decodeIfPresent(String.self, forKey: .roastLocale)
        readingLocale = try container.decodeIfPresent(String.self, forKey: .readingLocale)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(report, forKey: .report)
        try container.encodeIfPresent(roasts, forKey: .roasts)
        try container.encodeIfPresent(roastEdition, forKey: .roastEdition)
        try container.encodeIfPresent(viewerName, forKey: .viewerName)
        try container.encodeIfPresent(highlights, forKey: .highlights)
        try container.encodeIfPresent(reading, forKey: .reading)
        try container.encodeIfPresent(readingEdition, forKey: .readingEdition)
        try container.encodeIfPresent(roastLocale, forKey: .roastLocale)
        try container.encodeIfPresent(readingLocale, forKey: .readingLocale)
    }

    private enum CodingKeys: String, CodingKey {
        case id, createdAt, report, roasts, roastEdition, viewerName, highlights, reading, readingEdition
        case roastLocale, readingLocale
    }

    /// Who the paid "your role" card is about.
    func viewer() -> String { viewerName ?? report.talker.name }
}
