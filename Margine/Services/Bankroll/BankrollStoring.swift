//
//  BankrollStoring.swift
//  Margine
//
import Foundation

protocol BankrollStoring {
    var lastBankroll: Double? { get }
    func save(_ bankroll: Double)
}

final class DefaultBankrollStore: BankrollStoring {
    private enum Keys {
        static let lastBankroll = "wizard.lastBankroll"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastBankroll: Double? {
        let value = defaults.double(forKey: Keys.lastBankroll)
        return value > 0 ? value : nil
    }

    func save(_ bankroll: Double) {
        defaults.set(bankroll, forKey: Keys.lastBankroll)
    }
}

final class InMemoryBankrollStore: BankrollStoring {
    private(set) var lastBankroll: Double?
    init(lastBankroll: Double? = nil) { self.lastBankroll = lastBankroll }
    func save(_ bankroll: Double) { lastBankroll = bankroll }
}
