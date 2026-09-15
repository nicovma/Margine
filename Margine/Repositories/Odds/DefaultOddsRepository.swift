//
//  DefaultOddsRepository.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

/// El `sport` que pide siempre devuelve el mismo combinado de ligas top
/// configurado del lado del backend (ver `margine-odds-worker`) — no hay
/// forma de pedir una liga puntual todavía. El parámetro queda como parte
/// del contrato para no romper nada si en el futuro se agrega un selector
/// real de deporte (backlog: S3.2c).
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
