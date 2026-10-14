import SwiftUI

/// The sound effect for a finished game: "POW!" when you win, "BAM!" when the bot does,
/// "STALEMATE!" for a draw.
struct OutcomeBurst: View {
    let result: GameViewState.Result

    var body: some View {
        Text(word)
            .font(.comic(result == .draw ? 30 : 44, relativeTo: .largeTitle))
            .foregroundStyle(.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, result == .draw ? 30 : 34)
            .padding(.vertical, 32)
            .background {
                ZStack {
                    Starburst().fill(.ink).offset(x: ComicMetrics.shadow, y: ComicMetrics.shadow)
                    Starburst().fill(.paper)
                    Starburst().stroke(.ink, style: StrokeStyle(lineWidth: ComicMetrics.border, lineJoin: .round))
                }
            }
            .rotationEffect(.degrees(result == .botWon ? 8 : -8))
            // Stays on screen after the one-time announcement, so VoiceOver can always find the result.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(spokenResult))
    }

    private var spokenResult: LocalizedStringResource {
        switch result {
        case .youWon: "Result: you win."
        case .botWon: "Result: the bot wins."
        case .draw: "Result: a draw."
        }
    }

    private var word: LocalizedStringResource {
        switch result {
        case .youWon: "POW!"
        case .botWon: "BAM!"
        case .draw: "STALEMATE!"
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        OutcomeBurst(result: .youWon)
        OutcomeBurst(result: .botWon)
        OutcomeBurst(result: .draw)
    }
    .padding()
    .background(.paper)
}
