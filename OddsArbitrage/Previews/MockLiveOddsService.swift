//
//  MockLiveOddsService.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 12/9/2026.
//
import Combine
import Foundation

@MainActor
final class MockLiveOddsService: LiveOddsServiceProtocol {
    let refreshErrors = PassthroughSubject<String, Never>()
    
    let currentMatches: CurrentValueSubject<[MatchOdds]?, Never>
    private(set) var startPollingCallCount = 0
    private(set) var refreshNowCallCount = 0

    init(matches: [MatchOdds]? = MockDetectArbitrageUseCase.sampleMatches) {
        currentMatches = CurrentValueSubject(matches)
    }

    func startPolling() { startPollingCallCount += 1 }
    func stopPolling() {}
    func refreshNow() async { refreshNowCallCount += 1 }
}
