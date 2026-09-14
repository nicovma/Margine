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
        List {
            if match.hasArbitrage, let margin = match.arbitrageMargin {
                Section {
                    Label {
                        Text("Arbitraje: ") + Text(String(format: "%.2f", margin)) + Text("% de margen")
                    } icon: {
                        Image(systemName: "dollarsign.circle.fill")
                    }
                    .foregroundStyle(.green)
                }
            }

            Section("Mejor cuota por resultado") {
                ForEach(Array(match.bestOutcomes.keys.sorted()), id: \.self) { outcomeName in
                    if let best = match.bestOutcomes[outcomeName] {
                        HStack {
                            Text(outcomeName)
                            Spacer()
                            Text(best.bookmakerTitle)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", best.price))
                                .bold()
                        }
                    }
                }
            }
        }
        .navigationTitle(Text(match.homeTeam) + Text(" vs ") + Text(match.awayTeam))
    }
}

#Preview {
    NavigationStack {
        OddsDetailView(match: MockDetectArbitrageUseCase.sampleMatches[1])
    }
}
