//
//  NetworkService.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

protocol NetworkService {
    func fetch<T: Decodable>(_ url: URL) async throws -> T
}

enum NetworkError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed
}
