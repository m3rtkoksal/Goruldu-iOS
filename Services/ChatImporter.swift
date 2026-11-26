import Compression
import Foundation

/// Where a chat comes from.
enum ImportRequest: Hashable, Sendable {
    /// A `.txt` or `.zip` picked by the user or handed over by WhatsApp's export sheet.
    case file(URL)
    /// The synthetic chat bundled with the app.
    case sample

    var fileName: String? {
        if case .file(let url) = self { return url.lastPathComponent }
        return nil
    }
}

enum ImportFailure: Error, Equatable, Sendable {
    case unrecognized
    case tooShort
    case unreadable
    case tooLarge
}

/// Reads an export and computes the report. The text only lives in memory for the duration of
/// the call; nothing but the returned report is kept.
enum ChatImporter {
    static let maxTextBytes = 50 * 1_024 * 1_024
    static let maxArchiveBytes = 400 * 1_024 * 1_024
    static let sampleTitle = "Lise Tayfa"

    static func load(_ request: ImportRequest, fallbackTitle: String) async throws -> ChatReport {
        try await Task.detached(priority: .userInitiated) {
            try loadSync(request, fallbackTitle: fallbackTitle)
        }.value
    }

    static func loadSync(_ request: ImportRequest, fallbackTitle: String) throws -> ChatReport {
        let source: (data: Data, title: String)
        switch request {
        case .sample:
            guard let url = Bundle.main.url(forResource: "lise-tayfa", withExtension: "txt"),
                  let data = try? Data(contentsOf: url)
            else { throw ImportFailure.unreadable }
            source = (data, sampleTitle)
        case .file(let url):
            source = try read(url)
        }
        let title = source.title.isEmpty ? fallbackTitle : source.title
        do {
            return try ReportEngine.report(text: ReportEngine.decode(source.data), title: title)
        } catch ReportError.unrecognized {
            throw ImportFailure.unrecognized
        } catch ReportError.tooShort {
            throw ImportFailure.tooShort
        }
    }

    /// Returns the chat text bytes and the chat title derived from file names.
    static func read(_ url: URL) throws -> (data: Data, title: String) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped { url.stopAccessingSecurityScopedResource() }
            removeIfInbox(url)
        }
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        let isZip = url.pathExtension.lowercased() == "zip"
        if size > (isZip ? maxArchiveBytes : maxTextBytes) { throw ImportFailure.tooLarge }
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe), !data.isEmpty else {
            throw ImportFailure.unreadable
        }
        guard isZip || data.starts(with: [0x50, 0x4B, 0x03, 0x04]) else {
            return (data, ChatTitle.from(fileName: url.lastPathComponent))
        }
        return try unzip(data, archiveName: url.lastPathComponent)
    }

    static func unzip(_ data: Data, archiveName: String) throws -> (data: Data, title: String) {
        let archive: ZipArchive
        do {
            archive = try ZipArchive(data: data)
        } catch {
            throw ImportFailure.unreadable
        }
        guard let entry = archive.chatEntry else { throw ImportFailure.unrecognized }
        if entry.uncompressedSize > maxTextBytes { throw ImportFailure.tooLarge }
        guard let text = try? archive.contents(of: entry, inflate: inflate) else { throw ImportFailure.unreadable }
        let entryTitle = ChatTitle.from(fileName: ZipArchive.baseName(entry.name))
        return (text, entryTitle.isEmpty ? ChatTitle.from(fileName: archiveName) : entryTitle)
    }

    /// Raw DEFLATE through the system Compression framework.
    static func inflate(_ compressed: Data, size: Int) -> Data? {
        guard size > 0, !compressed.isEmpty else { return nil }
        var output = Data(count: size)
        let written = output.withUnsafeMutableBytes { (destination: UnsafeMutableRawBufferPointer) -> Int in
            compressed.withUnsafeBytes { (source: UnsafeRawBufferPointer) -> Int in
                guard let destinationBase = destination.bindMemory(to: UInt8.self).baseAddress,
                      let sourceBase = source.bindMemory(to: UInt8.self).baseAddress
                else { return 0 }
                return compression_decode_buffer(destinationBase, size, sourceBase, compressed.count, nil, COMPRESSION_ZLIB)
            }
        }
        return written == size ? output : nil
    }

    /// Files handed over by another app are copied into our Inbox; they hold message texts,
    /// so they are removed as soon as they have been read.
    private static func removeIfInbox(_ url: URL) {
        let path = url.resolvingSymlinksInPath().path
        let home = URL(fileURLWithPath: NSHomeDirectory()).resolvingSymlinksInPath().path
        guard path.hasPrefix(home + "/"), path.contains("/Inbox/") || path.contains("/tmp/") else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
