//
//  FirebaseAuthRepository.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation
import FirebaseAuth
import GoogleSignIn
import UIKit

final class FirebaseAuthRepository: AuthRepository {
    private let authStateSubject: CurrentValueSubject<AuthUser?, Never>
    private var handle: AuthStateDidChangeListenerHandle?

    var currentUser: AuthUser? { authStateSubject.value }
    var authStateChanges: AnyPublisher<AuthUser?, Never> { authStateSubject.eraseToAnyPublisher() }

    init() {
        authStateSubject = CurrentValueSubject(Auth.auth().currentUser.map { AuthUser(uid: $0.uid, email: $0.email) })
        handle = Auth.auth().addStateDidChangeListener { [authStateSubject] _, user in
            authStateSubject.send(user.map { AuthUser(uid: $0.uid, email: $0.email) })
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        try await mappingErrors {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return AuthUser(uid: result.user.uid, email: result.user.email)
        }
    }

    func signUp(email: String, password: String) async throws -> AuthUser {
        try await mappingErrors {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return AuthUser(uid: result.user.uid, email: result.user.email)
        }
    }

    func signInWithGoogle(presenting: UIViewController) async throws -> AuthUser {
        try await mappingErrors {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.unknown
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            return AuthUser(uid: authResult.user.uid, email: authResult.user.email)
        }
    }

    func signOut() throws {
        // Clearing only the Firebase session would leave the Google SDK holding
        // the previous account, so the next Google sign-in could skip the picker.
        GIDSignIn.sharedInstance.signOut()
        do {
            try Auth.auth().signOut()
        } catch {
            throw Self.map(error)
        }
    }

    private func mappingErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            throw Self.map(error)
        }
    }

    private static func map(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        let nsError = error as NSError
        if nsError.domain == kGIDSignInErrorDomain {
            return nsError.code == GIDSignInError.Code.canceled.rawValue ? .cancelled : .unknown
        }
        guard nsError.domain == AuthErrorDomain else {
            return .unknown
        }
        switch AuthErrorCode(rawValue: nsError.code) {
        case .invalidEmail: return .invalidEmail
        case .wrongPassword, .invalidCredential, .userNotFound: return .wrongCredentials
        case .emailAlreadyInUse: return .emailAlreadyInUse
        case .weakPassword: return .weakPassword
        case .networkError: return .networkError
        case .userDisabled: return .userDisabled
        case .tooManyRequests: return .tooManyRequests
        default: return .unknown
        }
    }
}
