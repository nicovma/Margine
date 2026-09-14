//
//  MainTabView.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import SwiftUI

struct MainTabView: View {
    private enum Tab {
        case matches, profile
    }

    let oddsListViewModel: OddsListViewModel
    let profileViewModel: ProfileViewModel
    @State private var selection: Tab = .matches

    var body: some View {
        TabView(selection: $selection) {
            OddsListView(viewModel: oddsListViewModel)
                .tabItem {
                    Label("Partidos", systemImage: "soccerball")
                }
                .tag(Tab.matches)

            ProfileView(viewModel: profileViewModel)
                .tabItem {
                    Label("Perfil", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)
        }
        // Only poll for odds while the Partidos tab is actually on screen —
        // no point spending API quota refreshing a list the user isn't looking at.
        .onAppear {
            if selection == .matches {
                oddsListViewModel.startLiveUpdates()
            }
        }
        .onDisappear {
            oddsListViewModel.stopLiveUpdates()
        }
        .onChange(of: selection) { _, newSelection in
            if newSelection == .matches {
                oddsListViewModel.startLiveUpdates()
            } else {
                oddsListViewModel.stopLiveUpdates()
            }
        }
    }
}

#Preview {
    MainTabView(
        oddsListViewModel: OddsListViewModel(liveOddsService: MockLiveOddsService()),
        profileViewModel: ProfileViewModel(
            authViewModel: AuthViewModel(authUseCase: DefaultAuthUseCase(repository: MockAuthRepository(currentUser: AuthUser(uid: "preview", email: "nico@ejemplo.com")))),
            bookmakerStore: BookmakerPreferencesStore(defaults: UserDefaults(suiteName: "MainTabView.preview")!),
            refreshOdds: {}
        )
    )
}
