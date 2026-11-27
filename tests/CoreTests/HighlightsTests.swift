import XCTest

#if canImport(GorulduCore)
@testable import GorulduCore
#else
@testable import Goruldu
#endif

final class HighlightsTests: XCTestCase {
    func testBusiestDayAndPairsComeFromMessages() throws {
        let highlights = try ChatHighlights.build(messages: ChatParser.parse(Fixture.text("lise-tayfa")))
        XCTAssertGreaterThan(highlights.busiestCount, 1)
        XCTAssertFalse(highlights.busiestDate.isEmpty)
        XCTAssertLessThanOrEqual(highlights.pairs.count, 3)
        XCTAssertEqual(highlights.pairs, highlights.pairs.sorted { $0.count > $1.count })
    }

    func testKeptLinesAreRealMessagesAndStayShort() throws {
        let highlights = try ChatHighlights.build(messages: ChatParser.parse(Fixture.text("lise-tayfa")))
        XCTAssertFalse(highlights.drama.isEmpty)
        for line in highlights.drama {
            XCTAssertTrue(line.text.contains("!") || line.text.contains("?"))
            XCTAssertLessThanOrEqual(line.text.count, ChatHighlights.quoteLimit)
        }
        XCTAssertLessThanOrEqual(highlights.drama.count, 3)
        XCTAssertFalse(highlights.moments.isEmpty)
        XCTAssertFalse(highlights.voices.isEmpty)
        let report = try Fixture.report("lise-tayfa")
        let fastest = PremiumFacts.fastest(report)
        XCTAssertGreaterThanOrEqual(fastest.count, 2)
        let minutes = fastest.compactMap(\.avgReplyMinutes)
        XCTAssertEqual(minutes, minutes.sorted())
    }

    func testReportBoardKeepsTheSamePeopleTheScreenShows() throws {
        let report = try Fixture.report("lise-tayfa")
        XCTAssertEqual(ReportBoard.talkers(report).map(\.name), report.participants.map(\.name))
        XCTAssertEqual(ReportBoard.fastest(report).count, report.participants.count)
        XCTAssertEqual(ReportBoard.night(report).count, report.participants.count)
        XCTAssertEqual(ReportBoard.extraWords(report).map(\.word), report.topWords.dropFirst().map(\.word))
        XCTAssertEqual(ReportBoard.awards(report, premium: false).count, report.awards.filter { !$0.premium }.count)
        XCTAssertEqual(ReportBoard.awards(report, premium: true).count, report.awards.count)

        var quiet = report
        quiet.participants = Array(report.participants.prefix(1))
        XCTAssertTrue(ReportBoard.fastest(quiet).isEmpty)
        XCTAssertTrue(ReportBoard.night(quiet).isEmpty)
    }

    func testTalkerIsTheMotorAndRankedFirst() throws {
        let report = try Fixture.report("lise-tayfa")
        XCTAssertEqual(PremiumFacts.role(of: report.talker.name, in: report), .motor)
        XCTAssertEqual(PremiumFacts.rank(of: report.talker.name, in: report), 1)
        XCTAssertEqual(PremiumFacts.person(named: report.talker.name, in: report)?.name, report.talker.name)
    }
}
