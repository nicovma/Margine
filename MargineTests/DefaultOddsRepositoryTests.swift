//
//  DefaultOddsRepositoryTests.swift
//  Margine
//

import Foundation
import Testing
@testable import Margine

struct DefaultOddsRepositoryTests {

    @Test("Construye la URL con el path y los query items correctos")
    func buildsExpectedURL() async throws {
        let networkService = SpyNetworkService()
        let sut = DefaultOddsRepository(networkService: networkService, apiKey: "test-key")

        _ = try? await sut.fetchUpcomingOdds(sport: "soccer_epl")

        let url = try #require(networkService.capturedURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/v4/sports/soccer_epl/odds")

        let queryItems = try #require(components.queryItems)
        #expect(queryItems.contains(URLQueryItem(name: "apiKey", value: "test-key")))
        #expect(queryItems.contains(URLQueryItem(name: "markets", value: "h2h")))
        #expect(queryItems.contains(URLQueryItem(name: "regions", value: "eu")))
    }

    @Test("Un sport con caracteres inválidos lanza invalidURL en vez de crashear")
    func invalidSportThrowsInsteadOfCrashing() async throws {
        let networkService = SpyNetworkService()
        let sut = DefaultOddsRepository(networkService: networkService, apiKey: "test-key")

        await #expect(throws: NetworkError.self) {
            _ = try await sut.fetchUpcomingOdds(sport: "soccer epl")
        }
    }
}

private final class SpyNetworkService: NetworkService {
    private(set) var capturedURL: URL?

    func fetch<T: Decodable>(_ url: URL) async throws -> T {
        capturedURL = url
        throw NetworkError.invalidResponse
    }
}
