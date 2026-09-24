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
}
