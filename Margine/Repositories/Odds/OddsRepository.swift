//
//  OddsRepository.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

protocol OddsRepository {
    func fetchUpcomingOdds(sport: String) async throws -> [OddsEvent]

    /// Asks the worker to refresh a single event on demand (bypassing its
    /// normal 12min/3h cache cycle) right before showing final stakes in the
    /// execution wizard.
    func refreshEvent(eventId: String) async throws -> EventRefreshResponse
}
