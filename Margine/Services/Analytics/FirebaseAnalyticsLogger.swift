//
//  FirebaseAnalyticsLogger.swift
//  Margine
//
//  Created by Nicolas Valentini on 15/9/2026.
//
import FirebaseAnalytics

struct FirebaseAnalyticsLogger: AnalyticsLogging {
    func logLogin(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    func logArbitrageDetected(count: Int) {
        Analytics.logEvent("arbitrage_detected", parameters: [
            "match_count": count
        ])
    }

    func logManualRefresh() {
        Analytics.logEvent("manual_refresh", parameters: nil)
    }

    func logStakeWizardOpened(matchId: String) {
        Analytics.logEvent("stake_wizard_opened", parameters: ["match_id": matchId])
    }

    func logLegPlaced(bookmakerKey: String) {
        Analytics.logEvent("stake_wizard_leg_placed", parameters: ["bookmaker_key": bookmakerKey])
    }

    func logWizardCompleted(matchId: String) {
        Analytics.logEvent("stake_wizard_completed", parameters: ["match_id": matchId])
    }

    func logWizardPartialCoverage(matchId: String) {
        Analytics.logEvent("stake_wizard_partial_coverage", parameters: ["match_id": matchId])
    }
}
