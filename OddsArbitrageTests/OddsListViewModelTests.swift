//
//  OddsListViewModelTests.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation
import XCTest
@testable import OddsArbitrage

@MainActor
final class OddsListViewModelTests: XCTestCase {
    
    func test_loadOdds_setsLoadedState_onSuccess() async {
        let mock = MockDetectArbitrageUseCase()
        mock.result = .success(MockDetectArbitrageUseCase.sampleMatches)
        let sut = OddsListViewModel(useCase: mock)
        
        await sut.loadOdds()
        
        guard case .loaded(let matches) = sut.state else {
            return XCTFail("expected .loaded state")
        }
        XCTAssertEqual(matches.count, MockDetectArbitrageUseCase.sampleMatches.count)
    }
    
    func test_loadOdds_setsErrorState_onFailure() async {
        let mock = MockDetectArbitrageUseCase()
        mock.result = .failure(URLError(.badServerResponse))
        let sut = OddsListViewModel(useCase: mock)

        await sut.loadOdds()

        guard case .error = sut.state else {
            return XCTFail("expected .error state")
        }
    }
}
