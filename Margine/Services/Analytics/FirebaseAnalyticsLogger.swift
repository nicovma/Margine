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
}
