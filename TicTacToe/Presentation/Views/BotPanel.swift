import SwiftUI

/// The bot's head and its speech balloon.
struct BotPanel: View {
    let mood: BotMood
    let variant: Int

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            BotFace(mood: mood)
                .frame(width: 64, height: 64)
            Text(BotLines.line(for: mood, variant: variant))
                .font(.comic(22, relativeTo: .title3))
                .foregroundStyle(.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 28)
                .padding(.trailing, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .background {
                    SpeechBubble()
                        .fill(.paper)
                        .overlay(SpeechBubble().stroke(.ink, lineWidth: ComicMetrics.border))
                }
                .contentTransition(.opacity)
                .animation(.snappy, value: mood)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Bot says: \(Text(BotLines.line(for: mood, variant: variant)))"))
    }
}

enum BotLines {
    static func line(for mood: BotMood, variant: Int) -> LocalizedStringResource {
        let lines: [LocalizedStringResource] = switch mood {
        case .waiting: ["YOUR MOVE, HERO.", "GO ON. I'LL WAIT.", "PICK A SQUARE. ANY SQUARE."]
        case .thinking: ["HMM…", "CALCULATING DOOM…", "LET ME THINK…"]
        case .gloating: ["BAM! TOO EASY.", "BEEP BOOP. YOU LOSE.", "NEXT VICTIM, PLEASE."]
        case .stunned: ["WHAT?! A FORK?!", "IMPOSSIBLE! RECALIBRATING…", "YOU GOT LUCKY, HUMAN."]
        case .shrugging: ["STALEMATE. AGAIN.", "A DRAW? I'LL ALLOW IT.", "NOBODY WINS. CLASSIC."]
        }
        return lines[variant % lines.count]
    }
}

/// A comic robot head drawn in ink. Decorative: the balloon carries the meaning.
struct BotFace: View {
    let mood: BotMood
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        face
            .phaseAnimator([-5.0, 5.0], trigger: mood) { content, angle in
                content.rotationEffect(.degrees(mood == .thinking && !reduceMotion ? angle : 0))
            } animation: { _ in
                .easeInOut(duration: 0.18).repeatCount(3, autoreverses: true)
            }
            .accessibilityHidden(true)
    }

    private var face: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let ink = GraphicsContext.Shading.color(.ink)
            let weight = s * 0.055
            let round = StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round)
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

            var antenna = Path()
            antenna.move(to: point(0.5, 0.22))
            antenna.addLine(to: point(0.5, 0.09))
            context.stroke(antenna, with: ink, style: round)
            context.fill(Path(ellipseIn: CGRect(origin: point(0.43, 0.02), size: CGSize(width: s * 0.14, height: s * 0.14))), with: ink)

            let head = Path(roundedRect: CGRect(origin: point(0.08, 0.2), size: CGSize(width: s * 0.78, height: s * 0.7)), cornerRadius: s * 0.14)
            context.fill(head.offsetBy(dx: s * 0.06, dy: s * 0.06), with: ink)
            context.fill(head, with: .color(.paper))
            context.stroke(head, with: ink, lineWidth: weight)

            let eyes = [point(0.32, 0.47), point(0.62, 0.47)]
            let eye = s * 0.075
            var marks = Path()
            switch mood {
            case .waiting:
                for center in eyes {
                    context.fill(Path(ellipseIn: CGRect(x: center.x - eye, y: center.y - eye, width: eye * 2, height: eye * 2)), with: ink)
                }
                marks.move(to: point(0.3, 0.7))
                marks.addQuadCurve(to: point(0.64, 0.66), control: point(0.5, 0.78))
            case .thinking:
                for center in eyes {
                    marks.addEllipse(in: CGRect(x: center.x - eye, y: center.y - eye, width: eye * 2, height: eye * 2))
                    let pupil = eye * 0.55
                    context.fill(Path(ellipseIn: CGRect(x: center.x + eye * 0.2, y: center.y - eye * 0.9, width: pupil, height: pupil)), with: ink)
                }
                marks.move(to: point(0.4, 0.72))
                marks.addLine(to: point(0.6, 0.72))
            case .gloating:
                for center in eyes {
                    marks.move(to: CGPoint(x: center.x - eye, y: center.y + eye * 0.5))
                    marks.addLine(to: CGPoint(x: center.x, y: center.y - eye * 0.6))
                    marks.addLine(to: CGPoint(x: center.x + eye, y: center.y + eye * 0.5))
                }
                var grin = Path()
                grin.move(to: point(0.28, 0.64))
                grin.addQuadCurve(to: point(0.66, 0.64), control: point(0.47, 0.9))
                grin.closeSubpath()
                context.fill(grin, with: ink)
            case .stunned:
                for center in eyes {
                    marks.move(to: CGPoint(x: center.x - eye, y: center.y - eye))
                    marks.addLine(to: CGPoint(x: center.x + eye, y: center.y + eye))
                    marks.move(to: CGPoint(x: center.x + eye, y: center.y - eye))
                    marks.addLine(to: CGPoint(x: center.x - eye, y: center.y + eye))
                }
                marks.addEllipse(in: CGRect(origin: point(0.4, 0.64), size: CGSize(width: s * 0.13, height: s * 0.14)))
            case .shrugging:
                for center in eyes {
                    marks.move(to: CGPoint(x: center.x - eye, y: center.y))
                    marks.addLine(to: CGPoint(x: center.x + eye, y: center.y))
                    context.fill(Path(ellipseIn: CGRect(x: center.x - eye * 0.45, y: center.y, width: eye * 0.9, height: eye * 0.8)), with: ink)
                }
                marks.move(to: point(0.34, 0.72))
                marks.addLine(to: point(0.6, 0.7))
            }
            context.stroke(marks, with: ink, style: round)
        }
    }
}

#Preview("Moods") {
    VStack(spacing: 16) {
        ForEach(BotMood.allCases, id: \.self) { mood in
            BotPanel(mood: mood, variant: 0)
        }
    }
    .padding()
    .background(.paper)
}
