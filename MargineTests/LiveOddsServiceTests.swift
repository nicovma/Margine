//
//  LiveOddsServiceTests.swift
//  Margine
//
//  Created by Nicolas Valentini on 14/9/2026.
//
import XCTest
@testable import Margine

@MainActor
final class LiveOddsServiceTests: XCTestCase {

    func test_refreshNow_success_publishesMatchesToCurrentMatches() async {
        let mock = MockDetectArbitrageUseCase()
        mock.result = .success(MockDetectArbitrageUseCase.sampleMatches)
        let sut = LiveOddsService(useCase: mock)

        await sut.refreshNow()

        XCTAssertEqual(sut.currentMatches.value?.count, MockDetectArbitrageUseCase.sampleMatches.count)
    }

    func test_refreshNow_failure_publishesToRefreshErrors_withoutTouchingCurrentMatches() async {
        let mock = MockDetectArbitrageUseCase()
        mock.result = .failure(StubError())
        let sut = LiveOddsService(useCase: mock)

        var receivedMessage: String?
        let cancellable = sut.refreshErrors.sink { receivedMessage = $0 }

        await sut.refreshNow()
        cancellable.cancel()

        XCTAssertEqual(receivedMessage, StubError().errorDescription)
        XCTAssertNil(sut.currentMatches.value)
    }
}

private struct StubError: LocalizedError, Equatable {
    var errorDescription: String? { "stub network failure" }
}
