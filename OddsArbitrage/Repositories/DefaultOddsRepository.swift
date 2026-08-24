//
//  DefaultOddsRepository.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

final class DefaultOddsRepository: OddsRepository {
    private let networkService: NetworkService
    private let apiKey: String
    private let baseURL = "https://api.the-odds-api.com/v4"

    init(networkService: NetworkService, apiKey: String) {
        self.networkService = networkService
        self.apiKey = apiKey
    }

    func fetchUpcomingOdds(sport: String) async throws -> [OddsEvent] {
        var components = URLComponents(string: "\(baseURL)/sports/\(sport)/odds")!
        components.queryItems = [
            URLQueryItem(name: "regions", value: "eu"),
            URLQueryItem(name: "markets", value: "h2h"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }
        return try await networkService.fetch(url)
    }
}
