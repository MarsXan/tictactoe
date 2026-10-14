import SwiftUI

/// Printed-comic halftone: ink dots on paper, large in two opposite corners and fading to nothing
/// across the middle. Greys in this app are only ever dots, never grey fills. Decorative.
struct HalftoneBackground: View {
    var spacing: CGFloat = 10

    var body: some View {
        Canvas { context, size in
            guard size.width > 0, size.height > 0 else { return }
            let maxRadius = spacing * 0.42
            var dots = Path()
            var row = 0
            var y: CGFloat = 0
            while y <= size.height + spacing {
                var x: CGFloat = row.isMultiple(of: 2) ? 0 : spacing / 2
                while x <= size.width + spacing {
                    // 0 on the diagonal from bottom left to top right, 1 in the other two corners.
                    let t = abs(x / size.width + y / size.height - 1)
                    // Thin out under the status bar so the clock stays readable.
                    let topFade = min(1, max(0, (y - 40) / 90))
                    let radius = maxRadius * pow(t, 1.8) * topFade
                    if radius > 0.35 {
                        dots.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    }
                    x += spacing
                }
                y += spacing * 0.866
                row += 1
            }
            context.fill(dots, with: .color(.ink))
        }
        .background(.paper)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Radiating action lines, drawn behind a win. Decorative.
struct SpeedLines: View {
    var count = 48

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = hypot(size.width, size.height) / 2
            var lines = Path()
            for index in 0..<count {
                let angle = Double(index) / Double(count) * 2 * .pi
                // Uneven lengths and widths, as if inked by hand.
                let inner = outer * (0.52 + 0.1 * sin(Double(index) * 2.3))
                let spread = 0.012 + 0.008 * cos(Double(index) * 1.7)
                lines.move(to: point(center, inner, angle))
                lines.addLine(to: point(center, outer, angle - spread))
                lines.addLine(to: point(center, outer, angle + spread))
                lines.closeSubpath()
            }
            context.fill(lines, with: .color(.ink))
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func point(_ center: CGPoint, _ radius: CGFloat, _ angle: Double) -> CGPoint {
        CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
    }
}
