//
//  OddsArbitrageApp.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//

import SwiftUI

@main
struct OddsArbitrageApp: App {
    var body: some Scene {
        WindowGroup {
            OddsListView(viewModel: makeViewModel())
        }
    }

    private func makeViewModel() -> OddsListViewModel {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "ODDS_API_KEY") as? String ?? ""
        let networkService = URLSessionNetworkService()
        let repository = DefaultOddsRepository(networkService: networkService, apiKey: apiKey)
        let useCase = DefaultDetectArbitrageUseCase(repository: repository)
        let liveOddsService = LiveOddsService(useCase: useCase)
        return OddsListViewModel(liveOddsService: liveOddsService)
    }
}
