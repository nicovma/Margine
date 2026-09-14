//
//  DefaultAuthUseCase.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation
import UIKit

/// Client-side validation errors, surfaced before ever reaching the network —
/// this is the actual business logic that justifies `DefaultAuthUseCase`
/// existing as a layer of its own instead of the ViewModel calling
/// `AuthRepository` directly.
enum AuthValidationError: LocalizedError {
    case invalidEmailFormat
    case passwordTooShort(minimumLength: Int)

    var errorDescription: String? {
        switch self {
        case .invalidEmailFormat:
            return String(localized: "El email no es válido.")
        case .passwordTooShort(let minimumLength):
            return String(localized: "La contraseña debe tener al menos \(minimumLength) caracteres.")
        }
    }
}

final class DefaultAuthUseCase: AuthUseCase {
    private static let minimumPasswordLength = 6
    private static let emailPattern = #/^[^\s@]+@[^\s@]+\.[^\s@]+$/#

    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    var currentUser: AuthUser? { repository.currentUser }
    var authStateChanges: AnyPublisher<AuthUser?, Never> { repository.authStateChanges }

    func signIn(email: String, password: String) async throws -> AuthUser {
        try validate(email: email)
        return try await repository.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws -> AuthUser {
        try validate(email: email)
        guard password.count >= Self.minimumPasswordLength else {
            throw AuthValidationError.passwordTooShort(minimumLength: Self.minimumPasswordLength)
        }
        return try await repository.signUp(email: email, password: password)
    }

    private func validate(email: String) throws {
        guard email.wholeMatch(of: Self.emailPattern) != nil else {
            throw AuthValidationError.invalidEmailFormat
        }
    }

    func signInWithGoogle(presenting: UIViewController) async throws -> AuthUser {
        try await repository.signInWithGoogle(presenting: presenting)
    }

    func signOut() throws {
        try repository.signOut()
    }
}
