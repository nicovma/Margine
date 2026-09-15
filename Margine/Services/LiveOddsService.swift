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
    /// Pega contra el cache del backend propio (margine-odds-worker), no
    /// directo contra The Odds API — un poll de 60s del cliente solo repite
    /// el mismo cache hasta que el backend lo refresque, no gasta cuota real.
    static let pollingInterval: TimeInterval = 60

    let currentMatches = CurrentValueSubject<[MatchOdds]?, Never>(nil)
    let refreshErrors = PassthroughSubject<String, Never>()

    private let coordinator: LiveOddsCoordinator
    private var pollingCancellable: AnyCancellable?

    init(useCase: DetectArbitrageUseCase, sport: String = "top-leagues") {
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
