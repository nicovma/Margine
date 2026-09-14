//
//  AuthViewModel.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation
import FirebaseAuth
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published private(set) var state: ViewState<AuthUser> = .idle
    @Published private(set) var isAuthenticated: Bool

    private let authUseCase: AuthUseCase
    private var cancellables = Set<AnyCancellable>()

    var currentUserEmail: String? { authUseCase.currentUser?.email }

    init(authUseCase: AuthUseCase) {
        self.authUseCase = authUseCase
        self.isAuthenticated = authUseCase.currentUser != nil

        authUseCase.authStateChanges
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak self] in self?.isAuthenticated = $0 }
            .store(in: &cancellables)
    }

    func signIn() async {
        state = .loading
        do {
            let user = try await authUseCase.signIn(email: email, password: password)
            state = .loaded(user)
        } catch {
            state = .error(mapError(error))
        }
    }

    func signUp() async {
        state = .loading
        do {
            let user = try await authUseCase.signUp(email: email, password: password)
            state = .loaded(user)
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

    func signOut() {
        do {
            try authUseCase.signOut()
            state = .idle
        } catch {
            state = .error(String(localized: "No se pudo cerrar la sesión. Intentá de nuevo."))
        }
    }

    private func mapError(_ error: Error) -> String {
        if let validationError = error as? AuthValidationError {
            return validationError.errorDescription ?? String(localized: "Ocurrió un error. Intentá de nuevo.")
        }
        let nsError = error as NSError
        switch AuthErrorCode(rawValue: nsError.code) {
        case .invalidEmail: return String(localized: "El email no es válido.")
        case .wrongPassword, .invalidCredential: return String(localized: "Email o contraseña incorrectos.")
        case .emailAlreadyInUse: return String(localized: "Ya existe una cuenta con ese email.")
        case .weakPassword: return String(localized: "La contraseña es muy débil (mínimo 6 caracteres).")
        case .networkError: return String(localized: "Sin conexión. Probá de nuevo.")
        case .userNotFound: return String(localized: "Email o contraseña incorrectos.")
        case .userDisabled: return String(localized: "Esta cuenta fue deshabilitada.")
        case .tooManyRequests: return String(localized: "Demasiados intentos. Esperá un momento y probá de nuevo.")
        default: return String(localized: "Ocurrió un error. Intentá de nuevo.")
        }
    }
}
