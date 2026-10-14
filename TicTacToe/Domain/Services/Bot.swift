/// Chooses the computer's moves.
protocol Bot: Sendable {
    /// The cell to play. Call only while the game is open and it is the bot's turn.
    func move(for game: Game, using generator: inout some RandomNumberGenerator) -> Int
}
