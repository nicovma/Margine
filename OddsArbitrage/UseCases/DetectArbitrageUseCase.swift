//
//  DetectArbitrageUseCase.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

protocol DetectArbitrageUseCase {
    func execute(sport: String) async throws -> [MatchOdds]
}
