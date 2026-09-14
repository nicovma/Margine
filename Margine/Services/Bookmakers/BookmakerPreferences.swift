//
//  BookmakerPreferences.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Foundation

protocol BookmakerFiltering {
    func isEnabled(_ bookmakerKey: String) async -> Bool
}

protocol BookmakerCatalogRecording {
    func recordSeen(_ bookmakers: [Bookmaker]) async
}

typealias BookmakerPreferences = BookmakerFiltering & BookmakerCatalogRecording
