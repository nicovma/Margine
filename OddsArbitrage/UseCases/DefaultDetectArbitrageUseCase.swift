//
//  DefaultDetectArbitrageUseCase.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

final class DefaultDetectArbitrageUseCase: DetectArbitrageUseCase {
    private let repository: OddsRepository

    init(repository: OddsRepository) {
        self.repository = repository
    }

    func execute(sport: String) async throws -> [MatchOdds] {
        let events = try await repository.fetchUpcomingOdds(sport: sport)
        return events.map(analyze)
    }

    private func analyze(_ event: OddsEvent) -> MatchOdds {
        var bestOutcomes: [String: BestOutcome] = [:]

        for bookmaker in event.bookmakers {
            guard let market = bookmaker.markets.first(where: { $0.key == "h2h" }) else { continue }
            for outcome in market.outcomes {
                if let current = bestOutcomes[outcome.name], current.price >= outcome.price {
                    continue
                }
                bestOutcomes[outcome.name] = BestOutcome(bookmakerTitle: bookmaker.title, price: outcome.price)
            }
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
