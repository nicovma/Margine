//
//  DefaultAuthUseCaseTests.swift
//  Margine
//

import Foundation
import Testing
@testable import Margine

struct DefaultAuthUseCaseTests {

    @Test("Sign in exitoso devuelve el usuario del repository")
    func signInSuccessReturnsUser() async throws {
        let repository = MockAuthRepository()
        repository.signInResult = .success(AuthUser(uid: "mock-uid", email: "test@test.com"))
        let sut = DefaultAuthUseCase(repository: repository)

        let user = try await sut.signIn(email: "test@test.com", password: "123456")

        #expect(user.email == "test@test.com")
    }

    @Test("Email inválido lanza invalidEmailFormat sin llegar al repository")
    func signInInvalidEmailThrowsValidationError() async throws {
        let repository = MockAuthRepository()
        repository.signInResult = .failure(NSError(domain: "should-not-be-called", code: 0))
        let sut = DefaultAuthUseCase(repository: repository)

        let error = try await #require(throws: AuthValidationError.self) {
            try await sut.signIn(email: "not-an-email", password: "123456")
        }
        guard case .invalidEmailFormat = error else {
            Issue.record("Se esperaba .invalidEmailFormat, se obtuvo \(error)")
            return
        }
    }

    @Test("Contraseña corta en sign up lanza passwordTooShort sin llegar al repository")
    func signUpPasswordTooShortThrowsValidationError() async throws {
        let repository = MockAuthRepository()
        repository.signUpResult = .failure(NSError(domain: "should-not-be-called", code: 0))
        let sut = DefaultAuthUseCase(repository: repository)

        let error = try await #require(throws: AuthValidationError.self) {
            try await sut.signUp(email: "test@test.com", password: "123")
        }
        guard case .passwordTooShort(let minimumLength) = error else {
            Issue.record("Se esperaba .passwordTooShort, se obtuvo \(error)")
            return
        }
        #expect(minimumLength == 6)
    }

    @Test("Error del repository en sign in se propaga sin modificarse")
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
