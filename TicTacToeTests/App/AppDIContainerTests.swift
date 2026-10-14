import Foundation
import Testing
@testable import TicTacToe

/// The composition root wires real use cases to a real file: a move made through the view model
/// reaches the disk, and a new container restores it.
@MainActor
struct AppDIContainerTests {
    private let dataSource: FileMatchDataSource

    init() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "AppDIContainerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        dataSource = FileMatchDataSource(directory: directory)
    }

    @Test func moveReachesDiskAndRestores() throws {
        let viewModel = AppDIContainer(dataSource: dataSource, bot: HardBot()).makeGameViewModel()

        viewModel.play(4)

        let saved = try #require(try DefaultMatchRepository(dataSource: dataSource).load())
        #expect(saved.game.board[4] == .x)
        #expect(saved.game.turn == .bot)
    }

    @Test func firstLaunchStartsEmpty() throws {
        _ = AppDIContainer(dataSource: dataSource, bot: HardBot()).makeGameViewModel()
        #expect(try dataSource.read() == nil)
    }
}
