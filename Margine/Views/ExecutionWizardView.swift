//
//  ExecutionWizardView.swift
//  Margine
//
import SwiftUI

/// Guides the user through placing an arbitrage bet across bookmakers.
/// Margine never places a bet for the user — it calculates amounts, refreshes
/// the price right before showing them, and lets the user open each
/// bookmaker themselves to place it. Every "placed"/"failed" status here is
/// self-reported by the user; there's no way to confirm it from the app.
struct ExecutionWizardView: View {
    @StateObject private var viewModel: ExecutionWizardViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: @autoclosure @escaping () -> ExecutionWizardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Calculá tu apuesta")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") { dismiss() }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.stage {
        case .idle, .error:
            bankrollForm
        case .refreshingOdds:
            ProgressView("Buscando la cuota más reciente…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .reviewingStakes:
            stakesReview
        case .executing, .partiallyCovered:
            legsChecklist
        case .completed:
            summary(
                title: "Listo",
                message: "Marcaste todas las patas como colocadas. Revisá cada casa para confirmar que la apuesta quedó registrada.",
                systemImage: "checkmark.circle.fill",
                tint: .green
            )
        case .cancelled:
            summary(
                title: "Cancelado",
                message: "No se registró ninguna pata pendiente como colocada.",
                systemImage: "xmark.circle.fill",
                tint: .secondary
            )
        }
    }

    // MARK: - Bankroll form

    private var bankrollForm: some View {
        Form {
            Section {
                TextField("Monto total a apostar", text: $viewModel.bankrollInput)
                    .keyboardType(.decimalPad)
            } header: {
                Text("¿Cuánto querés apostar en total?")
            } footer: {
                Text("Repartimos este monto entre las casas en proporción inversa a cada cuota, para que ganes lo mismo pase lo que pase.")
            }

            if case .error(let message) = viewModel.stage {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Calcular reparto") {
                    Task { await viewModel.start() }
                }
                .disabled(viewModel.bankrollInput.isEmpty)
            }
        }
    }

    // MARK: - Stakes review

    private var stakesReview: some View {
        Form {
            Section {
                ForEach(viewModel.legs) { leg in
                    allocationRow(leg.allocation)
                }
            } header: {
                Text("Reparto calculado")
            } footer: {
                if let plan = viewModel.plan {
                    Text("Ganancia garantizada si sale cualquiera de estos resultados: \(String(format: "%.2f", plan.guaranteedProfit)).")
                }
            }

            Section {
                Text("Esto usa la cuota más fresca que pudimos conseguir, pero sigue viniendo de un agregador de terceros — puede diferir un poco de lo que veas al entrar a cada casa. Revisá el monto antes de confirmar en cada una.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Empezar a apostar") {
                    viewModel.confirmStakes()
                }
            }
        }
    }

    private func allocationRow(_ allocation: StakeAllocation) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(allocation.outcomeName == MatchOdds.drawOutcomeKey ? String(localized: "Empate") : allocation.outcomeName)
                    .font(.headline)
                Text(allocation.bookmakerTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Cuota \(String(format: "%.2f", allocation.price))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", allocation.stake))
                    .font(.headline)
                Text("Cobrás \(String(format: "%.2f", allocation.potentialPayout))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Legs checklist (executing / partiallyCovered)

    private var legsChecklist: some View {
        Form {
            if case .partiallyCovered(let note) = viewModel.stage {
                Section {
                    Label(note, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            Section {
                ForEach(viewModel.legs) { leg in
                    legRow(leg)
                }
            } header: {
                Text("Colocá cada pata en su casa")
            }

            Section {
                Button("Cancelar", role: .destructive) {
                    viewModel.cancel()
                }
            }
        }
    }

    private func legRow(_ leg: ExecutionLeg) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            allocationRow(leg.allocation)

            Button {
                openLink(for: leg)
            } label: {
                Label("Abrir \(leg.allocation.bookmakerTitle)", systemImage: "arrow.up.right.square")
            }
            .buttonStyle(.bordered)
            .disabled(leg.status != .pending)

            if leg.status == .pending {
                HStack {
                    Button("Ya aposté") { viewModel.markPlaced(leg) }
                        .buttonStyle(.borderedProminent)
                    Button("No pude apostar") { viewModel.markFailed(leg, reason: nil) }
                        .buttonStyle(.bordered)
                }
            } else {
                statusLabel(for: leg.status)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusLabel(for status: LegStatus) -> some View {
        switch status {
        case .pending:
            EmptyView()
        case .placed:
            Label("Colocada", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:
            Label("No se pudo colocar", systemImage: "xmark.circle.fill").foregroundStyle(.red)
        case .skipped:
            Label("Salteada", systemImage: "arrow.uturn.forward.circle").foregroundStyle(.secondary)
        }
    }

    private func openLink(for leg: ExecutionLeg) {
        let link = viewModel.link(for: leg)
        if let appURL = link.appURL, UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(link.fallbackURL)
        }
    }

    // MARK: - Terminal summary

    private func summary(title: String, message: String, systemImage: String, tint: Color) -> some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(tint)
            Text(title)
                .font(.title2.bold())
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Cerrar") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ExecutionWizardView(viewModel: ExecutionWizardViewModel(
        match: MockDetectArbitrageUseCase.sampleMatches[1],
        oddsRepository: PreviewOddsRepository()
    ))
}

private final class PreviewOddsRepository: OddsRepository {
    func fetchUpcomingOdds(sport: String) async throws -> [OddsEvent] { [] }
    func refreshEvent(eventId: String) async throws -> EventRefreshResponse {
        EventRefreshResponse(
            event: OddsEvent(
                id: eventId, sportKey: "soccer_epl", commenceTime: .now, homeTeam: "Real Madrid", awayTeam: "Barcelona",
                bookmakers: [
                    Bookmaker(key: "bet365", title: "Bet365", markets: [Market(key: "h2h", outcomes: [Outcome(name: "Real Madrid", price: 2.60), Outcome(name: "Draw", price: 3.40), Outcome(name: "Barcelona", price: 2.90)])]),
                    Bookmaker(key: "betfair_ex_eu", title: "Betfair", markets: [Market(key: "h2h", outcomes: [Outcome(name: "Real Madrid", price: 2.40), Outcome(name: "Draw", price: 3.60), Outcome(name: "Barcelona", price: 3.10)])])
                ]
            ),
            refreshedJustNow: true
        )
    }
}
