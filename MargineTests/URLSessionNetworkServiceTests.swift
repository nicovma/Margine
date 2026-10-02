//
//  URLSessionNetworkServiceTests.swift
//  Margine
//

import Foundation
import Testing
@testable import Margine

@Suite(.serialized)
struct URLSessionNetworkServiceTests {
    private let url = URL(string: "https://api.the-odds-api.com/v4/sports/soccer_epl/odds")!

    @Test("A status code outside 200-299 throws httpError with the real code")
    func httpErrorOnBadStatusCode() async throws {
        URLProtocolStub.stubResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)
        URLProtocolStub.stubResponseData = Data()
        defer { URLProtocolStub.reset() }

        let sut = URLSessionNetworkService(session: URLProtocolStub.makeSession())

        let error = try await #require(throws: NetworkError.self) {
            let _: [OddsEvent] = try await sut.fetch(url)
        }
        guard case .httpError(let statusCode) = error else {
            Issue.record("Expected .httpError, got \(error)")
            return
        }
        #expect(statusCode == 500)
    }

    @Test("Status code 429 throws rateLimited instead of a generic httpError")
    func rateLimitedOnTooManyRequests() async throws {
        URLProtocolStub.stubResponse = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: nil)
        URLProtocolStub.stubResponseData = Data()
        defer { URLProtocolStub.reset() }

        let sut = URLSessionNetworkService(session: URLProtocolStub.makeSession())

        let error = try await #require(throws: NetworkError.self) {
            let _: [OddsEvent] = try await sut.fetch(url)
        }
        guard case .rateLimited = error else {
            Issue.record("Expected .rateLimited, got \(error)")
            return
        }
    }

    @Test("Invalid JSON throws decodingFailed, preserving the original DecodingError")
    func decodingFailurePreservesUnderlyingError() async throws {
        URLProtocolStub.stubResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.stubResponseData = Data("{\"unexpected\": true}".utf8)
        defer { URLProtocolStub.reset() }

        let sut = URLSessionNetworkService(session: URLProtocolStub.makeSession())

        let error = try await #require(throws: NetworkError.self) {
            let _: [OddsEvent] = try await sut.fetch(url)
        }
        guard case .decodingFailed(let underlying) = error else {
            Issue.record("Expected .decodingFailed, got \(error)")
            return
        }
        #expect(underlying is DecodingError)
    }

    @Test("A non-HTTPURLResponse throws invalidResponse")
    func invalidResponseWhenNotHTTP() async throws {
        URLProtocolStub.stubResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        URLProtocolStub.stubResponseData = Data()
        defer { URLProtocolStub.reset() }

        let sut = URLSessionNetworkService(session: URLProtocolStub.makeSession())

        await #expect(throws: NetworkError.self) {
            let _: [OddsEvent] = try await sut.fetch(url)
        }
    }

    @Test("httpError's user-facing message includes the status code")
    func httpErrorDescriptionIncludesStatusCode() {
        let description = NetworkError.httpError(statusCode: 503).errorDescription

        #expect(description?.contains("503") == true)
    }
}
