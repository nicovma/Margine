//
//  DefaultRecalculatePartialCoverageUseCase.swift
//  Margine
//
import Foundation

final class DefaultRecalculatePartialCoverageUseCase: RecalculatePartialCoverageUseCase {
    func execute(originalPlan: StakePlan, legs: [ExecutionLeg]) -> PartialCoveragePlan {
        let placedLegs = legs.filter { $0.status == .placed }
        let pendingLegs = legs.filter { $0.status == .pending }

        guard !placedLegs.isEmpty else {
            // Nada se colocó todavía: cancelar es gratis, no hay nada que
            // recalcular ni ninguna pérdida ya comprometida.
            return PartialCoveragePlan(
                updatedAllocations: pendingLegs.map(\.allocation),
                isFullyCovered: true,
                note: String(localized: "Todavía no colocaste ninguna pata: podés cancelar sin pérdida, no hay nada que recalcular.")
            )
        }

        let lockedPayouts = placedLegs.map { $0.allocation.stake * $0.allocation.price }
        let stakedSoFar = placedLegs.reduce(0) { $0 + $1.allocation.stake }
        let remainingBudget = originalPlan.bankroll - stakedSoFar

        guard !pendingLegs.isEmpty else {
            // Ya no queda ninguna pata pendiente para reasignar (todas están
            // colocadas o fallaron): la cobertura quedó incompleta, no hay
            // forma de mejorar esto con el capital que queda.
            let failedOutcomes = legs
                .filter { if case .failed = $0.status { return true }; return false }
                .map(\.allocation.outcomeName)
                .joined(separator: ", ")
            let prefix = String(localized: "No quedan patas pendientes para reasignar. Si gana ")
            let suffix = String(localized: ", no cobrás nada por esa pata: tu cobertura quedó incompleta.")
            let outcomeDescription = failedOutcomes.isEmpty ? String(localized: "el resultado que falló") : failedOutcomes
            return PartialCoveragePlan(updatedAllocations: [], isFullyCovered: false, note: "\(prefix)\(outcomeDescription)\(suffix)")
        }

        // Apuntamos a que ninguna pata pendiente termine pagando peor que la
        // mejor pata ya colocada — puede sobrar presupuesto sin apostar, eso
        // solo mejora el retorno relativo, nunca lo empeora.
        let targetPayout = lockedPayouts.max() ?? 0
        let neededBudget = pendingLegs.reduce(0) { $0 + targetPayout / $1.allocation.price }

        if neededBudget <= remainingBudget {
            let updated = pendingLegs.map { leg in
                Self.allocation(basedOn: leg.allocation, rawStake: targetPayout / leg.allocation.price)
            }
            return PartialCoveragePlan(
                updatedAllocations: updated,
                isFullyCovered: true,
                note: String(localized: "Todavía se puede cubrir por completo: ajustá las patas pendientes a estos montos nuevos.")
            )
        }

        // No alcanza para igualar el mejor pago ya comprometido: repartimos
        // lo que queda proporcional a 1/cuota, mismo criterio que el cálculo
        // original pero solo sobre las patas pendientes.
        let impliedSum = pendingLegs.reduce(0) { $0 + 1 / $1.allocation.price }
        let updated = pendingLegs.map { leg in
            Self.allocation(basedOn: leg.allocation, rawStake: (1 / leg.allocation.price) / impliedSum * remainingBudget)
        }
        let worstPayout = (lockedPayouts + updated.map(\.potentialPayout)).min() ?? 0
        let worstLoss = max(0, (stakedSoFar + remainingBudget) - worstPayout)
        let prefix = String(localized: "No alcanza para cubrir el peor caso con lo que queda: si sale el resultado más caro podés perder hasta ")
        let suffix = String(localized: ". Reparto ajustado a lo que queda de presupuesto.")
        let note = "\(prefix)\(String(format: "%.2f", worstLoss))\(suffix)"

        return PartialCoveragePlan(updatedAllocations: updated, isFullyCovered: false, note: note)
    }

    private static func allocation(basedOn original: StakeAllocation, rawStake: Double) -> StakeAllocation {
        let stake = (rawStake * 100).rounded() / 100
        let payout = (stake * original.price * 100).rounded() / 100
        return StakeAllocation(
            bookmakerKey: original.bookmakerKey,
            bookmakerTitle: original.bookmakerTitle,
            outcomeName: original.outcomeName,
            price: original.price,
            stake: stake,
            potentialPayout: payout
        )
    }
}
