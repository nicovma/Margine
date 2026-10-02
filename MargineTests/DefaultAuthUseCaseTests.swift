//
//  DefaultAuthUseCaseTests.swift
//  Margine
//

import Foundation
import Testing
@testable import Margine

struct DefaultAuthUseCaseTests {

    @Test("Successful sign in returns the repository user")
    func signInSuccessReturnsUser() async throws {
        let repository = MockAuthRepository()
        repository.signInResult = .success(AuthUser(uid: "mock-uid", email: "test@test.com"))
        let sut = DefaultAuthUseCase(repository: repository)

        let user = try await sut.signIn(email: "test@test.com", password: "123456")

        #expect(user.email == "test@test.com")
    }

    @Test("Invalid email throws invalidEmailFormat without reaching the repository")
    func signInInvalidEmailThrowsValidationError() async throws {
        let repository = MockAuthRepository()
        repository.signInResult = .failure(NSError(domain: "should-not-be-called", code: 0))
        let sut = DefaultAuthUseCase(repository: repository)

        let error = try await #require(throws: AuthValidationError.self) {
            try await sut.signIn(email: "not-an-email", password: "123456")
        }
        guard case .invalidEmailFormat = error else {
            Issue.record("Expected .invalidEmailFormat, got \(error)")
            return
        }
    }

    @Test("Short password on sign up throws passwordTooShort without reaching the repository")
    func signUpPasswordTooShortThrowsValidationError() async throws {
        let repository = MockAuthRepository()
        repository.signUpResult = .failure(NSError(domain: "should-not-be-called", code: 0))
        let sut = DefaultAuthUseCase(repository: repository)

        let error = try await #require(throws: AuthValidationError.self) {
            try await sut.signUp(email: "test@test.com", password: "123")
        }
        guard case .passwordTooShort(let minimumLength) = error else {
            Issue.record("Expected .passwordTooShort, got \(error)")
            return
        }
        #expect(minimumLength == 6)
    }

    @Test("A repository error on sign in propagates unchanged")
    func signInPropagatesRepositoryError() async throws {
        let repository = MockAuthRepository()
        let repositoryError = NSError(domain: "FIRAuthErrorDomain", code: 17009)
        repository.signInResult = .failure(repositoryError)
        let sut = DefaultAuthUseCase(repository: repository)

        let error = try await #require(throws: NSError.self) {
            try await sut.signIn(email: "test@test.com", password: "wrongpassword")
        }
        #expect(error.domain == repositoryError.domain)
        #expect(error.code == repositoryError.code)
    }
}
