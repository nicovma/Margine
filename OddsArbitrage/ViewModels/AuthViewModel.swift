//
//  AuthViewModel.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published private(set) var state: ViewState<AuthUser> = .idle
    @Published private(set) var isAuthenticated: Bool

    private let authUseCase: AuthUseCase
    private var cancellables = Set<AnyCancellable>()

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

    func signOut() {
        do {
            try authUseCase.signOut()
        } catch {
            print("AuthViewModel.signOut failed: \(error)")
        }
        state = .idle
    }

    private func mapError(_ error: Error) -> String {
        let nsError = error as NSError
        switch AuthErrorCode(rawValue: nsError.code) {
        case .invalidEmail: return "El email no es válido."
        case .wrongPassword, .invalidCredential: return "Email o contraseña incorrectos."
        case .emailAlreadyInUse: return "Ya existe una cuenta con ese email."
        case .weakPassword: return "La contraseña es muy débil (mínimo 6 caracteres)."
        case .networkError: return "Sin conexión. Probá de nuevo."
        default: return "Ocurrió un error. Intentá de nuevo."
        }
    }
}
