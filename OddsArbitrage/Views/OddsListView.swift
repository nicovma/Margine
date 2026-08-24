//
//  OddsListView.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation
import SwiftUI

struct OddsListView: View {
    @StateObject private var viewModel: OddsListViewModel
    
    init(viewModel: OddsListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Próximos partidos")
                .task { await viewModel.loadOdds() }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let matches):
            List(matches) { match in
                NavigationLink(value: match) {
                    matchRow(match)
                }
            }
            .navigationDestination(for: MatchOdds.self) { match in
                OddsDetailView(match: match)
            }
        case .error(let message):
            Text(message)
                .foregroundStyle(.red)
        }
    }
    
    private func matchRow(_ match: MatchOdds) -> some View {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(match.homeTeam) vs \(match.awayTeam)")
                    Text(match.commenceTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if match.hasArbitrage {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }

