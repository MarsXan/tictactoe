import SwiftUI

/// The one screen: score, bot, board and controls on halftone paper. Stacks vertically in narrow
/// windows and puts the board beside the panels in wide ones.
struct GameScreen: View {
    private let viewModel: GameViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var shakes: CGFloat = 0
    @State private var confirmingReset = false

    init(viewModel: GameViewModel) {
        ComicFont.registerOnce()
        self.viewModel = viewModel
    }

    private var state: GameViewState { viewModel.state }

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width > proxy.size.height * 1.15
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    // The board still fits the visible height, so a turn never needs a scroll.
                    let side = min(proxy.size.width, proxy.size.height) - 40
                    ScrollView {
                        VStack(spacing: 20) {
                            panels(showsTitle: true)
                            board(withBurst: true).frame(width: side, height: side)
                            controls
                        }
                        .padding(20)
                    }
                } else if wide {
                    // The board fills the height, so the burst goes in the side column instead.
                    HStack(spacing: 28) {
                        board(withBurst: false)
                        VStack(spacing: 18) {
                            panels(showsTitle: proxy.size.height >= 500)
                            Spacer(minLength: 0)
                            if let result = state.result {
                                burst(result)
                            }
                            Spacer(minLength: 0)
                            controls
                        }
                        .animation(burstAnimation, value: state.result)
                        .frame(maxWidth: 400)
                    }
                    .padding(24)
                } else {
                    VStack(spacing: 18) {
                        // On short screens the title gives its room to the board and the burst.
                        panels(showsTitle: proxy.size.height >= 700)
                        board(withBurst: true).frame(maxHeight: .infinity)
                        controls
                    }
                    .frame(maxWidth: 640)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background {
            // Behind everything, so the action lines never cross a panel.
            ZStack {
                HalftoneBackground()
                if state.result == .youWon || state.result == .botWon {
                    SpeedLines()
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.3), value: state.result)
        }
        .task { viewModel.resume() }
        .sensoryFeedback(.impact(weight: .medium), trigger: state.cells)
        .sensoryFeedback(trigger: state.result) { _, result in
            switch result {
            case .youWon: .success
            case .botWon: .error
            case .draw: .warning
            case nil: nil
            }
        }
        .onChange(of: state) { old, new in
            announceChanges(from: old, to: new)
            if new.result == .botWon, old.result == nil, !reduceMotion {
                withAnimation(.linear(duration: 0.45)) { shakes += 1 }
            }
        }
        .confirmationDialog("Reset your record?", isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Reset record", role: .destructive) { viewModel.resetRecord() }
        } message: {
            Text("Wins, losses and draws go back to zero. The current game stays.")
        }
    }

    // MARK: Parts

    private func panels(showsTitle: Bool) -> some View {
        VStack(spacing: 14) {
            if showsTitle {
                Text("TIC·TAC·TOE!")
                    .font(.comic(44, relativeTo: .largeTitle))
                    .foregroundStyle(.ink)
                    .rotationEffect(.degrees(-2))
                    .accessibilityAddTraits(.isHeader)
            }
            RecordPanel(score: state.score)
            BotPanel(mood: state.botMood, variant: state.botLineVariant)
        }
    }

    private func board(withBurst: Bool) -> some View {
        BoardView(cells: state.cells, winningLine: state.winningLine, canPlay: state.canPlay) { viewModel.play($0) }
            .modifier(Shake(animatableData: shakes))
            .overlay(alignment: .top) {
                // A zero-height strip along the board's top edge. The burst stands on it and sinks
                // into the board's margin, above where any mark starts, so no mark is hidden.
                Color.clear
                    .frame(height: 0)
                    .overlay(alignment: .bottomTrailing) {
                        if withBurst, let result = state.result {
                            burst(result).offset(x: 12, y: 38)
                        }
                    }
                    .animation(burstAnimation, value: state.result)
            }
    }

    private func burst(_ result: GameViewState.Result) -> some View {
        OutcomeBurst(result: result)
            .fixedSize()
            .transition(reduceMotion ? .opacity : .scale(scale: 0.2).combined(with: .opacity))
    }

    /// Lands just after the winning slash.
    private var burstAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.55).delay(0.35)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button("NEW GAME!") {
                viewModel.newGame()
            }
            .buttonStyle(.comic)
            .accessibilityHint(newGameHint)

            Button {
                confirmingReset = true
            } label: {
                Label("Reset record", systemImage: "arrow.counterclockwise")
                    .labelStyle(.iconOnly)
                    .fontWeight(.black)
            }
            .buttonStyle(.comic(size: 22))
        }
    }

    private var newGameHint: Text {
        if state.leavingCountsAsLoss {
            Text("Leaving this game counts as a loss.")
        } else {
            Text("Starts the next game. The first move alternates.")
        }
    }

    // MARK: VoiceOver

    private func announceChanges(from old: GameViewState, to new: GameViewState) {
        var parts: [String] = []
        if let cell = new.cells.first(where: { $0.symbol == .o && old.cells[$0.id].symbol == nil }) {
            parts.append(String(localized: "Bot played row \(cell.row), column \(cell.column)."))
        }
        if new.result != old.result {
            switch new.result {
            case .youWon: parts.append(String(localized: "You win!"))
            case .botWon: parts.append(String(localized: "The bot wins."))
            case .draw: parts.append(String(localized: "It's a draw."))
            case nil: break
            }
        }
        guard !parts.isEmpty else { return }
        AccessibilityNotification.Announcement(parts.joined(separator: " ")).post()
    }
}
