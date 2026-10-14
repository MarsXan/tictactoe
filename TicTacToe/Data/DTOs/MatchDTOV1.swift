/// The on-disk shape of `match.json`, schema version 1.
///
/// Once shipped, this shape is permanent. Add a field only with a default for files that lack it.
/// A breaking change gets a new DTO version, a migration, and a test that still loads
/// `TicTacToeTests/Data/Fixtures/match-v1.json`.
struct MatchDTOV1: Codable, Equatable {
    static let version = 1

    var schemaVersion: Int
    var record: RecordDTO
    /// Decoded tolerantly: a game that cannot be read is dropped and the record is kept.
    var game: GameDTO?

    struct RecordDTO: Codable, Equatable {
        var wins: Int
        var losses: Int
        var draws: Int
    }

    struct GameDTO: Codable, Equatable {
        /// Nine entries, row by row: "x", "o" or "" for an empty cell.
        var cells: [String]
        /// "human" or "bot".
        var turn: String
        var startedBy: String
    }

    init(schemaVersion: Int, record: RecordDTO, game: GameDTO?) {
        self.schemaVersion = schemaVersion
        self.record = record
        self.game = game
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        record = try container.decode(RecordDTO.self, forKey: .record)
        game = try? container.decodeIfPresent(GameDTO.self, forKey: .game)
    }
}

/// Read first, to choose the DTO version before decoding the rest.
struct SchemaVersionDTO: Decodable {
    let schemaVersion: Int
}
