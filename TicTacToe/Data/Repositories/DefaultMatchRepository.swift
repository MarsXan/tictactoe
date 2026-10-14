import Foundation
import Synchronization

/// Implements the domain's `MatchRepository` with a data source and the v1 mapper.
final class DefaultMatchRepository: MatchRepository {
    private let dataSource: any MatchDataSource
    /// Set when a saved match existed but could not be read. From then on nothing is written, so
    /// the file survives for the next launch.
    private let isReadOnly = Mutex(false)

    init(dataSource: any MatchDataSource) {
        self.dataSource = dataSource
    }

    /// Returns nil when nothing is saved. Contents this version cannot understand are set aside,
    /// never deleted, and nil is returned. Bytes that cannot be read at all (for example while the
    /// device is locked) throw, and the repository becomes read-only.
    func load() throws -> Match? {
        let data: Data?
        do {
            data = try dataSource.read()
        } catch {
            isReadOnly.withLock { $0 = true }
            throw error
        }
        guard let data else { return nil }
        if let match = MatchMapper.match(from: data) {
            return match
        }
        try dataSource.setAside()
        return nil
    }

    func save(_ match: Match) throws {
        guard !isReadOnly.withLock({ $0 }) else {
            throw MatchRepositoryError.saveCouldNotBeRead
        }
        try dataSource.write(MatchMapper.data(from: match))
    }
}

enum MatchRepositoryError: Error, Equatable {
    /// The save file could not be read at launch, so this session does not overwrite it.
    case saveCouldNotBeRead
}
