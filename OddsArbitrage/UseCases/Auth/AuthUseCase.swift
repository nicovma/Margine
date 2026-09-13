//
//  AuthUseCase.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Foundation

protocol AuthUseCase {
    var currentUser: AuthUser? { get }
    func signIn(email: String, password: String) async throws -> AuthUser
    func signUp(email: String, password: String) async throws -> AuthUser
    func signOut() throws
}
