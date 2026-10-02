//
//  DefaultCalculateStakeAllocationUseCase.swift
//  Margine
//
import Foundation

final class DefaultCalculateStakeAllocationUseCase: CalculateStakeAllocationUseCase {
    func execute(matchId: String, bestOutcomes: [String: BestOutcome], bankroll: Double) throws -> StakePlan {
        guard bankroll > 0 else { throw StakeAllocationError.invalidBankroll }
        guard !bestOutcomes.isEmpty else { throw StakeAllocationError.noArbitrage }

        let impliedProbabilitySum = bestOutcomes.values.reduce(0) { $0 + 1 / $1.price }
        guard impliedProbabilitySum < 1 else { throw StakeAllocationError.noArbitrage }

        let allocations = bestOutcomes.map { outcomeName, best -> StakeAllocation in
            let rawStake = (1 / best.price) / impliedProbabilitySum * bankroll
            let stake = (rawStake * 100).rounded() / 100
            let payout = (stake * best.price * 100).rounded() / 100
            return StakeAllocation(
                bookmakerKey: best.bookmakerKey,
                bookmakerTitle: best.bookmakerTitle,
                outcomeName: outcomeName,
                price: best.price,
                stake: stake,
                potentialPayout: payout
            )
        }.sorted { $0.outcomeName < $1.outcomeName }

        let totalStaked = allocations.reduce(0) { $0 + $1.stake }
        // Ganancia real = el peor payout entre los resultados posibles, no la
        // fórmula teórica — el redondeo por pata puede dejar a un resultado
        // pagando un poco menos que otro.
        let worstPayout = allocations.map(\.potentialPayout).min() ?? 0
        let guaranteedProfit = worstPayout - totalStaked

        return StakePlan(
            matchId: matchId,
            bankroll: bankroll,
            allocations: allocations,
            guaranteedProfit: guaranteedProfit,
            impliedProbabilitySum: impliedProbabilitySum
        )
    }
}
