import XCTest
@testable import Goruldu

final class ChatImporterTests: XCTestCase {
    func testUnzipsDeflatedExportAndTakesTitleFromArchiveName() throws {
        let result = try ChatImporter.unzip(Fixture.data("export-deflated", "zip"), archiveName: "WhatsApp Chat - Aile.zip")
        XCTAssertEqual(result.data, try Fixture.data("ios-tr", "txt"))
        XCTAssertEqual(result.title, "Aile")
    }

    func testStoredExportTakesTitleFromEntryName() throws {
        let result = try ChatImporter.unzip(Fixture.data("export-stored", "zip"), archiveName: "export.zip")
        XCTAssertEqual(result.title, "Aile")
    }

    func testFileImportMatchesFixtureReport() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("WhatsApp Chat - ios-tr.zip")
        try Fixture.data("export-deflated", "zip").write(to: file)

        let report = try ChatImporter.loadSync(.file(file), fallbackTitle: "Sohbet")
        XCTAssertEqual(report, try Fixture.expectedReport("ios-tr"))
    }

    func testSampleChatIsBundledAndMatchesFixture() throws {
        var expected = try Fixture.expectedReport("lise-tayfa")
        expected.title = ChatImporter.sampleTitle
        XCTAssertEqual(try ChatImporter.loadSync(.sample, fallbackTitle: "Sohbet"), expected)
    }

    func testFailuresAreMapped() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let notAChat = folder.appendingPathComponent("not-a-chat.txt")
        try Fixture.data("not-a-chat", "txt").write(to: notAChat)
        XCTAssertThrowsError(try ChatImporter.loadSync(.file(notAChat), fallbackTitle: "Sohbet")) { error in
            XCTAssertEqual(error as? ImportFailure, .unrecognized)
        }

        let tooShort = folder.appendingPathComponent("too-short.txt")
        try Fixture.data("too-short", "txt").write(to: tooShort)
        XCTAssertThrowsError(try ChatImporter.loadSync(.file(tooShort), fallbackTitle: "Sohbet")) { error in
            XCTAssertEqual(error as? ImportFailure, .tooShort)
        }

        let missing = folder.appendingPathComponent("yok.txt")
        XCTAssertThrowsError(try ChatImporter.loadSync(.file(missing), fallbackTitle: "Sohbet")) { error in
            XCTAssertEqual(error as? ImportFailure, .unreadable)
        }

        let brokenZip = folder.appendingPathComponent("bozuk.zip")
        try Data("zip değil".utf8).write(to: brokenZip)
        XCTAssertThrowsError(try ChatImporter.loadSync(.file(brokenZip), fallbackTitle: "Sohbet")) { error in
            XCTAssertEqual(error as? ImportFailure, .unreadable)
        }
    }
}
