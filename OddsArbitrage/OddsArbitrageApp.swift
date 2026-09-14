//
//  OddsArbitrageApp.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import SwiftUI
import FirebaseCore

@main
struct OddsArbitrageApp: App {
    @StateObject private var authViewModel: AuthViewModel
    private let oddsListViewModel: OddsListViewModel

    init() {
        FirebaseApp.configure()
        let authRepository = FirebaseAuthRepository()
        if ProcessInfo.processInfo.arguments.contains("--uitesting-signed-out") {
            try? authRepository.signOut()
        }
        let authUseCase = DefaultAuthUseCase(repository: authRepository)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authUseCase: authUseCase))

        let apiKey = Bundle.main.object(forInfoDictionaryKey: "ODDS_API_KEY") as? String ?? ""
        let networkService = URLSessionNetworkService()
        let repository = DefaultOddsRepository(networkService: networkService, apiKey: apiKey)
        let useCase = DefaultDetectArbitrageUseCase(repository: repository)
        let liveOddsService = LiveOddsService(useCase: useCase)
        oddsListViewModel = OddsListViewModel(liveOddsService: liveOddsService)
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                OddsListView(viewModel: oddsListViewModel)
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
    }
}
