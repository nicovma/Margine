//
//  BestOutcomesCalculator.swift
//  Margine
//
import Foundation

/// Picks the best available price per outcome (1/X/2) across enabled
/// bookmakers for a single event. Shared by `DefaultDetectArbitrageUseCase`
/// and by the execution wizard's on-demand single-event refresh, so the
/// "what counts as the best price" rule lives in exactly one place.
protocol BestOutcomesCalculating {
    func bestOutcomes(for event: OddsEvent, preferences: BookmakerPreferences) async -> [String: BestOutcome]
}

final class BestOutcomesCalculator: BestOutcomesCalculating {
    func bestOutcomes(for event: OddsEvent, preferences: BookmakerPreferences) async -> [String: BestOutcome] {
        var bestOutcomes: [String: BestOutcome] = [:]

        for bookmaker in event.bookmakers {
            guard await preferences.isEnabled(bookmaker.key) else { continue }
            guard let market = bookmaker.markets.first(where: { $0.key == "h2h" }) else { continue }
            for outcome in market.outcomes where outcome.price > 0 {
                if let current = bestOutcomes[outcome.name], current.price >= outcome.price {
                    continue
                }
                bestOutcomes[outcome.name] = BestOutcome(
                    bookmakerKey: bookmaker.key,
                    bookmakerTitle: bookmaker.title,
                    price: outcome.price
                )
            }
        }

        return bestOutcomes
    }
}
