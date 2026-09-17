//
//  StakeAllocation.swift
//  Margine
//
import Foundation

/// How much to stake on one leg (bookmaker + outcome) of an arbitrage bet.
struct StakeAllocation: Identifiable, Hashable {
    let bookmakerKey: String
    let bookmakerTitle: String
    let outcomeName: String
    let price: Double
    let stake: Double
    let potentialPayout: Double

    var id: String { bookmakerKey + outcomeName }
}

/// The full multi-leg plan for one match: how much to put on each outcome so
/// that every possible result pays out more than the total staked.
///
/// `guaranteedProfit` is computed from the worst real payout *after*
/// rounding each stake to the cent, not from the closed-form formula — cent
/// rounding can make one outcome pay a cent or two less than another, and
/// the "guaranteed" number needs to reflect the real worst case.
struct StakePlan: Hashable {
    let matchId: String
    let bankroll: Double
    let allocations: [StakeAllocation]
    let guaranteedProfit: Double
    let impliedProbabilitySum: Double
}
