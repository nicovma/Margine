//
//  MockDetectArbitrageUseCase.swift
//  Margine
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
                  "Arsenal": BestOutcome(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", price: 2.30),
                  "Draw": BestOutcome(bookmakerKey: "pinnacle", bookmakerTitle: "Pinnacle", price: 3.50),
                  "Chelsea": BestOutcome(bookmakerKey: "pinnacle", bookmakerTitle: "Pinnacle", price: 3.40)
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
                  "Real Madrid": BestOutcome(bookmakerKey: "bet365", bookmakerTitle: "Bet365", price: 2.60),
                  "Draw": BestOutcome(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", price: 3.60),
                  "Barcelona": BestOutcome(bookmakerKey: "pinnacle", bookmakerTitle: "Pinnacle", price: 3.10)
              ],
              hasArbitrage: true,
              arbitrageMargin: 3.8
          )
      ]
  }
