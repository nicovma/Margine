//
//  OddsListViewModelTests.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation
import XCTest
@testable import Margine

@MainActor
final class OddsListViewModelTests: XCTestCase {

    func test_init_updatesState_whenServicePublishesNewMatches() {
        let service = MockLiveOddsService(matches: [])
        let sut = OddsListViewModel(liveOddsService: service)

        service.currentMatches.send(MockDetectArbitrageUseCase.sampleMatches)

        guard case .loaded(let matches) = sut.state else {
            return XCTFail("expected .loaded state")
        }
        XCTAssertEqual(matches.count, MockDetectArbitrageUseCase.sampleMatches.count)
    }

    func test_startLiveUpdates_setsLoadingState_andStartsPolling() {
        let service = MockLiveOddsService(matches: nil)
        let sut = OddsListViewModel(liveOddsService: service)

        sut.startLiveUpdates()

        XCTAssertEqual(service.startPollingCallCount, 1)
        guard case .loading = sut.state else {
            return XCTFail("expected .loading state")
        }
    }

    func test_manualRefresh_callsRefreshNowOnService() async {
        let service = MockLiveOddsService(matches: [])
        let sut = OddsListViewModel(liveOddsService: service)

        await sut.manualRefresh()

        XCTAssertEqual(service.refreshNowCallCount, 1)
    }
    
    func test_showOnlyArbitrage_filtersOutMatchesWithoutArbitrage() {
        let service = MockLiveOddsService(matches: MockDetectArbitrageUseCase.sampleMatches)
        let sut = OddsListViewModel(liveOddsService: service)

        sut.showOnlyArbitrage = true

        guard case .loaded(let matches) = sut.state else {
            return XCTFail("expected .loaded state")
        }
        XCTAssertEqual(matches.count, 1)
        XCTAssertTrue(matches.allSatisfy(\.hasArbitrage))
    }
    
    func test_refreshError_whenAlreadyLoaded_showsBannerWithoutClearingState() {
        let service = MockLiveOddsService(matches: MockDetectArbitrageUseCase.sampleMatches)
        let sut = OddsListViewModel(liveOddsService: service)

        service.refreshErrors.send("network error")

        XCTAssertEqual(sut.bannerErrorMessage, "network error")
        guard case .loaded = sut.state else {
            return XCTFail("expected state to remain .loaded")
        }
    }

    func test_refreshError_whileLoading_setsErrorState() {
        let service = MockLiveOddsService(matches: nil)
        let sut = OddsListViewModel(liveOddsService: service)
        sut.startLiveUpdates()

        service.refreshErrors.send("network error")

        guard case .error(let message) = sut.state else {
            return XCTFail("expected .error state")
        }
        XCTAssertEqual(message, "network error")
    }
}
