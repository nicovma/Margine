# OddsArbitrage

[![CI](https://github.com/nicovma/OddsArbitrage/actions/workflows/ci.yml/badge.svg)](https://github.com/nicovma/OddsArbitrage/actions/workflows/ci.yml)

An iOS app that tracks upcoming soccer matches and detects arbitrage ("surebet") opportunities across bookmakers, using live odds from [The Odds API](https://the-odds-api.com).

For each match, the app compares the best available price per outcome across bookmakers and computes the implied probability sum. If that sum is below 100%, there's a guaranteed profit margin regardless of the result — the app surfaces it directly in the list and in the match detail.

## Features

- Live odds ticker: polls for updated odds every 15 seconds, with pull-to-refresh and no disruption to already-loaded content.
- Arbitrage detection with computed profit margin per match.
- Search by team name and a toggle to show arbitrage-only matches.
- Email/password authentication (Firebase Auth), with the session gate reacting to real auth state changes, not just local view state.
- Spanish and English UI (String Catalog).

## Architecture

MVVM + UseCase + Repository, each layer behind a protocol so it can be swapped or mocked independently:

```
View ── ViewModel ── UseCase ── Repository ── NetworkService / Firebase SDK
                         │
                    (business logic:
                  arbitrage detection,
                   auth error mapping)
```

- **Repository** (`OddsRepository`, `AuthRepository`) — the only layer that knows about network requests or the Firebase SDK.
- **UseCase** (`DetectArbitrageUseCase`, `AuthUseCase`) — pure business logic, no I/O. This is where the arbitrage math lives, independently testable from networking.
- **ViewModel** — exposes a `ViewState<T>` enum (`idle` / `loading` / `loaded` / `error`) to each View, and owns Combine wiring (live odds pipeline, search debounce, auth state subscription).
- **View** — SwiftUI, no business logic.

Live odds use a small reactive pipeline: `LiveOddsService` exposes a `CurrentValueSubject` polled every 15s via `Timer.publish`, bridged to an `actor LiveOddsCoordinator` that guards against overlapping refreshes (manual pull-to-refresh vs. the automatic poll never race).

## Tech stack

- Swift 5, SwiftUI, Swift Concurrency (async/await, actors)
- Combine (live odds pipeline, search debounce, auth state)
- Firebase Auth (email/password)
- Unit tests in both **Swift Testing** and **XCTest** (used deliberately side by side across the suite), plus an XCUITest target for the login flow

## Setup

The app needs two files that are gitignored on purpose (never commit API keys or Firebase config):

1. `Resources/Config.xcconfig`:
   ```
   API_KEY = <your-the-odds-api-key>
   ```
   Get a free key at [the-odds-api.com](https://the-odds-api.com) (no card required, ~500 requests/month).

2. `OddsArbitrage/GoogleService-Info.plist` — download it from your own Firebase project (Firebase Console → Project settings → your iOS app), with Email/Password sign-in enabled under Authentication.

Then open `OddsArbitrage.xcodeproj` and run. Requires Xcode 16+, iOS 18.5+.

## Testing

```
xcodebuild test -project OddsArbitrage.xcodeproj -scheme OddsArbitrage \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

Unit tests cover the arbitrage use case, both ViewModels, the live-odds actor/Combine pipeline, and the networking layer (status codes, decoding failures, URL construction) via a stubbed `URLProtocol`. The UI test target exercises the real login flow (happy and error paths) against a dedicated test Firebase account.

CI (GitHub Actions) builds and runs the full suite on every push and pull request against `main`/`develop`/`feature/**`.

## Localization

UI strings are in a String Catalog (`Localizable.xcstrings`), source language Spanish with English translations. Dynamic content (team names, computed margins) is kept outside the translated segments on purpose — it's data, not UI copy.

## Git history

Built with a real Git Flow: a `feature/*` (or `fix/*`) branch per unit of work, merged with `--no-ff` into `develop`. The history is preserved as-is, including the original design/implementation split per layer.
