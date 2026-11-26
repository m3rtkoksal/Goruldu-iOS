import XCTest

#if canImport(GorulduCore)
@testable import GorulduCore
#else
@testable import Goruldu
#endif

/// The engine must reproduce the reference output for every fixture, field by field.
final class ReportFixtureTests: XCTestCase {
    func testLiseTayfa() throws { try assertMatches("lise-tayfa") }
    func testIosTurkish() throws { try assertMatches("ios-tr") }
    func testAndroidEnglishUS() throws { try assertMatches("android-en-us") }
    func testIosEnglishGB() throws { try assertMatches("ios-en-gb") }

    func testNotAChat() throws { try assertFails("not-a-chat", with: .unrecognized) }
    func testTooShort() throws { try assertFails("too-short", with: .tooShort) }

    func testReportSurvivesJSONRoundTrip() throws {
        let report = try Fixture.report("lise-tayfa")
        let decoded = try JSONDecoder().decode(ChatReport.self, from: JSONEncoder().encode(report))
        XCTAssertEqual(decoded, report)
    }

    private func assertMatches(_ name: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let actual = try Fixture.report(name)
        let expected = try Fixture.expectedReport(name)
        XCTAssertEqual(actual.participants, expected.participants, file: file, line: line)
        XCTAssertEqual(actual.talker, expected.talker, file: file, line: line)
        XCTAssertEqual(actual.slowReplier, expected.slowReplier, file: file, line: line)
        XCTAssertEqual(actual.nightOwl, expected.nightOwl, file: file, line: line)
        XCTAssertEqual(actual.topWords, expected.topWords, file: file, line: line)
        XCTAssertEqual(actual.awards, expected.awards, file: file, line: line)
        XCTAssertEqual(actual, expected, file: file, line: line)
    }

    private func assertFails(_ name: String, with error: ReportError, file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(try Fixture.expectedError(name), error.rawValue, file: file, line: line)
        XCTAssertThrowsError(try Fixture.report(name), file: file, line: line) { thrown in
            XCTAssertEqual(thrown as? ReportError, error, file: file, line: line)
        }
    }
}
