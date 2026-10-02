//
//  BookmakerDeepLinkResolver.swift
//  Margine
//
import Foundation

struct BookmakerLink {
    /// `nil` when there's no confirmed URL scheme for this bookmaker — the
    /// caller should skip straight to `fallbackURL`.
    let appURL: URL?
    /// Always present: a generic web search for the bookmaker + match, so
    /// there's never a dead link even for a bookmaker with no known app
    /// scheme or bet-slip URL format.
    let fallbackURL: URL
}

protocol BookmakerDeepLinkResolving {
    func resolveLink(bookmakerKey: String, bookmakerTitle: String, homeTeam: String, awayTeam: String) -> BookmakerLink
}

/// We don't have cooperation from any of these bookmakers to build a direct
/// link straight to a specific match's bet slip — guessing that URL format
/// is fragile and breaks silently the moment a site redesigns, and we have
/// no internal event ID of theirs to point at anyway (only The Odds API's).
///
/// The fallback we CAN build reliably is a web search scoped to the
/// bookmaker's own real domain (`site:domain.com <home> vs <away>`) instead
/// of a plain, unscoped search — it's far more likely to land on that
/// bookmaker's own match page as the first result, and it still degrades
/// gracefully to a generic search for any bookmaker outside `domainByKey`
/// (The Odds API surfaces 25+ of them, most without a domain confirmed here).
///
/// `schemesByKey` is a real, but partial, table of confirmed app URL
/// schemes — add to it only after confirming a scheme actually opens that
/// bookmaker's app (and after adding it to `LSApplicationQueriesSchemes` in
/// Info.plist, or `canOpenURL` will just silently return `false`).
final class DefaultBookmakerDeepLinkResolver: BookmakerDeepLinkResolving {
    /// Real root domains, confirmed reachable (from the odds-vs-official-site
    /// audit) for the bookmakers Nicolás actually uses. Keyed by the exact
    /// `bookmaker.key` The Odds API returns under `regions=eu`, not the title.
    static let defaultDomainsByKey: [String: String] = [
        "onexbet": "1xbet.com",
        "betfair_ex_eu": "betfair.com",
        "betsson": "betsson.com",
        "codere_it": "codere.it"
    ]

    private let schemesByKey: [String: String]
    private let domainByKey: [String: String]

    init(schemesByKey: [String: String] = [:], domainByKey: [String: String] = DefaultBookmakerDeepLinkResolver.defaultDomainsByKey) {
        self.schemesByKey = schemesByKey
        self.domainByKey = domainByKey
    }

    func resolveLink(bookmakerKey: String, bookmakerTitle: String, homeTeam: String, awayTeam: String) -> BookmakerLink {
        let appURL = schemesByKey[bookmakerKey].flatMap { URL(string: "\($0)://") }

        let matchQuery = "\(homeTeam) vs \(awayTeam)"
        let query = domainByKey[bookmakerKey].map { "site:\($0) \(matchQuery)" } ?? "\(bookmakerTitle) \(matchQuery)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // Force-unwrap is safe: the base URL is a fixed literal and the query
        // was already percent-encoded for the query character set above.
        let fallbackURL = URL(string: "https://www.google.com/search?q=\(encodedQuery)")!
        return BookmakerLink(appURL: appURL, fallbackURL: fallbackURL)
    }
}
