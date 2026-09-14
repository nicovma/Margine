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
    case invalidURL
    case httpError(statusCode: Int)
    case decodingFailed(underlying: Error)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return String(localized: "No se recibió una respuesta válida del servidor.")
        case .invalidURL:
            return String(localized: "No se pudo construir la URL del pedido.")
        case .httpError(let statusCode):
            let prefix = String(localized: "El servidor respondió con un error (código ")
            let suffix = String(localized: ").")
            return "\(prefix)\(statusCode)\(suffix)"
        case .decodingFailed:
            return String(localized: "No se pudo interpretar la respuesta del servidor.")
        }
    }
}
