//
//  LoginView.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var isSignUpMode = false
    @FocusState private var focusedField: Field?

    @ScaledMetric private var titleSize: CGFloat = 24
    @ScaledMetric private var subtitleSize: CGFloat = 14
    @ScaledMetric private var fieldLabelSize: CGFloat = 11.5
    @ScaledMetric private var fieldValueSize: CGFloat = 16
    @ScaledMetric private var submitLabelSize: CGFloat = 16
    @ScaledMetric private var errorMessageSize: CGFloat = 13.5
    @ScaledMetric private var googleButtonSize: CGFloat = 15
    @ScaledMetric private var modeToggleSize: CGFloat = 14
    @ScaledMetric private var dividerLabelSize: CGFloat = 12.5

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
                .accessibilityHidden(true)

            VStack(spacing: 3) {
                Text(isSignUpMode ? "Crear cuenta" : "Ingresar")
                    .font(.system(size: titleSize, weight: .heavy))
                    .foregroundStyle(.primary)
                Text(isSignUpMode ? "Creá tu cuenta para empezar" : "Accedé para ver tus partidos")
                    .font(.system(size: subtitleSize))
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
                    .accessibilityLabel("Email")
            }

            fieldCard(label: "Contraseña") {
                SecureField("••••••••", text: $viewModel.password)
                    .textContentType(isSignUpMode ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .accessibilityIdentifier("loginPasswordField")
                    .accessibilityLabel("Contraseña")
            }
        }
    }

    private func fieldCard(label: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: fieldLabelSize, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .accessibilityHidden(true)
            content()
                .font(.system(size: fieldValueSize))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
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
                    .font(.system(size: submitLabelSize, weight: .bold))
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
                    .font(.system(size: errorMessageSize))
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("loginErrorMessage")
                    .accessibilityAddTraits(.updatesFrequently)
                    .onAppear {
                        AccessibilityNotification.Announcement(message).post()
                    }
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
                        .accessibilityHidden(true)
                    Text("Continuar con Google")
                        .font(.system(size: googleButtonSize, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color(.secondarySystemGroupedBackground))
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
                    .font(.system(size: modeToggleSize, weight: .semibold))
            }
            .accessibilityIdentifier("loginModeToggle")
        }
    }

    private var divider: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color(.separator)).frame(height: 1).accessibilityHidden(true)
            Text("o continuá con")
                .font(.system(size: dividerLabelSize, weight: .semibold))
                .foregroundStyle(.secondary)
                .fixedSize()
            Rectangle().fill(Color(.separator)).frame(height: 1).accessibilityHidden(true)
        }
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel(authUseCase: DefaultAuthUseCase(repository: MockAuthRepository())))
}
