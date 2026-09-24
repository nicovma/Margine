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
        authViewModel: AuthViewModel,
        refreshOdds: @escaping () async -> Void = {}
    ) -> ProfileViewModel {
        ProfileViewModel(
            authViewModel: authViewModel,
            bookmakerStore: BookmakerPreferencesStore(defaults: defaults),
            refreshOdds: refreshOdds
        )
    }

    func test_userEmail_reflectsCurrentAuthenticatedUser() async {
        let repository = MockAuthRepository()
        let authViewModel = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        authViewModel.email = "test@test.com"
        authViewModel.password = "123456"
        await authViewModel.signIn()
        let sut = makeSUT(authViewModel: authViewModel)

        XCTAssertEqual(sut.userEmail, "test@test.com")
    }

    func test_userEmail_isNil_whenNotAuthenticated() {
        let repository = MockAuthRepository()
        let authViewModel = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        let sut = makeSUT(authViewModel: authViewModel)

        XCTAssertNil(sut.userEmail)
    }

    func test_signOut_delegatesToAuthViewModel() async {
        let repository = MockAuthRepository()
        let authViewModel = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: repository))
        authViewModel.email = "test@test.com"
        authViewModel.password = "123456"
        await authViewModel.signIn()
        XCTAssertTrue(authViewModel.isAuthenticated, "precondition: sign-in should have succeeded")
        let sut = makeSUT(authViewModel: authViewModel)

        sut.signOut()

        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertEqual(repository.signOutCallCount, 1)
    }

    func test_bookmakerRows_reflectsKnownBookmakersAndEnabledState() {
        let store = BookmakerPreferencesStore(defaults: defaults)
        store.recordSeen([
            Bookmaker(key: "bet365", title: "Bet365", markets: []),
            Bookmaker(key: "betfair", title: "Betfair", markets: [])
        ])
        store.setEnabled(false, for: "betfair")
        let authViewModel = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: MockAuthRepository()))
        let sut = ProfileViewModel(authViewModel: authViewModel, bookmakerStore: store, refreshOdds: {})

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
        let authViewModel = AuthViewModel(authUseCase: DefaultAuthUseCase(repository: MockAuthRepository()))
        let refreshCalled = expectation(description: "refreshOdds called")
        let sut = ProfileViewModel(authViewModel: authViewModel, bookmakerStore: store, refreshOdds: {
            refreshCalled.fulfill()
        })

        sut.setBookmakerEnabled(false, key: "bet365")

        XCTAssertFalse(store.isEnabled("bet365"))
        XCTAssertEqual(sut.bookmakerRows.first?.isEnabled, false)
        await fulfillment(of: [refreshCalled], timeout: 1)
    }
}
