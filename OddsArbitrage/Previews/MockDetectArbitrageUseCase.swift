//
//  MockDetectArbitrageUseCase.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

final class MockDetectArbitrageUseCase: DetectArbitrageUseCase {
    var result: Result<[MatchOdds], Error> = .success(MockDetectArbitrageUseCase.sampleMatches)
    
    func execute(sport: String) async throws -> [MatchOdds] {
        try result.get()
    }
    
    static let sampleMatches: [MatchOdds] = [
          MatchOdds(
              id: "1",
              homeTeam: "Arsenal",
              awayTeam: "Chelsea",
              commenceTime: .now,
              bestOutcomes: [
                  "Arsenal": BestOutcome(bookmakerTitle: "Betfair", price: 2.30),
                  "Draw": BestOutcome(bookmakerTitle: "Pinnacle", price: 3.50),
                  "Chelsea": BestOutcome(bookmakerTitle: "Pinnacle", price: 3.40)
              ],
              hasArbitrage: false,
              arbitrageMargin: nil
          ),
          MatchOdds(
              id: "2",
              homeTeam: "Real Madrid",
              awayTeam: "Barcelona",
              commenceTime: .now.addingTimeInterval(86400),
              bestOutcomes: [
                  "Real Madrid": BestOutcome(bookmakerTitle: "Bet365", price: 2.60),
                  "Draw": BestOutcome(bookmakerTitle: "Betfair", price: 3.60),
                  "Barcelona": BestOutcome(bookmakerTitle: "Pinnacle", price: 3.10)
              ],
              hasArbitrage: true,
              arbitrageMargin: 3.8
          )
      ]
  }
