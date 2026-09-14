//
//  OddsRepository.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

protocol OddsRepository {
    func fetchUpcomingOdds(sport: String) async throws -> [OddsEvent]
}
