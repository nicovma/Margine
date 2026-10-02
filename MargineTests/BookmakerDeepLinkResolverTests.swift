//
//  BookmakerDeepLinkResolverTests.swift
//  Margine
//
import Foundation
import Testing
@testable import Margine

struct BookmakerDeepLinkResolverTests {

    @Test("Con una casa conocida, la búsqueda de fallback queda acotada a su dominio real")
    func scopesFallbackSearchToKnownDomain() throws {
        let sut = DefaultBookmakerDeepLinkResolver()

        let link = sut.resolveLink(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", homeTeam: "Arsenal", awayTeam: "Chelsea")

        let query = try #require(link.fallbackURL.query)
        let decoded = query.removingPercentEncoding ?? query
        #expect(decoded.contains("site:betfair.com"))
        #expect(decoded.contains("Arsenal vs Chelsea"))
    }

    @Test("Con una casa sin dominio confirmado, cae a búsqueda genérica por título")
    func fallsBackToGenericSearchForUnknownBookmaker() throws {
        let sut = DefaultBookmakerDeepLinkResolver()

        let link = sut.resolveLink(bookmakerKey: "some_unknown_book", bookmakerTitle: "Some Unknown Book", homeTeam: "Arsenal", awayTeam: "Chelsea")

        let query = try #require(link.fallbackURL.query)
        let decoded = query.removingPercentEncoding ?? query
        #expect(!decoded.contains("site:"))
        #expect(decoded.contains("Some Unknown Book"))
    }

    @Test("Sin schemes configurados, appURL es nil y solo queda el fallback")
    func appURLIsNilWithoutConfiguredSchemes() throws {
        let sut = DefaultBookmakerDeepLinkResolver(schemesByKey: [:])

        let link = sut.resolveLink(bookmakerKey: "betfair_ex_eu", bookmakerTitle: "Betfair", homeTeam: "Arsenal", awayTeam: "Chelsea")

        #expect(link.appURL == nil)
    }
}
