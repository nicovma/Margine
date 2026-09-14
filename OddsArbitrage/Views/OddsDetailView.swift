//
//  OddsDetailView.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation
import SwiftUI

struct OddsDetailView: View {
    let match: MatchOdds

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if match.hasArbitrage, let margin = match.arbitrageMargin {
                    arbitrageBanner(margin: margin)
                }

                bestOutcomesSection
                howToPlaySection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text(match.homeTeam) + Text(" vs ") + Text(match.awayTeam))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func arbitrageBanner(margin: Double) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 18))
                )
            VStack(alignment: .leading, spacing: 1) {
                Text("Oportunidad de arbitraje")
                    .font(.system(size: 15, weight: .bold))
                (Text("Arbitraje: ") + Text(String(format: "%.1f", margin)) + Text("% de margen"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var bestOutcomesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mejor cuota por resultado")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(Array(match.bestOutcomes.keys.sorted()), id: \.self) { outcomeName in
                    if let best = match.bestOutcomes[outcomeName] {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(outcomeLabel(outcomeName))
                                    .font(.system(size: 16, weight: .semibold))
                                Text(best.bookmakerTitle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.2f", best.price))
                                .font(.system(size: 20, weight: .bold))
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }

    private func outcomeLabel(_ outcomeName: String) -> String {
        outcomeName == MatchOdds.drawOutcomeKey ? String(localized: "Empate") : outcomeName
    }

    private var howToPlaySection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 4) {
                Text("Cómo jugar")
                    .font(.system(size: 14, weight: .bold))
                Text("Elegimos la cuota más alta de cada resultado por vos. Cuando aparece el arbitraje, repartí tu apuesta entre las casas en proporción inversa a la cuota de cada resultado: así ganás lo mismo pase lo que pase, y ese monto supera lo apostado.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        OddsDetailView(match: MockDetectArbitrageUseCase.sampleMatches[1])
    }
}
