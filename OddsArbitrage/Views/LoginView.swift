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
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    init(viewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    header
                    fields
                    actions
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 64, height: 64)
                .overlay(
                    BrandMarkIcon()
                        .frame(width: 32, height: 32)
                )

            VStack(spacing: 3) {
                Text(isSignUpMode ? "Crear cuenta" : "Ingresar")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.primary)
                Text(isSignUpMode ? "Creá tu cuenta para empezar" : "Accedé para ver tus partidos")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            fieldCard(label: "Email") {
                TextField("tu@email.com", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
                    .accessibilityIdentifier("loginEmailField")
            }

            fieldCard(label: "Contraseña") {
                SecureField("••••••••", text: $viewModel.password)
                    .textContentType(isSignUpMode ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .accessibilityIdentifier("loginPasswordField")
            }
        }
    }

    private func fieldCard(label: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
                .font(.system(size: 16))
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actions: some View {
        VStack(spacing: 16) {
            Button {
                focusedField = nil
                Task {
                    if isSignUpMode {
                        await viewModel.signUp()
                    } else {
                        await viewModel.signIn()
                    }
                }
            } label: {
                Text(isSignUpMode ? "Crear cuenta" : "Ingresar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
            .accessibilityIdentifier("loginSubmitButton")

            if case .loading = viewModel.state {
                ProgressView()
            }

            if case .error(let message) = viewModel.state {
                Text(message)
                    .font(.system(size: 13.5))
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("loginErrorMessage")
            }

            divider

            Button {
                focusedField = nil
                Task { await viewModel.signInWithGoogle() }
            } label: {
                HStack(spacing: 10) {
                    Image("GoogleLogo")
                        .resizable()
                        .frame(width: 18, height: 18)
                    Text("Continuar con Google")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityIdentifier("loginGoogleButton")

            Button {
                isSignUpMode.toggle()
            } label: {
                Text(isSignUpMode ? "¿Ya tenés cuenta? Ingresá" : "¿No tenés cuenta? Registrate")
                    .font(.system(size: 14, weight: .semibold))
            }
            .accessibilityIdentifier("loginModeToggle")
        }
    }

    private var divider: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color(.separator)).frame(height: 1)
            Text("o continuá con")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.secondary)
                .fixedSize()
            Rectangle().fill(Color(.separator)).frame(height: 1)
        }
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel(authUseCase: DefaultAuthUseCase(repository: MockAuthRepository())))
}
