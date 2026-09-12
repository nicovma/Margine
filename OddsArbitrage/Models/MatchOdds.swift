//
//  MatchOdds.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 27/8/2026.
//
import Foundation

struct MatchOdds: Identifiable, Hashable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    let commenceTime: Date
    let bestOutcomes: [String: BestOutcome]
    let hasArbitrage: Bool
    let arbitrageMargin: Double?
}

struct BestOutcome: Hashable {
    let bookmakerTitle: String
    let price: Double
}
