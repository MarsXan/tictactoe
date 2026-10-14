/// Hard but beatable. It always takes a win and always blocks an immediate loss. Otherwise it plays
/// a best move, except that with probability `mistakeRate` it plays a random one, so the only way
/// to beat it is to set up a fork. With `mistakeRate` 0 it never loses.
struct HardBot: Bot {
    let mistakeRate: Double

    init(mistakeRate: Double = 0.10) {
        precondition((0...1).contains(mistakeRate), "mistakeRate must be between 0 and 1")
        self.mistakeRate = mistakeRate
    }

    func move(for game: Game, using generator: inout some RandomNumberGenerator) -> Int {
        precondition(!game.isOver, "the game is over")
        let mark = game.turn.mark
        let forced = Self.forcedMoves(on: game.board, for: mark)
        if let move = forced.randomElement(using: &generator) {
            return move
        }
        if Double.random(in: 0..<1, using: &generator) < mistakeRate,
           let move = game.board.emptyCells.randomElement(using: &generator) {
            return move
        }
        return Minimax.bestMoves(on: game.board, for: mark).randomElement(using: &generator)!
    }

    /// Every move the bot may choose when it makes no mistake.
    static func perfectMoves(on board: Board, for mark: Mark) -> [Int] {
        let forced = forcedMoves(on: board, for: mark)
        return forced.isEmpty ? Minimax.bestMoves(on: board, for: mark) : forced
    }

    /// The winning moves if there are any, otherwise the moves that block the opponent's
    /// immediate win. Empty when neither exists.
    static func forcedMoves(on board: Board, for mark: Mark) -> [Int] {
        let open = board.emptyCells
        let wins = open.filter { board.wins(mark, at: $0) }
        return wins.isEmpty ? open.filter { board.wins(mark.opponent, at: $0) } : wins
    }
}
