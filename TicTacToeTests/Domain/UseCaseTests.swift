import Synchronization
import Testing
@testable import TicTacToe

struct UseCaseTests {
    /// Serves one stored match and records saves; can fail either way.
    final class FakeRepository: MatchRepository {
        let stored: Match?
        let loadFails: Bool
        let saveFails: Bool
        private let saved = Mutex<[Match]>([])

        init(stored: Match? = nil, loadFails: Bool = false, saveFails: Bool = false) {
            self.stored = stored
            self.loadFails = loadFails
            self.saveFails = saveFails
        }

        var savedMatches: [Match] { saved.withLock { $0 } }

        func load() throws -> Match? {
            if loadFails { throw Failure() }
            return stored
        }

        func save(_ match: Match) throws {
            if saveFails { throw Failure() }
            saved.withLock { $0.append(match) }
        }
    }

    struct Failure: Error {}

    /// Always plays the first empty cell, and counts its calls.
    final class FirstEmptyBot: Bot {
        private let calls = Mutex(0)
        var callCount: Int { calls.withLock { $0 } }

        func move(for game: Game, using generator: inout some RandomNumberGenerator) -> Int {
            calls.withLock { $0 += 1 }
            return game.board.emptyCells[0]
        }
    }

    private func playing(_ cells: [Int], from match: Match = .initial) throws -> Match {
        var match = match
        for cell in cells {
            try match.play(cell, by: match.game.turn)
        }
        return match
    }

    // MARK: Load

    @Test func loadReturnsSavedMatch() throws {
        let match = try playing([4])
        #expect(try DefaultLoadMatchUseCase(repository: FakeRepository(stored: match)).execute() == match)
    }

    @Test func loadStartsFreshWhenNothingIsSaved() throws {
        #expect(try DefaultLoadMatchUseCase(repository: FakeRepository()).execute() == .initial)
    }

    @Test func loadPassesOnReadFailure() {
        #expect(throws: Failure.self) {
            try DefaultLoadMatchUseCase(repository: FakeRepository(loadFails: true)).execute()
        }
    }

    // MARK: Play move

    @Test func playMovePlaysAndSaves() throws {
        let repository = FakeRepository()
        let match = try DefaultPlayMoveUseCase(repository: repository).execute(cell: 4, in: .initial)
        #expect(match.game.board[4] == .x)
        #expect(repository.savedMatches == [match])
    }

    @Test func illegalMoveChangesAndSavesNothing() throws {
        let repository = FakeRepository()
        let useCase = DefaultPlayMoveUseCase(repository: repository)
        let afterMove = try playing([4])
        #expect(throws: MoveError.notYourTurn) { try useCase.execute(cell: 0, in: afterMove) }
        #expect(throws: MoveError.cellUnavailable) { try useCase.execute(cell: 4, in: try playing([4, 0])) }
        #expect(repository.savedMatches.isEmpty)
    }

    @Test func unsavedMoveCarriesTheChangedMatch() throws {
        let useCase = DefaultPlayMoveUseCase(repository: FakeRepository(saveFails: true))
        do {
            _ = try useCase.execute(cell: 4, in: .initial)
            Issue.record("expected MatchNotSaved")
        } catch let notSaved as MatchNotSaved {
            #expect(notSaved.match.game.board[4] == .x)
        }
    }

    // MARK: Bot move

    @Test func botMovePlaysAndSaves() throws {
        let repository = FakeRepository()
        let match = try DefaultPlayBotMoveUseCase(bot: FirstEmptyBot(), repository: repository)
            .execute(in: try playing([4]))
        #expect(match.game.board[0] == .o)
        #expect(match.game.turn == .human)
        #expect(repository.savedMatches == [match])
    }

    @Test func botNeverMovesOutOfTurn() throws {
        let bot = FirstEmptyBot()
        let useCase = DefaultPlayBotMoveUseCase(bot: bot, repository: FakeRepository())
        #expect(throws: MoveError.notYourTurn) { try useCase.execute(in: .initial) }
        #expect(throws: MoveError.gameOver) { try useCase.execute(in: try playing([0, 3, 1, 4, 2])) }
        #expect(bot.callCount == 0)
    }

    // MARK: New game and reset

    @Test func newGameAppliesRulesAndSaves() throws {
        let repository = FakeRepository()
        let match = try DefaultStartNewGameUseCase(repository: repository).execute(from: try playing([4, 0]))
        #expect(match.record.losses == 1)
        #expect(match.game.startedBy == .bot)
        #expect(repository.savedMatches == [match])
    }

    @Test func resetRecordKeepsGameAndSaves() throws {
        let repository = FakeRepository()
        var finished = try playing([0, 3, 1, 4, 2])
        finished.startNextGame()
        let match = try DefaultResetRecordUseCase(repository: repository).execute(on: finished)
        #expect(match.record == .zero)
        #expect(match.game == finished.game)
        #expect(repository.savedMatches == [match])
    }
}
