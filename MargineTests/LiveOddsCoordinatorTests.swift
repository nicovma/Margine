//
//  LiveOddsCoordinatorTests.swift
//  Margine
//
//  Created by Nicolas Valentini on 12/9/2026.
//
import Testing
@testable import Margine

@Suite
struct LiveOddsCoordinatorTests {

    @Test
    func refreshIfNeeded_returnsMatches_onSuccess() async throws {
        let mock = MockDetectArbitrageUseCase()
        mock.result = .success(MockDetectArbitrageUseCase.sampleMatches)
        let sut = LiveOddsCoordinator(useCase: mock, sport: "soccer_epl")

        let matches = try await sut.refreshIfNeeded()

        #expect(matches?.count == MockDetectArbitrageUseCase.sampleMatches.count)
    }

    @Test
    func refreshIfNeeded_whenAlreadyRefreshing_skipsSecondCall_andCallsUseCaseOnlyOnce() async throws {
        let mock = SlowMockDetectArbitrageUseCase()
        let sut = LiveOddsCoordinator(useCase: mock, sport: "soccer_epl")

        async let first = sut.refreshIfNeeded()
        await mock.waitUntilStarted() // esperamos la señal real, no un tiempo fijo

        let second = try await sut.refreshIfNeeded()
        #expect(second == nil)

        await mock.resume(with: MockDetectArbitrageUseCase.sampleMatches)
        let firstResult = try await first

        #expect(firstResult?.count == MockDetectArbitrageUseCase.sampleMatches.count)
        let callCount = await mock.executeCallCount
        #expect(callCount == 1) // la prueba real del guard
    }
}

actor SlowMockDetectArbitrageUseCase: DetectArbitrageUseCase {
    private(set) var executeCallCount = 0
    private var pendingContinuation: CheckedContinuation<[MatchOdds], Error>?
    private var startedContinuation: CheckedContinuation<Void, Never>?

    func execute(sport: String) async throws -> [MatchOdds] {
        executeCallCount += 1
        startedContinuation?.resume()
        startedContinuation = nil
        return try await withCheckedThrowingContinuation { continuation in
            self.pendingContinuation = continuation
        }
    }

    func waitUntilStarted() async {
        if executeCallCount > 0 { return }
        await withCheckedContinuation { continuation in
            self.startedContinuation = continuation
        }
    }

    func resume(with matches: [MatchOdds]) {
        pendingContinuation?.resume(returning: matches)
        pendingContinuation = nil
    }
}
