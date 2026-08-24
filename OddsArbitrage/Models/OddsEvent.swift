//
//  OddsEvent.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

struct OddsEvent: Codable, Identifiable {
    let id: String
    let sportKey: String
    let commenceTime: Date
    let homeTeam: String
    let awayTeam: String
    let bookmakers: [Bookmaker]

    enum CodingKeys: String, CodingKey {
        case id
        case sportKey = "sport_key"
        case commenceTime = "commence_time"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case bookmakers
    }
}

struct Bookmaker: Codable, Identifiable {
    let key: String
    let title: String
    let markets: [Market]

    var id: String { key }
}

struct Market: Codable {
    let key: String
    let outcomes: [Outcome]
}

struct Outcome: Codable {
    let name: String
    let price: Double
}
