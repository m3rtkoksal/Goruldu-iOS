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
        XCTAssertEqual(open.rows.first?.name, "Burak")
        XCTAssertEqual(hidden.rows.first?.name, "B.")

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
        XCTAssertEqual(all.map(\.card), cards.filter { $0 != .premiumGate && $0 != .fastest })
        let withoutRoast = ShareContent.pages(for: .roast, report: report, roasts: [], hideNames: false)
        XCTAssertEqual(withoutRoast.map(\.card), [.talker])
    }

    func testShareImagesUseTheSameListsAsTheScreen() throws {
        let report = try Fixture.report("lise-tayfa")
        let roasts = [
            Roast(name: "Burak", line: "Bir satır."),
            Roast(name: "Deniz", line: "İkinci satır."),
        ]
        let deck = ShareContent.deck(report: report, roasts: roasts, hideNames: false, viewerName: "Zeynep")
        let cover = try XCTUnwrap(deck.first { $0.card == .cover })
        XCTAssertEqual(cover.stats.map(\.value), [
            Format.number(report.totalMessages),
            Format.number(report.participantCount),
            Format.number(report.activeDays),
        ])
        XCTAssertTrue(cover.rows.isEmpty)
        let talkers = try XCTUnwrap(deck.first { $0.card == .talker })
        XCTAssertEqual(talkers.rows.map(\.name), ReportBoard.talkers(report).map(\.name))
        XCTAssertEqual(talkers.rows.map(\.value), ReportBoard.talkers(report).map { Format.percent($0.sharePercent) })
        XCTAssertEqual(talkers.rows.count, 8)
        XCTAssertTrue(talkers.rows.contains { $0.name == "Zeynep" && $0.you })

        let speed = try XCTUnwrap(deck.first { $0.card == .slowReplier })
        XCTAssertEqual(speed.rows.map(\.name), ReportBoard.fastest(report).map(\.name))
        XCTAssertEqual(speed.rows.map(\.value), ReportBoard.fastest(report).map { Format.duration(minutes: $0.avgReplyMinutes ?? 0) })
        XCTAssertEqual(speed.name, report.slowReplier?.name)

        let night = try XCTUnwrap(deck.first { $0.card == .nightOwl })
        XCTAssertEqual(night.rows.map(\.name), ReportBoard.night(report).map(\.name))
        XCTAssertEqual(night.rows.map(\.value), ReportBoard.night(report).map { Format.percent($0.nightPercent) })

        let words = try XCTUnwrap(deck.first { $0.card == .words })
        XCTAssertEqual(words.name, report.topWords[0].word)
        XCTAssertEqual(words.stat, Format.number(report.topWords[0].count))
        XCTAssertEqual(words.rows.map(\.name), report.topWords.prefix(8).map(\.word))
        XCTAssertEqual(words.rows.map(\.value), report.topWords.prefix(8).map { Format.number($0.count) })

        let awards = try XCTUnwrap(deck.first { $0.card == .ceremony })
        XCTAssertEqual(awards.lines.count, ReportBoard.awards(report, premium: false).count)
        XCTAssertEqual(deck.first { $0.card == .roast }?.lines.count, 1)

        let paid = ShareContent.deck(report: report, roasts: roasts, hideNames: false, premium: true, viewerName: "Burak")
        XCTAssertEqual(paid.first { $0.card == .ceremony }?.lines.count, report.awards.count)
        XCTAssertEqual(paid.first { $0.card == .roast }?.lines.count, 2)
        XCTAssertEqual(paid.first { $0.card == .cast }?.lines.map(\.title), report.participants.map(\.name))
        XCTAssertEqual(StoreLink.url.absoluteString, "https://apps.apple.com/app/id6839817495")
        XCTAssertTrue(cover.spoken.contains(StoreLink.url.absoluteString))
    }

    func testShareFallsBackToTalkerWhenRoastIsMissing() throws {
        let report = try Fixture.report("lise-tayfa")
        let content = ShareContent.make(card: .roast, report: report, roasts: [], hideNames: false)
        XCTAssertEqual(content.card, .talker)
        XCTAssertEqual(content.name, report.talker.name)
    }
}
