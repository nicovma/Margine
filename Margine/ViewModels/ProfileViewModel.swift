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

    private let authViewModel: AuthViewModel
    private let bookmakerStore: BookmakerPreferencesStore
    private let refreshOdds: () async -> Void

    @Published private(set) var bookmakerRows: [BookmakerRow] = []

    init(authViewModel: AuthViewModel, bookmakerStore: BookmakerPreferencesStore, refreshOdds: @escaping () async -> Void) {
        self.authViewModel = authViewModel
        self.bookmakerStore = bookmakerStore
        self.refreshOdds = refreshOdds

        Publishers.CombineLatest(bookmakerStore.$knownBookmakers, bookmakerStore.$disabledKeys)
            .map { known, disabled in
                known.map { BookmakerRow(key: $0.key, title: $0.title, isEnabled: !disabled.contains($0.key)) }
            }
            .assign(to: &$bookmakerRows)
    }

    var userEmail: String? { authViewModel.currentUserEmail }

    func signOut() {
        authViewModel.signOut()
    }

    func setBookmakerEnabled(_ isEnabled: Bool, key: String) {
        bookmakerStore.setEnabled(isEnabled, for: key)
        Task { await refreshOdds() }
    }
}
