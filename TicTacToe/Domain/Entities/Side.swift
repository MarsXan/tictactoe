/// A symbol on the board.
enum Mark: Sendable, Hashable, CaseIterable {
    case x
    case o

    var opponent: Mark { self == .x ? .o : .x }
}

/// Who makes a move.
enum Side: Sendable, Hashable, CaseIterable {
    case human
    case bot

    var opponent: Side { self == .human ? .bot : .human }

    /// The human always plays X and the bot O. Saved games store marks, so changing this
    /// changes the meaning of every saved game.
    var mark: Mark { self == .human ? .x : .o }

    init(playing mark: Mark) {
        self = mark == .x ? .human : .bot
    }
}
