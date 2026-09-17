//
//  MainTabView.swift
//  Margine
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
    let makeExecutionWizardViewModel: (MatchOdds) -> ExecutionWizardViewModel
    @State private var selection: Tab = .matches

    var body: some View {
        TabView(selection: $selection) {
            OddsListView(viewModel: oddsListViewModel, makeExecutionWizardViewModel: makeExecutionWizardViewModel)
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
        ),
        makeExecutionWizardViewModel: { match in
            ExecutionWizardViewModel(match: match, oddsRepository: PreviewMainTabRepository())
        }
    )
}

private final class PreviewMainTabRepository: OddsRepository {
    func fetchUpcomingOdds(sport: String) async throws -> [OddsEvent] { [] }
    func refreshEvent(eventId: String) async throws -> EventRefreshResponse {
        EventRefreshResponse(
            event: OddsEvent(id: eventId, sportKey: "soccer_epl", commenceTime: .now, homeTeam: "Home", awayTeam: "Away", bookmakers: []),
            refreshedJustNow: true
        )
    }
}
