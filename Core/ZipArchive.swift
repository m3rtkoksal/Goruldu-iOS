import Foundation

/// Minimal reader for the zip files WhatsApp produces: finds entries and returns their bytes.
/// Zip64, encryption and multi-disk archives are not supported and are reported as errors.
struct ZipArchive {
    enum Failure: Error, Equatable {
        case notAZip
        case unsupported
        case corrupt
    }

    struct Entry: Equatable {
        var name: String
        var method: UInt16
        var compressedSize: Int
        var uncompressedSize: Int
        var localHeaderOffset: Int
        var encrypted: Bool
    }

    /// Inflates a raw DEFLATE stream to exactly `size` bytes, or returns nil.
    typealias Inflate = (_ compressed: Data, _ size: Int) -> Data?

    let entries: [Entry]
    private let data: Data

    init(data: Data) throws {
        self.data = data
        let bytes = ByteReader(data: data)
        guard data.count >= 22, bytes.uint32(at: 0) == 0x0403_4B50 || bytes.uint32(at: 0) == 0x0605_4B50 else {
            throw Failure.notAZip
        }
        let lowest = max(0, data.count - 22 - 0xFFFF)
        var position = data.count - 22
        var endOfDirectory: Int?
        while position >= lowest {
            if bytes.uint32(at: position) == 0x0605_4B50 {
                endOfDirectory = position
                break
            }
            position -= 1
        }
        guard let end = endOfDirectory,
              let count = bytes.uint16(at: end + 10),
              let directorySize = bytes.uint32(at: end + 12),
              let directoryOffset = bytes.uint32(at: end + 16)
        else { throw Failure.corrupt }
        if count == 0xFFFF || directoryOffset == 0xFFFF_FFFF || directorySize == 0xFFFF_FFFF { throw Failure.unsupported }

        var entries: [Entry] = []
        var cursor = Int(directoryOffset)
        for _ in 0..<Int(count) {
            guard bytes.uint32(at: cursor) == 0x0201_4B50,
                  let flags = bytes.uint16(at: cursor + 8),
                  let method = bytes.uint16(at: cursor + 10),
                  let compressedSize = bytes.uint32(at: cursor + 20),
                  let uncompressedSize = bytes.uint32(at: cursor + 24),
                  let nameLength = bytes.uint16(at: cursor + 28),
                  let extraLength = bytes.uint16(at: cursor + 30),
                  let commentLength = bytes.uint16(at: cursor + 32),
                  let localOffset = bytes.uint32(at: cursor + 42),
                  let nameBytes = bytes.slice(at: cursor + 46, count: Int(nameLength))
            else { throw Failure.corrupt }
            if compressedSize == 0xFFFF_FFFF || uncompressedSize == 0xFFFF_FFFF || localOffset == 0xFFFF_FFFF {
                throw Failure.unsupported
            }
            entries.append(Entry(
                name: String(decoding: nameBytes, as: UTF8.self),
                method: method,
                compressedSize: Int(compressedSize),
                uncompressedSize: Int(uncompressedSize),
                localHeaderOffset: Int(localOffset),
                encrypted: flags & 1 == 1
            ))
            cursor += 46 + Int(nameLength) + Int(extraLength) + Int(commentLength)
        }
        self.entries = entries
    }

    func contents(of entry: Entry, inflate: Inflate) throws -> Data {
        if entry.encrypted { throw Failure.unsupported }
        let bytes = ByteReader(data: data)
        guard bytes.uint32(at: entry.localHeaderOffset) == 0x0403_4B50,
              let nameLength = bytes.uint16(at: entry.localHeaderOffset + 26),
              let extraLength = bytes.uint16(at: entry.localHeaderOffset + 28),
              let payload = bytes.slice(
                  at: entry.localHeaderOffset + 30 + Int(nameLength) + Int(extraLength),
                  count: entry.compressedSize
              )
        else { throw Failure.corrupt }
        switch entry.method {
        case 0:
            guard entry.compressedSize == entry.uncompressedSize else { throw Failure.corrupt }
            return Data(payload)
        case 8:
            if entry.uncompressedSize == 0 { return Data() }
            guard let inflated = inflate(Data(payload), entry.uncompressedSize), inflated.count == entry.uncompressedSize else {
                throw Failure.corrupt
            }
            return inflated
        default:
            throw Failure.unsupported
        }
    }

    /// The chat text inside an export: `_chat.txt` when present, otherwise the first `.txt` file.
    var chatEntry: Entry? {
        let candidates = entries.filter { entry in
            let lowered = entry.name.lowercased()
            return lowered.hasSuffix(".txt") && !lowered.hasPrefix("__macosx/") && !lowered.hasSuffix("/")
        }
        return candidates.first { Self.baseName($0.name).lowercased() == "_chat.txt" } ?? candidates.first
    }

    static func baseName(_ path: String) -> String {
        path.split(separator: "/").last.map(String.init) ?? path
    }
}

private struct ByteReader {
    let data: Data

    func slice(at offset: Int, count: Int) -> Data? {
        guard offset >= 0, count >= 0, offset <= data.count - count else { return nil }
        let start = data.startIndex + offset
        return data[start..<(start + count)]
    }

    func uint16(at offset: Int) -> UInt16? {
        guard let bytes = slice(at: offset, count: 2) else { return nil }
        var value: UInt16 = 0
        for (index, byte) in bytes.enumerated() { value |= UInt16(byte) << (8 * UInt16(index)) }
        return value
    }

    func uint32(at offset: Int) -> UInt32? {
        guard let bytes = slice(at: offset, count: 4) else { return nil }
        var value: UInt32 = 0
        for (index, byte) in bytes.enumerated() { value |= UInt32(byte) << (8 * UInt32(index)) }
        return value
    }
}
