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

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        report: ChatReport,
        roasts: [Roast]? = nil,
        roastEdition: Int? = nil,
        viewerName: String? = nil,
        highlights: ChatHighlights? = nil,
        reading: ChatReading? = nil,
        readingEdition: Int? = nil
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
    }

    /// Who the paid "your role" card is about.
    func viewer() -> String { viewerName ?? report.talker.name }
}
