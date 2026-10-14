import SwiftUI

/// The 3×3 board inside a comic panel. Each cell is a button; the drawing is decorative.
struct BoardView: View {
    let cells: [GameViewState.Cell]
    let winningLine: [Int]?
    let canPlay: Bool
    let onTap: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let inset = side * 0.06
            let grid = side - inset * 2
            ZStack {
                BoardGrid()
                    .stroke(.ink, style: StrokeStyle(lineWidth: side * 0.024, lineCap: .round))
                    .frame(width: grid, height: grid)
                    .accessibilityHidden(true)
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    ForEach(0..<3, id: \.self) { row in
                        GridRow {
                            ForEach(0..<3, id: \.self) { column in
                                cell(row * 3 + column, size: grid / 3)
                            }
                        }
                    }
                }
                .frame(width: grid, height: grid)
                if let winningLine {
                    WinSlashView(line: winningLine)
                        .frame(width: grid, height: grid)
                }
            }
            .frame(width: side, height: side)
            .comicPanel()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cell(_ index: Int, size: CGFloat) -> some View {
        let cell = cells[index]
        return Button {
            onTap(cell.id)
        } label: {
            ZStack {
                Rectangle().fill(.clear).contentShape(Rectangle())
                if let symbol = cell.symbol {
                    MarkView(symbol: symbol, cell: cell.id)
                        .padding(size * 0.2)
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(CellButtonStyle())
        .disabled(!canPlay || cell.symbol != nil)
        .accessibilityLabel(Self.accessibilityLabel(for: cell))
    }

    static func accessibilityLabel(for cell: GameViewState.Cell) -> Text {
        switch cell.symbol {
        case .x: Text("Row \(cell.row), column \(cell.column), X")
        case .o: Text("Row \(cell.row), column \(cell.column), O")
        case nil: Text("Row \(cell.row), column \(cell.column), empty")
        }
    }
}

/// Presses in slightly. Never dims: the ink stays black when the board is waiting on the bot.
private struct CellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.1), value: configuration.isPressed)
    }
}

/// X or O as brush strokes that ink themselves in, then settle with a small pop. With Reduce
/// Motion the finished mark fades in instead.
struct MarkView: View {
    let symbol: GameViewState.Symbol
    let cell: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var popped = false
    @State private var shown = false

    /// A fixed lean per cell, so marks look hand-placed but never jump between redraws.
    private static let tilts: [Double] = [-6, 4, -3, 5, -4, 3, 6, -5, 2]

    var body: some View {
        GeometryReader { proxy in
            let weight = proxy.size.width * 0.16
            let style = StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round)
            Group {
                switch symbol {
                case .x: XStroke().trim(from: 0, to: progress).stroke(.ink, style: style)
                case .o: OStroke().trim(from: 0, to: progress).stroke(.ink, style: style)
                }
            }
            .padding(weight / 2)
        }
        .rotationEffect(.degrees(Self.tilts[cell]))
        .scaleEffect(popped ? 1 : 1.15)
        .opacity(shown ? 1 : 0)
        .onAppear {
            if reduceMotion {
                withoutAnimation {
                    progress = 1
                    popped = true
                }
                withAnimation(.easeOut(duration: 0.2)) { shown = true }
            } else {
                withoutAnimation { shown = true }
                withAnimation(.easeOut(duration: 0.24)) { progress = 1 }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.45).delay(0.12)) { popped = true }
            }
        }
        .accessibilityHidden(true)
    }
}

/// The slash through the winning line, in the same ink as the marks. With Reduce Motion it fades
/// in whole instead of drawing across.
private struct WinSlashView: View {
    let line: [Int]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var shown = false

    var body: some View {
        GeometryReader { proxy in
            WinSlash(line: line).trim(from: 0, to: progress)
                .stroke(.ink, style: StrokeStyle(lineWidth: proxy.size.width * 0.032, lineCap: .round))
        }
        .opacity(shown ? 1 : 0)
        .onAppear {
            if reduceMotion {
                withoutAnimation { progress = 1 }
                withAnimation(.easeOut(duration: 0.2)) { shown = true }
            } else {
                withoutAnimation { shown = true }
                withAnimation(.easeIn(duration: 0.28).delay(0.25)) { progress = 1 }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Applies state changes without any animation, including one an ancestor started.
private func withoutAnimation(_ changes: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, changes)
}
