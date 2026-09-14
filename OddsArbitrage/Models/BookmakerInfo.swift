//
//  BookmakerInfo.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Foundation

struct BookmakerInfo: Identifiable, Hashable {
    let key: String
    let title: String

    var id: String { key }
}
