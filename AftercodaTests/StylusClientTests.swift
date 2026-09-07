import XCTest
@testable import Aftercoda

private struct ProbeDTO: Decodable {
    var reading: FlexibleScalar
}

private actor ScriptedStylusTransport: StylusTransport {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class StylusClientTests: XCTestCase {
    private let url = URL(string: "https://aftercoda.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let transport = ScriptedStylusTransport(results: [
            .success((Data("{\"reading\":1}".utf8), try http(200))),
        ])
        let client = StylusClient(transport: transport)
        _ = try await client.getJSON(ProbeDTO.self, from: url)
        let request = await transport.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), StylusClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(StylusClient.userAgent, "Aftercoda/1.0 (iOS; +https://aftercoda.pro)")
    }

    func test_retriesTransientTransportOnce() async throws {
        let transport = ScriptedStylusTransport(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"reading\":\"4.5\"}".utf8), try http(200))),
        ])
        let client = StylusClient(transport: transport)
        let dto = try await client.getJSON(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.reading.value, 4.5)
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async throws {
        let transport = ScriptedStylusTransport(results: [
            .success((Data(), try http(404))),
            .success((Data("{\"reading\":1}".utf8), try http(200))),
        ])
        let client = StylusClient(transport: transport)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? StylusClientError, .notFound)
        }
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async throws {
        let transport = ScriptedStylusTransport(results: [
            .success((Data("{".utf8), try http(200))),
        ])
        let client = StylusClient(transport: transport)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? StylusClientError, .decoding)
        }
    }

    func test_flexibleScalarAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"reading\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"reading\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"reading\":null}".utf8))
        XCTAssertEqual(number.reading.value, 12.5)
        XCTAssertEqual(string.reading.value, 12.5)
        XCTAssertNil(missing.reading.value)
    }

    private func http(_ status: Int) throws -> HTTPURLResponse {
        try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
    }
}
