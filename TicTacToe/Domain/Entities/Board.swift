/// A 3×3 board. Cells are numbered 0...8, row by row from the top left.
struct Board: Sendable, Hashable {
    static let cellCount = 9

    /// The eight winning lines: three rows, three columns, two diagonals. A constant, so readable
    /// from any isolation (test arguments are built off the main actor).
    nonisolated static let lines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6],
    ]

    private(set) var cells: [Mark?]

    init() {
        cells = Array(repeating: nil, count: Self.cellCount)
    }

    /// Returns nil unless `cells` has exactly nine entries.
    init?(cells: [Mark?]) {
        guard cells.count == Self.cellCount else { return nil }
        self.cells = cells
    }

    subscript(cell: Int) -> Mark? { cells[cell] }

    var emptyCells: [Int] { cells.indices.filter { cells[$0] == nil } }

    var isFull: Bool { !cells.contains(nil) }

    func count(of mark: Mark) -> Int {
        cells.lazy.filter { $0 == mark }.count
    }

    /// The board with `mark` in `cell`, or nil when the cell is out of range or taken.
    func placing(_ mark: Mark, at cell: Int) -> Board? {
        guard cells.indices.contains(cell), cells[cell] == nil else { return nil }
        var next = self
        next.cells[cell] = mark
        return next
    }

    /// How the game on this board ended, or nil while it is still open.
    var outcome: Outcome? {
        if let first = completedLines.first {
            return .won(first.mark, line: first.line)
        }
        return isFull ? .draw : nil
    }

    /// Every line held entirely by one mark.
    var completedLines: [(mark: Mark, line: [Int])] {
        Self.lines.compactMap { line in
            guard let mark = cells[line[0]], cells[line[1]] == mark, cells[line[2]] == mark else {
                return nil
            }
            return (mark, line)
        }
    }

    /// Whether placing `mark` in the empty `cell` completes a line for it.
    func wins(_ mark: Mark, at cell: Int) -> Bool {
        placing(mark, at: cell)?.completedLines.contains { $0.mark == mark } ?? false
    }
}

enum Outcome: Sendable, Hashable {
    /// `line` holds the three winning cells, in order, for drawing the slash.
    case won(Mark, line: [Int])
    case draw
}
