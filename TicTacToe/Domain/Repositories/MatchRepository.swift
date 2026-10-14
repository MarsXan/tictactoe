/// Port for keeping the match between launches. The data layer implements it.
protocol MatchRepository: Sendable {
    /// The saved match, or nil when there is nothing to restore.
    ///
    /// Throws when a saved match exists but cannot be read. After that, the repository must not
    /// overwrite what it could not read: `save` fails until the next launch.
    func load() throws -> Match?

    func save(_ match: Match) throws
}

extension MatchRepository {
    /// Saves `match` and returns it, or throws `MatchNotSaved` carrying it.
    func saving(_ match: Match) throws(MatchNotSaved) -> Match {
        do {
            try save(match)
        } catch {
            throw MatchNotSaved(match: match, underlying: error)
        }
        return match
    }
}
