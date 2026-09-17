//
//  RecalculatePartialCoverageUseCaseTests.swift
//  Margine
//
import Foundation
import Testing
@testable import Margine

struct RecalculatePartialCoverageUseCaseTests {

    @Test("Sin patas colocadas todavía, una falla y no hay nada que recalcular")
    func nothingToRecalculateBeforeAnyLegIsPlaced() throws {
        let allocation1 = Self.makeAllocation(key: "bet365", outcome: "1", price: 2.00, stake: 52.63, payout: 105.26)
        let allocationX = Self.makeAllocation(key: "betfair_ex_eu", outcome: "X", price: 4.00, stake: 26.32, payout: 105.28)
        let allocation2 = Self.makeAllocation(key: "codere_it", outcome: "2", price: 5.00, stake: 21.05, payout: 105.25)
        let plan = StakePlan(matchId: "m1", bankroll: 100, allocations: [allocation1, allocationX, allocation2], guaranteedProfit: 5.25, impliedProbabilitySum: 0.95)
        let legs = [
            ExecutionLeg(allocation: allocation1, status: .pending),
            ExecutionLeg(allocation: allocationX, status: .pending),
            ExecutionLeg(allocation: allocation2, status: .failed(reason: "Cuota ya no disponible"))
        ]
        let sut = DefaultRecalculatePartialCoverageUseCase()

        let result = sut.execute(originalPlan: plan, legs: legs)

        #expect(result.isFullyCovered == true)
        #expect(Set(result.updatedAllocations) == Set([allocation1, allocationX]))
    }

    @Test("Una pata colocada, el presupuesto restante alcanza para igualar el mejor pago ya comprometido")
    func fullCoverageStillPossibleAfterOneLegPlaced() throws {
        let allocation1 = Self.makeAllocation(key: "bet365", outcome: "1", price: 2.00, stake: 52.63, payout: 105.26)
        let allocationX = Self.makeAllocation(key: "betfair_ex_eu", outcome: "X", price: 4.00, stake: 26.32, payout: 105.28)
        let allocation2 = Self.makeAllocation(key: "codere_it", outcome: "2", price: 5.00, stake: 21.05, payout: 105.25)
        let plan = StakePlan(matchId: "m1", bankroll: 100, allocations: [allocation1, allocationX, allocation2], guaranteedProfit: 5.25, impliedProbabilitySum: 0.95)
        let legs = [
            ExecutionLeg(allocation: allocation1, status: .placed),
            ExecutionLeg(allocation: allocationX, status: .pending),
            ExecutionLeg(allocation: allocation2, status: .failed(reason: nil))
        ]
        let sut = DefaultRecalculatePartialCoverageUseCase()

        let result = sut.execute(originalPlan: plan, legs: legs)

        #expect(result.isFullyCovered == true)
        let updatedX = try #require(result.updatedAllocations.first)
        #expect(updatedX.outcomeName == "X")
        #expect(updatedX.stake == 26.32)
        #expect(updatedX.potentialPayout == 105.28)
    }

    @Test("Una pata colocada, el presupuesto restante NO alcanza: reparte proporcional entre las pendientes")
    func proportionalFallbackWhenBudgetIsInsufficient() throws {
        let placedAllocation = Self.makeAllocation(key: "bet365", outcome: "1", price: 1.05, stake: 85, payout: 89.25)
        let pendingX = Self.makeAllocation(key: "betfair_ex_eu", outcome: "X", price: 2.00, stake: 0, payout: 0)
        let pending2 = Self.makeAllocation(key: "codere_it", outcome: "2", price: 3.00, stake: 0, payout: 0)
        let plan = StakePlan(matchId: "m2", bankroll: 100, allocations: [placedAllocation, pendingX, pending2], guaranteedProfit: 0, impliedProbabilitySum: 0.9)
        let legs = [
            ExecutionLeg(allocation: placedAllocation, status: .placed),
            ExecutionLeg(allocation: pendingX, status: .pending),
            ExecutionLeg(allocation: pending2, status: .pending)
        ]
        let sut = DefaultRecalculatePartialCoverageUseCase()

        let result = sut.execute(originalPlan: plan, legs: legs)

        #expect(result.isFullyCovered == false)
        let stakesByOutcome = Dictionary(uniqueKeysWithValues: result.updatedAllocations.map { ($0.outcomeName, $0.stake) })
        #expect(stakesByOutcome["X"] == 9.0)
        #expect(stakesByOutcome["2"] == 6.0)
        let payoutsByOutcome = Dictionary(uniqueKeysWithValues: result.updatedAllocations.map { ($0.outcomeName, $0.potentialPayout) })
        #expect(payoutsByOutcome["X"] == 18.0)
        #expect(payoutsByOutcome["2"] == 18.0)
        #expect(!result.note.isEmpty)
    }

    @Test("Dos de tres patas colocadas, la tercera falla: no queda nada pendiente para reasignar")
    func noPendingLegsLeftAfterTwoPlacedAndOneFailed() throws {
        let allocation1 = Self.makeAllocation(key: "bet365", outcome: "1", price: 2.00, stake: 52.63, payout: 105.26)
        let allocationX = Self.makeAllocation(key: "betfair_ex_eu", outcome: "X", price: 4.00, stake: 26.32, payout: 105.28)
        let allocation2 = Self.makeAllocation(key: "codere_it", outcome: "2", price: 5.00, stake: 21.05, payout: 105.25)
        let plan = StakePlan(matchId: "m1", bankroll: 100, allocations: [allocation1, allocationX, allocation2], guaranteedProfit: 5.25, impliedProbabilitySum: 0.95)
        let legs = [
            ExecutionLeg(allocation: allocation1, status: .placed),
            ExecutionLeg(allocation: allocationX, status: .placed),
            ExecutionLeg(allocation: allocation2, status: .failed(reason: "Casa rechazó la apuesta"))
        ]
        let sut = DefaultRecalculatePartialCoverageUseCase()

        let result = sut.execute(originalPlan: plan, legs: legs)

        #expect(result.isFullyCovered == false)
        #expect(result.updatedAllocations.isEmpty)
        #expect(result.note.contains("2"))
    }

    // MARK: - Helpers

    private static func makeAllocation(key: String, outcome: String, price: Double, stake: Double, payout: Double) -> StakeAllocation {
        StakeAllocation(bookmakerKey: key, bookmakerTitle: key, outcomeName: outcome, price: price, stake: stake, potentialPayout: payout)
    }
}
