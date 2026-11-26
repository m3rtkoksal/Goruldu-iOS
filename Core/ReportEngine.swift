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

    /// Decodes export bytes. WhatsApp writes UTF-8; invalid bytes are replaced rather than rejected.
    static func decode(_ data: Data) -> String {
        String(decoding: data, as: UTF8.self)
    }
}
