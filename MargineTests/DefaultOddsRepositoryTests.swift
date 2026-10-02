//
//  DefaultOddsRepositoryTests.swift
//  Margine
//

import Foundation
import Testing
@testable import Margine

struct DefaultOddsRepositoryTests {

    @Test("Construye la URL contra el baseURL configurado, con el sport en el path")
    func buildsExpectedURL() async throws {
        let networkService = SpyNetworkService()
        let sut = DefaultOddsRepository(networkService: networkService, baseURL: "https://worker.example.com")

        _ = try? await sut.fetchUpcomingOdds(sport: "top-leagues")

        let url = try #require(networkService.capturedURL)
        #expect(url.absoluteString == "https://worker.example.com/sports/top-leagues/odds")
    }

    @Test("Un sport con caracteres inválidos lanza invalidURL en vez de crashear")
    func invalidSportThrowsInsteadOfCrashing() async throws {
        let networkService = SpyNetworkService()
        let sut = DefaultOddsRepository(networkService: networkService, baseURL: "https://worker.example.com")

        await #expect(throws: NetworkError.self) {
            _ = try await sut.fetchUpcomingOdds(sport: "soccer epl")
        }
    }

    @Test("refreshEvent hace POST contra /events/:eventId/refresh")
    func refreshEventPostsToExpectedURL() async throws {
        let networkService = SpyNetworkService()
        let sut = DefaultOddsRepository(networkService: networkService, baseURL: "https://worker.example.com")

        _ = try? await sut.refreshEvent(eventId: "event-1")

        let request = try #require(networkService.capturedRequest)
        #expect(request.url?.absoluteString == "https://worker.example.com/events/event-1/refresh")
        #expect(request.httpMethod == "POST")
    }
}

private final class SpyNetworkService: NetworkService {
    private(set) var capturedURL: URL?
    private(set) var capturedRequest: URLRequest?

    func fetch<T: Decodable>(_ request: URLRequest) async throws -> T {
        capturedURL = request.url
        capturedRequest = request
        throw NetworkError.invalidResponse
    }
}
