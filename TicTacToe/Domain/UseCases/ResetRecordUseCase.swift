/// Clears the win/loss/draw record.
protocol ResetRecordUseCase: Sendable {
    /// Clears the record, keeps the game in progress, and saves the match.
    /// - Throws: `MatchNotSaved` when the change could not be saved.
    func execute(on match: Match) throws -> Match
}

struct DefaultResetRecordUseCase: ResetRecordUseCase {
    private let repository: any MatchRepository

    init(repository: any MatchRepository) {
        self.repository = repository
    }

    func execute(on match: Match) throws -> Match {
        var next = match
        next.resetRecord()
        return try repository.saving(next)
    }
}
