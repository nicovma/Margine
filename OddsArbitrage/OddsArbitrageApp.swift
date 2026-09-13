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

    init() {
        FirebaseApp.configure()
        let authRepository = FirebaseAuthRepository()
        if ProcessInfo.processInfo.arguments.contains("--uitesting-signed-out") {
            try? authRepository.signOut()
        }
        let authUseCase = DefaultAuthUseCase(repository: authRepository)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authUseCase: authUseCase))
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                OddsListView(viewModel: makeOddsListViewModel())
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
    }

    private func makeOddsListViewModel() -> OddsListViewModel {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "ODDS_API_KEY") as? String ?? ""
        let networkService = URLSessionNetworkService()
        let repository = DefaultOddsRepository(networkService: networkService, apiKey: apiKey)
        let useCase = DefaultDetectArbitrageUseCase(repository: repository)
        let liveOddsService = LiveOddsService(useCase: useCase)
        return OddsListViewModel(liveOddsService: liveOddsService)
    }
}
