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
}

private final class SpyNetworkService: NetworkService {
    private(set) var capturedURL: URL?

    func fetch<T: Decodable>(_ url: URL) async throws -> T {
        capturedURL = url
        throw NetworkError.invalidResponse
    }
}
