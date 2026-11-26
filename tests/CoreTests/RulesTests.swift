import XCTest

#if canImport(GorulduCore)
@testable import GorulduCore
#else
@testable import Goruldu
#endif

final class RulesTests: XCTestCase {
    func testStopwordsMatchSharedList() throws {
        let shared = Set(try Fixture.text("stopwords").split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        XCTAssertEqual(Stopwords.all, shared)
    }

    func testChatTitles() {
        XCTAssertEqual(ChatTitle.from(fileName: "WhatsApp Chat with Lise Tayfa.txt"), "Lise Tayfa")
        XCTAssertEqual(ChatTitle.from(fileName: "WhatsApp Chat - Lise Tayfa.zip"), "Lise Tayfa")
        XCTAssertEqual(ChatTitle.from(fileName: "WhatsApp Sohbeti - Aile.zip"), "Aile")
        XCTAssertEqual(ChatTitle.from(fileName: "Aile ile WhatsApp Sohbeti.txt"), "Aile")
        XCTAssertEqual(ChatTitle.from(fileName: "/tmp/inbox/_chat.txt"), "")
        XCTAssertEqual(ChatTitle.from(fileName: "notlar.txt"), "notlar")
    }

    func testRoundDivRoundsHalfUp() {
        XCTAssertEqual(TextRules.roundDiv(1, 2), 1)
        XCTAssertEqual(TextRules.roundDiv(1, 3), 0)
        XCTAssertEqual(TextRules.roundDiv(5, 2), 3)
        XCTAssertEqual(TextRules.roundDiv(0, 7), 0)
    }

    func testKeysmash() {
        for word in ["sjsjsj", "asdfghjkl", "kdjfhgkdjfhg"] {
            XCTAssertTrue(TextRules.isKeysmash(TextRules.scalars(word)), word)
        }
        for word in ["thursday", "thanks", "tamam", "nerdesiniz", "brb"] {
            XCTAssertFalse(TextRules.isKeysmash(TextRules.scalars(word)), word)
        }
    }

    func testTurkishLowercase() {
        let turkish = TextRules.string(TextRules.lower(TextRules.scalars("IŞIK İLE"), turkish: true))
        XCTAssertEqual(turkish, "ışık ile")
        let english = TextRules.string(TextRules.lower(TextRules.scalars("I’M IN"), turkish: false))
        XCTAssertEqual(english, "i'm in")
    }

    func testTokensSkipLinks() {
        let tokens = TextRules.tokens(TextRules.scalars("bak https://example.com/a?b=c www.x.com şuna2bak"))
        XCTAssertEqual(tokens.map(TextRules.string), ["bak", "şuna", "bak"])
    }

    func testDayNumber() throws {
        let epoch = try XCTUnwrap(ChatTime(year: 1970, month: 1, day: 1, hour: 0, minute: 0, second: 0))
        let leap = try XCTUnwrap(ChatTime(year: 2024, month: 2, day: 29, hour: 12, minute: 0, second: 0))
        let next = try XCTUnwrap(ChatTime(year: 2024, month: 3, day: 1, hour: 12, minute: 0, second: 0))
        XCTAssertEqual(epoch.dayNumber, 0)
        XCTAssertEqual(next.dayNumber - leap.dayNumber, 1)
        XCTAssertNil(ChatTime(year: 2023, month: 2, day: 29, hour: 0, minute: 0, second: 0))
        XCTAssertNil(ChatTime(year: 2024, month: 13, day: 1, hour: 0, minute: 0, second: 0))
    }

    func testMeridiemAndMonthFirst() throws {
        var lines: [String] = []
        for index in 0..<20 {
            lines.append("12/\(13 + index % 5)/23, 12:0\(index % 10) AM - \(index % 2 == 0 ? "Ann" : "Bob"): hello there \(index)")
        }
        lines.append("12/20/23, 11:30\u{202F}PM - Ann: late one")
        let messages = try ChatParser.parse(lines.joined(separator: "\n"))
        XCTAssertEqual(messages.count, 21)
        XCTAssertEqual(messages[0].time.hour, 0)
        XCTAssertEqual(messages[0].time.month, 12)
        XCTAssertEqual(messages[20].time.hour, 23)
        XCTAssertEqual(messages[20].time.day, 20)
    }

    func testSystemAndMediaLines() throws {
        let text = """
        [01.03.2024 10:00:00] Lise Tayfa: \u{200E}Mesajlar ve aramalar uçtan uca şifrelidir.
        [01.03.2024 10:01:00] Ayşe: selam
        devam satırı
        [01.03.2024 10:02:00] Mehmet: \u{200E}görüntü dahil edilmedi
        [01.03.2024 10:03:00] Mehmet: Bu mesaj silindi.
        [01.03.2024 10:04:00] Ayşe: \u{200E}Ayşe grup simgesini değiştirdi
        [01.03.2024 10:05:00] Ayşe: tamam <Bu mesaj düzenlendi>
        """
        let messages = try ChatParser.parse(text)
        XCTAssertEqual(messages.map(\.sender), ["Ayşe", "Mehmet", "Mehmet", "Ayşe"])
        XCTAssertEqual(messages[0].text, "selam\ndevam satırı")
        XCTAssertEqual(messages[1].kind, .media)
        XCTAssertEqual(messages[2].kind, .deleted)
        XCTAssertEqual(messages[3].text, "tamam")
    }
}
