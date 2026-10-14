/// One game: the board, whose turn it is and who started.
struct Game: Sendable, Hashable {
    private(set) var board: Board
    /// The side to move next. Once the game is over, the side that did not make the last move.
    private(set) var turn: Side
    let startedBy: Side

    init(startedBy: Side) {
        board = Board()
        turn = startedBy
        self.startedBy = startedBy
    }

    /// Rebuilds a saved game. Returns nil when no sequence of legal moves leads to it.
    init?(board: Board, turn: Side, startedBy: Side) {
        let starterCount = board.count(of: startedBy.mark)
        let otherCount = board.count(of: startedBy.opponent.mark)
        guard starterCount == otherCount || starterCount == otherCount + 1 else { return nil }
        guard turn == (starterCount == otherCount ? startedBy : startedBy.opponent) else { return nil }

        let winners = Set(board.completedLines.map(\.mark))
        guard winners.count <= 1 else { return nil }
        // The winner made the last move, so it cannot be the side to move.
        if let winner = winners.first, Side(playing: winner) == turn { return nil }

        self.board = board
        self.turn = turn
        self.startedBy = startedBy
    }

    var outcome: Outcome? { board.outcome }

    var isOver: Bool { outcome != nil }

    /// The side that won, or nil for a draw or an open game.
    var winner: Side? {
        guard case .won(let mark, _) = outcome else { return nil }
        return Side(playing: mark)
    }

    var humanHasMoved: Bool { board.count(of: Side.human.mark) > 0 }

    mutating func play(_ cell: Int, by side: Side) throws(MoveError) {
        guard !isOver else { throw .gameOver }
        guard side == turn else { throw .notYourTurn }
        guard let next = board.placing(side.mark, at: cell) else { throw .cellUnavailable }
        board = next
        turn = side.opponent
    }
}

enum MoveError: Error, Equatable {
    case gameOver
    case notYourTurn
    case cellUnavailable
}
