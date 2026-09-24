//
//  LiveOddsCoordinator.swift
//  Margine
//
//  Created by Nicolas Valentini on 12/9/2026.
//
import Foundation

actor LiveOddsCoordinator {
    private let useCase: DetectArbitrageUseCase
    private let sport: String
    private var isRefreshing = false

    init(useCase: DetectArbitrageUseCase, sport: String) {
        self.useCase = useCase
        self.sport = sport
    }

    func refreshIfNeeded() async throws -> [MatchOdds]? {
        guard !isRefreshing else { return nil }
        isRefreshing = true
        defer { isRefreshing = false }

        return try await useCase.execute(sport: sport)
    }
}
