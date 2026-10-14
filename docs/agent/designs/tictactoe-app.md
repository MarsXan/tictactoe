# TicTacToe: a hard bot, Clean layers, black-and-white comic look

Status: accepted (2026-10-14) · Author: Claude (`/mobile-core:design`), for Mohsen Mokhtari · Date: 2026-10-14

## Problem

Build a one-player tic-tac-toe app for iPhone and iPad against a hard computer opponent. It must feel interactive and look like a black-and-white comic. The app saves the win/loss/draw record and the game in progress, so a game survives a quit or a kill. The code follows a layered ("Clean") architecture and is tested with Swift Testing. The repository today is the unmodified Xcode template (`docs/agent/CODEMAP.md`).

The hard part is not the game, which is small. It is three things:
- deciding what "hard" means when perfect tic-tac-toe is always a draw;
- giving a 300-line game real layer boundaries without ceremony;
- making a decorative comic style work with VoiceOver, Dynamic Type and Reduce Motion.

Out of scope for v1: two players on one device, online play, accounts, sound, analytics, Mac and visionOS.

## Forces

- **The OS kills the app at will.** The game in progress must be on disk after every move, including a move made while the bot is "thinking".
- **Stored data is forever.** The saved file is the only one-way door in this app. It carries a schema version from the first build, and a test opens a v1 fixture in every later version.
- **iPadOS 26 windows can be any size, and the iPhone can rotate.** The layout cannot assume a portrait phone. The board sizes to the shorter side, and the screen switches between a vertical and a side-by-side layout.
- **Accessibility in a comic style.** Contrast comes free with black and white. The risks are motion (pops, shakes, bursts), a display font at large text sizes, and a 3×3 grid read by VoiceOver.
- **The app target defaults to the main actor** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). Pure game logic should not inherit that. A Swift package target does not inherit it.
- **Privacy declarations follow storage choices.** `UserDefaults` is a required-reason API that needs a privacy-manifest entry. A JSON file in Application Support does not.

## Options: architecture

### A. Clean Architecture, one module per layer (recommended)
How it works: a local package `Packages/TicTacToeKit` has one library target per layer, and the compiler enforces the dependency rule.
- `GameDomain` holds entities, use cases, and the ports they need (the `MatchRepository` and `Bot` protocols). It imports no framework.
- `GameData` implements the repository port with a data source, DTOs and a mapper.
- `GamePresentation` holds the view model, a presentation-only view state, the SwiftUI views and the design system. It reaches the domain only through use-case protocols and cannot import `GameData`.
- The app target is the application layer: a DI container, the composition root, and `@main`.
- Domain, data and presentation tests all run with `swift test` on the Mac in seconds.

Costs: one `Package.swift`, one package reference in `project.pbxproj`, a protocol plus a default implementation per use case, and view-state mapping.
Makes easy / makes hard: no layer can reach past its neighbour, and the views never see a domain type. A new behaviour has an obvious home: a use case. Each change touches more files than a single model would.
Failure and rollback: if the package causes build or CI friction, the same folders move into the app target (option B) with no code changes.

### B. Layered, as folders in the app target
How it works: the same `Domain/`, `Data/` and `Presentation/` code as folders in the one target, kept apart by discipline only. All tests run in the app test target on a simulator.
Costs: lowest setup. Slower tests, because each run needs a simulator.
Makes easy / makes hard: nothing stops a domain file importing SwiftUI or a view calling the file system. Domain types are main-actor isolated unless each is marked `nonisolated`.
Failure and rollback: boundaries erode silently. Moving to A later is a folder move.

### C. Do less: one `@Observable` game model
How it works: one class holds the board, rules, bot and saving, and the views bind to it.
Costs: smallest code, but it is not the Clean architecture you asked for. The bot and saving cannot be tested without the UI model.

Considered and rejected: **TCA**. It adds a macro-heavy dependency, and version 1.x does not support this target's default main-actor isolation (per the `mobile-ios` architecture notes).

## Options: what "hard" means

1. **Unbeatable:** minimax over all 5,478 positions. It never loses, so your best result is a draw and the win column stays at 0.
2. **Hard but beatable (recommended):** the same engine, with a fixed rule order. It always takes a winning move and always blocks your immediate win. Otherwise it plays the best move, except that with probability `mistakeRate` it plays a random move. You can only beat it by setting up a fork. `mistakeRate = 0` makes it option 1, so either choice is one constant.
3. **Hand-written rules** (win, block, fork, center, corner): as strong as option 1 when complete, but much harder to prove than minimax.

## Decision

**Architecture A, bot option 2 with `mistakeRate` starting at 0.10.** A is the only option where the compiler enforces the Clean dependency rule, and every layer is fast to test. Option 2 matches your answer "hard" rather than "unbeatable", and an exhaustive test still proves the engine underneath plays perfectly.

What would change the recommendation:
- If the package makes builds or CI awkward, use B.
- If playtesting shows wins come too easily or never come, tune `mistakeRate`. That needs no data or design change.

Hard to reverse once shipped:
- The saved file format (schema v1 below) and its location.
- The convention that the human always plays X. The format stores marks, so a later "play as O" needs an additive `humanMark` field defaulting to `"x"`.
- The bundle ID `mohsen.TicTacToe`, if it has not been changed before the first upload.

## Design

**Boundaries.** Clean Architecture. Dependencies point inward only:

```
GamePresentation ──▶ GameDomain ◀── GameData
        ▲                ▲              ▲
        └──────── App (composition root) ┘
```

```
Packages/TicTacToeKit/Sources/
  GameDomain/
    Entities/       Mark, Side, Board, Outcome, Game, Record, Match (rules live here)
    UseCases/       LoadMatch, PlayMove, PlayBotMove, StartNewGame, ResetRecord
                    (protocol + Default implementation each), MatchNotSaved
    Repositories/   MatchRepository (port)
    Services/       Bot (port), HardBot, Minimax
  GameData/
    DataSources/    MatchDataSource (port for bytes), FileMatchDataSource
    DTOs/           MatchDTOV1 (on-disk shape, schema 1)
    Mappers/        MatchMapper (DTO ↔ entity)
    Repositories/   DefaultMatchRepository (implements MatchRepository)
  GamePresentation/
    ViewModels/     GameViewModel (depends on use-case protocols only), GameViewState, BotMood
    Views/          GameScreen, BoardView, RecordPanel, BotPanel, OutcomeBurst (no domain types)
    DesignSystem/   Palette, ComicFont, ComicPanel, ComicShapes, Halftone
    Resources/      Fonts (Bangers, OFL)
TicTacToe/Application/   AppDIContainer (composition root), TicTacToeApp (@main)
```

- **Use cases** are the only way presentation changes the match. Each one applies a domain rule and saves through the repository port. A change that was made but not saved comes back as `MatchNotSaved(match:)`, so play continues.
- **Entities** keep the rules: the record changes in the same transition that ends a game. Because one `Match` value is saved whole, the file can never hold a finished game without its result counted.
- **Views** read `GameViewState` (cells, score, result, mood), which the view model maps from the domain. They never import `GameDomain`.

**Data.** One file, `Application Support/match.json`, written with `.atomic` (a temp file, then a rename) by `FileMatchDataSource`. It is included in device backups. The file holds the on-disk shape `MatchDTOV1`, which `MatchMapper` maps to and from `Match`:

```json
{ "schemaVersion": 1,
  "record": { "wins": 2, "losses": 5, "draws": 11 },
  "game":   { "cells": ["x","","o","","x","","","",""], "turn": "bot", "startedBy": "human" } }
```

- **Derived, not stored:** the outcome is recomputed from `cells`, and the next starter is the opposite of `startedBy`.
- **Decoding** is tolerant: unknown keys are ignored and missing additive fields get defaults. A change that only adds a field keeps `schemaVersion` 1. Only a breaking change bumps it, and that needs a migration plus a test against the v1 fixture.
- **A bad file never costs the record.** If `game` is invalid (wrong cell count, impossible counts, two winners), keep `record` and start a new game. If the whole file is unreadable, or its `schemaVersion` is newer than this build knows (a downgrade), rename it to `match.unreadable-<date>.json`, never delete it, and start `Match.initial`.
- **Rejected:** SwiftData, which is too much for one small record with no queries and would bring migration ceremony. `UserDefaults`, which needs a required-reason declaration and offers no advantage here.

**State and concurrency.**
- `GameViewModel` is `@Observable` and on the main actor (the presentation module's default isolation). It owns the `Match` in memory. `AppDIContainer` builds it once, and the `App` struct holds it with `@State`.
- On creation the view model runs `LoadMatchUseCase`. The file is under 1 KB, and loading it first avoids a flash of an empty board.
- Each intent calls one use case, and each use case saves before it returns. That takes under a millisecond for a sub-1 KB file. Nothing saves "bot is thinking". That is derived: it's the bot's turn and there is no outcome.
- The bot's turn is a stored `Task` that runs the injected pause (600 ms; tests release it by hand), checks for cancellation, then calls `PlayBotMoveUseCase`. **New game** cancels the task.
- On launch, `.task { viewModel.resume() }` lets the bot move if the saved game stopped on its turn.
- Taps are ignored unless it is your turn and the game is open. The domain also rejects them, with `MoveError`.
- The bot is synchronous, nonisolated domain code and runs on the main actor (measured: see Implementation notes).

**Failure.** There is no network. If a save fails (for example, the disk is full), play continues in memory, the error is logged, and the next save tries again.

**Security and privacy.** No network, accounts, permissions or tracking. Add a privacy manifest that declares nothing collected, and confirm it with Xcode's privacy report before release. No required-reason APIs are planned.

**Visual and interaction design.**

- **Two colours only:** `ink` and `paper` in the asset catalog. The dark appearance swaps them, giving white ink on black paper. Greys appear only as halftone dots, never as grey fills, which keeps the print look and full contrast.
- **Panels:** paper fill, a 3.5 pt ink border, a 6 pt hard offset shadow with no blur, and a slight fixed tilt (±1.5°) for a hand-made feel. Buttons drop their shadow offset when pressed, so they look pushed into the page.
- **Lettering:** uppercase titles, buttons and sound-effect words in one comic display font. The recommendation is Bangers (SIL OFL 1.1; confirm the licence file when adding it). It is registered at launch with `CTFontManagerRegisterFontsForURL`, so no Info.plist change is needed. It is used through `Font.custom(_:size:relativeTo:)` so it scales with Dynamic Type, and falls back to the system font, at regular weight, if the face is missing. Numbers and accessibility text use the system font.
- **Board:** four uneven brush strokes rather than a ruled grid. X is two strokes and O is an open ring. Each mark draws itself in about 0.22 s with `trim`, pops from 1.15× to 1×, and sits at a small fixed tilt per cell.
- **Outcome:** a thick ink slash through the winning line, speed lines, and a starburst with "POW!" when you win, "BAM!" when the bot wins and "STALEMATE!" for a draw. The bot is a drawn comic head with a speech bubble: "Hmm…" while thinking, and a short taunt at the end. All strings go in the String Catalog.
- **Feel:** `.sensoryFeedback` gives an impact on each move, success when you win and error when you lose. A short shake plays when the bot wins.
- **Layout:** compact width stacks the record, bot bubble, board and **New game** vertically. Regular width, or any landscape window, puts the board on the left and the panels on the right. The board size is `min(width, height)` minus margins.

```
┌──────────────────────────────┐
│ ·:·:· halftone paper ·:·:·:· │
│ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│ ┃ TIC·TAC·TOE!             ┃█│
│ ┃ YOU 2   DRAWS 11   BOT 5 ┃█│
│ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛█│
│  (ò_ó)  ╭──────────────────╮ │
│   BOT  <  HMM… CUTE MOVE.  │ │
│         ╰──────────────────╯ │
│ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│ ┃    X    ╱    ╲    O      ┃█│
│ ┃  ━━━━━━━╋━━━━━━━╋━━━━━━  ┃█│
│ ┃         ╲  X  ╱          ┃█│
│ ┃  ━━━━━━━╋━━━━━━━╋━━━━━━  ┃█│
│ ┃    O                     ┃█│
│ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛█│
│        ┏━━━━━━━━━━━━┓        │
│        ┃ NEW GAME!  ┃█       │
│        ┗━━━━━━━━━━━━┛█       │
└──────────────────────────────┘
```

**Accessibility.**
- Each cell is a button labelled "Row 2, column 3, empty" (or "X", or "O"). The bot's move is announced with `AccessibilityNotification.Announcement`, and so is the outcome.
- Reduce Motion replaces the draw-on, pop, shake and burst animations with fades.
- At accessibility text sizes the record panel stacks vertically, and the board keeps its size.
- Decorative drawings (halftone, speed lines, the bot's face) are hidden from VoiceOver.

## Rollout

There is no server, so there are no flags or remote kill switch. The build goes to internal TestFlight, is played on the device matrix below, and then goes to the App Store. Rolling back means re-releasing the previous build. That build must still read the saved file, which tolerant decoding guarantees as long as v1 changes stay additive.

## Test strategy

- **Domain** (`swift test`, Swift Testing):
  - all 8 winning lines, draws and illegal moves (parameterised tests);
  - turn order and starter alternation;
  - the record updates exactly once per finished game;
  - the abandon rule.
- **Bot:**
  - **exhaustive proof:** at `mistakeRate = 0`, for every sequence of your moves and every move the bot is allowed to choose, the bot never loses;
  - at `mistakeRate = 1`, it still never misses an immediate win or block;
  - a seeded generator makes every test deterministic;
  - a one-off timing of the empty-board search on the slowest device.
- **Data:**
  - round trip;
  - the checked-in `match-v1.json` fixture loads in every future version;
  - an invalid game keeps the record;
  - an unreadable or newer file is renamed and never deleted;
  - each test gets its own temporary directory, because Swift Testing runs in parallel.
- **View model** (app test target, `@MainActor` tests, with a fake repository, a scripted bot and `botDelay = .zero`):
  - your move triggers the bot's reply and a save;
  - a game saved on the bot's turn resumes with the bot moving;
  - taps during the bot's turn are ignored;
  - **New game** cancels the pending bot move.
- **UI tests:** Swift Testing cannot drive UI, so there are no UI tests in v1 and the device matrix covers the screen. If one is added later, it is an XCTest smoke test running `performAccessibilityAudit()`, kept in its own target so the two assertion families never mix.
- **Device matrix:** the smallest iPhone that runs iOS 26 (SE size), a large iPhone in landscape, an iPad mini, and an iPad in a resized window. Each with VoiceOver, the largest accessibility text size, Reduce Motion, and dark appearance.

## Build order

None of these ships on its own. Each slice lands on `main` with its tests green.

| # | Slice | Done when | Depends on |
|---|---|---|---|
| 0 | Enablers: trim the target to iPhone/iPad; share the scheme; add the `TicTacToeKit` package linked to the app; add the app test target (Swift Testing). A person sets the verify commands in `.mobile-coding-agents.json` | `mobile verify --level test` runs both test commands | none |
| 1 | Domain: `Board`, rules, `Game`, `Record`, `Match` | domain tests pass | 0 |
| 2 | Bot: memoised minimax, the hard policy, exhaustive test, timing | proof test passes; timing recorded here | 1 |
| 3 | Data: data source, DTO v1, mapper, `DefaultMatchRepository`, fixture | data tests pass | 1 |
| 4 | Playable plain screen: view model, composition root, restore on launch, bot delay; no styling | play, kill the app, relaunch: the game and record are back | 2, 3 |
| 5 | Comic design system and styled screen: tokens, panels, font, halftone, animated marks, win slash, bursts, bot bubble, haptics | matches the mockup on iPhone and iPad | 4 |
| 6 | Accessibility and layout pass, app icon, privacy manifest | device matrix passes | 5 |

## Resolved questions (2026-10-14)

1. Hard but beatable: `mistakeRate = 0.10`.
2. **New game** before the game ends counts as a loss, once you have made a move.
3. The first player alternates each game. You start the very first one.
4. One bot.
5. Bangers is the display font.
6. A "Reset record" action ships in v1, behind a confirmation dialog (`Match.resetRecord()`). It resets the record only, not the game in progress.

## Implementation notes (2026-10-14)

Built slices 0 to 6. Where the build differs from the plan above:

- **Bot timing** (slice 2). The first version hashed boards on every call and took 88 ms per move in debug. Minimax now uses 9-bit masks and one shared value table, computed on first use: about 1 ms in release and about 17 ms in debug, once. After that a move takes about 2 µs in release (measured on the Mac with `swift test -c release`). The bot stays on the main actor; no `@concurrent` hop is needed.
- **Two test commands.** Package test targets added to the app's Xcode scheme were silently ignored by `xcodebuild`. Package tests run with `swift test --package-path Packages/TicTacToeKit`, and the view-model tests with `xcodebuild test`.
- **The win slash** is plain ink. A paper halo under it erased the middle of X marks on row wins and a whole stroke on diagonal wins.
- **The burst** sits above the board, sinking only into the board's margin, which is above where any mark starts. In wide layouts it goes in the side column instead. The title is hidden in narrow layouts under 700 pt of height and wide layouts under 500 pt, so the burst never covers the bot's line.
- **Speed lines** radiate from the centre of the screen, behind every panel.
- **App icon:** light, dark and tinted 1024 pt PNGs drawn by a CoreGraphics script in the same style as the app.

**Independent review (`mobile-core:reviewer`) fixes, 2026-10-14:**

- **Data loss.** A save file that exists but cannot be read (EIO, data protection before first unlock) used to start a fresh match that overwrote it on the first move. Now that session uses `UnsavedMatchRepository` and the file is left for the next launch. A package test (a mode-000 file) and an app test cover it.
- **Cancellation test.** The bot's pause is injectable (`pauseBeforeBotMove`), so the test resumes the cancelled turn by hand. A mutation check confirmed it: with `botTurn?.cancel()` removed, the test fails.
- **Accessibility text sizes.** The board is `min(width, height) - 40` square, so a turn never needs a scroll.
- **Reduce Motion.** Marks and the win slash now only fade in. The mark pop is 1.15× as designed.
- **VoiceOver.** The outcome burst carries the result ("Result: you win.") so it can be found after the announcement.
- **Still open:** strings are not in a String Catalog yet (`.xcstrings`), and the set-aside file is named with a UUID rather than a date.

**Correction, 2026-10-14: real Clean Architecture.** The first build had only a domain/data split. `GameViewModel` called the repository and the bot directly, presentation lived in the app target, and the views used domain entities. That was not the Clean Architecture asked for. The fix:
- **Use cases**, each a protocol plus a `Default` implementation.
- **Data split** into data source, DTO, mapper and repository.
- **A `GamePresentation` module** that cannot import `GameData`, with a view state so views see no domain types.
- **An `AppDIContainer` composition root.**

Behaviour, the saved format and the look are unchanged.

The unreadable-save protection moved into `DefaultMatchRepository`: after a failed read, the repository is read-only for the session.

**Change, 2026-10-14: layers moved into the app target.** At the user's request, the code left `Packages/TicTacToeKit` for folders in the app target: `TicTacToe/Domain`, `Data`, `Presentation` and `Application`, with tests in `TicTacToeTests/Domain`, `Data`, `Presentation` and `App`. The user chose this over one framework target per layer, accepting the trade-off below.
- **The layers and use cases are unchanged.** It is one module now, so the dependency rule is kept by review, not by the compiler.
- **Concurrency.** The domain and data code took the target's main-actor default isolation. `Board.lines` is `nonisolated`, because test arguments read it off the main actor.
- **The font** registers from `Bundle.main`.
- **Tests.** All 65 run on the simulator through the scheme; `swift test` is gone.
- **Unchanged:** behaviour, the saved format and the look (simulator screenshot checked).

