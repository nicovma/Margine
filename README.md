# Margine

[![CI](https://github.com/nicovma/Margine/actions/workflows/ci.yml/badge.svg)](https://github.com/nicovma/Margine/actions/workflows/ci.yml)

An iOS app that tracks upcoming soccer matches and detects arbitrage ("surebet") opportunities across bookmakers, using live odds from [The Odds API](https://the-odds-api.com).

For each match, the app compares the best available price per outcome across bookmakers and computes the implied probability sum. If that sum is below 100%, there's a guaranteed profit margin regardless of the result — the app surfaces it in the match list, in the match detail, and explains how to actually place that bet.

## Features

- Live odds ticker: polls for updated odds every 60 seconds, with pull-to-refresh and no disruption to already-loaded content.
- Arbitrage detection with computed profit margin per match, plus an in-app explanation of how to split the stake to lock in the profit.
- Search by team name and a toggle to show arbitrage-only matches.
- A **Partidos / Perfil** tab bar. Profile shows the signed-in account, lets the user pick which bookmakers count toward arbitrage detection (a house they don't have an account with shouldn't factor into the calculation), and sign out.
- Email/password **and** Sign in with Google (Firebase Auth), with the session gate reacting to real auth state changes, not just local view state.
- Spanish and English UI (String Catalog).

## Architecture

MVVM + UseCase + Repository, each layer behind a protocol so it can be swapped or mocked independently:

```
View ── ViewModel ── UseCase ── Repository ── NetworkService ── The Odds API
                         │                 └─ FirebaseAuthRepository ── Firebase Auth / Google Sign-In
                    (business logic:
                  arbitrage detection,
                  bookmaker filtering,
                   auth error mapping)
```

- **Repository** (`OddsRepository`, `AuthRepository`) — the only layer that knows about network requests or the Firebase/GoogleSignIn SDKs. `OddsRepository` talks to [The Odds API](https://the-odds-api.com) over plain HTTP via `NetworkService`; `AuthRepository` talks to Firebase Auth (email/password and Google) via the Firebase/GoogleSignIn SDKs.
- **UseCase** (`DetectArbitrageUseCase`, `AuthUseCase`) — pure business logic, no I/O. This is where the arbitrage math lives, independently testable from networking.
- **ViewModel** — exposes a `ViewState<T>` enum (`idle` / `loading` / `loaded` / `error`) to each View, and owns Combine wiring (live odds pipeline, search debounce, auth state subscription).
- **View** — SwiftUI, no business logic.

Live odds use a small reactive pipeline: `LiveOddsService` exposes a `CurrentValueSubject` polled every 60s via `Timer.publish`, bridged to an `actor LiveOddsCoordinator` that guards against overlapping refreshes (manual pull-to-refresh vs. the automatic poll never race).

**Bookmaker filtering** (`Services/Bookmakers/`) is its own small piece, same protocol-first pattern: `BookmakerPreferencesStore` (backed by `UserDefaults`) records every bookmaker the app has ever seen in a response and tracks which ones are disabled — new bookmakers are opt-out, so existing behavior never silently changes. It's injected straight into `DefaultDetectArbitrageUseCase`, the only layer that already needs to look at each bookmaker's odds to compute `bestOutcomes` — filtering there means the Repository and ViewModel don't need to know it exists. The Profile tab reads and writes the same store, and triggers a manual refresh after a toggle so the change is reflected without waiting for the next poll.

## Tech stack

- Swift 5, SwiftUI, Swift Concurrency (async/await, actors)
- Combine (live odds pipeline, search debounce, auth state, bookmaker preferences)
- Firebase Auth (email/password + Google)
- Unit tests in both **Swift Testing** and **XCTest** (used deliberately side by side across the suite), plus an XCUITest target for the login flow

## Setup

The app needs two files that are gitignored on purpose (never commit API keys or Firebase config):

1. `Resources/Config.xcconfig`:
   ```
   API_KEY = <your-the-odds-api-key>
   ```
   Get a free key at [the-odds-api.com](https://the-odds-api.com) (no card required, ~500 requests/month).

2. `Margine/GoogleService-Info.plist` — download it from your own Firebase project (Firebase Console → Project settings → your iOS app), with **Email/Password** and **Google** both enabled under Authentication → Sign-in method. The Google URL scheme and client ID in `Info.plist` are read straight from this file's `REVERSED_CLIENT_ID`/`CLIENT_ID`, so there's nothing else to configure beyond enabling the provider.

Then open `Margine.xcodeproj` and run. Requires Xcode 16+, iOS 18.5+.

## Testing

```
xcodebuild test -project Margine.xcodeproj -scheme Margine \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

Unit tests cover the arbitrage use case (including bookmaker filtering), the bookmaker preferences store, all four ViewModels, the live-odds actor/Combine pipeline, and the networking layer (status codes, decoding failures, URL construction) via a stubbed `URLProtocol`. The UI test target exercises the real login flow (happy and error paths) against a dedicated test Firebase account.

CI (GitHub Actions) builds and runs the full suite on every push and pull request against `main`/`develop`/`feature/**`.

## Localization

UI strings are in a String Catalog (`Localizable.xcstrings`), source language Spanish with English translations. Dynamic content (team names, computed margins, bookmaker names) is kept outside the translated segments on purpose — it's data, not UI copy. The one deliberate exception is the literal outcome name `"Draw"` that the odds API always returns in English regardless of region: the app maps it to a proper localized "Empate"/"Draw" for display, since it's a fixed piece of API vocabulary (there are only ever three possible outcome names for a match), not open-ended data like a team name.

## Git history

Built with a real Git Flow: a `feature/*` (or `fix/*`) branch per unit of work, merged with `--no-ff` into `develop`. The history is preserved as-is, including the original design/implementation split per layer.
