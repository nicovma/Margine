//
//  DefaultDetectArbitrageUseCase.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

final class DefaultDetectArbitrageUseCase: DetectArbitrageUseCase {
    private let repository: OddsRepository
    private let preferences: BookmakerPreferences
    private let bestOutcomesCalculator: BestOutcomesCalculating

    init(
        repository: OddsRepository,
        preferences: BookmakerPreferences = AllowAllBookmakerPreferences(),
        bestOutcomesCalculator: BestOutcomesCalculating = BestOutcomesCalculator()
    ) {
        self.repository = repository
        self.preferences = preferences
        self.bestOutcomesCalculator = bestOutcomesCalculator
    }

    func execute(sport: String) async throws -> [MatchOdds] {
        let events = try await repository.fetchUpcomingOdds(sport: sport)
        var results: [MatchOdds] = []
        for event in events {
            await preferences.recordSeen(event.bookmakers)
            results.append(await analyze(event))
        }
        return results
    }

    private func analyze(_ event: OddsEvent) async -> MatchOdds {
        let bestOutcomes = await bestOutcomesCalculator.bestOutcomes(for: event, preferences: preferences)

        guard !bestOutcomes.isEmpty else {
            return MatchOdds(
                id: event.id,
                homeTeam: event.homeTeam,
                awayTeam: event.awayTeam,
                commenceTime: event.commenceTime,
                bestOutcomes: bestOutcomes,
                hasArbitrage: false,
                arbitrageMargin: nil
            )
        }

        let impliedProbabilitySum = bestOutcomes.values.reduce(0) { $0 + (1 / $1.price) }
        let hasArbitrage = impliedProbabilitySum < 1.0
        let margin = hasArbitrage ? (1 / impliedProbabilitySum - 1) * 100 : nil

        return MatchOdds(
            id: event.id,
            homeTeam: event.homeTeam,
            awayTeam: event.awayTeam,
            commenceTime: event.commenceTime,
            bestOutcomes: bestOutcomes,
            hasArbitrage: hasArbitrage,
            arbitrageMargin: margin
        )
    }
}
