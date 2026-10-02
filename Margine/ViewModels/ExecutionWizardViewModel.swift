//
//  ExecutionWizardViewModel.swift
//  Margine
//
import Foundation

/// Drives the "atomicidad práctica" execution wizard for one match: refresh
/// the event on demand, split the bankroll into stakes, and guide the user
/// leg by leg — the user places every bet themselves, in each bookmaker's
/// own app or site; this only tracks what they report back.
@MainActor
final class ExecutionWizardViewModel: ObservableObject {
    let match: MatchOdds

    @Published private(set) var stage: WizardStage = .idle
    @Published var bankrollInput: String
    @Published private(set) var legs: [ExecutionLeg] = []
    @Published private(set) var plan: StakePlan?

    private let oddsRepository: OddsRepository
    private let preferences: BookmakerPreferences
    private let bestOutcomesCalculator: BestOutcomesCalculating
    private let calculateStakes: CalculateStakeAllocationUseCase
    private let recalculatePartialCoverage: RecalculatePartialCoverageUseCase
    private let deepLinkResolver: BookmakerDeepLinkResolving
    private let analytics: AnalyticsLogging
    private let bankrollStore: BankrollStoring

    init(
        match: MatchOdds,
        oddsRepository: OddsRepository,
        preferences: BookmakerPreferences = AllowAllBookmakerPreferences(),
        bestOutcomesCalculator: BestOutcomesCalculating = BestOutcomesCalculator(),
        calculateStakes: CalculateStakeAllocationUseCase = DefaultCalculateStakeAllocationUseCase(),
        recalculatePartialCoverage: RecalculatePartialCoverageUseCase = DefaultRecalculatePartialCoverageUseCase(),
        deepLinkResolver: BookmakerDeepLinkResolving = DefaultBookmakerDeepLinkResolver(),
        analytics: AnalyticsLogging = NoOpAnalyticsLogger(),
        bankrollStore: BankrollStoring = DefaultBankrollStore()
    ) {
        self.match = match
        self.oddsRepository = oddsRepository
        self.preferences = preferences
        self.bestOutcomesCalculator = bestOutcomesCalculator
        self.calculateStakes = calculateStakes
        self.recalculatePartialCoverage = recalculatePartialCoverage
        self.deepLinkResolver = deepLinkResolver
        self.analytics = analytics
        self.bankrollStore = bankrollStore
        self.bankrollInput = bankrollStore.lastBankroll.map { String($0) } ?? ""
    }

    var allLegsPlaced: Bool {
        !legs.isEmpty && legs.allSatisfy { $0.status == .placed }
    }

    /// Refreshes this event on demand (bypassing the worker's normal cache
    /// cycle) and calculates the stake plan against the freshest price
    /// available. Still not a perfect price — see the disclaimer shown by
    /// the wizard view.
    func start() async {
        let normalizedInput = bankrollInput.replacingOccurrences(of: ",", with: ".")
        guard let bankroll = Double(normalizedInput), bankroll > 0 else {
            stage = .error(String(localized: "Ingresá un monto válido para calcular el reparto."))
            return
        }

        stage = .refreshingOdds
        analytics.logStakeWizardOpened(matchId: match.id)

        do {
            let response = try await oddsRepository.refreshEvent(eventId: match.id)
            let freshBestOutcomes = await bestOutcomesCalculator.bestOutcomes(for: response.event, preferences: preferences)
            let newPlan = try calculateStakes.execute(matchId: match.id, bestOutcomes: freshBestOutcomes, bankroll: bankroll)
            plan = newPlan
            legs = newPlan.allocations.map { ExecutionLeg(allocation: $0) }
            bankrollStore.save(bankroll)
            stage = .reviewingStakes
        } catch {
            stage = .error(error.localizedDescription)
        }
    }

    func confirmStakes() {
        stage = .executing
    }

    func link(for leg: ExecutionLeg) -> BookmakerLink {
        deepLinkResolver.resolveLink(
            bookmakerKey: leg.allocation.bookmakerKey,
            bookmakerTitle: leg.allocation.bookmakerTitle,
            homeTeam: match.homeTeam,
            awayTeam: match.awayTeam
        )
    }

    func markPlaced(_ leg: ExecutionLeg) {
        updateStatus(.placed, for: leg)
        analytics.logLegPlaced(bookmakerKey: leg.allocation.bookmakerKey)
        if allLegsPlaced {
            stage = .completed
            analytics.logWizardCompleted(matchId: match.id)
        }
    }

    func markFailed(_ leg: ExecutionLeg, reason: String?) {
        updateStatus(.failed(reason: reason), for: leg)
        recalculateCoverage()
    }

    func markSkipped(_ leg: ExecutionLeg) {
        updateStatus(.skipped, for: leg)
        recalculateCoverage()
    }

    func cancel() {
        stage = .cancelled
    }

    private func updateStatus(_ status: LegStatus, for leg: ExecutionLeg) {
        guard let index = legs.firstIndex(where: { $0.id == leg.id }) else { return }
        legs[index].status = status
    }

    private func recalculateCoverage() {
        guard let plan else { return }
        let coverage = recalculatePartialCoverage.execute(originalPlan: plan, legs: legs)
        for updated in coverage.updatedAllocations {
            guard let index = legs.firstIndex(where: { $0.id == updated.id }) else { continue }
            legs[index] = ExecutionLeg(allocation: updated, status: legs[index].status)
        }
        stage = .partiallyCovered(note: coverage.note)
        analytics.logWizardPartialCoverage(matchId: match.id)
    }
}
