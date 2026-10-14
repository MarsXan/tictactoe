/// Perfect play by exhaustive search. There are only 5,478 legal positions, so the value of every
/// one is computed once, on first use, and each move after that is at most nine lookups.
///
/// A position's value is from the side to move: positive when it can force a win (higher means
/// sooner), 0 for a draw, negative for a forced loss (closer to 0 means later).
enum Minimax {
    /// Every move that reaches the best value for `mark`.
    static func bestMoves(on board: Board, for mark: Mark) -> [Int] {
        let mine = mask(of: mark, on: board)
        let theirs = mask(of: mark.opponent, on: board)
        var best = Int.min
        var moves: [Int] = []
        for cell in 0..<Board.cellCount where (mine | theirs) & (1 << cell) == 0 {
            let score = -value(mover: theirs, other: mine | 1 << cell)
            if score > best {
                best = score
                moves = [cell]
            } else if score == best {
                moves.append(cell)
            }
        }
        return moves
    }

    /// Searched once from the empty board, which reaches every legal position. The table depends
    /// only on whose marks are whose, not on which side is X, so one search serves both sides.
    static let table: [Int8] = {
        var search = Search()
        _ = search.value(mover: 0, other: 0)
        return search.memo
    }()

    private static func value(mover: Int, other: Int) -> Int {
        if let terminal = terminalValue(mover: mover, other: other) {
            return terminal
        }
        let known = table[index(mover: mover, other: other)]
        if known != Search.unknown {
            return Int(known)
        }
        // Not reachable from the empty board: search it on its own.
        var search = Search()
        return search.value(mover: mover, other: other)
    }

    private static func terminalValue(mover: Int, other: Int) -> Int? {
        let taken = mover | other
        if lineMasks.contains(where: { other & $0 == $0 }) {
            // The previous move won.
            return -(1 + Board.cellCount - taken.nonzeroBitCount)
        }
        return taken == fullMask ? 0 : nil
    }

    private static func index(mover: Int, other: Int) -> Int {
        mover << Board.cellCount | other
    }

    private static func mask(of mark: Mark, on board: Board) -> Int {
        board.cells.indices.reduce(0) { mask, cell in board[cell] == mark ? mask | 1 << cell : mask }
    }

    private static let lineMasks = Board.lines.map { line in line.reduce(0) { $0 | 1 << $1 } }
    private static let fullMask = (1 << Board.cellCount) - 1

    private struct Search {
        static let unknown = Int8.max

        /// Indexed by `index(mover:other:)`.
        private(set) var memo = [Int8](repeating: unknown, count: 1 << (2 * Board.cellCount))

        /// The value for the side that owns `mover`, which is to move.
        mutating func value(mover: Int, other: Int) -> Int {
            if let terminal = Minimax.terminalValue(mover: mover, other: other) {
                return terminal
            }
            let index = Minimax.index(mover: mover, other: other)
            if memo[index] != Self.unknown {
                return Int(memo[index])
            }
            var best = Int.min
            for cell in 0..<Board.cellCount where (mover | other) & (1 << cell) == 0 {
                best = max(best, -value(mover: other, other: mover | 1 << cell))
            }
            memo[index] = Int8(best)
            return best
        }
    }
}
