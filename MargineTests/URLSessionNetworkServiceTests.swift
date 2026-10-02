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

    @Test("Status code fuera de 200-299 lanza httpError con el código real")
    func httpErrorOnBadStatusCode() async throws {
        URLProtocolStub.stubResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)
        URLProtocolStub.stubResponseData = Data()
        defer { URLProtocolStub.reset() }

        let sut = URLSessionNetworkService(session: URLProtocolStub.makeSession())

        let error = try await #require(throws: NetworkError.self) {
            let _: [OddsEvent] = try await sut.fetch(url)
        }
        guard case .httpError(let statusCode) = error else {
            Issue.record("Se esperaba .httpError, se obtuvo \(error)")
            return
        }
        #expect(statusCode == 500)
    }

    @Test("Status code 429 lanza rateLimited en vez de httpError genérico")
    func rateLimitedOnTooManyRequests() async throws {
        URLProtocolStub.stubResponse = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: nil)
        URLProtocolStub.stubResponseData = Data()
        defer { URLProtocolStub.reset() }

        let sut = URLSessionNetworkService(session: URLProtocolStub.makeSession())

        let error = try await #require(throws: NetworkError.self) {
            let _: [OddsEvent] = try await sut.fetch(url)
        }
        guard case .rateLimited = error else {
            Issue.record("Se esperaba .rateLimited, se obtuvo \(error)")
            return
        }
    }

    @Test("JSON inválido lanza decodingFailed preservando el DecodingError original")
    func decodingFailurePreservesUnderlyingError() async throws {
        URLProtocolStub.stubResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.stubResponseData = Data("{\"unexpected\": true}".utf8)
        defer { URLProtocolStub.reset() }

        let sut = URLSessionNetworkService(session: URLProtocolStub.makeSession())

        let error = try await #require(throws: NetworkError.self) {
            let _: [OddsEvent] = try await sut.fetch(url)
        }
        guard case .decodingFailed(let underlying) = error else {
            Issue.record("Se esperaba .decodingFailed, se obtuvo \(error)")
            return
        }
        #expect(underlying is DecodingError)
    }

    @Test("Response sin ser HTTPURLResponse lanza invalidResponse")
    func invalidResponseWhenNotHTTP() async throws {
        URLProtocolStub.stubResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        URLProtocolStub.stubResponseData = Data()
        defer { URLProtocolStub.reset() }

        let sut = URLSessionNetworkService(session: URLProtocolStub.makeSession())

        await #expect(throws: NetworkError.self) {
            let _: [OddsEvent] = try await sut.fetch(url)
        }
    }

    @Test("Un URLRequest con httpMethod POST se envía tal cual, sin degradarlo a GET")
    func sendsRequestMethodAsIs() async throws {
        URLProtocolStub.stubResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        URLProtocolStub.stubResponseData = Data("{}".utf8)
        defer { URLProtocolStub.reset() }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let sut = URLSessionNetworkService(session: URLProtocolStub.makeSession())

        let _: EventRefreshResponseStub = try await sut.fetch(request)

        #expect(URLProtocolStub.capturedRequest?.httpMethod == "POST")
    }
}

private struct EventRefreshResponseStub: Decodable {}
