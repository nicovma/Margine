//
//  AuthViewModelTests.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Foundation
import FirebaseAuth
import XCTest
@testable import Margine

@MainActor
final class AuthViewModelTests: XCTestCase {

    func test_signIn_success_setsLoadedState() async {
        let repository = MockAuthRepository()
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        sut.email = "test@test.com"
        sut.password = "123456"

        await sut.signIn()

        guard case .loaded(let user) = sut.state else {
            return XCTFail("expected .loaded state")
        }
        XCTAssertEqual(user.email, "test@test.com")
        XCTAssertTrue(sut.isAuthenticated)
    }

    func test_signIn_failure_setsErrorState() async {
        let repository = MockAuthRepository()
         repository.signInResult = .failure(NSError(domain: "FIRAuthErrorDomain", code: AuthErrorCode.wrongPassword.rawValue))
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        sut.email = "test@test.com"
        sut.password = "wrongpassword"

        await sut.signIn()

        guard case .error(let message) = sut.state else {
            return XCTFail("expected .error state")
        }
        XCTAssertEqual(message, "Email o contraseña incorrectos.")
        XCTAssertFalse(sut.isAuthenticated)
    }

    func test_signIn_invalidEmailFormat_setsErrorState_withoutCallingRepository() async {
        let repository = MockAuthRepository()
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        sut.email = "not-an-email"
        sut.password = "123456"

        await sut.signIn()

        guard case .error(let message) = sut.state else {
            return XCTFail("expected .error state")
        }
        XCTAssertEqual(message, "El email no es válido.")
        XCTAssertFalse(sut.isAuthenticated)
    }

    func test_signUp_success_setsLoadedState() async {
        let repository = MockAuthRepository()
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        sut.email = "test@test.com"
        sut.password = "123456"

        await sut.signUp()

        guard case .loaded = sut.state else {
            return XCTFail("expected .loaded state")
        }
        XCTAssertTrue(sut.isAuthenticated)
    }

    func test_signUp_passwordTooShort_setsErrorState_withoutCallingRepository() async {
        let repository = MockAuthRepository()
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        sut.email = "test@test.com"
        sut.password = "123"

        await sut.signUp()

        guard case .error(let message) = sut.state else {
            return XCTFail("expected .error state")
        }
        XCTAssertEqual(message, "La contraseña debe tener al menos 6 caracteres.")
        XCTAssertFalse(sut.isAuthenticated)
    }

    func test_signInWithGoogle_success_setsLoadedState() async {
        let repository = MockAuthRepository()
        repository.signInWithGoogleResult = .success(AuthUser(uid: "google-uid", email: "nico@gmail.com"))
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))

        await sut.signInWithGoogle()

        guard case .loaded(let user) = sut.state else {
            return XCTFail("expected .loaded state")
        }
        XCTAssertEqual(user.email, "nico@gmail.com")
        XCTAssertTrue(sut.isAuthenticated)
    }

    func test_signInWithGoogle_failure_setsErrorState() async {
        let repository = MockAuthRepository()
        repository.signInWithGoogleResult = .failure(NSError(domain: "FIRAuthErrorDomain", code: AuthErrorCode.networkError.rawValue))
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))

        await sut.signInWithGoogle()

        guard case .error = sut.state else {
            return XCTFail("expected .error state")
        }
        XCTAssertFalse(sut.isAuthenticated)
    }

    func test_signOut_clearsSessionAndResetsState() async {
        let repository = MockAuthRepository()
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        sut.email = "test@test.com"
        sut.password = "123456"
        await sut.signIn()
        XCTAssertTrue(sut.isAuthenticated, "precondition: sign-in should have succeeded")

        sut.signOut()

        XCTAssertFalse(sut.isAuthenticated)
        guard case .idle = sut.state else {
            return XCTFail("expected .idle state")
        }
    }
}
