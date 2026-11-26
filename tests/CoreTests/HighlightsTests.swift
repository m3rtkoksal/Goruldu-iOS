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

    func testTalkerIsTheMotorAndRankedFirst() throws {
        let report = try Fixture.report("lise-tayfa")
        XCTAssertEqual(PremiumFacts.role(of: report.talker.name, in: report), .motor)
        XCTAssertEqual(PremiumFacts.rank(of: report.talker.name, in: report), 1)
        XCTAssertEqual(PremiumFacts.person(named: report.talker.name, in: report)?.name, report.talker.name)
    }
}
