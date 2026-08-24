//
//  DetectArbitrageUseCase.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

protocol DetectArbitrageUseCase {
    func execute(sport: String) async throws -> [MatchOdds]
}

struct MatchOdds: Identifiable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    let commenceTime: Date
    let bestOutcomes: [String: BestOutcome]
    let hasArbitrage: Bool
    let arbitrageMargin: Double?
}

struct BestOutcome {
    let bookmakerTitle: String
    let price: Double
}
