//
//  DetectArbitrageUseCaseTests.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation
import Testing
@testable import Margine

struct DetectArbitrageUseCaseTests {
    
    @Test("No arbitrage when the implied probability sum exceeds 100%")
    func noArbitrageWhenSumAboveOne() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.10), ("Draw", 3.40), ("Chelsea", 3.20)]),
            Self.makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.30), ("Draw", 3.30), ("Chelsea", 3.10)]),
            Self.makeBookmaker(title: "Pinnacle", outcomes: [("Arsenal", 2.00), ("Draw", 3.50), ("Chelsea", 3.40)])
        ])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))
        
        let result = try await sut.execute(sport: "soccer_epl")
        
        #expect(result[0].hasArbitrage == false)
        #expect(result[0].arbitrageMargin == nil)
    }
    
    @Test("No bookmakers means no arbitrage and no margin")
    func noArbitrageWhenNoBookmakers() async throws {
        let event = Self.makeEvent(bookmakers: [])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))

        let result = try await sut.execute(sport: "soccer_epl")

        #expect(result[0].hasArbitrage == false)
        #expect(result[0].arbitrageMargin == nil)
    }
    
    @Test("Detects arbitrage when the implied probability sum is below 100%")
    func detectsArbitrageWhenSumBelowOne() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.50), ("Draw", 3.60), ("Chelsea", 3.90)]),
            Self.makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.60), ("Draw", 3.70), ("Chelsea", 4.00)])
        ])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))
        
        let result = try await sut.execute(sport: "soccer_epl")
        
        #expect(result[0].hasArbitrage == true)
        let margin = try #require(result[0].arbitrageMargin)
        #expect(margin > 0)
    }
    
    @Test("With tied odds across bookmakers, keeps the first one found")
    func keepsFirstBookmakerWhenTied() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.50), ("Draw", 3.40), ("Chelsea", 3.20)]),
            Self.makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.50), ("Draw", 3.40), ("Chelsea", 3.20)])
        ])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))
        
        let result = try await sut.execute(sport: "soccer_epl")
        
        #expect(result[0].bestOutcomes["Arsenal"]?.bookmakerTitle == "Bet365")
    }
    
    @Test("A disabled bookmaker is left out of the best-odds calculation")
    func disabledBookmakerIsExcludedFromBestOutcomes() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.60), ("Draw", 3.60), ("Chelsea", 3.10)]),
            Self.makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.30), ("Draw", 3.40), ("Chelsea", 3.20)])
        ])
        let preferences = StubBookmakerPreferences(disabledKeys: ["bet365"])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]), preferences: preferences)

        let result = try await sut.execute(sport: "soccer_epl")

        #expect(result[0].bestOutcomes["Arsenal"]?.bookmakerTitle == "Betfair")
        #expect(result[0].bestOutcomes["Arsenal"]?.price == 2.30)
    }

    @Test("Records the bookmakers seen in every fetched event")
    func recordsSeenBookmakersFromFetchedEvents() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.60), ("Draw", 3.60), ("Chelsea", 3.10)])
        ])
        let preferences = StubBookmakerPreferences()
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]), preferences: preferences)

        _ = try await sut.execute(sport: "soccer_epl")

        #expect(preferences.recordedBookmakers.map(\.title) == ["Bet365"])
    }

    @Test("No arbitrage when no enabled bookmaker prices one of the outcomes")
    func noArbitrageWhenAnOutcomeIsOnlyOfferedByADisabledBookmaker() async throws {
        // Home/away alone would sum to ~0.83 and look like an arbitrage, but the
        // only "Draw" price belongs to a disabled bookmaker.
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.40), ("Chelsea", 2.40)]),
            Self.makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.10), ("Draw", 3.40), ("Chelsea", 3.20)])
        ])
        let preferences = StubBookmakerPreferences(disabledKeys: ["betfair"])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]), preferences: preferences)

        let result = try await sut.execute(sport: "soccer_epl")

        #expect(result[0].bestOutcomes["Draw"] == nil)
        #expect(result[0].hasArbitrage == false)
        #expect(result[0].arbitrageMargin == nil)
    }

    @Test("No arbitrage when the only price for an outcome is zero")
    func noArbitrageWhenAnOutcomeHasOnlyAZeroPrice() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.40), ("Draw", 0), ("Chelsea", 2.40)])
        ])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))

        let result = try await sut.execute(sport: "soccer_epl")

        #expect(result[0].hasArbitrage == false)
        #expect(result[0].arbitrageMargin == nil)
    }

    @Test("Still detects arbitrage when best prices come from different bookmakers covering every outcome")
    func detectsArbitrageAcrossBookmakersWhenAllOutcomesAreCovered() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 3.00), ("Draw", 3.00), ("Chelsea", 2.00)]),
            Self.makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.00), ("Draw", 3.00), ("Chelsea", 4.00)])
        ])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))

        let result = try await sut.execute(sport: "soccer_epl")

        #expect(result[0].bestOutcomes["Arsenal"]?.bookmakerTitle == "Bet365")
        #expect(result[0].bestOutcomes["Chelsea"]?.bookmakerTitle == "Betfair")
        #expect(result[0].hasArbitrage == true)
    }

    // MARK: - Helpers

    private static func makeEvent(bookmakers: [Bookmaker]) -> OddsEvent {
        OddsEvent(id: "event-1", sportKey: "soccer_epl", commenceTime: .now,
                  homeTeam: "Arsenal", awayTeam: "Chelsea", bookmakers: bookmakers)
    }

    private static func makeBookmaker(title: String, outcomes: [(String, Double)]) -> Bookmaker {
        Bookmaker(key: title.lowercased(), title: title,
                  markets: [Market(key: "h2h", outcomes: outcomes.map { Outcome(name: $0.0, price: $0.1) })])
    }
}

private final class StubOddsRepository: OddsRepository {
    let events: [OddsEvent]
    init(events: [OddsEvent]) { self.events = events }
    func fetchUpcomingOdds(sport: String) async throws -> [OddsEvent] { events }
}

private final class StubBookmakerPreferences: BookmakerPreferences {
    private let disabledKeys: Set<String>
    private(set) var recordedBookmakers: [Bookmaker] = []

    init(disabledKeys: Set<String> = []) {
        self.disabledKeys = disabledKeys
    }

    func isEnabled(_ bookmakerKey: String) async -> Bool {
        !disabledKeys.contains(bookmakerKey)
    }

    func recordSeen(_ bookmakers: [Bookmaker]) async {
        recordedBookmakers.append(contentsOf: bookmakers)
    }
}
