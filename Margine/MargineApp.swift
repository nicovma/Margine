//
//  MargineApp.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import SwiftUI
import FirebaseCore
import FirebaseCrashlytics
import GoogleSignIn

@main
struct MargineApp: App {
    @StateObject private var authViewModel: AuthViewModel
    private let oddsListViewModel: OddsListViewModel
    private let profileViewModel: ProfileViewModel
    private let bookmakerPreferencesStore: BookmakerPreferencesStore

    init() {
        FirebaseApp.configure()
        let isUITestingSignedOut = ProcessInfo.processInfo.arguments.contains("--uitesting-signed-out")
        // No mandar crashes ni eventos de las corridas de UI tests a Firebase.
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(!isUITestingSignedOut)
        let analytics: AnalyticsLogging = isUITestingSignedOut ? NoOpAnalyticsLogger() : FirebaseAnalyticsLogger()

        let authRepository = FirebaseAuthRepository()
        if isUITestingSignedOut {
            try? authRepository.signOut()
        }
        let authUseCase = DefaultAuthUseCase(repository: authRepository)
        let authViewModel = AuthViewModel(authUseCase: authUseCase, analytics: analytics)
        _authViewModel = StateObject(wrappedValue: authViewModel)

        let bookmakerPreferencesStore = BookmakerPreferencesStore()
        self.bookmakerPreferencesStore = bookmakerPreferencesStore

        let useCase: DetectArbitrageUseCase
        if isUITestingSignedOut {
            // UI tests only need the screen to have *some* matches on it, not real
            // odds — hitting the real API on every test run burns through its
            // (very tight) free-tier quota for no benefit.
            useCase = MockDetectArbitrageUseCase()
        } else {
            let networkService = URLSessionNetworkService()
            let repository = DefaultOddsRepository(
                networkService: networkService,
                baseURL: "https://margine-odds-worker.margine-app.workers.dev"
            )
            useCase = DefaultDetectArbitrageUseCase(repository: repository, preferences: bookmakerPreferencesStore)
        }
        let liveOddsService = LiveOddsService(useCase: useCase)
        let oddsListViewModel = OddsListViewModel(liveOddsService: liveOddsService, analytics: analytics)
        self.oddsListViewModel = oddsListViewModel

        profileViewModel = ProfileViewModel(
            authViewModel: authViewModel,
            bookmakerStore: bookmakerPreferencesStore,
            refreshOdds: { await oddsListViewModel.manualRefresh() }
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView(oddsListViewModel: oddsListViewModel, profileViewModel: profileViewModel)
                } else {
                    LoginView(viewModel: authViewModel)
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
