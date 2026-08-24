//
//  DetectArbitrageUseCaseTests.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation
import XCTest
@testable import OddsArbitrage

final class DetectArbitrageUseCaseTests: XCTestCase {
    
    func test_execute_returnsNoArbitrage_whenImpliedProbabilitySumIsAboveOne() async throws {
        let event = makeEvent(bookmakers: [
            makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.10), ("Draw", 3.40), ("Chelsea", 3.20)]),
            makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.30), ("Draw", 3.30), ("Chelsea", 3.10)]),
            makeBookmaker(title: "Pinnacle", outcomes: [("Arsenal", 2.00), ("Draw", 3.50), ("Chelsea", 3.40)])
        ])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))
        
        let result = try await sut.execute(sport: "soccer_epl")
        
        XCTAssertFalse(result[0].hasArbitrage)
        XCTAssertNil(result[0].arbitrageMargin)
    }
    
    func test_execute_detectsArbitrage_whenImpliedProbabilitySumIsBelowOne() async throws {
        let event = makeEvent(bookmakers: [
            makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.50), ("Draw", 3.60), ("Chelsea", 3.90)]),
            makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.60), ("Draw", 3.70), ("Chelsea", 4.00)])
        ])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))
        
        let result = try await sut.execute(sport: "soccer_epl")
        
        XCTAssertTrue(result[0].hasArbitrage)
        let margin = try XCTUnwrap(result[0].arbitrageMargin)
        XCTAssertGreaterThan(margin, 0)
    }
    
    func test_execute_keepsFirstBookmaker_whenOddsAreTied() async throws {
        let event = makeEvent(bookmakers: [
            makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.50), ("Draw", 3.40), ("Chelsea", 3.20)]),
            makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.50), ("Draw", 3.40), ("Chelsea", 3.20)])
        ])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))
        
        let result = try await sut.execute(sport: "soccer_epl")
        
        XCTAssertEqual(result[0].bestOutcomes["Arsenal"]?.bookmakerTitle, "Bet365")
    }
    
    // MARK: - Helpers

    private func makeEvent(bookmakers: [Bookmaker]) -> OddsEvent {
        OddsEvent(id: "event-1", sportKey: "soccer_epl", commenceTime: .now,
                  homeTeam: "Arsenal", awayTeam: "Chelsea", bookmakers: bookmakers)
    }

    private func makeBookmaker(title: String, outcomes: [(String, Double)]) -> Bookmaker {
        Bookmaker(key: title.lowercased(), title: title,
                  markets: [Market(key: "h2h", outcomes: outcomes.map { Outcome(name: $0.0, price: $0.1) })])
    }
}

private final class StubOddsRepository: OddsRepository {
    let events: [OddsEvent]
    init(events: [OddsEvent]) { self.events = events }
    func fetchUpcomingOdds(sport: String) async throws -> [OddsEvent] { events }
}
