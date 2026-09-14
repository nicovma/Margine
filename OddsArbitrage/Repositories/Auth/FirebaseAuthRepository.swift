//
//  FirebaseAuthRepository.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation
import FirebaseAuth
import GoogleSignIn
import UIKit

enum FirebaseAuthRepositoryError: Error {
    case missingGoogleIDToken
}

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
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthUser(uid: result.user.uid, email: result.user.email)
    }
    
    func signUp(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthUser(uid: result.user.uid, email: result.user.email)
    }

    func signInWithGoogle(presenting: UIViewController) async throws -> AuthUser {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        guard let idToken = result.user.idToken?.tokenString else {
            throw FirebaseAuthRepositoryError.missingGoogleIDToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        return AuthUser(uid: authResult.user.uid, email: authResult.user.email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
