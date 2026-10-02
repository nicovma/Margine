//
//  CalculateStakeAllocationUseCase.swift
//  Margine
//
import Foundation

enum StakeAllocationError: Error, LocalizedError {
    case invalidBankroll
    case noArbitrage

    var errorDescription: String? {
        switch self {
        case .invalidBankroll:
            return String(localized: "Ingresá un monto mayor a cero para calcular el reparto.")
        case .noArbitrage:
            return String(localized: "Este partido ya no tiene una oportunidad de arbitraje real para repartir.")
        }
    }
}

/// Splits a bankroll across the best-priced outcomes of a match so that
/// every possible result guarantees a profit, in proportion to each
/// outcome's implied probability (`1 / price`).
protocol CalculateStakeAllocationUseCase {
    func execute(matchId: String, bestOutcomes: [String: BestOutcome], bankroll: Double) throws -> StakePlan
}
