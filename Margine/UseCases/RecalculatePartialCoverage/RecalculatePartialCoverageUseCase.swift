//
//  RecalculatePartialCoverageUseCase.swift
//  Margine
//
import Foundation

/// Result of recalculating what's left of a `StakePlan` after at least one
/// leg has already been placed and another one failed. This is a heuristic,
/// not a mathematical guarantee: a placed bet is irreversible, so once one
/// leg is locked in, "atomicity" only means making the best of what's left,
/// not undoing anything.
struct PartialCoveragePlan: Equatable {
    /// New stakes for the legs that are still `.pending`. Empty when there's
    /// nothing left to reassign to (no pending legs remain).
    let updatedAllocations: [StakeAllocation]
    /// `true` only if the worst possible remaining outcome still pays more
    /// than the total that ends up staked.
    let isFullyCovered: Bool
    let note: String
}

protocol RecalculatePartialCoverageUseCase {
    func execute(originalPlan: StakePlan, legs: [ExecutionLeg]) -> PartialCoveragePlan
}
