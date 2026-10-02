//
//  AuthError.swift
//  Margine
//
//  Created by Nicolas Valentini on 2/10/2026.
//
import Foundation

/// Domain-level auth failures. `FirebaseAuthRepository` translates raw SDK
/// errors into these so nothing above the Repository layer depends on
/// FirebaseAuth/GoogleSignIn error codes. UI copy stays in the ViewModel.
enum AuthError: Error, Equatable {
    case invalidEmail
    case wrongCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case userDisabled
    case tooManyRequests
    /// The user dismissed the Google account picker — not a failure to surface.
    case cancelled
    case unknown
}
