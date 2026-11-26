import XCTest
@testable import Goruldu

final class RoastServiceTests: XCTestCase {
    override func tearDown() {
        StubProtocol.handler = nil
    }

    func testRequestBodyFollowsTheContract() throws {
        let report = try Fixture.report("lise-tayfa")
        let people = Array(report.participants.prefix(RoastService.maxParticipants))
        let body = RoastService.body(report: report, people: people, locale: "tr")
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: Any])

        XCTAssertEqual(Set(json.keys), ["locale", "chat", "participants"])
        let chat = try XCTUnwrap(json["chat"] as? [String: Any])
        XCTAssertEqual(Set(chat.keys), ["title", "participantCount", "totalMessages", "activeDays", "topWords"])
        let participants = try XCTUnwrap(json["participants"] as? [[String: Any]])
        XCTAssertEqual(participants.count, 8)
        XCTAssertEqual(Set(participants[0].keys), [
            "name", "messages", "sharePercent", "avgReplyMinutes", "nightPercent", "capsCount", "mediaCount",
            "longestSilenceDays", "longestMonologue", "planBreaks", "dramaCount", "laughCount",
        ])
    }

    func testMissingAverageIsSentAsNull() throws {
        var report = try Fixture.report("ios-tr")
        report.participants[0].avgReplyMinutes = nil
        let body = RoastService.body(report: report, people: report.participants, locale: "en")
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: Any])
        let first = try XCTUnwrap((json["participants"] as? [[String: Any]])?.first)
        XCTAssertTrue(first["avgReplyMinutes"] is NSNull)
    }

    func testLongNamesAndTitlesAreCut() throws {
        var report = try Fixture.report("ios-tr")
        report.title = String(repeating: "a", count: 200)
        report.participants[0].name = String(repeating: "b", count: 50)
        let body = RoastService.body(report: report, people: report.participants, locale: "en")
        XCTAssertEqual(body.chat.title.count, RoastService.maxTitleLength)
        XCTAssertEqual(body.participants[0].name.count, RoastService.maxNameLength)
    }

    func testWithoutAnAddressNothingIsSent() async throws {
        let service = RoastService(config: AppConfig(apiBaseURL: nil, appKey: nil), session: stubbedSession())
        StubProtocol.handler = { _ in XCTFail("no request expected"); return (500, Data()) }
        do {
            _ = try await service.roasts(for: Fixture.report("ios-tr"), locale: "tr")
            XCTFail("expected notConfigured")
        } catch {
            XCTAssertEqual(error as? RoastService.Failure, .notConfigured)
        }
    }

    func testRoastsKeepOurNamesAndOrder() async throws {
        let report = try Fixture.report("ios-tr")
        let lines = report.participants.enumerated().map { ["name": "x\($0.offset)", "line": "satır \($0.offset)"] }
        let payload = try JSONSerialization.data(withJSONObject: ["source": "template", "roasts": lines])
        StubProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "http://localhost:5831/v1/roasts")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-app-key"), "anahtar")
            return (201, payload)
        }
        let service = RoastService(
            config: AppConfig(apiBaseURL: URL(string: "http://localhost:5831"), appKey: "anahtar"),
            session: stubbedSession()
        )
        let roasts = try await service.roasts(for: report, locale: "tr")
        XCTAssertEqual(roasts.map(\.name), report.participants.map(\.name))
        XCTAssertEqual(roasts.first?.line, "satır 0")
    }

    func testServerErrorsAndShortAnswersAreFailures() async throws {
        let report = try Fixture.report("ios-tr")
        let service = RoastService(
            config: AppConfig(apiBaseURL: URL(string: "http://localhost:5831"), appKey: nil),
            session: stubbedSession()
        )

        StubProtocol.handler = { _ in (429, Data("{}".utf8)) }
        do {
            _ = try await service.roasts(for: report, locale: "tr")
            XCTFail("expected rejected")
        } catch {
            XCTAssertEqual(error as? RoastService.Failure, .rejected)
        }

        StubProtocol.handler = { _ in (200, Data(#"{"source":"ai","roasts":[{"name":"a","line":"tek"}]}"#.utf8)) }
        do {
            _ = try await service.roasts(for: report, locale: "tr")
            XCTFail("expected badResponse")
        } catch {
            XCTAssertEqual(error as? RoastService.Failure, .badResponse)
        }
    }

    private func stubbedSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class StubProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let handler = StubProtocol.handler, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (status, data) = handler(request)
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}
