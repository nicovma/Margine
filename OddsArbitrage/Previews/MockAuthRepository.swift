//
//  MockAuthRepository.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation

final class MockAuthRepository: AuthRepository {
    private let authStateSubject: CurrentValueSubject<AuthUser?, Never>
    var signInResult: Result<AuthUser, Error> = .success(AuthUser(uid: "mock-uid", email: "test@test.com"))
    var signUpResult: Result<AuthUser, Error> = .success(AuthUser(uid: "mock-uid", email: "test@test.com"))
    private(set) var signOutCallCount = 0

    var currentUser: AuthUser? {
        get { authStateSubject.value }
        set { authStateSubject.send(newValue) }
    }
    var authStateChanges: AnyPublisher<AuthUser?, Never> { authStateSubject.eraseToAnyPublisher() }

    init(currentUser: AuthUser? = nil) {
        authStateSubject = CurrentValueSubject(currentUser)
    }

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
