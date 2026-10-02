//
//  NetworkService.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation

protocol NetworkService {
    func fetch<T: Decodable>(_ request: URLRequest) async throws -> T
}

extension NetworkService {
    func fetch<T: Decodable>(_ url: URL) async throws -> T {
        try await fetch(URLRequest(url: url))
    }
}

enum NetworkError: Error {
    case invalidResponse
    case invalidURL
    case httpError(statusCode: Int)
    case rateLimited
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
        case .rateLimited:
            return String(localized: "Se alcanzó el límite de pedidos a la API. Probá de nuevo en unos minutos.")
        case .decodingFailed:
            return String(localized: "No se pudo interpretar la respuesta del servidor.")
        }
    }
}
