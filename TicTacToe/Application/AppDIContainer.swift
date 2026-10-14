
/// The composition root: the only place that knows the concrete type in every layer, and the only
/// code outside `Data/` that names a `Data/` type.
final class AppDIContainer {
    private let repository: any MatchRepository
    private let bot: any Bot

    init(dataSource: any MatchDataSource, bot: any Bot) {
        repository = DefaultMatchRepository(dataSource: dataSource)
        self.bot = bot
    }

    /// The app's real dependencies: `match.json` in Application Support, and the hard bot.
    static func live() -> AppDIContainer {
        AppDIContainer(dataSource: FileMatchDataSource.applicationSupport, bot: HardBot())
    }

    func makeGameViewModel() -> GameViewModel {
        GameViewModel(
            loadMatch: DefaultLoadMatchUseCase(repository: repository),
            playMove: DefaultPlayMoveUseCase(repository: repository),
            playBotMove: DefaultPlayBotMoveUseCase(bot: bot, repository: repository),
            startNewGame: DefaultStartNewGameUseCase(repository: repository),
            resetRecord: DefaultResetRecordUseCase(repository: repository)
        )
    }
}
