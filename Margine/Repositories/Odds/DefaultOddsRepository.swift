//
//  DefaultOddsRepository.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

/// The `sport` it requests always returns the same top-leagues combo
/// configured on the backend side (see `margine-odds-worker`) — there's no
/// way to request a specific league yet. The parameter stays part of the
/// contract so nothing breaks if a real sport selector gets added in the
/// future (backlog: S3.2c).
final class DefaultOddsRepository: OddsRepository {
    private let networkService: NetworkService
    private let baseURL: String

    init(networkService: NetworkService, baseURL: String) {
        self.networkService = networkService
        self.baseURL = baseURL
    }

    func fetchUpcomingOdds(sport: String) async throws -> [OddsEvent] {
        guard let url = URL(string: "\(baseURL)/sports/\(sport)/odds") else {
            throw NetworkError.invalidURL
        }
        return try await networkService.fetch(url)
    }
}
