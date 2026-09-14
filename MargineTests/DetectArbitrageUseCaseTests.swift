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
    
    @Test("Sin arbitraje cuando la suma de probabilidades implícitas supera 100%")
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
    
    @Test("Sin bookmakers, no hay arbitraje ni margen")
    func noArbitrageWhenNoBookmakers() async throws {
        let event = Self.makeEvent(bookmakers: [])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))

        let result = try await sut.execute(sport: "soccer_epl")

        #expect(result[0].hasArbitrage == false)
        #expect(result[0].arbitrageMargin == nil)
    }
    
    @Test("Detecta arbitraje cuando la suma de probabilidades implícitas es menor a 100%")
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
    
    @Test("Con cuotas empatadas entre casas, se queda con la primera encontrada")
    func keepsFirstBookmakerWhenTied() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.50), ("Draw", 3.40), ("Chelsea", 3.20)]),
            Self.makeBookmaker(title: "Betfair", outcomes: [("Arsenal", 2.50), ("Draw", 3.40), ("Chelsea", 3.20)])
        ])
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]))
        
        let result = try await sut.execute(sport: "soccer_epl")
        
        #expect(result[0].bestOutcomes["Arsenal"]?.bookmakerTitle == "Bet365")
    }
    
    @Test("Un bookmaker deshabilitado queda afuera del cálculo de mejores cuotas")
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

    @Test("Registra los bookmakers vistos en cada evento traído del repositorio")
    func recordsSeenBookmakersFromFetchedEvents() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(title: "Bet365", outcomes: [("Arsenal", 2.60), ("Draw", 3.60), ("Chelsea", 3.10)])
        ])
        let preferences = StubBookmakerPreferences()
        let sut = DefaultDetectArbitrageUseCase(repository: StubOddsRepository(events: [event]), preferences: preferences)

        _ = try await sut.execute(sport: "soccer_epl")

        #expect(preferences.recordedBookmakers.map(\.title) == ["Bet365"])
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
