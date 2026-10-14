@testable import TicTacToe
import Testing

@MainActor
struct GameViewModelTests {
    @Test func humanMoveGetsBotReplyAndBothAreSaved() async {
        let repository = RecordingRepository()
        let viewModel = makeViewModel(repository: repository)

        viewModel.play(0)
        #expect(viewModel.state.isBotThinking)
        await viewModel.botTurnFinished()

        #expect(viewModel.state.cells[0].symbol == .x)
        #expect(viewModel.state.cells[4].symbol == .o)
        #expect(viewModel.state.canPlay)
        #expect(repository.savedMatches.count == 2)
        #expect(repository.savedMatches.last == viewModel.match)
    }

    @Test func restoresSavedMatch() throws {
        let match = try playing([4])
        let viewModel = makeViewModel(repository: RecordingRepository(stored: match))
        #expect(viewModel.match == match)
    }

    @Test func restoredGameOnBotsTurnResumes() async throws {
        let viewModel = makeViewModel(repository: RecordingRepository(stored: try playing([0])))

        viewModel.resume()
        await viewModel.botTurnFinished()

        #expect(viewModel.state.cells[4].symbol == .o)
        #expect(viewModel.state.canPlay)
    }

    /// The repository protects an unreadable save (see DefaultMatchRepositoryTests); the screen starts fresh.
    @Test func unreadableSaveStartsFresh() {
        let viewModel = makeViewModel(repository: RecordingRepository(loadError: DiskFull()))
        #expect(viewModel.match == .initial)
    }

    @Test func tapsDuringBotTurnAreIgnored() async {
        let repository = RecordingRepository()
        let gate = Gate()
        let viewModel = makeViewModel(repository: repository) { await gate.wait() }

        viewModel.play(0)
        viewModel.play(1)

        #expect(viewModel.state.cells[1].symbol == nil)
        #expect(repository.savedMatches.count == 1)
        await gate.untilWaiting(1)
        gate.releaseAll()
    }

    @Test func tapOnTakenCellIsIgnored() async {
        let repository = RecordingRepository()
        let viewModel = makeViewModel(repository: repository)
        viewModel.play(0)
        await viewModel.botTurnFinished()

        viewModel.play(4)

        #expect(viewModel.state.cells[4].symbol == .o)
        #expect(repository.savedMatches.count == 2)
    }

    @Test func newGameCancelsPendingBotMove() async {
        let bot = ScriptedBot(moves: [4, 2])
        let gate = Gate()
        let viewModel = makeViewModel(bot: bot) { await gate.wait() }
        viewModel.play(0)
        await gate.untilWaiting(1)

        // Abandoned after moving: a loss. The bot starts the next game.
        viewModel.newGame()
        await gate.untilWaiting(2)
        #expect(viewModel.state.score.bot == 1)
        #expect(viewModel.match.game.startedBy == .bot)

        // The first game's bot turn wakes after New game: it was cancelled, so it must not move.
        gate.releaseOldest()
        for _ in 0..<50 { await Task.yield() }
        #expect(viewModel.state.cells.allSatisfy { $0.symbol == nil })
        #expect(bot.remainingMoves == 2)

        // The new game's bot turn plays its opening move.
        gate.releaseOldest()
        await viewModel.botTurnFinished()
        #expect(viewModel.state.cells.filter { $0.symbol == .o }.count == 1)
        #expect(bot.remainingMoves == 1)
    }

    @Test func resetRecordKeepsGameAndSaves() async throws {
        let repository = RecordingRepository(stored: try playing([0, 3, 1, 4, 2]))
        let viewModel = makeViewModel(repository: repository)
        let game = viewModel.match.game

        viewModel.resetRecord()

        #expect(viewModel.state.score == .init(you: 0, draws: 0, bot: 0))
        #expect(viewModel.match.game == game)
        #expect(repository.savedMatches.last?.record == .zero)
    }

    /// A move that could not be saved still happens, and play goes on.
    @Test func unsavedMoveIsKept() async {
        let viewModel = makeViewModel(repository: RecordingRepository(saveError: DiskFull()))

        viewModel.play(0)
        await viewModel.botTurnFinished()

        #expect(viewModel.state.cells[0].symbol == .x)
        #expect(viewModel.state.cells[4].symbol == .o)
    }
}
