/// Starts the next game.
protocol StartNewGameUseCase: Sendable {
    /// Starts the next game with the other side first and saves the match. Leaving an open game
    /// after the human has moved counts as a loss (see `Match.startNextGame()`).
    /// - Throws: `MatchNotSaved` when the new game could not be saved.
    func execute(from match: Match) throws -> Match
}

struct DefaultStartNewGameUseCase: StartNewGameUseCase {
    private let repository: any MatchRepository

    init(repository: any MatchRepository) {
        self.repository = repository
    }

    func execute(from match: Match) throws -> Match {
        var next = match
        next.startNextGame()
        return try repository.saving(next)
    }
}
