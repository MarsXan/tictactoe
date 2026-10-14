import Testing
@testable import TicTacToe

struct MatchTests {
    /// Plays `cells` in order, each by whichever side is to move.
    private func playing(_ cells: [Int], from match: Match = .initial) throws -> Match {
        var match = match
        for cell in cells {
            try match.play(cell, by: match.game.turn)
        }
        return match
    }

    @Test func humanWinCountsOnce() throws {
        // Human X takes the top row.
        let match = try playing([0, 3, 1, 4, 2])
        #expect(match.game.winner == .human)
        #expect(match.record == Record(wins: 1, losses: 0, draws: 0))
    }

    @Test func botWinCountsAsLoss() throws {
        let match = try playing([0, 3, 1, 4, 8, 5])
        #expect(match.game.winner == .bot)
        #expect(match.record == Record(wins: 0, losses: 1, draws: 0))
    }

    @Test func drawCounts() throws {
        // x o x / x o o / o x x
        let match = try playing([0, 1, 2, 4, 3, 5, 7, 6, 8])
        #expect(match.game.outcome == .draw)
        #expect(match.record == Record(wins: 0, losses: 0, draws: 1))
    }

    @Test func nextGameAlternatesStarter() throws {
        var match = try playing([0, 3, 1, 4, 2])
        match.startNextGame()
        #expect(match.game.startedBy == .bot)
        #expect(match.game.turn == .bot)
        #expect(match.game.board == Board())
        match.startNextGame()
        #expect(match.game.startedBy == .human)
    }

    @Test func finishedGameIsNotCountedAgain() throws {
        var match = try playing([0, 3, 1, 4, 2])
        match.startNextGame()
        #expect(match.record == Record(wins: 1, losses: 0, draws: 0))
    }

    @Test func abandoningAfterHumanMovedCountsAsLoss() throws {
        var match = try playing([4, 0])
        match.startNextGame()
        #expect(match.record == Record(wins: 0, losses: 1, draws: 0))
    }

    @Test func abandoningBeforeHumanMovedIsFree() throws {
        var match = Match.initial
        match.startNextGame()
        // The bot starts and moves; the human leaves without moving.
        match = try playing([4], from: match)
        match.startNextGame()
        #expect(match.record == .zero)
    }

    @Test func resetRecordKeepsGame() throws {
        var match = try playing([0, 3, 1, 4, 2])
        match.startNextGame()
        match = try playing([4], from: match)
        let game = match.game
        match.resetRecord()
        #expect(match.record == .zero)
        #expect(match.game == game)
    }
}
