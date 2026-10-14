# TicTacToe code map

Updated 2026-10-14 after the layers moved from a local package into the app target (`docs/agent/designs/tictactoe-app.md`). Every statement was read in the cited file.

## Shape: Clean Architecture, folders in one app target

```
Presentation/ ──▶ Domain/ ◀── Data/          (all in the TicTacToe target)
       ▲             ▲           ▲
       └──── Application/ (composition root) ┘
```

**One module: the compiler does not check these arrows.** A view could use a `Data/` type and it would build. Review keeps the rule.

- **`TicTacToe/Domain`** imports nothing.
  - `Entities/`: `Match`, `Game`, `Board`, `Record`, `Side`/`Mark`. The rules live here.
  - `UseCases/`: `LoadMatch`, `PlayMove`, `PlayBotMove`, `StartNewGame`, `ResetRecord`. Each is a protocol plus a `Default…` struct; all except `LoadMatch` save through the repository before returning.
  - `Repositories/MatchRepository.swift`: the port.
  - `Services/`: the `Bot` port, `HardBot` and `Minimax`.
- **`TicTacToe/Data`** imports Foundation and Synchronization, and uses `Domain/`.
  - `DataSources/`: `MatchDataSource` (bytes) and `FileMatchDataSource`.
  - `DTOs/MatchDTOV1.swift`: the on-disk shape.
  - `Mappers/MatchMapper.swift`: DTO ↔ entity.
  - `Repositories/DefaultMatchRepository.swift`: implements the port.
- **`TicTacToe/Presentation`** uses `Domain/` only.
  - `ViewModels/`: `GameViewModel` (use-case protocols in, `GameViewState` out) and `GameViewState` (cells, score, result, mood).
  - `Views/`: `GameScreen` and its parts. They read `GameViewState`, never domain types.
  - `DesignSystem/`: `Palette` (ink/paper), `ComicFont`, panels, shapes, halftone.
- **`TicTacToe/Resources/Fonts`**: Bangers, SIL OFL 1.1, copied to the app bundle's root. `ComicFont` registers it at runtime from `Bundle.main`.
- **`TicTacToe/Application`**: `AppDIContainer`, the only code that names types from every layer, and `TicTacToeApp` (`@main`).
- Target settings: iPhone and iPad, iOS 26.0, Swift 5 mode, main-actor default isolation (so domain and data types are main-actor too), folder-synced groups (a new file in these folders is in the target).

## Where new code goes

| Change | Place |
|---|---|
| A new game rule | an entity in `Domain/Entities`, with a test in `TicTacToeTests/Domain` |
| A new thing the user can do | a use case (protocol + `Default…`) in `Domain/UseCases`, then an intent on `GameViewModel`, wired in `AppDIContainer` |
| A new stored field | `MatchDTOV1` (additive, with a default) and `MatchMapper`; the v1 fixture tests must still pass |
| Something new on screen | a field on `GameViewState`, mapped in `GameViewState(match:)`, read by a view |

## How it runs

- `TicTacToeApp` → `AppDIContainer.live()`, which uses `FileMatchDataSource.applicationSupport` and `HardBot()` → `makeGameViewModel()`.
- `GameViewModel` runs `LoadMatchUseCase` on creation. Intents call one use case each. The bot's turn is a cancellable `Task` that runs the injected pause (600 ms), then `PlayBotMoveUseCase`. `resume()` runs from `.task`.
- A change the use case made but could not save arrives as `MatchNotSaved(match:)`; the view model keeps the match and logs the error.

## Data

- **The file:** `Application Support/match.json`, written atomically. Schema version 1, pinned by `TicTacToeTests/Data/Fixtures/match-v1.json`.
- **Bad files:**
  - an invalid game keeps the record;
  - contents this version cannot understand are renamed to `match.unreadable-<UUID>.json`, never deleted;
  - bytes that cannot be read at all make `DefaultMatchRepository` read-only for the session, so the file survives.
- **No `UserDefaults`.** The privacy manifest (`TicTacToe/PrivacyInfo.xcprivacy`) declares nothing.

## Tests

One target, `TicTacToeTests` (Swift Testing, hosted in the app), with folders `Domain/`, `Data/`, `Presentation/`, `App/`: 65 tests.

```
xcodebuild test -project TicTacToe.xcodeproj -scheme TicTacToe -destination 'platform=iOS Simulator,name=iPhone 17'
```

- They run on the simulator only; there is no `swift test` any more.
- **`mobile verify` has no command yet:** `.mobile-coding-agents.json` still has `"verify": {}`.

## Risk register

- **The saved format is the one-way door.** Keep `loadsVersion1Fixture` and `savesVersion1Shape` passing.
- **Layer rule unchecked by the compiler** since the move into one target.
- **`project.pbxproj` was written by hand.** It builds and tests from the command line, but has not been opened in the Xcode UI yet.
- **Not checked on a real device:** haptics, VoiceOver announcements and real rotation.
