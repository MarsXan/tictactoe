/// Restores the match at launch.
protocol LoadMatchUseCase: Sendable {
    /// The saved match, or a first-launch match when nothing is saved.
    /// - Throws: when a save exists but cannot be read. The repository then keeps it safe.
    func execute() throws -> Match
}

struct DefaultLoadMatchUseCase: LoadMatchUseCase {
    private let repository: any MatchRepository

    init(repository: any MatchRepository) {
        self.repository = repository
    }

    func execute() throws -> Match {
        try repository.load() ?? .initial
    }
}
