//
//  ProfileView.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    @ScaledMetric private var avatarInitialSize: CGFloat = 18
    @ScaledMetric private var emailSize: CGFloat = 16
    @ScaledMetric private var bookmakerTitleSize: CGFloat = 13
    @ScaledMetric private var bookmakerSubtitleSize: CGFloat = 12.5
    @ScaledMetric private var bookmakerEmptySize: CGFloat = 13.5
    @ScaledMetric private var signOutSize: CGFloat = 16
    @ScaledMetric private var privacyLinkSize: CGFloat = 14

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    accountCard
                    bookmakerSection
                    signOutButton
                    privacyPolicyLink
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Perfil")
        }
    }

    private var accountCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(initial)
                        .font(.system(size: avatarInitialSize, weight: .bold))
                        .foregroundStyle(.white)
                )
                .accessibilityHidden(true)
            Text(viewModel.userEmail ?? String(localized: "Usuario"))
                .font(.system(size: emailSize, weight: .semibold))
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var bookmakerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Casas de apuestas para arbitraje")
                    .font(.system(size: bookmakerTitleSize, weight: .bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text("El detector solo compara cuotas entre las casas activadas.")
                    .font(.system(size: bookmakerSubtitleSize))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            if viewModel.bookmakerRows.isEmpty {
                Text("Todavía no vimos casas de apuestas. Abrí la lista de partidos para que se detecten.")
                    .font(.system(size: bookmakerEmptySize))
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .accessibilityIdentifier("bookmakerEmptyState")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.bookmakerRows.enumerated()), id: \.element.id) { index, row in
                        if index > 0 {
                            Divider().padding(.leading, 16)
                        }
                        Toggle(row.title, isOn: Binding(
                            get: { row.isEnabled },
                            set: { viewModel.setBookmakerEnabled($0, key: row.key) }
                        ))
                        .tint(.accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .accessibilityIdentifier("bookmakerToggle_\(row.key)")
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            viewModel.signOut()
        } label: {
            Text("Cerrar sesión")
                .font(.system(size: signOutSize, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityIdentifier("profileSignOutButton")
    }

    private var privacyPolicyLink: some View {
        Link(destination: URL(string: "https://nicovma.github.io/Margine/privacy-policy.html")!) {
            Text("Política de privacidad")
                .font(.system(size: privacyLinkSize))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
        .accessibilityIdentifier("privacyPolicyLink")
    }

    private var initial: String {
        guard let email = viewModel.userEmail, let first = email.first else { return "?" }
        return String(first).uppercased()
    }
}

#Preview {
    let store = BookmakerPreferencesStore(defaults: UserDefaults(suiteName: "ProfileView.preview")!)
    store.recordSeen([
        Bookmaker(key: "bet365", title: "Bet365", markets: []),
        Bookmaker(key: "betfair", title: "Betfair", markets: []),
        Bookmaker(key: "pinnacle", title: "Pinnacle", markets: [])
    ])
    return ProfileView(viewModel: ProfileViewModel(
        authViewModel: AuthViewModel(authUseCase: DefaultAuthUseCase(repository: MockAuthRepository(currentUser: AuthUser(uid: "preview", email: "nico@ejemplo.com")))),
        bookmakerStore: store,
        refreshOdds: {}
    ))
}
