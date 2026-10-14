import Foundation
import Testing
@testable import TicTacToe

/// `DefaultMatchRepository` over a real `FileMatchDataSource`. Each test works in its own temporary
/// directory, because Swift Testing runs tests in parallel.
struct DefaultMatchRepositoryTests {
    private let directory: URL
    private let dataSource: FileMatchDataSource
    private let repository: DefaultMatchRepository

    init() throws {
        directory = FileManager.default.temporaryDirectory.appending(path: "DefaultMatchRepositoryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        dataSource = FileMatchDataSource(directory: directory)
        repository = DefaultMatchRepository(dataSource: dataSource)
    }

    /// The match that `Fixtures/match-v1.json` holds.
    private let fixtureMatch = Match(
        record: Record(wins: 2, losses: 5, draws: 11)!,
        game: Game(
            board: Board(cells: [.x, nil, .o, nil, .x, nil, nil, nil, nil])!,
            turn: .bot,
            startedBy: .human
        )!
    )

    private func write(_ text: String) throws {
        try Data(text.utf8).write(to: dataSource.fileURL)
    }

    private func setAsideFiles() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("match.unreadable-") }
    }

    private func fixtureURL() throws -> URL {
        try #require(#bundle.url(forResource: "match-v1", withExtension: "json"))
    }

    @Test func missingFileLoadsNothing() throws {
        #expect(try repository.load() == nil)
    }

    @Test func roundTrips() throws {
        try repository.save(fixtureMatch)
        #expect(try repository.load() == fixtureMatch)
    }

    /// Every future version must still read a file written by version 1.
    @Test func loadsVersion1Fixture() throws {
        try FileManager.default.copyItem(at: fixtureURL(), to: dataSource.fileURL)
        #expect(try repository.load() == fixtureMatch)
    }

    /// Pins the on-disk shape: saving must write exactly what version 1 reads.
    @Test func savesVersion1Shape() throws {
        try repository.save(fixtureMatch)
        let saved = try JSONSerialization.jsonObject(with: Data(contentsOf: dataSource.fileURL)) as? NSDictionary
        let expected = try JSONSerialization.jsonObject(with: Data(contentsOf: fixtureURL())) as? NSDictionary
        #expect(saved != nil)
        #expect(saved == expected)
    }

    @Test func invalidGameKeepsRecord() throws {
        try write("""
            {"schemaVersion": 1, "record": {"wins": 3, "losses": 4, "draws": 5},
             "game": {"cells": ["x", "x", "x"], "turn": "bot", "startedBy": "human"}}
            """)
        let match = try #require(try repository.load())
        #expect(match.record == Record(wins: 3, losses: 4, draws: 5))
        #expect(match.game == Game(startedBy: .human))
    }

    @Test func impossibleGameKeepsRecord() throws {
        try write("""
            {"schemaVersion": 1, "record": {"wins": 1, "losses": 0, "draws": 0},
             "game": {"cells": ["x", "x", "", "", "", "", "", "", ""], "turn": "bot", "startedBy": "human"}}
            """)
        let match = try #require(try repository.load())
        #expect(match.record == Record(wins: 1, losses: 0, draws: 0))
        #expect(match.game == Game(startedBy: .human))
    }

    @Test func ignoresUnknownKeys() throws {
        try write("""
            {"schemaVersion": 1, "addedLater": true, "record": {"wins": 1, "losses": 2, "draws": 3, "streak": 4}}
            """)
        let match = try #require(try repository.load())
        #expect(match.record == Record(wins: 1, losses: 2, draws: 3))
    }

    @Test(arguments: [
        "not json",
        #"{"schemaVersion": 2, "record": {"wins": 1, "losses": 0, "draws": 0}}"#,
        #"{"schemaVersion": 1, "record": {"wins": -1, "losses": 0, "draws": 0}}"#,
        #"{"schemaVersion": 1}"#,
    ])
    func unreadableFileIsSetAsideNotDeleted(contents: String) throws {
        try write(contents)
        #expect(try repository.load() == nil)
        #expect(!FileManager.default.fileExists(atPath: dataSource.fileURL.path()))
        let kept = try setAsideFiles()
        #expect(kept.count == 1)
        #expect(try String(contentsOf: #require(kept.first), encoding: .utf8) == contents)
    }

    /// A read error is not a bad file: it may pass (a locked device). The file is left alone, and
    /// the session must not overwrite it, so saving fails until the next launch.
    @Test func unreadableFileIsNeverOverwritten() throws {
        try repository.save(fixtureMatch)
        let path = dataSource.fileURL.path()
        let before = try Data(contentsOf: dataSource.fileURL)
        let session = DefaultMatchRepository(dataSource: dataSource)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: path) }

        #expect(throws: (any Error).self) { try session.load() }
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: path)
        #expect(throws: MatchRepositoryError.saveCouldNotBeRead) { try session.save(.initial) }

        #expect(try Data(contentsOf: dataSource.fileURL) == before)
        #expect(try setAsideFiles().isEmpty)
        // The next launch reads it again.
        #expect(try DefaultMatchRepository(dataSource: dataSource).load() == fixtureMatch)
    }

    @Test func saveCreatesMissingDirectory() throws {
        let nested = DefaultMatchRepository(dataSource: FileMatchDataSource(directory: directory.appending(path: "a/b")))
        try nested.save(.initial)
        #expect(try nested.load() == .initial)
    }
}
