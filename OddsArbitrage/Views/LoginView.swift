//
//  LoginView.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var isSignUpMode = false

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .accessibilityIdentifier("loginEmailField")

                    SecureField("Contraseña", text: $viewModel.password)
                        .textContentType(isSignUpMode ? .newPassword : .password)
                        .accessibilityIdentifier("loginPasswordField")
                }

                Section {
                    Button(isSignUpMode ? "Crear cuenta" : "Ingresar") {
                        Task {
                            if isSignUpMode {
                                await viewModel.signUp()
                            } else {
                                await viewModel.signIn()
                            }
                        }
                    }
                    .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
                    .accessibilityIdentifier("loginSubmitButton")

                    if case .loading = viewModel.state {
                        ProgressView()
                    }

                    if case .error(let message) = viewModel.state {
                        Text(message)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("loginErrorMessage")
                    }
                }

                Section {
                    Button(isSignUpMode ? "¿Ya tenés cuenta? Ingresá" : "¿No tenés cuenta? Registrate") {
                        isSignUpMode.toggle()
                    }
                    .accessibilityIdentifier("loginModeToggle")
                }
            }
            .navigationTitle(isSignUpMode ? "Crear cuenta" : "Ingresar")
        }
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel(authUseCase: DefaultAuthUseCase(repository: MockAuthRepository())))
}
