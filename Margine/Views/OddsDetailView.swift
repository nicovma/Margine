//
//  OddsDetailView.swift
//  Margine
//
//  Created by Nicolas Valentini on 24/8/2026.
//
import Foundation
import SwiftUI

struct OddsDetailView: View {
    let match: MatchOdds

    @ScaledMetric private var bannerIconSize: CGFloat = 18
    @ScaledMetric private var bannerTitleSize: CGFloat = 15
    @ScaledMetric private var bannerSubtitleSize: CGFloat = 13
    @ScaledMetric private var sectionTitleSize: CGFloat = 13
    @ScaledMetric private var outcomeNameSize: CGFloat = 16
    @ScaledMetric private var outcomeBookmakerSize: CGFloat = 13
    @ScaledMetric private var outcomePriceSize: CGFloat = 20
    @ScaledMetric private var howToPlayIconSize: CGFloat = 18
    @ScaledMetric private var howToPlayTitleSize: CGFloat = 14
    @ScaledMetric private var howToPlayBodySize: CGFloat = 13
    @ScaledMetric private var disclaimerSize: CGFloat = 11

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if match.hasArbitrage, let margin = match.arbitrageMargin {
                    arbitrageBanner(margin: margin)
                }

                bestOutcomesSection
                howToPlaySection
                disclaimerSection
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
                .fill(Color("ArbitrageGreen"))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: bannerIconSize))
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Oportunidad de arbitraje")
                    .font(.system(size: bannerTitleSize, weight: .bold))
                (Text("Arbitraje: ") + Text(String(format: "%.1f", margin)) + Text("% de margen"))
                    .font(.system(size: bannerSubtitleSize))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color("ArbitrageGreenBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private var bestOutcomesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mejor cuota por resultado")
                .font(.system(size: sectionTitleSize, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(Array(match.bestOutcomes.keys.sorted()), id: \.self) { outcomeName in
                    if let best = match.bestOutcomes[outcomeName] {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(outcomeLabel(outcomeName))
                                    .font(.system(size: outcomeNameSize, weight: .semibold))
                                Text(best.bookmakerTitle)
                                    .font(.system(size: outcomeBookmakerSize))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.2f", best.price))
                                .font(.system(size: outcomePriceSize, weight: .bold))
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(outcomeLabel(outcomeName)), \(best.bookmakerTitle)")
                        .accessibilityValue(String(format: "Cuota %.2f", best.price))
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
                .font(.system(size: howToPlayIconSize))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Cómo jugar")
                    .font(.system(size: howToPlayTitleSize, weight: .bold))
                Text("Elegimos la cuota más alta de cada resultado por vos. Cuando aparece el arbitraje, repartí tu apuesta entre las casas en proporción inversa a la cuota de cada resultado: así ganás lo mismo pase lo que pase, y ese monto supera lo apostado.\n\nPor ejemplo: con cuotas 2.00 / 4.00 / 5.00 para 1 / X / 2, apostando $100 en total repartís $52,63 al resultado 1, $26,32 al empate y $21,05 al resultado 2 (cada monto es proporcional a 1/cuota). Gane quien gane, cobrás $105,26 — quedan $5,26 de ganancia neta pase lo que pase.")
                    .font(.system(size: howToPlayBodySize))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var disclaimerSection: some View {
        Text("Margine es solo informativa: no es asesoramiento financiero ni una casa de apuestas. Las cuotas pueden cambiar en la casa de apuestas antes de que confirmes tu apuesta, y apostar puede estar restringido según tu jurisdicción — verificá la normativa local antes de usar cualquier casa de apuestas.")
            .font(.system(size: disclaimerSize))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

#Preview {
    NavigationStack {
        OddsDetailView(match: MockDetectArbitrageUseCase.sampleMatches[1])
    }
}
