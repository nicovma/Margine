//
//  DefaultOddsRepositoryTests.swift
//  Margine
//

import Foundation
import Testing
@testable import Margine

struct DefaultOddsRepositoryTests {

    @Test("Builds the URL against the configured baseURL, with the sport in the path")
    func buildsExpectedURL() async throws {
        let networkService = SpyNetworkService()
        let sut = DefaultOddsRepository(networkService: networkService, baseURL: "https://worker.example.com")

        _ = try? await sut.fetchUpcomingOdds(sport: "top-leagues")

        let url = try #require(networkService.capturedURL)
        #expect(url.absoluteString == "https://worker.example.com/sports/top-leagues/odds")
    }

    @Test("A sport with invalid characters throws invalidURL instead of crashing")
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
