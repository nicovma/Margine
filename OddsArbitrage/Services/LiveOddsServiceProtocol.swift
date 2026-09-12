//
//  LiveOddsServiceProtocol.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 12/9/2026.
//
import Combine
import Foundation

@MainActor
protocol LiveOddsServiceProtocol {
    var currentMatches: CurrentValueSubject<[MatchOdds], Never> { get }
    var refreshErrors: PassthroughSubject<String, Never> { get }
    func startPolling()
    func stopPolling()
    func refreshNow() async
}
