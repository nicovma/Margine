//
//  OddsListViewModel.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation
import Combine

enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)
}

@MainActor
final class OddsListViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[MatchOdds]> = .idle
    @Published var showOnlyArbitrage = false
    @Published var searchText = ""
    @Published var bannerErrorMessage: String?

    private let liveOddsService: LiveOddsServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(liveOddsService: LiveOddsServiceProtocol) {
        self.liveOddsService = liveOddsService

        let immediateSearch = Just(searchText)
        let debouncedSearch = $searchText
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        let searchPublisher = immediateSearch.merge(with: debouncedSearch)

        liveOddsService.currentMatches
            .combineLatest($showOnlyArbitrage, searchPublisher)
            .compactMap { matches, showOnlyArbitrage, searchText -> [MatchOdds]? in
                guard let matches else { return nil }
                var filtered = showOnlyArbitrage ? matches.filter(\.hasArbitrage) : matches
                if !searchText.isEmpty {
                    filtered = filtered.filter {
                        $0.homeTeam.localizedCaseInsensitiveContains(searchText) ||
                        $0.awayTeam.localizedCaseInsensitiveContains(searchText)
                    }
                }
                return filtered
            }
            .sink { [weak self] filtered in
                self?.state = .loaded(filtered)
            }
            .store(in: &cancellables)
        
        liveOddsService.refreshErrors
            .sink { [weak self] message in
                self?.handleRefreshError(message)
            }
            .store(in: &cancellables)
    }

    func startLiveUpdates() {
        if case .loaded = state {} else {
            state = .loading
        }
        liveOddsService.startPolling()
    }

    func stopLiveUpdates() {
        liveOddsService.stopPolling()
    }

    func manualRefresh() async {
        await liveOddsService.refreshNow()
    }
    
    private func handleRefreshError(_ message: String) {
        switch state {
        case .loaded:
            bannerErrorMessage = message // ya hay datos en pantalla, no los pisamos
        case .idle, .loading, .error:
            state = .error(message) // no hay nada que mostrar todavía
        }
    }
}
