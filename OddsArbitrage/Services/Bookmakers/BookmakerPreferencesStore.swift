//
//  BookmakerPreferencesStore.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Foundation

@MainActor
final class BookmakerPreferencesStore: ObservableObject, BookmakerPreferences {
    private enum Keys {
        static let catalog = "bookmaker.catalog"
        static let disabledKeys = "bookmaker.disabledKeys"
    }

    private let defaults: UserDefaults

    @Published private(set) var knownBookmakers: [BookmakerInfo]
    @Published private(set) var disabledKeys: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let catalog = defaults.dictionary(forKey: Keys.catalog) as? [String: String] ?? [:]
        self.disabledKeys = Set(defaults.stringArray(forKey: Keys.disabledKeys) ?? [])
        self.knownBookmakers = Self.sortedInfos(from: catalog)
    }

    func isEnabled(_ bookmakerKey: String) -> Bool {
        !disabledKeys.contains(bookmakerKey)
    }

    func recordSeen(_ bookmakers: [Bookmaker]) {
        var catalog = Dictionary(uniqueKeysWithValues: knownBookmakers.map { ($0.key, $0.title) })
        var changed = false
        for bookmaker in bookmakers where catalog[bookmaker.key] != bookmaker.title {
            catalog[bookmaker.key] = bookmaker.title
            changed = true
        }
        guard changed else { return }
        defaults.set(catalog, forKey: Keys.catalog)
        knownBookmakers = Self.sortedInfos(from: catalog)
    }

    func setEnabled(_ enabled: Bool, for bookmakerKey: String) {
        if enabled {
            disabledKeys.remove(bookmakerKey)
        } else {
            disabledKeys.insert(bookmakerKey)
        }
        defaults.set(Array(disabledKeys), forKey: Keys.disabledKeys)
    }

    private static func sortedInfos(from catalog: [String: String]) -> [BookmakerInfo] {
        catalog
            .map { BookmakerInfo(key: $0.key, title: $0.value) }
            .sorted { $0.title < $1.title }
    }
}
