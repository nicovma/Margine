//
//  ProfileViewModel.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    struct BookmakerRow: Identifiable, Hashable {
        let key: String
        let title: String
        let isEnabled: Bool

        var id: String { key }
    }

    private let authUseCase: AuthUseCase
    private let bookmakerStore: BookmakerPreferencesManaging
    private let refreshOdds: () async -> Void

    @Published private(set) var bookmakerRows: [BookmakerRow] = []
    @Published var errorMessage: String?

    init(authUseCase: AuthUseCase, bookmakerStore: BookmakerPreferencesManaging, refreshOdds: @escaping () async -> Void) {
        self.authUseCase = authUseCase
        self.bookmakerStore = bookmakerStore
        self.refreshOdds = refreshOdds

        Publishers.CombineLatest(bookmakerStore.knownBookmakersPublisher, bookmakerStore.disabledKeysPublisher)
            .map { known, disabled in
                known.map { BookmakerRow(key: $0.key, title: $0.title, isEnabled: !disabled.contains($0.key)) }
            }
            .assign(to: &$bookmakerRows)
    }

    var userEmail: String? { authUseCase.currentUser?.email }

    /// The session gate (`AuthViewModel.isAuthenticated`) observes the same
    /// auth state stream, so a successful sign-out swaps back to the login
    /// screen on its own — this only has to surface a failure.
    func signOut() {
        do {
            try authUseCase.signOut()
        } catch {
            errorMessage = String(localized: "No se pudo cerrar la sesión. Intentá de nuevo.")
        }
    }

    func setBookmakerEnabled(_ isEnabled: Bool, key: String) {
        bookmakerStore.setEnabled(isEnabled, for: key)
        Task { await refreshOdds() }
    }
}
