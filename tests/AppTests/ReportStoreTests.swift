import XCTest
@testable import Goruldu

@MainActor
final class ReportStoreTests: XCTestCase {
    private var folder: URL = FileManager.default.temporaryDirectory

    override func setUp() async throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: folder)
    }

    func testSavedReportsSurviveReload() throws {
        let store = ReportStore(directory: folder)
        XCTAssertTrue(store.reports.isEmpty)

        var saved = SavedReport(report: try Fixture.report("lise-tayfa"))
        try store.save(saved)
        saved.roasts = [Roast(name: "Burak", line: "Çok yazıyor.")]
        try store.save(saved)

        let reloaded = ReportStore(directory: folder)
        XCTAssertEqual(reloaded.reports.count, 1)
        XCTAssertEqual(reloaded.reports.first?.report, saved.report)
        XCTAssertEqual(reloaded.reports.first?.roasts, saved.roasts)
        XCTAssertEqual(reloaded.unreadableCount, 0)
    }

    func testNewestReportComesFirstAndDeleteRemovesTheFile() throws {
        let store = ReportStore(directory: folder)
        let report = try Fixture.report("ios-tr")
        let older = SavedReport(createdAt: Date(timeIntervalSince1970: 1_000), report: report)
        let newer = SavedReport(createdAt: Date(timeIntervalSince1970: 2_000), report: report)
        try store.save(older)
        try store.save(newer)

        XCTAssertEqual(ReportStore(directory: folder).reports.map(\.id), [newer.id, older.id])
        try store.delete(id: newer.id)
        XCTAssertEqual(ReportStore(directory: folder).reports.map(\.id), [older.id])
        try store.deleteAll()
        XCTAssertTrue(ReportStore(directory: folder).reports.isEmpty)
    }

    func testDamagedFilesAreCountedNotHidden() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("{".utf8).write(to: folder.appendingPathComponent("bozuk.json"))
        let store = ReportStore(directory: folder)
        XCTAssertTrue(store.reports.isEmpty)
        XCTAssertEqual(store.unreadableCount, 1)
    }

    func testSavedFileHoldsNoMessageText() throws {
        let store = ReportStore(directory: folder)
        try store.save(SavedReport(report: try Fixture.report("ios-tr")))
        let file = try XCTUnwrap(try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).first)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        XCTAssertEqual(Set(json.keys), ["id", "createdAt", "report"])
        let report = try XCTUnwrap(json["report"] as? [String: Any])
        XCTAssertNil(report["messages"])
    }
}
