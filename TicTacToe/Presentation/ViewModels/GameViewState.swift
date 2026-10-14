
/// Everything the game screen shows, already decided. Views read this and never see domain types.
struct GameViewState: Equatable {
    /// X is always the player, O always the bot.
    enum Symbol: Equatable {
        case x
        case o
    }

    enum Result: Equatable {
        case youWon
        case botWon
        case draw
    }

    struct Cell: Equatable, Identifiable {
        /// 0...8, row by row from the top left.
        let id: Int
        let symbol: Symbol?

        var row: Int { id / 3 + 1 }
        var column: Int { id % 3 + 1 }
    }

    struct Score: Equatable {
        let you: Int
        let draws: Int
        let bot: Int
    }

    let cells: [Cell]
    let score: Score
    let result: Result?
    /// The three winning cells, for the slash.
    let winningLine: [Int]?
    let canPlay: Bool
    let isBotThinking: Bool
    /// Starting a new game now would count as a loss.
    let leavingCountsAsLoss: Bool
    let botMood: BotMood
    /// Picks the bot's line: changes from game to game, stays put within one.
    let botLineVariant: Int
}

/// How the bot looks and talks.
enum BotMood: Hashable, CaseIterable {
    case waiting
    case thinking
    case gloating
    case stunned
    case shrugging
}

// MARK: - Mapping from the domain

extension GameViewState {
    init(match: Match) {
        let game = match.game
        let isOpen = !game.isOver
        cells = game.board.cells.enumerated().map { index, mark in
            Cell(id: index, symbol: mark.map { $0 == Side.human.mark ? .x : .o })
        }
        score = Score(you: match.record.wins, draws: match.record.draws, bot: match.record.losses)
        switch game.outcome {
        case .won(let mark, let line):
            result = Side(playing: mark) == .human ? .youWon : .botWon
            winningLine = line
        case .draw:
            result = .draw
            winningLine = nil
        case nil:
            result = nil
            winningLine = nil
        }
        canPlay = isOpen && game.turn == .human
        isBotThinking = isOpen && game.turn == .bot
        let humanMoves = game.board.count(of: Side.human.mark)
        leavingCountsAsLoss = isOpen && humanMoves > 0
        botMood = switch result {
        case .botWon: .gloating
        case .youWon: .stunned
        case .draw: .shrugging
        case nil: isBotThinking ? .thinking : .waiting
        }
        botLineVariant = match.record.wins + match.record.losses + match.record.draws + humanMoves
    }
}
