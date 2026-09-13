//
//  MockAuthRepository.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Foundation

final class MockAuthRepository: AuthRepository {
    var currentUser: AuthUser?
    var signInResult: Result<AuthUser, Error> = .success(AuthUser(uid: "mock-uid", email: "test@test.com"))
    var signUpResult: Result<AuthUser, Error> = .success(AuthUser(uid: "mock-uid", email: "test@test.com"))
    private(set) var signOutCallCount = 0

    func signIn(email: String, password: String) async throws -> AuthUser {
        let user = try signInResult.get()
        currentUser = user
        return user
    }

    func signUp(email: String, password: String) async throws -> AuthUser {
        let user = try signUpResult.get()
        currentUser = user
        return user
    }

    func signOut() throws {
        signOutCallCount += 1
        currentUser = nil
    }
}
