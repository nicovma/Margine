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
                .searchable(text: $viewModel.searchText, prompt: "Buscar equipo")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        arbitrageOnlyToggle
                    }
                }
                .alert("No se pudo actualizar", isPresented: Binding(
                    get: { viewModel.bannerErrorMessage != nil },
                    set: { if !$0 { viewModel.bannerErrorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.bannerErrorMessage ?? "")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let matches) where matches.isEmpty:
            emptyResultsView
                .refreshable { await viewModel.manualRefresh() }
        case .loaded(let matches):
            List(matches) { match in
                ZStack {
                    NavigationLink(value: match) { EmptyView() }
                        .opacity(0)
                    MatchRowView(match: match)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))
            .refreshable { await viewModel.manualRefresh() }
            .navigationDestination(for: MatchOdds.self) { match in
                OddsDetailView(match: match)
            }
        case .error(let message):
            Text(message)
                .foregroundStyle(.red)
        }
    }

    private var emptyResultsView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Sin resultados")
                    .font(.system(size: 16, weight: .semibold))
                if isFiltering {
                    Text("Ningún partido coincide con el filtro actual.")
                        .font(.system(size: 13.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("No hay partidos disponibles en este momento.")
                        .font(.system(size: 13.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 300)
        }
        .accessibilityIdentifier("oddsListEmptyState")
    }

    private var isFiltering: Bool {
        viewModel.showOnlyArbitrage || !viewModel.searchText.isEmpty
    }

    private var arbitrageOnlyToggle: some View {
        Button {
            viewModel.showOnlyArbitrage.toggle()
        } label: {
            BrandMarkIcon(color: viewModel.showOnlyArbitrage ? .white : .primary)
                .frame(width: 18, height: 18)
                .padding(9)
                .background(viewModel.showOnlyArbitrage ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .clipShape(Circle())
        }
        .accessibilityIdentifier("arbitrageOnlyToggle")
        .accessibilityLabel("Solo arbitraje")
        .accessibilityAddTraits(viewModel.showOnlyArbitrage ? .isSelected : [])
    }
}

#Preview {
    OddsListView(viewModel: OddsListViewModel(liveOddsService: MockLiveOddsService()))
}
