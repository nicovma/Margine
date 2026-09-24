//
//  DetectArbitrageUseCase.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

/// Fetches upcoming odds for `sport` and analyzes them for arbitrage opportunities.
///
/// As a side effect, every bookmaker seen in the response is recorded into the
/// bookmaker catalog (`BookmakerPreferences`), so the Profile tab's filter list
/// stays up to date without a separate fetch.
protocol DetectArbitrageUseCase {
    func execute(sport: String) async throws -> [MatchOdds]
}
