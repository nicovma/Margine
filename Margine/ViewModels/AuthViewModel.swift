//
//  AuthViewModel.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published private(set) var state: ViewState<AuthUser> = .idle
    @Published private(set) var isAuthenticated: Bool

    private let authUseCase: AuthUseCase
    private let analytics: AnalyticsLogging
    private var cancellables = Set<AnyCancellable>()

    init(authUseCase: AuthUseCase, analytics: AnalyticsLogging = NoOpAnalyticsLogger()) {
        self.authUseCase = authUseCase
        self.analytics = analytics
        self.isAuthenticated = authUseCase.currentUser != nil

        authUseCase.authStateChanges
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
                // Signing out can happen outside this ViewModel (Profile tab),
                // so a stale `.loaded` session state must not survive it.
                if !isAuthenticated { self?.state = .idle }
            }
            .store(in: &cancellables)
    }

    func signIn() async {
        state = .loading
        do {
            let user = try await authUseCase.signIn(email: email, password: password)
            state = .loaded(user)
            analytics.logLogin(method: "password")
        } catch {
            state = .error(mapError(error))
        }
    }

    func signUp() async {
        state = .loading
        do {
            let user = try await authUseCase.signUp(email: email, password: password)
            state = .loaded(user)
            analytics.logLogin(method: "password_signup")
        } catch {
            state = .error(mapError(error))
        }
    }

    func signInWithGoogle() async {
        guard let presenter = Self.topViewController() else {
            state = .error(String(localized: "No se pudo abrir el selector de cuentas de Google."))
            return
        }
        state = .loading
        do {
            let user = try await authUseCase.signInWithGoogle(presenting: presenter)
            state = .loaded(user)
            analytics.logLogin(method: "google")
        } catch AuthError.cancelled {
            state = .idle
        } catch {
            state = .error(mapError(error))
        }
    }

    private static func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

    private func mapError(_ error: Error) -> String {
        if let validationError = error as? AuthValidationError {
            return validationError.errorDescription ?? String(localized: "Ocurrió un error. Intentá de nuevo.")
        }
        switch error as? AuthError {
        case .invalidEmail: return String(localized: "El email no es válido.")
        case .wrongCredentials: return String(localized: "Email o contraseña incorrectos.")
        case .emailAlreadyInUse: return String(localized: "Ya existe una cuenta con ese email.")
        case .weakPassword: return String(localized: "La contraseña es muy débil (mínimo 6 caracteres).")
        case .networkError: return String(localized: "Sin conexión. Probá de nuevo.")
        case .userDisabled: return String(localized: "Esta cuenta fue deshabilitada.")
        case .tooManyRequests: return String(localized: "Demasiados intentos. Esperá un momento y probá de nuevo.")
        default: return String(localized: "Ocurrió un error. Intentá de nuevo.")
        }
    }
}
