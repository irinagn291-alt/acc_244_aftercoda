import Foundation

/// Store. Typed transport failures. This product has no remote catalog.
enum StylusClientError: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Store. Injected so tests never open a live socket.
protocol StylusTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Store. URLSession with a 15 s timeout and the Aftercoda User-Agent on every request.
struct SessionStylusTransport: StylusTransport {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": StylusClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Store. DTO scalar that accepts a JSON number or a numeric string. Missing stays nil.
struct FlexibleScalar: Sendable, Equatable {
    var value: Double?
}

extension FlexibleScalar: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Store. Owns the session. Offline product; this is the transport seam only.
actor StylusClient {
    static let userAgent = "Aftercoda/1.0 (iOS; +https://aftercoda.pro)"

    private let transport: any StylusTransport

    init(transport: any StylusTransport) {
        self.transport = transport
    }

    init() {
        self.transport = SessionStylusTransport()
    }

    func getJSON<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let payload = try await fetch(request(url: url))
        do {
            return try JSONDecoder().decode(DTO.self, from: payload)
        } catch is CancellationError {
            throw StylusClientError.cancelled
        } catch {
            throw StylusClientError.decoding
        }
    }

    private func request(url: URL) -> URLRequest {
        var item = URLRequest(url: url, timeoutInterval: 15)
        item.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return item
    }

    private func fetch(_ item: URLRequest) async throws -> Data {
        do {
            return try await send(item)
        } catch let error as StylusClientError {
            throw error
        } catch is CancellationError {
            throw StylusClientError.cancelled
        } catch {
            if stylusCancelled(error) {
                throw StylusClientError.cancelled
            }
            guard stylusTransient(error) else {
                throw StylusClientError.transport
            }
            return try await retry(item)
        }
    }

    private func retry(_ item: URLRequest) async throws -> Data {
        do {
            return try await send(item)
        } catch let error as StylusClientError {
            throw error
        } catch is CancellationError {
            throw StylusClientError.cancelled
        } catch {
            if stylusCancelled(error) {
                throw StylusClientError.cancelled
            }
            throw StylusClientError.transport
        }
    }

    private func send(_ item: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await transport.data(for: item)
        guard let http = response as? HTTPURLResponse else {
            throw StylusClientError.invalidResponse
        }
        if http.statusCode == 404 {
            throw StylusClientError.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw StylusClientError.transport
        }
        return data
    }
}

func stylusTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

func stylusCancelled(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}
