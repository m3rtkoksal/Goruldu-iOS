import Foundation
import XCTest

#if canImport(GorulduCore)
@testable import GorulduCore
#else
@testable import Goruldu
#endif

enum Fixture {
    private final class Anchor {}

    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: Anchor.self)
        #endif
    }

    static func data(_ name: String, _ ext: String, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: ext), "\(name).\(ext) is missing", file: file, line: line)
        return try Data(contentsOf: url)
    }

    static func text(_ name: String) throws -> String {
        ReportEngine.decode(try data(name, "txt"))
    }

    static func report(_ name: String) throws -> ChatReport {
        try ReportEngine.report(text: text(name), title: ChatTitle.from(fileName: "\(name).txt"))
    }

    static func expectedReport(_ name: String) throws -> ChatReport {
        try JSONDecoder().decode(ChatReport.self, from: data("\(name).expected", "json"))
    }

    static func expectedError(_ name: String) throws -> String {
        struct Failure: Decodable { let error: String }
        return try JSONDecoder().decode(Failure.self, from: data("\(name).expected", "json")).error
    }
}
