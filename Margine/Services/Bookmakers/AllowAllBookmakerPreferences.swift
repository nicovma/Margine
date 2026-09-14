//
//  AllowAllBookmakerPreferences.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Foundation

struct AllowAllBookmakerPreferences: BookmakerPreferences {
    func isEnabled(_ bookmakerKey: String) async -> Bool { true }
    func recordSeen(_ bookmakers: [Bookmaker]) async {}
}
