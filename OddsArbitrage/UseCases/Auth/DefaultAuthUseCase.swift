//
//  DefaultAuthUseCase.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation

final class DefaultAuthUseCase: AuthUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    var currentUser: AuthUser? { repository.currentUser }
    var authStateChanges: AnyPublisher<AuthUser?, Never> { repository.authStateChanges }

    func signIn(email: String, password: String) async throws -> AuthUser {
        try await repository.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws -> AuthUser {
        try await repository.signUp(email: email, password: password)
    }

    func signOut() throws {
        try repository.signOut()
    }
}
