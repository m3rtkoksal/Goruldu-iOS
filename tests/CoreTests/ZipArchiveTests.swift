import XCTest

#if canImport(GorulduCore)
@testable import GorulduCore
#else
@testable import Goruldu
#endif

final class ZipArchiveTests: XCTestCase {
    func testReadsStoredEntry() throws {
        let archive = try ZipArchive(data: Fixture.data("export-stored", "zip"))
        let entry = try XCTUnwrap(archive.chatEntry)
        XCTAssertEqual(entry.name, "WhatsApp Chat with Aile.txt")
        XCTAssertEqual(entry.method, 0)
        let contents = try archive.contents(of: entry) { _, _ in nil }
        XCTAssertEqual(contents, try Fixture.data("ios-tr", "txt"))
    }

    func testPrefersChatFileAndSkipsResourceForks() throws {
        let archive = try ZipArchive(data: Fixture.data("export-deflated", "zip"))
        XCTAssertEqual(archive.entries.map(\.name), ["__MACOSX/._chat.txt", "notlar.txt", "_chat.txt"])
        let entry = try XCTUnwrap(archive.chatEntry)
        XCTAssertEqual(entry.name, "_chat.txt")
        XCTAssertEqual(entry.method, 8)
        XCTAssertEqual(entry.uncompressedSize, try Fixture.data("ios-tr", "txt").count)
    }

    func testFailedInflateIsReportedAsCorrupt() throws {
        let archive = try ZipArchive(data: Fixture.data("export-deflated", "zip"))
        let entry = try XCTUnwrap(archive.chatEntry)
        XCTAssertThrowsError(try archive.contents(of: entry) { _, _ in nil }) { error in
            XCTAssertEqual(error as? ZipArchive.Failure, .corrupt)
        }
    }

    func testRejectsOtherFiles() throws {
        XCTAssertThrowsError(try ZipArchive(data: Fixture.data("ios-tr", "txt"))) { error in
            XCTAssertEqual(error as? ZipArchive.Failure, .notAZip)
        }
        XCTAssertThrowsError(try ZipArchive(data: Data([0x50, 0x4B, 0x03, 0x04] + [UInt8](repeating: 0, count: 40)))) { error in
            XCTAssertEqual(error as? ZipArchive.Failure, .corrupt)
        }
    }
}
