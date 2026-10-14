/// Results of finished games, counted from the human's side.
struct Record: Sendable, Hashable {
    private(set) var wins: Int
    private(set) var losses: Int
    private(set) var draws: Int

    static let zero = Record()

    /// Returns nil when any count is negative.
    init?(wins: Int, losses: Int, draws: Int) {
        guard wins >= 0, losses >= 0, draws >= 0 else { return nil }
        self.wins = wins
        self.losses = losses
        self.draws = draws
    }

    private init() {
        wins = 0
        losses = 0
        draws = 0
    }

    mutating func count(_ outcome: Outcome) {
        switch outcome {
        case .won(let mark, _):
            if Side(playing: mark) == .human { wins += 1 } else { losses += 1 }
        case .draw:
            draws += 1
        }
    }

    mutating func countLoss() {
        losses += 1
    }
}
