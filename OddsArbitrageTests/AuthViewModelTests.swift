//
//  AuthViewModelTests.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Foundation
import FirebaseAuth
import XCTest
@testable import OddsArbitrage

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

        await sut.signIn()

        guard case .error(let message) = sut.state else {
            return XCTFail("expected .error state")
        }
        XCTAssertEqual(message, "Email o contraseña incorrectos.")
        XCTAssertFalse(sut.isAuthenticated)
    }

    func test_signUp_success_setsLoadedState() async {
        let repository = MockAuthRepository()
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))

        await sut.signUp()

        guard case .loaded = sut.state else {
            return XCTFail("expected .loaded state")
        }
        XCTAssertTrue(sut.isAuthenticated)
    }

    func test_signOut_clearsSessionAndResetsState() async {
        let repository = MockAuthRepository()
        let sut = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        await sut.signIn()

        sut.signOut()

        XCTAssertFalse(sut.isAuthenticated)
        guard case .idle = sut.state else {
            return XCTFail("expected .idle state")
        }
    }
}
