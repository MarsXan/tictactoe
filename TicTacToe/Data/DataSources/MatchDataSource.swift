import Foundation

/// The saved match as raw bytes. Knows where they live, not what they mean.
protocol MatchDataSource: Sendable {
    /// The saved bytes, or nil when nothing has been saved.
    func read() throws -> Data?

    /// Replaces the saved bytes in one step, so a kill never leaves half a file.
    func write(_ data: Data) throws

    /// Moves the saved bytes aside under a new name. Never deletes them.
    func setAside() throws
}

/// `match.json` in a directory, written atomically.
struct FileMatchDataSource: MatchDataSource {
    let fileURL: URL

    init(directory: URL) {
        fileURL = directory.appending(path: "match.json")
    }

    /// The app's Application Support directory, which is backed up.
    static var applicationSupport: FileMatchDataSource {
        FileMatchDataSource(directory: .applicationSupportDirectory)
    }

    func read() throws -> Data? {
        do {
            return try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            return nil
        }
    }

    func write(_ data: Data) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }

    /// Renames the file to `match.unreadable-<UUID>.json` beside it, so a newer build or a person
    /// can still recover it.
    func setAside() throws {
        let destination = fileURL.deletingLastPathComponent()
            .appending(path: "match.unreadable-\(UUID().uuidString).json")
        try FileManager.default.moveItem(at: fileURL, to: destination)
    }
}
