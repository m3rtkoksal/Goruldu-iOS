import Foundation

/// Entry point of the report rules: export text in, report out.
enum ReportEngine {
    /// - Parameters:
    ///   - text: Contents of the exported `.txt` file.
    ///   - title: Chat name shown on the cover.
    /// - Throws: `ReportError.unrecognized` or `ReportError.tooShort`.
    static func report(text: String, title: String) throws -> ChatReport {
        try ReportBuilder.build(messages: ChatParser.parse(text), title: title)
    }

    /// The report plus the paid-card counts. The message text is not returned.
    static func imported(text: String, title: String) throws -> (ChatReport, ChatHighlights) {
        let messages = try ChatParser.parse(text)
        return (try ReportBuilder.build(messages: messages, title: title), ChatHighlights.build(messages: messages))
    }

    /// Decodes export bytes. WhatsApp writes UTF-8; invalid bytes are replaced rather than rejected.
    static func decode(_ data: Data) -> String {
        String(decoding: data, as: UTF8.self)
    }
}
