/// Everything the app saves: the running record and the current game.
struct Match: Sendable, Hashable {
    private(set) var record: Record
    private(set) var game: Game

    init(record: Record, game: Game) {
        self.record = record
        self.game = game
    }

    /// A first launch: no results yet, and the human starts.
    static let initial = Match(record: .zero, game: Game(startedBy: .human))

    /// Plays one move. A move that ends the game counts its result in the same step, so a saved
    /// match never holds a finished game whose result is missing from the record.
    mutating func play(_ cell: Int, by side: Side) throws(MoveError) {
        try game.play(cell, by: side)
        if let outcome = game.outcome {
            record.count(outcome)
        }
    }

    /// Starts the next game with the other side first. Leaving an open game after the human has
    /// moved counts as a loss; otherwise quitting would hide losses.
    mutating func startNextGame() {
        if !game.isOver && game.humanHasMoved {
            record.countLoss()
        }
        game = Game(startedBy: game.startedBy.opponent)
    }

    /// Clears the record and keeps the game in progress.
    mutating func resetRecord() {
        record = .zero
    }
}
