import XCTest
@testable import Goruldu

final class FormatTests: XCTestCase {
    func testNumberGroupingFollowsLocale() {
        XCTAssertEqual(Format.number(9_812, locale: Locale(identifier: "tr_TR")), "9.812")
        XCTAssertEqual(Format.number(9_812, locale: Locale(identifier: "en_US")), "9,812")
        XCTAssertEqual(Format.number(42, locale: Locale(identifier: "tr_TR")), "42")
    }

    func testDurationParts() {
        XCTAssertTrue(Format.durationParts(minutes: 554) == (0, 9, 14))
        XCTAssertTrue(Format.durationParts(minutes: 59) == (0, 0, 59))
        XCTAssertTrue(Format.durationParts(minutes: 1_500) == (1, 1, 0))
        XCTAssertTrue(Format.durationParts(minutes: -5) == (0, 0, 0))
    }

    func testClock() {
        XCTAssertEqual(Format.clock(hour: 2), "02:00")
        XCTAssertEqual(Format.clock(hour: 23, minute: 16), "23:16")
    }

    func testMaskedNamesAndInitials() {
        XCTAssertEqual(Format.masked("Burak"), "B.")
        XCTAssertEqual(Format.masked("  çağla"), "Ç.")
        XCTAssertEqual(Format.masked(""), "?")
        XCTAssertEqual(Format.initials("Lise Tayfa"), "LT")
        XCTAssertEqual(Format.initials("Aile"), "A")
        XCTAssertEqual(Format.initials("bir çok kişi"), "BÇ")
    }

    func testEveryLocalizedKeyResolves() {
        // A missing key comes back as the key itself.
        for key in ["home.title", "award.laugher.title", "import.error.tooLarge.text", "format.percent"] {
            XCTAssertNotEqual(L10n.tr(key), key)
        }
        XCTAssertTrue(["38%", "%38"].contains(Format.percent(38)))
    }
}
