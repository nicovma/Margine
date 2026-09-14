//
//  AuthUseCase.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import Combine
import Foundation
import UIKit

protocol AuthUseCase {
    var currentUser: AuthUser? { get }
    var authStateChanges: AnyPublisher<AuthUser?, Never> { get }
    func signIn(email: String, password: String) async throws -> AuthUser
    func signUp(email: String, password: String) async throws -> AuthUser
    func signInWithGoogle(presenting: UIViewController) async throws -> AuthUser
    func signOut() throws
}
