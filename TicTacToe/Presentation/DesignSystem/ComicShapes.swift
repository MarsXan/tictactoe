import SwiftUI

/// The sound-effect burst behind "POW!": spikes of uneven length, as if drawn by hand.
struct Starburst: Shape {
    var spikes = 13

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for index in 0..<(spikes * 2) {
            let angle = Double(index) * .pi / Double(spikes) - .pi / 2
            let scale: CGFloat = index.isMultiple(of: 2) ? (index % 4 == 0 ? 1 : 0.86) : 0.7
            let radiusX = rect.width / 2 * scale
            let radiusY = rect.height / 2 * scale
            let point = CGPoint(
                x: rect.midX + radiusX * CGFloat(cos(angle)),
                y: rect.midY + radiusY * CGFloat(sin(angle))
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// A speech balloon with its tail on the left, pointing at whoever is talking.
struct SpeechBubble: Shape {
    var tail: CGFloat = 16
    var cornerRadius: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX + tail, y: rect.minY, width: rect.width - tail, height: rect.height)
        let radius = min(cornerRadius, body.height / 2 - 8)
        var path = Path()
        path.move(to: CGPoint(x: body.minX + radius, y: body.minY))
        path.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
        path.addArc(tangent1End: CGPoint(x: body.maxX, y: body.minY), tangent2End: CGPoint(x: body.maxX, y: body.maxY), radius: radius)
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
        path.addArc(tangent1End: CGPoint(x: body.maxX, y: body.maxY), tangent2End: CGPoint(x: body.minX, y: body.maxY), radius: radius)
        path.addLine(to: CGPoint(x: body.minX + radius, y: body.maxY))
        path.addArc(tangent1End: CGPoint(x: body.minX, y: body.maxY), tangent2End: CGPoint(x: body.minX, y: body.minY), radius: radius)
        path.addLine(to: CGPoint(x: body.minX, y: body.midY + 6))
        path.addLine(to: CGPoint(x: rect.minX, y: body.midY + 10))
        path.addLine(to: CGPoint(x: body.minX, y: body.midY - 6))
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
        path.addArc(tangent1End: CGPoint(x: body.minX, y: body.minY), tangent2End: CGPoint(x: body.maxX, y: body.minY), radius: radius)
        path.closeSubpath()
        return path
    }
}

/// The four board lines, each slightly bowed like a brush stroke.
struct BoardGrid: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()
        for (index, bow) in [(1, CGFloat(-0.014)), (2, CGFloat(0.012))] {
            let x = rect.minX + width * CGFloat(index) / 3
            path.move(to: CGPoint(x: x + width * 0.006, y: rect.minY + height * 0.03))
            path.addQuadCurve(
                to: CGPoint(x: x - width * 0.004, y: rect.maxY - height * 0.02),
                control: CGPoint(x: x + width * bow, y: rect.midY)
            )
            let y = rect.minY + height * CGFloat(index) / 3
            path.move(to: CGPoint(x: rect.minX + width * 0.02, y: y - height * 0.005))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - width * 0.03, y: y + height * 0.006),
                control: CGPoint(x: rect.midX, y: y - height * bow)
            )
        }
        return path
    }
}

/// X as two brush strokes. Trimming draws the first stroke, then the second.
struct XStroke: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.04))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX + rect.width * 0.08, y: rect.midY - rect.height * 0.08)
        )
        path.move(to: CGPoint(x: rect.maxX - rect.width * 0.02, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.maxY - rect.height * 0.02),
            control: CGPoint(x: rect.midX + rect.width * 0.06, y: rect.midY + rect.height * 0.05)
        )
        return path
    }
}

/// O as one pen stroke that overshoots its start and drifts inward a little.
struct OStroke: Shape {
    func path(in rect: CGRect) -> Path {
        let start = -Double.pi * 0.62
        let sweep = Double.pi * 2.14
        let steps = 72
        var path = Path()
        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let angle = start + sweep * progress
            let wobble = 1 + 0.04 * sin(angle * 3) - 0.07 * progress
            let radiusX = rect.width / 2 * CGFloat(wobble)
            let radiusY = rect.height / 2 * CGFloat(wobble)
            let point = CGPoint(
                x: rect.midX + radiusX * CGFloat(cos(angle)),
                y: rect.midY + radiusY * CGFloat(sin(angle))
            )
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

/// The slash through a winning line, running a little past both end cells.
struct WinSlash: Shape {
    var line: [Int]

    func path(in rect: CGRect) -> Path {
        guard let first = line.first, let last = line.last else { return Path() }
        func center(of cell: Int) -> CGPoint {
            CGPoint(
                x: rect.minX + rect.width * (CGFloat(cell % 3) + 0.5) / 3,
                y: rect.minY + rect.height * (CGFloat(cell / 3) + 0.5) / 3
            )
        }
        let start = center(of: first)
        let end = center(of: last)
        let overshoot: CGFloat = 0.24
        let dx = end.x - start.x
        let dy = end.y - start.y
        var path = Path()
        path.move(to: CGPoint(x: start.x - dx * overshoot, y: start.y - dy * overshoot))
        path.addLine(to: CGPoint(x: end.x + dx * overshoot, y: end.y + dy * overshoot))
        return path
    }
}

/// A short horizontal shake, for when the bot wins.
struct Shake: GeometryEffect {
    var travel: CGFloat = 9
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * 6), y: 0))
    }
}
