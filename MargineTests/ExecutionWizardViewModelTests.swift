//
//  ExecutionWizardViewModelTests.swift
//  Margine
//
import Foundation
import Testing
@testable import Margine

@MainActor
struct ExecutionWizardViewModelTests {

    @Test("start() con bankroll válido refresca el evento y termina en reviewingStakes con el plan calculado")
    func startCalculatesStakePlan() async throws {
        let match = Self.makeMatch()
        let repository = StubOddsRepository(refreshedEvent: Self.makeFreshEvent())
        let sut = ExecutionWizardViewModel(match: match, oddsRepository: repository, bankrollStore: InMemoryBankrollStore())
        sut.bankrollInput = "100"

        await sut.start()

        #expect(sut.stage == .reviewingStakes)
        #expect(sut.plan?.allocations.count == 2)
        #expect(sut.legs.allSatisfy { $0.status == .pending })
    }

    @Test("start() con un bankroll inválido termina en error sin llamar al repositorio")
    func startWithInvalidBankrollFails() async throws {
        let match = Self.makeMatch()
        let repository = StubOddsRepository(refreshedEvent: Self.makeFreshEvent())
        let sut = ExecutionWizardViewModel(match: match, oddsRepository: repository, bankrollStore: InMemoryBankrollStore())
        sut.bankrollInput = "no-es-un-numero"

        await sut.start()

        guard case .error = sut.stage else {
            Issue.record("Se esperaba .error, se obtuvo \(sut.stage)")
            return
        }
        #expect(repository.refreshEventCallCount == 0)
    }

    @Test("Marcar todas las patas como colocadas termina en completed")
    func markingAllLegsPlacedCompletesTheWizard() async throws {
        let match = Self.makeMatch()
        let repository = StubOddsRepository(refreshedEvent: Self.makeFreshEvent())
        let sut = ExecutionWizardViewModel(match: match, oddsRepository: repository, bankrollStore: InMemoryBankrollStore())
        sut.bankrollInput = "100"
        await sut.start()
        sut.confirmStakes()

        for leg in sut.legs {
            sut.markPlaced(leg)
        }

        #expect(sut.stage == .completed)
    }

    @Test("Marcar una pata como fallida dispara el recálculo y pasa a partiallyCovered")
    func markingALegFailedRecalculatesCoverage() async throws {
        let match = Self.makeMatch()
        let repository = StubOddsRepository(refreshedEvent: Self.makeFreshEvent())
        let sut = ExecutionWizardViewModel(match: match, oddsRepository: repository, bankrollStore: InMemoryBankrollStore())
        sut.bankrollInput = "100"
        await sut.start()
        sut.confirmStakes()

        let firstLeg = try #require(sut.legs.first)
        sut.markFailed(firstLeg, reason: "Cuota ya no disponible")

        guard case .partiallyCovered = sut.stage else {
            Issue.record("Se esperaba .partiallyCovered, se obtuvo \(sut.stage)")
            return
        }
    }

    @Test("cancel() lleva a cancelled en cualquier punto")
    func cancelMovesToCancelled() async throws {
        let match = Self.makeMatch()
        let repository = StubOddsRepository(refreshedEvent: Self.makeFreshEvent())
        let sut = ExecutionWizardViewModel(match: match, oddsRepository: repository, bankrollStore: InMemoryBankrollStore())
        sut.bankrollInput = "100"
        await sut.start()

        sut.cancel()

        #expect(sut.stage == .cancelled)
    }

    // MARK: - Helpers

    private static func makeMatch() -> MatchOdds {
        MatchOdds(
            id: "event-1", homeTeam: "Arsenal", awayTeam: "Chelsea", commenceTime: .now,
            bestOutcomes: [
                "Arsenal": BestOutcome(bookmakerKey: "bet365", bookmakerTitle: "Bet365", price: 2.50),
                "Chelsea": BestOutcome(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", price: 2.50)
            ],
            hasArbitrage: false,
            arbitrageMargin: nil
        )
    }

    private static func makeFreshEvent() -> OddsEvent {
        OddsEvent(
            id: "event-1", sportKey: "soccer_epl", commenceTime: .now,
            homeTeam: "Arsenal", awayTeam: "Chelsea",
            bookmakers: [
                Bookmaker(key: "bet365", title: "Bet365", markets: [Market(key: "h2h", outcomes: [Outcome(name: "Arsenal", price: 2.50), Outcome(name: "Chelsea", price: 2.10)])]),
                Bookmaker(key: "betfair_ex_eu", title: "Betfair", markets: [Market(key: "h2h", outcomes: [Outcome(name: "Arsenal", price: 2.10), Outcome(name: "Chelsea", price: 2.50)])])
            ]
        )
    }
}

private final class StubOddsRepository: OddsRepository {
    private let refreshedEvent: OddsEvent
    private(set) var refreshEventCallCount = 0

    init(refreshedEvent: OddsEvent) {
        self.refreshedEvent = refreshedEvent
    }

    func fetchUpcomingOdds(sport: String) async throws -> [OddsEvent] { [] }

    func refreshEvent(eventId: String) async throws -> EventRefreshResponse {
        refreshEventCallCount += 1
        return EventRefreshResponse(event: refreshedEvent, refreshedJustNow: true)
    }
}
