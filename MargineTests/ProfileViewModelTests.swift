//
//  ProfileViewModelTests.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import XCTest
@testable import Margine

@MainActor
final class ProfileViewModelTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "ProfileViewModelTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeSUT(
        repository: MockAuthRepository = MockAuthRepository(),
        store: BookmakerPreferencesStore? = nil,
        refreshOdds: @escaping () async -> Void = {}
    ) -> ProfileViewModel {
        ProfileViewModel(
            authUseCase: DefaultAuthUseCase(repository: repository),
            bookmakerStore: store ?? BookmakerPreferencesStore(defaults: defaults),
            refreshOdds: refreshOdds
        )
    }

    func test_userEmail_reflectsCurrentAuthenticatedUser() {
        let repository = MockAuthRepository(currentUser: AuthUser(uid: "uid", email: "test@test.com"))
        let sut = makeSUT(repository: repository)

        XCTAssertEqual(sut.userEmail, "test@test.com")
    }

    func test_userEmail_isNil_whenNotAuthenticated() {
        let sut = makeSUT()

        XCTAssertNil(sut.userEmail)
    }

    func test_signOut_endsSessionThroughUseCase() {
        let repository = MockAuthRepository(currentUser: AuthUser(uid: "uid", email: "test@test.com"))
        let sut = makeSUT(repository: repository)

        sut.signOut()

        XCTAssertEqual(repository.signOutCallCount, 1)
        XCTAssertNil(repository.currentUser)
        XCTAssertNil(sut.errorMessage)
    }

    func test_signOut_failure_setsErrorMessage_andKeepsSession() {
        let repository = MockAuthRepository(currentUser: AuthUser(uid: "uid", email: "test@test.com"))
        repository.signOutError = SignOutStubError()
        let sut = makeSUT(repository: repository)

        sut.signOut()

        XCTAssertEqual(sut.errorMessage, "No se pudo cerrar la sesión. Intentá de nuevo.")
        XCTAssertEqual(sut.userEmail, "test@test.com")
    }

    func test_signOut_switchesSessionGateBackToLogin() async {
        let repository = MockAuthRepository()
        let authViewModel = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        authViewModel.email = "test@test.com"
        authViewModel.password = "123456"
        await authViewModel.signIn()
        XCTAssertTrue(authViewModel.isAuthenticated, "precondition: sign-in should have succeeded")
        let sut = makeSUT(repository: repository)

        sut.signOut()

        XCTAssertFalse(authViewModel.isAuthenticated)
        guard case .idle = authViewModel.state else {
            return XCTFail("expected AuthViewModel to drop its stale .loaded state")
        }
    }

    func test_bookmakerRows_reflectsKnownBookmakersAndEnabledState() {
        let store = BookmakerPreferencesStore(defaults: defaults)
        store.recordSeen([
            Bookmaker(key: "bet365", title: "Bet365", markets: []),
            Bookmaker(key: "betfair", title: "Betfair", markets: [])
        ])
        store.setEnabled(false, for: "betfair")
        let sut = makeSUT(store: store)

        XCTAssertEqual(
            Set(sut.bookmakerRows),
            Set([
                ProfileViewModel.BookmakerRow(key: "bet365", title: "Bet365", isEnabled: true),
                ProfileViewModel.BookmakerRow(key: "betfair", title: "Betfair", isEnabled: false)
            ])
        )
    }

    func test_setBookmakerEnabled_updatesStore_andTriggersRefresh() async {
        let store = BookmakerPreferencesStore(defaults: defaults)
        store.recordSeen([Bookmaker(key: "bet365", title: "Bet365", markets: [])])
        let refreshCalled = expectation(description: "refreshOdds called")
        let sut = makeSUT(store: store, refreshOdds: {
            refreshCalled.fulfill()
        })

        sut.setBookmakerEnabled(false, key: "bet365")

        XCTAssertFalse(store.isEnabled("bet365"))
        XCTAssertEqual(sut.bookmakerRows.first?.isEnabled, false)
        await fulfillment(of: [refreshCalled], timeout: 1)
    }
}

private struct SignOutStubError: Error {}
