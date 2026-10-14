import Testing
@testable import TicTacToe

struct GameTests {
    @Test(arguments: Side.allCases)
    func starterMovesFirst(starter: Side) {
        let game = Game(startedBy: starter)
        #expect(game.turn == starter)
        #expect(!game.isOver)
    }

    @Test func turnsAlternate() throws {
        var game = Game(startedBy: .human)
        try game.play(4, by: .human)
        #expect(game.turn == .bot)
        #expect(game.board[4] == .x)
        try game.play(0, by: .bot)
        #expect(game.turn == .human)
        #expect(game.board[0] == .o)
    }

    @Test func rejectsMoveOutOfTurn() {
        var game = Game(startedBy: .human)
        #expect(throws: MoveError.notYourTurn) { try game.play(4, by: .bot) }
    }

    @Test func rejectsTakenCell() throws {
        var game = Game(startedBy: .human)
        try game.play(4, by: .human)
        #expect(throws: MoveError.cellUnavailable) { try game.play(4, by: .bot) }
    }

    @Test func rejectsMoveAfterGameOver() throws {
        var game = Game(startedBy: .human)
        for (cell, side) in [(0, Side.human), (3, .bot), (1, .human), (4, .bot), (2, .human)] {
            try game.play(cell, by: side)
        }
        #expect(game.winner == .human)
        #expect(throws: MoveError.gameOver) { try game.play(5, by: .bot) }
    }

    // MARK: Restoring a saved game

    @Test func restoresReachableGame() {
        let board = Board(cells: [.x, nil, .o, nil, .x, nil, nil, nil, nil])!
        let game = Game(board: board, turn: .bot, startedBy: .human)
        #expect(game?.board == board)
        #expect(game?.turn == .bot)
    }

    @Test func rejectsWrongTurn() {
        let board = Board(cells: [.x, nil, .o, nil, .x, nil, nil, nil, nil])!
        #expect(Game(board: board, turn: .human, startedBy: .human) == nil)
    }

    @Test func rejectsImpossibleCounts() {
        let board = Board(cells: [.x, .x, nil, nil, .x, nil, nil, nil, .o])!
        #expect(Game(board: board, turn: .bot, startedBy: .human) == nil)
        // The bot started, so it cannot have fewer marks than the human.
        let other = Board(cells: [.x, nil, nil, nil, nil, nil, nil, nil, nil])!
        #expect(Game(board: other, turn: .bot, startedBy: .bot) == nil)
    }

    @Test func rejectsTwoWinners() {
        // x x x
        // o o o
        // . . .
        let board = Board(cells: [.x, .x, .x, .o, .o, .o, nil, nil, nil])!
        #expect(Game(board: board, turn: .human, startedBy: .human) == nil)
        #expect(Game(board: board, turn: .bot, startedBy: .human) == nil)
    }

    @Test func rejectsWinnerToMove() {
        // The bot started and won with its third mark, so the human moves next, not the bot.
        let board = Board(cells: [.o, .o, .o, .x, .x, nil, nil, nil, nil])!
        #expect(Game(board: board, turn: .human, startedBy: .bot) != nil)
        // The human moved again after the bot won, so the counts say it is the bot's turn.
        let afterWin = Board(cells: [.o, .o, .o, .x, .x, nil, .x, nil, nil])!
        #expect(Game(board: afterWin, turn: .bot, startedBy: .bot) == nil)
    }
}
