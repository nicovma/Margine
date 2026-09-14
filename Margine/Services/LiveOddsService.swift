//
//  LiveOddsService.swift
//  Margine
//
//  Created by Nicolas Valentini on 12/9/2026.
//
import Combine
import Foundation

@MainActor
final class LiveOddsService: LiveOddsServiceProtocol {
    /// The Odds API's free tier is ~500 requests/month — nowhere near enough
    /// for a short poll interval. 60s keeps the "live" feel (real sportsbooks
    /// don't move odds much faster than that anyway) while staying sustainable.
    static let pollingInterval: TimeInterval = 60

    let currentMatches = CurrentValueSubject<[MatchOdds]?, Never>(nil)
    let refreshErrors = PassthroughSubject<String, Never>()

    private let coordinator: LiveOddsCoordinator
    private var pollingCancellable: AnyCancellable?

    init(useCase: DetectArbitrageUseCase, sport: String = "soccer_epl") {
        self.coordinator = LiveOddsCoordinator(useCase: useCase, sport: sport)
    }

    func startPolling() {
        Task { await refreshNow() }
        pollingCancellable = Timer.publish(every: Self.pollingInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refreshNow() }
            }
    }

    func stopPolling() {
        pollingCancellable = nil
    }

    func refreshNow() async {
        do {
            guard let matches = try await coordinator.refreshIfNeeded() else {
                return
            }
            currentMatches.send(matches)
        } catch {
            refreshErrors.send(error.localizedDescription)
        }
    }
}
