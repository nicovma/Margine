//
//  MatchRowView.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import SwiftUI

struct MatchRowView: View {
    let match: MatchOdds

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(match.homeTeam) + Text(" vs ") + Text(match.awayTeam)
                Spacer()
                Text(match.commenceTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 16, weight: .semibold))

            if match.hasArbitrage, let margin = match.arbitrageMargin {
                Label {
                    Text("Arbitraje: ") + Text(String(format: "%.1f", margin)) + Text("% de margen")
                } icon: {
                    Image(systemName: "clock.fill")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color("ArbitrageGreenText"))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color("ArbitrageGreenBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .accessibilityLabel("Oportunidad de arbitraje")
            }

            oddsRow
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(match.hasArbitrage ? Color("ArbitrageGreen") : .clear, lineWidth: 1.5)
        )
    }

    private var oddsRow: some View {
        HStack(spacing: 8) {
            oddsChip(label: "1", outcome: match.bestOutcomes[match.homeTeam])
            oddsChip(label: "X", outcome: match.bestOutcomes[MatchOdds.drawOutcomeKey])
            oddsChip(label: "2", outcome: match.bestOutcomes[match.awayTeam])
        }
    }

    private func oddsChip(label: String, outcome: BestOutcome?) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(outcome.map { String(format: "%.2f", $0.price) } ?? "—")
                .font(.system(size: 14.5, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

#Preview {
    VStack(spacing: 10) {
        ForEach(MockDetectArbitrageUseCase.sampleMatches) { match in
            MatchRowView(match: match)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
