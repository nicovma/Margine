# Architecture

## Overview

Margine is an iOS app that tracks upcoming soccer matches and detects arbitrage ("surebet") opportunities across bookmakers, using live odds sourced from The Odds API through a self-hosted caching backend. It's built for bettors who want a fast way to spot risk-free profit windows before odds move, without manually comparing several bookmaker apps.

## Layers & data flow

```
View ── ViewModel ── UseCase ── Repository ── NetworkService ── margine-odds-worker ── The Odds API
                         │                 │              (Cloudflare, caches The Odds API)
                         │                 └─ FirebaseAuthRepository ── Firebase Auth / Google Sign-In
                    (business logic:
                  arbitrage detection,
                  bookmaker filtering,
                   auth error mapping)
```

- **View** (SwiftUI) — no business logic, renders whatever `ViewState` the ViewModel exposes.
- **ViewModel** — owns `@Published` state and Combine wiring (debounced search, filter toggles, auth state subscription). Talks only to UseCases and Services, never to a Repository directly.
- **UseCase** — pure business logic, no I/O: arbitrage math, auth validation, bookmaker filtering. Independently testable from networking.
- **Repository** — the only layer that knows about network requests or the Firebase/GoogleSignIn SDKs.
- **NetworkService** — thin `URLSession` wrapper: builds requests, decodes responses, maps HTTP status codes to typed errors.

### End-to-end flow: opening the match list

1. The user opens the app and lands on the **Partidos** tab. `MainTabView` calls `OddsListViewModel.startLiveUpdates()`, which tells `LiveOddsService` to start polling.
2. `LiveOddsService` fires an immediate refresh, then a `Timer.publish` every 60 seconds for as long as the tab is on screen (`MainTabView` stops polling when the user switches to Perfil, so background tabs don't burn API quota).
3. Each tick calls into `actor LiveOddsCoordinator`, which guards against overlapping requests with an `isRefreshing` flag — if a poll fires while a pull-to-refresh (or another poll) is still in flight, it's a no-op instead of a duplicate request.
4. The coordinator calls `DefaultDetectArbitrageUseCase.execute(sport:)`, which asks `DefaultOddsRepository` for upcoming odds. The repository builds a request against `margine-odds-worker` (not The Odds API directly) via `NetworkService`, and also records every bookmaker seen in the response into `BookmakerPreferencesStore`, so the Profile tab's filter list stays current without a separate fetch.
5. The use case computes, per match, the best available price per outcome across the bookmakers the user has enabled, sums the implied probabilities, and flags arbitrage when that sum is below 100%.
6. `LiveOddsService` publishes the result on a `CurrentValueSubject<[MatchOdds]?, Never>`.
7. `OddsListViewModel` combines three publishers with `combineLatest` — the matches stream, the `showOnlyArbitrage` toggle, and a debounced search stream (an immediate first emission merged with a 300ms-debounced one, so typing doesn't feel laggy but the initial state renders instantly) — and republishes the filtered result as `state = .loaded(filtered)`.
8. `OddsListView` observes `state` and re-renders.

## Key design decisions

**Manual composition root in `MargineApp.swift`, no DI framework.**
Alternatives considered: a container/resolver-based DI framework (e.g. Factory), a service locator.
Why this: the object graph is small (roughly a dozen concrete types) and every dependency is a protocol passed through initializers. A DI framework would add indirection and a learning-curve cost with no real payoff at this size — `MargineApp.init()` wiring everything by hand is easy to read top-to-bottom and the compiler catches missing dependencies for free.

**`actor LiveOddsCoordinator` with a reentrancy guard (`isRefreshing`).**
Alternatives considered: a `Task` cancellation-based approach (cancel the in-flight poll on manual refresh), a simple `Bool` flag on the `@MainActor` ViewModel.
Why this: pull-to-refresh and the 60s automatic poll are two independent triggers for the same operation, and firing both concurrently would double-request the (rate-limited) backend for no benefit — the second caller just wants "the latest odds," not its own round trip. An `actor` makes the guard-check-and-set sequence atomic without manual locking, and keeps the coordination logic out of the ViewModel (which stays `@MainActor` and UI-focused) and out of the Repository (which stays a dumb data-access layer).

**Combine for the live odds pipeline, not async/await alone.**
Alternatives considered: an `AsyncStream` driven by a `Task` loop, or exposing odds purely as a one-shot `async` function called on a timer with no stream abstraction.
Why this: the pipeline isn't just "fetch odds" — it's several independent, continuously-changing inputs (live matches, a search string, a boolean toggle) that need to be combined and re-filtered on *any* of them changing, with debouncing on one input only. That's exactly the shape Combine's operators (`combineLatest`, `debounce`, `merge`) are built for, declaratively. Modeling the same thing with async/await alone would mean manually re-triggering the combination logic from three different places every time one input changes — Combine's operators express "recompute when any of these change" as data, not as manually wired callbacks.

**A backend worker (`margine-odds-worker`, Cloudflare) instead of the client talking to The Odds API directly.**
Alternatives considered: keep the client-side API key (as the app originally shipped), or add a heavier backend (a real server with a database).
Why this: The Odds API's free tier is a shared, low request budget — one client polling every 60s. Every installed copy of the app hitting the API independently would burn through that budget almost immediately and there's no way to increase it without paying per environment. A lightweight worker that fetches once and serves a shared cache to every client turns N clients' worth of requests into one upstream request per cache window, and it also means the API key lives server-side only — the client never has anything to leak. A Cloudflare Worker was enough for this: no client-specific data, no need for a database, just a cache in front of a single upstream.

## Testing strategy

- **UseCases** (`DefaultDetectArbitrageUseCase`, `DefaultAuthUseCase`) — the most heavily tested layer, since this is where the actual business rules live: arbitrage math with tied/disabled bookmakers, email/password validation before ever reaching the network. Tested with **Swift Testing** (`@Test`/`#expect`), against stubbed or mocked dependencies — no real network, no real Firebase.
- **Repositories and NetworkService** (`DefaultOddsRepository`, `URLSessionNetworkService`) — tested against a stubbed `URLProtocol`, covering URL construction, HTTP status mapping (429 rate-limited vs. generic error), and decoding failures.
- **ViewModels** (`AuthViewModel`, `OddsListViewModel`, `ProfileViewModel`) — tested with **XCTest**, driving `@Published` state through mocks (`MockAuthRepository`, `MockLiveOddsService`) and asserting on the resulting `ViewState`. These are more stateful/async-heavy than the UseCase tests, which is why they lean on XCTest's more familiar async expectations rather than Swift Testing.
- **`LiveOddsCoordinator`** — tested for the specific behavior that justifies it existing as an `actor`: concurrent calls only trigger one underlying use case execution.
- **XCUITest** (`LoginUITests`) — the one true end-to-end test, run against a real (dedicated test) Firebase project, covering the happy and error paths of the login screen. This is deliberately the only place a real backend is exercised; everything else is mocked, because Firebase Auth's actual behavior (wrong password, disabled account, network errors) is exactly the kind of thing worth verifying isn't broken by a client SDK update.
- **What's not tested directly**: SwiftUI Views. They contain no business logic (validated by the layering above), so testing them would mostly be testing SwiftUI itself. The one exception is `LoginUITests`, which exercises `LoginView` indirectly as a side effect of testing the real auth flow.

## Known trade-offs

- **No DI framework**, as noted above — the right call at this size, but revisit if the object graph grows past what fits legibly in `MargineApp.init()`. At a larger scale, a Factory/Resolver-style container would be worth the added indirection.
- **No offline/cached-on-device odds.** If the worker or The Odds API is unreachable, the user sees an error rather than stale-but-usable data. Acceptable for a betting-odds app (stale arbitrage odds are actively misleading, not just inconvenient), but worth flagging as a deliberate choice, not an oversight.
- **Single sport/league combo per request** (see `DefaultOddsRepository`'s doc comment) — the `sport` parameter is threaded through the whole stack but the worker currently always returns the same fixed set of top leagues. This was a scope cut to ship the core arbitrage-detection loop first; a real per-sport/league selector is tracked as backlog (S3.2c).
- **Single external data dependency**, with no fallback provider. If The Odds API changes pricing or shuts down, there's no secondary odds source — mitigated somewhat by the worker's caching layer, but not eliminated.
