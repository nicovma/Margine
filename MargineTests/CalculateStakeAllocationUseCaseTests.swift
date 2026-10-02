//
//  CalculateStakeAllocationUseCaseTests.swift
//  Margine
//
import Foundation
import Testing
@testable import Margine

struct CalculateStakeAllocationUseCaseTests {

    @Test("Con 2 patas de igual cuota, reparte 50/50 y calcula la ganancia garantizada")
    func splitsEquallyWhenPricesMatch() throws {
        let bestOutcomes = [
            "Home": BestOutcome(bookmakerKey: "bet365", bookmakerTitle: "Bet365", price: 2.10),
            "Away": BestOutcome(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", price: 2.10)
        ]
        let sut = DefaultCalculateStakeAllocationUseCase()

        let plan = try sut.execute(matchId: "match-1", bestOutcomes: bestOutcomes, bankroll: 100)

        #expect(plan.allocations.map(\.stake) == [50.0, 50.0])
        #expect(plan.allocations.allSatisfy { $0.potentialPayout == 105.0 })
        #expect(plan.guaranteedProfit == 5.0)
    }

    @Test("Con 3 patas (2.00/4.00/5.00), reproduce el reparto proporcional a 1/cuota")
    func splitsProportionallyAcrossThreeOutcomes() throws {
        let bestOutcomes = [
            "1": BestOutcome(bookmakerKey: "bet365", bookmakerTitle: "Bet365", price: 2.00),
            "X": BestOutcome(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", price: 4.00),
            "2": BestOutcome(bookmakerKey: "pinnacle", bookmakerTitle: "Pinnacle", price: 5.00)
        ]
        let sut = DefaultCalculateStakeAllocationUseCase()

        let plan = try sut.execute(matchId: "match-2", bestOutcomes: bestOutcomes, bankroll: 100)

        let stakesByOutcome = Dictionary(uniqueKeysWithValues: plan.allocations.map { ($0.outcomeName, $0.stake) })
        #expect(stakesByOutcome["1"] == 52.63)
        #expect(stakesByOutcome["X"] == 26.32)
        #expect(stakesByOutcome["2"] == 21.05)

        let totalStaked = plan.allocations.reduce(0) { $0 + $1.stake }
        #expect(totalStaked == 100.0)

        // El peor payout real (21.05 * 5.00 = 105.25) es el que manda, no la
        // fórmula teórica cerrada (que redondearía a 105.26 si no se
        // verificara el caso real).
        #expect(plan.guaranteedProfit == 5.25)
    }

    @Test("Bankroll inválido lanza invalidBankroll")
    func invalidBankrollThrows() throws {
        let bestOutcomes = ["1": BestOutcome(bookmakerKey: "bet365", bookmakerTitle: "Bet365", price: 2.10)]
        let sut = DefaultCalculateStakeAllocationUseCase()

        #expect(throws: StakeAllocationError.invalidBankroll) {
            _ = try sut.execute(matchId: "match-3", bestOutcomes: bestOutcomes, bankroll: 0)
        }
        #expect(throws: StakeAllocationError.invalidBankroll) {
            _ = try sut.execute(matchId: "match-3", bestOutcomes: bestOutcomes, bankroll: -10)
        }
    }

    @Test("Sin oportunidad de arbitraje (suma de probabilidades implícitas >= 1) lanza noArbitrage")
    func noArbitrageThrows() throws {
        let bestOutcomes = [
            "1": BestOutcome(bookmakerKey: "bet365", bookmakerTitle: "Bet365", price: 1.80),
            "2": BestOutcome(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", price: 1.80)
        ]
        let sut = DefaultCalculateStakeAllocationUseCase()

        #expect(throws: StakeAllocationError.noArbitrage) {
            _ = try sut.execute(matchId: "match-4", bestOutcomes: bestOutcomes, bankroll: 100)
        }
    }

    @Test("Sin bestOutcomes lanza noArbitrage")
    func emptyBestOutcomesThrows() throws {
        let sut = DefaultCalculateStakeAllocationUseCase()

        #expect(throws: StakeAllocationError.noArbitrage) {
            _ = try sut.execute(matchId: "match-5", bestOutcomes: [:], bankroll: 100)
        }
    }

    @Test("Cada pata conserva su propio bookmakerKey aunque dos casas empaten en cuota")
    func preservesBookmakerKeyPerLeg() throws {
        let bestOutcomes = [
            "1": BestOutcome(bookmakerKey: "bet365", bookmakerTitle: "Bet365", price: 2.10),
            "2": BestOutcome(bookmakerKey: "codere_it", bookmakerTitle: "Codere (IT)", price: 2.10)
        ]
        let sut = DefaultCalculateStakeAllocationUseCase()

        let plan = try sut.execute(matchId: "match-6", bestOutcomes: bestOutcomes, bankroll: 100)

        let keysByOutcome = Dictionary(uniqueKeysWithValues: plan.allocations.map { ($0.outcomeName, $0.bookmakerKey) })
        #expect(keysByOutcome["1"] == "bet365")
        #expect(keysByOutcome["2"] == "codere_it")
    }
}
