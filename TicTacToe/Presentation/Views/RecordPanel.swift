import SwiftUI

/// The running score, lettered like a comic caption box.
struct RecordPanel: View {
    let score: GameViewState.Score

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 20) { tallies }
            VStack(alignment: .leading, spacing: 4) { tallies }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .comicPanel(tilt: .degrees(-1))
    }

    @ViewBuilder private var tallies: some View {
        Tally(title: "YOU", value: score.you)
            .accessibilityLabel(Text("Your wins: \(score.you)"))
        Tally(title: "DRAWS", value: score.draws)
            .accessibilityLabel(Text("Draws: \(score.draws)"))
        Tally(title: "BOT", value: score.bot)
            .accessibilityLabel(Text("Bot wins: \(score.bot)"))
    }
}

private struct Tally: View {
    let title: LocalizedStringKey
    let value: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.comic(20, relativeTo: .headline))
            Text(value, format: .number)
                .font(.system(.title2, design: .rounded, weight: .black))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy, value: value)
        }
        .foregroundStyle(.ink)
        .accessibilityElement(children: .ignore)
    }
}
