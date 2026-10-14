import Foundation

/// Converts between the domain's `Match` and the stored bytes. The only place that knows both.
enum MatchMapper {
    static func data(from match: Match) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(dto(from: match))
    }

    /// The match in `data`, or nil when it is not a version 1 file with a valid record. A newer
    /// version is unreadable too: after a downgrade this build must not guess at it. A missing or
    /// invalid game is replaced by a new one that the human starts.
    static func match(from data: Data) -> Match? {
        let decoder = JSONDecoder()
        guard let version = try? decoder.decode(SchemaVersionDTO.self, from: data),
              version.schemaVersion == MatchDTOV1.version,
              let dto = try? decoder.decode(MatchDTOV1.self, from: data),
              let record = Record(wins: dto.record.wins, losses: dto.record.losses, draws: dto.record.draws) else {
            return nil
        }
        return Match(record: record, game: dto.game.flatMap { game(from: $0) } ?? Game(startedBy: .human))
    }

    static func dto(from match: Match) -> MatchDTOV1 {
        let game = match.game
        return MatchDTOV1(
            schemaVersion: MatchDTOV1.version,
            record: .init(wins: match.record.wins, losses: match.record.losses, draws: match.record.draws),
            game: .init(
                cells: game.board.cells.map { string(for: $0) },
                turn: string(for: game.turn),
                startedBy: string(for: game.startedBy)
            )
        )
    }

    private static func game(from dto: MatchDTOV1.GameDTO) -> Game? {
        var marks: [Mark?] = []
        for cell in dto.cells {
            switch cell {
            case "x": marks.append(.x)
            case "o": marks.append(.o)
            case "": marks.append(nil)
            default: return nil
            }
        }
        guard let board = Board(cells: marks),
              let turn = side(from: dto.turn),
              let startedBy = side(from: dto.startedBy) else {
            return nil
        }
        return Game(board: board, turn: turn, startedBy: startedBy)
    }

    private static func string(for mark: Mark?) -> String {
        switch mark {
        case .x: "x"
        case .o: "o"
        case nil: ""
        }
    }

    private static func string(for side: Side) -> String {
        switch side {
        case .human: "human"
        case .bot: "bot"
        }
    }

    private static func side(from string: String) -> Side? {
        switch string {
        case "human": .human
        case "bot": .bot
        default: nil
        }
    }
}
