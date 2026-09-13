//
//  FirebaseAuthRepository.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Foundation
import FirebaseAuth

final class FirebaseAuthRepository: AuthRepository {
    var currentUser: AuthUser? {
        Auth.auth().currentUser.map { AuthUser(uid: $0.uid, email: $0.email) }
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthUser(uid: result.user.uid, email: result.user.email)
    }
    
    func signUp(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthUser(uid: result.user.uid, email: result.user.email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
