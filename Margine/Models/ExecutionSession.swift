//
//  ExecutionSession.swift
//  Margine
//
import Foundation

/// A leg's status is always set by the user (there's no way to detect from
/// the app whether a bet actually got placed at a bookmaker) — this only
/// tracks what the user told Margine happened.
enum LegStatus: Equatable {
    case pending
    case placed
    case failed(reason: String?)
    case skipped
}

struct ExecutionLeg: Identifiable, Hashable {
    let allocation: StakeAllocation
    var status: LegStatus = .pending

    var id: String { allocation.id }

    static func == (lhs: ExecutionLeg, rhs: ExecutionLeg) -> Bool {
        lhs.allocation == rhs.allocation && lhs.status == rhs.status
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(allocation)
    }
}

enum WizardStage: Equatable {
    case idle
    case refreshingOdds
    case reviewingStakes
    case executing
    case completed
    case partiallyCovered(note: String)
    case cancelled
    case error(String)
}
