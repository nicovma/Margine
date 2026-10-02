//
//  BookmakerPreferences.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation

protocol BookmakerFiltering {
    func isEnabled(_ bookmakerKey: String) async -> Bool
}

protocol BookmakerCatalogRecording {
    func recordSeen(_ bookmakers: [Bookmaker]) async
}

typealias BookmakerPreferences = BookmakerFiltering & BookmakerCatalogRecording

/// What the Profile screen needs from the bookmaker store: observe the
/// catalog and toggle entries. Kept separate from `BookmakerPreferences`,
/// which is the narrower read/record contract the arbitrage use case needs.
@MainActor
protocol BookmakerPreferencesManaging: AnyObject {
    var knownBookmakersPublisher: AnyPublisher<[BookmakerInfo], Never> { get }
    var disabledKeysPublisher: AnyPublisher<Set<String>, Never> { get }
    func setEnabled(_ enabled: Bool, for bookmakerKey: String)
}
