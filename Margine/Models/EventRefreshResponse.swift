//
//  EventRefreshResponse.swift
//  Margine
//
import Foundation

/// Response of `POST /events/:eventId/refresh` on the worker.
struct EventRefreshResponse: Decodable {
    let event: OddsEvent
    let refreshedJustNow: Bool
}
