//
//  OddsListViewModel.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)
}

@MainActor
final class OddsListViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[MatchOdds]> = .idle

    private let useCase: DetectArbitrageUseCase
    private let sport: String

    init(useCase: DetectArbitrageUseCase, sport: String = "soccer_epl") {
        self.useCase = useCase
        self.sport = sport
    }

    func loadOdds() async {
        state = .loading
        do {
            let matches = try await useCase.execute(sport: sport)
            state = .loaded(matches)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
