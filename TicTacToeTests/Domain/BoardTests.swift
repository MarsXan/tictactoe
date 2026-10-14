import Testing
@testable import TicTacToe

struct BoardTests {
    @Test("Each of the eight lines wins", arguments: Board.lines)
    func lineWins(line: [Int]) {
        var board = Board()
        for cell in line {
            board = board.placing(.o, at: cell)!
        }
        #expect(board.outcome == .won(.o, line: line))
    }

    @Test func fullBoardWithoutLineIsDraw() {
        // x o x
        // x o o
        // o x x
        let board = Board(cells: [.x, .o, .x, .x, .o, .o, .o, .x, .x])!
        #expect(board.outcome == .draw)
    }

    @Test func openBoardHasNoOutcome() {
        let board = Board().placing(.x, at: 4)!
        #expect(board.outcome == nil)
    }

    @Test func placingNeedsAnEmptyCellInRange() {
        let board = Board().placing(.x, at: 0)!
        #expect(board.placing(.o, at: 0) == nil)
        #expect(board.placing(.o, at: 9) == nil)
        #expect(board.placing(.o, at: -1) == nil)
    }

    @Test func boardNeedsNineCells() {
        #expect(Board(cells: Array(repeating: nil, count: 8)) == nil)
        #expect(Board(cells: Array(repeating: nil, count: 10)) == nil)
    }
}
