//
//  AnalyticsLogging.swift
//  Margine
//
//  Created by Nicolas Valentini on 15/9/2026.
//
import Foundation

protocol AnalyticsLogging {
    func logLogin(method: String)
    func logArbitrageDetected(count: Int)
    func logManualRefresh()
    func logStakeWizardOpened(matchId: String)
    func logLegPlaced(bookmakerKey: String)
    func logWizardCompleted(matchId: String)
    func logWizardPartialCoverage(matchId: String)
}
