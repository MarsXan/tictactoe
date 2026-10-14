import Observation
import os

/// Presents the game. Turns user intents into use cases and their results into `state`.
/// Owns timing (the pause before the bot moves), never game rules or saving.
@Observable
final class GameViewModel {
    private(set) var match: Match

    var state: GameViewState { GameViewState(match: match) }

    @ObservationIgnored private let playMoveUseCase: any PlayMoveUseCase
    @ObservationIgnored private let playBotMoveUseCase: any PlayBotMoveUseCase
    @ObservationIgnored private let startNewGameUseCase: any StartNewGameUseCase
    @ObservationIgnored private let resetRecordUseCase: any ResetRecordUseCase
    @ObservationIgnored private let pauseBeforeBotMove: () async -> Void
    @ObservationIgnored private var botTurn: Task<Void, Never>?

    private static let logger = Logger(subsystem: "mohsen.TicTacToe", category: "Game")

    convenience init(
        loadMatch: any LoadMatchUseCase,
        playMove: any PlayMoveUseCase,
        playBotMove: any PlayBotMoveUseCase,
        startNewGame: any StartNewGameUseCase,
        resetRecord: any ResetRecordUseCase,
        botDelay: Duration = .milliseconds(600)
    ) {
        self.init(
            loadMatch: loadMatch,
            playMove: playMove,
            playBotMove: playBotMove,
            startNewGame: startNewGame,
            resetRecord: resetRecord
        ) {
            try? await Task.sleep(for: botDelay)
        }
    }

    /// `pauseBeforeBotMove` runs before each bot move; tests pass one they release by hand.
    init(
        loadMatch: any LoadMatchUseCase,
        playMove: any PlayMoveUseCase,
        playBotMove: any PlayBotMoveUseCase,
        startNewGame: any StartNewGameUseCase,
        resetRecord: any ResetRecordUseCase,
        pauseBeforeBotMove: @escaping () async -> Void
    ) {
        do {
            match = try loadMatch.execute()
        } catch {
            Self.logger.error("Loading the match failed; this session will not save: \(String(describing: error))")
            match = .initial
        }
        playMoveUseCase = playMove
        playBotMoveUseCase = playBotMove
        startNewGameUseCase = startNewGame
        resetRecordUseCase = resetRecord
        self.pauseBeforeBotMove = pauseBeforeBotMove
    }

    // MARK: Intents

    func play(_ cell: Int) {
        guard state.canPlay else { return }
        guard apply({ try playMoveUseCase.execute(cell: cell, in: match) }) else { return }
        scheduleBotTurn()
    }

    func newGame() {
        botTurn?.cancel()
        botTurn = nil
        apply { try startNewGameUseCase.execute(from: match) }
        scheduleBotTurn()
    }

    func resetRecord() {
        apply { try resetRecordUseCase.execute(on: match) }
    }

    /// Lets the bot move when the restored game stopped on its turn.
    func resume() {
        scheduleBotTurn()
    }

    /// Waits until a scheduled bot move has finished. For tests.
    func botTurnFinished() async {
        await botTurn?.value
    }

    // MARK: Bot turn

    private func scheduleBotTurn() {
        guard state.isBotThinking, botTurn == nil else { return }
        botTurn = Task { [weak self, pauseBeforeBotMove] in
            await pauseBeforeBotMove()
            guard !Task.isCancelled else { return }
            self?.playBotTurn()
        }
    }

    private func playBotTurn() {
        botTurn = nil
        apply { try playBotMoveUseCase.execute(in: match) }
    }

    /// Takes a use case's result. A change that was made but not saved is kept, so play goes on;
    /// a move the rules reject changes nothing. Returns whether the match changed.
    @discardableResult
    private func apply(_ change: () throws -> Match) -> Bool {
        do {
            match = try change()
        } catch let notSaved as MatchNotSaved {
            match = notSaved.match
            Self.logger.error("Saving the match failed: \(String(describing: notSaved.underlying))")
        } catch {
            return false
        }
        return true
    }
}
