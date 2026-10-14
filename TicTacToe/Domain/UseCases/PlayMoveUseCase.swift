/// The human places an X.
protocol PlayMoveUseCase: Sendable {
    /// Plays the human's move in `cell` and saves the match.
    /// - Throws: `MoveError` when the move is not legal (nothing changes), or `MatchNotSaved` when
    ///   the move was made but could not be saved.
    func execute(cell: Int, in match: Match) throws -> Match
}

struct DefaultPlayMoveUseCase: PlayMoveUseCase {
    private let repository: any MatchRepository

    init(repository: any MatchRepository) {
        self.repository = repository
    }

    func execute(cell: Int, in match: Match) throws -> Match {
        var next = match
        try next.play(cell, by: .human)
        return try repository.saving(next)
    }
}
