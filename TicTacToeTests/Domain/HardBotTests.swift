import Testing
@testable import TicTacToe

struct HardBotTests {
    /// The proof behind "hard": with no mistakes, for every sequence of human moves and every move
    /// the bot is allowed to choose, the bot never loses.
    @Test(arguments: Side.allCases)
    func neverLosesWithoutMistakes(starter: Side) {
        var finishedGames = 0
        func explore(_ game: Game) {
            if game.isOver {
                #expect(game.winner != .human, "human won: \(game.board.cells)")
                finishedGames += 1
                return
            }
            let moves = game.turn == .human
                ? game.board.emptyCells
                : HardBot.perfectMoves(on: game.board, for: Side.bot.mark)
            for cell in moves {
                var next = game
                try! next.play(cell, by: game.turn)
                explore(next)
            }
        }
        explore(Game(startedBy: starter))
        #expect(finishedGames > 0)
    }

    @Test func alwaysTakesWinEvenWhenErring() {
        // o o .
        // x x .
        // x . .   bot to move: 2 wins, 5 would only block.
        let game = Game(
            board: Board(cells: [.o, .o, nil, .x, .x, nil, .x, nil, nil])!,
            turn: .bot,
            startedBy: .human
        )!
        let bot = HardBot(mistakeRate: 1)
        for seed in 0..<200 as Range<UInt64> {
            var generator = SeededGenerator(seed: seed)
            #expect(bot.move(for: game, using: &generator) == 2)
        }
    }

    @Test func alwaysBlocksEvenWhenErring() {
        // x x .
        // . o .
        // . . .   bot to move: must block at 2.
        let game = Game(
            board: Board(cells: [.x, .x, nil, nil, .o, nil, nil, nil, nil])!,
            turn: .bot,
            startedBy: .human
        )!
        let bot = HardBot(mistakeRate: 1)
        for seed in 0..<200 as Range<UInt64> {
            var generator = SeededGenerator(seed: seed)
            #expect(bot.move(for: game, using: &generator) == 2)
        }
    }

    /// The human took the centre. Only a corner holds the draw; an edge loses to a fork.
    private let centreOpening = Game(
        board: Board(cells: [nil, nil, nil, nil, .x, nil, nil, nil, nil])!,
        turn: .bot,
        startedBy: .human
    )!

    @Test func answersCentreWithCorner() {
        #expect(Set(HardBot.perfectMoves(on: centreOpening.board, for: .o)) == [0, 2, 6, 8])
        let bot = HardBot(mistakeRate: 0)
        for seed in 0..<200 as Range<UInt64> {
            var generator = SeededGenerator(seed: seed)
            #expect([0, 2, 6, 8].contains(bot.move(for: centreOpening, using: &generator)))
        }
    }

    @Test func makesMistakesAtItsRate() {
        let bot = HardBot(mistakeRate: 0.10)
        var edges = 0
        let trials = 2_000
        for seed in 0..<UInt64(trials) {
            var generator = SeededGenerator(seed: seed)
            if [1, 3, 5, 7].contains(bot.move(for: centreOpening, using: &generator)) {
                edges += 1
            }
        }
        // A mistake is a random move: half of the 8 open cells are edges, so about 5% of trials.
        #expect((50...150).contains(edges), "edges: \(edges)")
    }

    @Test func everyOpeningDraws() {
        #expect(Minimax.bestMoves(on: Board(), for: .o) == Array(0..<9))
    }
}
