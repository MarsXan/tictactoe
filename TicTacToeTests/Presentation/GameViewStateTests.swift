@testable import TicTacToe
import Testing

@MainActor
struct GameViewStateTests {
    @Test func mapsCellsAndScore() throws {
        var match = try playing([0, 3, 1, 4, 2])
        match.startNextGame()
        match = try playing([8], from: match)

        let state = GameViewState(match: match)

        #expect(state.cells.map(\.symbol) == [nil, nil, nil, nil, nil, nil, nil, nil, .o])
        #expect(state.cells[8].row == 3 && state.cells[8].column == 3)
        #expect(state.score == .init(you: 1, draws: 0, bot: 0))
        #expect(state.canPlay)
        #expect(!state.isBotThinking)
    }

    @Test func mapsWinningLine() throws {
        let state = GameViewState(match: try playing([0, 3, 1, 4, 2]))
        #expect(state.result == .youWon)
        #expect(state.winningLine == [0, 1, 2])
        #expect(!state.canPlay)
    }

    @Test func leavingCountsAsLossOnlyAfterHumanMoved() throws {
        #expect(!GameViewState(match: .initial).leavingCountsAsLoss)
        #expect(GameViewState(match: try playing([4, 0])).leavingCountsAsLoss)
        #expect(!GameViewState(match: try playing([0, 3, 1, 4, 2])).leavingCountsAsLoss)
    }

    @Test(arguments: [
        ([0, 3, 1, 4, 2], GameViewState.Result.youWon, BotMood.stunned),
        ([0, 3, 1, 4, 8, 5], .botWon, .gloating),
        ([0, 1, 2, 4, 3, 5, 7, 6, 8], .draw, .shrugging),
    ])
    func moodFollowsResult(cells: [Int], result: GameViewState.Result, mood: BotMood) throws {
        let state = GameViewState(match: try playing(cells))
        #expect(state.result == result)
        #expect(state.botMood == mood)
    }

    @Test func botThinksOnItsTurn() throws {
        let state = GameViewState(match: try playing([4]))
        #expect(state.isBotThinking)
        #expect(state.botMood == .thinking)
    }
}
