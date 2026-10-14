/// The computer chooses and places an O.
protocol PlayBotMoveUseCase: Sendable {
    /// Lets the bot play its move and saves the match.
    /// - Throws: `MoveError` when the game is over or it is not the bot's turn (nothing changes),
    ///   or `MatchNotSaved` when the move was made but could not be saved.
    func execute(in match: Match) throws -> Match
}

struct DefaultPlayBotMoveUseCase: PlayBotMoveUseCase {
    private let bot: any Bot
    private let repository: any MatchRepository

    init(bot: any Bot, repository: any MatchRepository) {
        self.bot = bot
        self.repository = repository
    }

    func execute(in match: Match) throws -> Match {
        guard !match.game.isOver else { throw MoveError.gameOver }
        guard match.game.turn == .bot else { throw MoveError.notYourTurn }
        var generator = SystemRandomNumberGenerator()
        var next = match
        try next.play(bot.move(for: match.game, using: &generator), by: .bot)
        return try repository.saving(next)
    }
}
