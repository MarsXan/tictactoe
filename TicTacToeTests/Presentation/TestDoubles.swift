@testable import TicTacToe
import Synchronization
import Testing

/// Plays a fixed list of moves and counts what is left.
final class ScriptedBot: Bot {
    private let moves: Mutex<[Int]>

    init(moves: [Int]) {
        self.moves = Mutex(moves)
    }

    var remainingMoves: Int { moves.withLock { $0.count } }

    func move(for game: Game, using generator: inout some RandomNumberGenerator) -> Int {
        moves.withLock { $0.removeFirst() }
    }
}

/// Serves one stored match (or a load error) and records every save.
final class RecordingRepository: MatchRepository {
    private let stored: Match?
    private let loadError: (any Error)?
    private let saveError: (any Error)?
    private let saved = Mutex<[Match]>([])

    init(stored: Match? = nil, loadError: (any Error)? = nil, saveError: (any Error)? = nil) {
        self.stored = stored
        self.loadError = loadError
        self.saveError = saveError
    }

    var savedMatches: [Match] { saved.withLock { $0 } }

    func load() throws -> Match? {
        if let loadError { throw loadError }
        return stored
    }

    func save(_ match: Match) throws {
        if let saveError { throw saveError }
        saved.withLock { $0.append(match) }
    }
}

struct DiskFull: Error {}

/// Holds each bot turn until the test releases it, oldest first.
@MainActor
final class Gate {
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        await withCheckedContinuation { waiting.append($0) }
    }

    /// Yields until `count` bot turns are held.
    func untilWaiting(_ count: Int) async {
        for _ in 0..<1_000 where waiting.count < count {
            await Task.yield()
        }
        #expect(waiting.count == count)
    }

    func releaseOldest() {
        waiting.removeFirst().resume()
    }

    func releaseAll() {
        while !waiting.isEmpty { releaseOldest() }
    }
}

/// A view model wired to the real use cases over test doubles.
@MainActor
func makeViewModel(
    repository: RecordingRepository = RecordingRepository(),
    bot: ScriptedBot = ScriptedBot(moves: [4, 2]),
    pause: @escaping () async -> Void = {}
) -> GameViewModel {
    GameViewModel(
        loadMatch: DefaultLoadMatchUseCase(repository: repository),
        playMove: DefaultPlayMoveUseCase(repository: repository),
        playBotMove: DefaultPlayBotMoveUseCase(bot: bot, repository: repository),
        startNewGame: DefaultStartNewGameUseCase(repository: repository),
        resetRecord: DefaultResetRecordUseCase(repository: repository),
        pauseBeforeBotMove: pause
    )
}

/// Plays `cells` in order, each by whichever side is to move.
func playing(_ cells: [Int], from match: Match = .initial) throws -> Match {
    var match = match
    for cell in cells {
        try match.play(cell, by: match.game.turn)
    }
    return match
}
