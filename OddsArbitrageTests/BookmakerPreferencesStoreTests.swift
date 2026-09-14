//
//  BookmakerPreferencesStoreTests.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import XCTest
@testable import OddsArbitrage

@MainActor
final class BookmakerPreferencesStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "BookmakerPreferencesStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeBookmaker(key: String, title: String) -> Bookmaker {
        Bookmaker(key: key, title: title, markets: [])
    }

    func test_newBookmaker_isEnabledByDefault() {
        let sut = BookmakerPreferencesStore(defaults: defaults)

        sut.recordSeen([makeBookmaker(key: "bet365", title: "Bet365")])

        XCTAssertTrue(sut.isEnabled("bet365"))
        XCTAssertEqual(sut.knownBookmakers, [BookmakerInfo(key: "bet365", title: "Bet365")])
    }

    func test_disablingABookmaker_persistsAcrossInstances() {
        let sut = BookmakerPreferencesStore(defaults: defaults)
        sut.recordSeen([makeBookmaker(key: "bet365", title: "Bet365")])

        sut.setEnabled(false, for: "bet365")

        XCTAssertFalse(sut.isEnabled("bet365"))

        let reloaded = BookmakerPreferencesStore(defaults: defaults)
        XCTAssertFalse(reloaded.isEnabled("bet365"))
        XCTAssertEqual(reloaded.knownBookmakers, [BookmakerInfo(key: "bet365", title: "Bet365")])
    }

    func test_reEnablingABookmaker_persists() {
        let sut = BookmakerPreferencesStore(defaults: defaults)
        sut.recordSeen([makeBookmaker(key: "bet365", title: "Bet365")])
        sut.setEnabled(false, for: "bet365")

        sut.setEnabled(true, for: "bet365")

        XCTAssertTrue(sut.isEnabled("bet365"))
        let reloaded = BookmakerPreferencesStore(defaults: defaults)
        XCTAssertTrue(reloaded.isEnabled("bet365"))
    }

    func test_recordSeen_growsCatalogWithNewBookmakers() {
        let sut = BookmakerPreferencesStore(defaults: defaults)

        sut.recordSeen([makeBookmaker(key: "bet365", title: "Bet365")])
        sut.recordSeen([makeBookmaker(key: "pinnacle", title: "Pinnacle")])

        XCTAssertEqual(
            Set(sut.knownBookmakers),
            Set([BookmakerInfo(key: "bet365", title: "Bet365"), BookmakerInfo(key: "pinnacle", title: "Pinnacle")])
        )
    }

    func test_unknownBookmaker_isEnabledByDefault() {
        let sut = BookmakerPreferencesStore(defaults: defaults)

        XCTAssertTrue(sut.isEnabled("never-seen-before"))
    }
}
