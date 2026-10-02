//
//  BestOutcomesCalculatorTests.swift
//  Margine
//
import Foundation
import Testing
@testable import Margine

struct BestOutcomesCalculatorTests {

    @Test("Se queda con la mejor cuota de cada resultado entre bookmakers habilitados")
    func picksBestPricePerOutcome() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(key: "bet365", title: "Bet365", outcomes: [("Arsenal", 2.60), ("Draw", 3.40), ("Chelsea", 3.10)]),
            Self.makeBookmaker(key: "betfair_ex_eu", title: "Betfair", outcomes: [("Arsenal", 2.30), ("Draw", 3.70), ("Chelsea", 3.20)])
        ])
        let sut = BestOutcomesCalculator()

        let result = await sut.bestOutcomes(for: event, preferences: AllowAllBookmakerPreferences())

        #expect(result["Arsenal"] == BestOutcome(bookmakerKey: "bet365", bookmakerTitle: "Bet365", price: 2.60))
        #expect(result["Draw"] == BestOutcome(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", price: 3.70))
        #expect(result["Chelsea"] == BestOutcome(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", price: 3.20))
    }

    @Test("Un bookmaker deshabilitado queda afuera del cálculo")
    func excludesDisabledBookmaker() async throws {
        let event = Self.makeEvent(bookmakers: [
            Self.makeBookmaker(key: "bet365", title: "Bet365", outcomes: [("Arsenal", 2.60)]),
            Self.makeBookmaker(key: "betfair_ex_eu", title: "Betfair", outcomes: [("Arsenal", 2.30)])
        ])
        let sut = BestOutcomesCalculator()
        let preferences = StubBookmakerPreferences(disabledKeys: ["bet365"])

        let result = await sut.bestOutcomes(for: event, preferences: preferences)

        #expect(result["Arsenal"]?.bookmakerKey == "betfair_ex_eu")
    }

    @Test("Ignora mercados que no sean h2h y precios no positivos")
    func ignoresNonH2HMarketsAndNonPositivePrices() async throws {
        let bookmakerWithOtherMarket = Bookmaker(
            key: "bet365", title: "Bet365",
            markets: [Market(key: "totals", outcomes: [Outcome(name: "Over", price: 1.90)])]
        )
        let bookmakerWithZeroPrice = Bookmaker(
            key: "betfair_ex_eu", title: "Betfair",
            markets: [Market(key: "h2h", outcomes: [Outcome(name: "Arsenal", price: 0)])]
        )
        let event = Self.makeEvent(bookmakers: [bookmakerWithOtherMarket, bookmakerWithZeroPrice])
        let sut = BestOutcomesCalculator()

        let result = await sut.bestOutcomes(for: event, preferences: AllowAllBookmakerPreferences())

        #expect(result.isEmpty)
    }

    // MARK: - Helpers

    private static func makeEvent(bookmakers: [Bookmaker]) -> OddsEvent {
        OddsEvent(id: "event-1", sportKey: "soccer_epl", commenceTime: .now,
                  homeTeam: "Arsenal", awayTeam: "Chelsea", bookmakers: bookmakers)
    }

    private static func makeBookmaker(key: String, title: String, outcomes: [(String, Double)]) -> Bookmaker {
        Bookmaker(key: key, title: title,
                  markets: [Market(key: "h2h", outcomes: outcomes.map { Outcome(name: $0.0, price: $0.1) })])
    }
}

private final class StubBookmakerPreferences: BookmakerPreferences {
    private let disabledKeys: Set<String>
    init(disabledKeys: Set<String> = []) { self.disabledKeys = disabledKeys }
    func isEnabled(_ bookmakerKey: String) async -> Bool { !disabledKeys.contains(bookmakerKey) }
    func recordSeen(_ bookmakers: [Bookmaker]) async {}
}
