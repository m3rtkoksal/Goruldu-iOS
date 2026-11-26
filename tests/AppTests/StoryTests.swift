import XCTest
@testable import Goruldu

final class StoryTests: XCTestCase {
    func testFullReportShowsEveryCard() throws {
        let report = try Fixture.report("lise-tayfa")
        XCTAssertEqual(
            StoryCard.cards(for: report),
            [.cover, .talker, .slowReplier, .nightOwl, .words, .ceremony, .roast, .premiumGate]
        )
        XCTAssertTrue(StoryCard.cards(for: report, premium: true).contains(.role))
        XCTAssertEqual(StoryCard.cards(for: report, premium: true).last, .cliques)
    }

    func testCardsWithoutDataAreLeftOut() throws {
        var report = try Fixture.report("lise-tayfa")
        report.slowReplier = nil
        report.nightOwl = nil
        report.topWords = []
        report.awards = []
        XCTAssertEqual(StoryCard.cards(for: report), [.cover, .talker, .roast, .premiumGate])
    }

    func testAwardNumbersFollowShownCards() {
        let all = StoryCard.allCases
        XCTAssertEqual(StoryCard.awardNumber(of: .talker, in: all), "01")
        XCTAssertEqual(StoryCard.awardNumber(of: .nightOwl, in: all), "03")
        XCTAssertEqual(StoryCard.awardNumber(of: .nightOwl, in: [.cover, .talker, .nightOwl, .roast]), "02")
    }

    func testShareCardHidesNames() throws {
        let report = try Fixture.report("lise-tayfa")
        let open = ShareContent.make(card: .talker, report: report, roasts: [], hideNames: false)
        let hidden = ShareContent.make(card: .talker, report: report, roasts: [], hideNames: true)
        XCTAssertEqual(open.name, "Burak")
        XCTAssertEqual(hidden.name, "B.")

        let roasts = [Roast(name: "Burak", line: "Burak yazar, Deniz okumaz.")]
        let roast = ShareContent.make(card: .roast, report: report, roasts: roasts, hideNames: true)
        XCTAssertEqual(roast.name, "B.")
        XCTAssertEqual(roast.note, "B. yazar, D. okumaz.")
    }

    func testOnlyTheLastCardSharesTheWholeSet() throws {
        let report = try Fixture.report("lise-tayfa")
        let cards = StoryCard.cards(for: report)
        let roasts = [Roast(name: "Burak", line: "Bir satır.")]
        let single = ShareContent.pages(for: .talker, report: report, roasts: roasts, hideNames: false)
        XCTAssertEqual(single.map(\.card), [.talker])
        let all = ShareContent.pages(for: cards.last ?? .premiumGate, report: report, roasts: roasts, hideNames: false)
        XCTAssertEqual(all.map(\.card), cards.filter { $0 != .premiumGate })
        let withoutRoast = ShareContent.pages(for: .roast, report: report, roasts: [], hideNames: false)
        XCTAssertEqual(withoutRoast.map(\.card), [.talker])
    }

    func testShareFallsBackToTalkerWhenRoastIsMissing() throws {
        let report = try Fixture.report("lise-tayfa")
        let content = ShareContent.make(card: .roast, report: report, roasts: [], hideNames: false)
        XCTAssertEqual(content.card, .talker)
        XCTAssertEqual(content.name, report.talker.name)
    }
}
