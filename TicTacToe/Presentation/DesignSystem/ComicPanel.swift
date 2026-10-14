import SwiftUI

/// Line weights shared by every drawn element, so the page reads as one pen.
enum ComicMetrics {
    static let border: CGFloat = 3.5
    static let shadow: CGFloat = 6
}

extension View {
    /// A comic panel: paper fill, a heavy ink border and a hard shadow with no blur.
    func comicPanel(tilt: Angle = .zero, shadow: CGFloat = ComicMetrics.shadow, cornerRadius: CGFloat = 6) -> some View {
        modifier(ComicPanel(tilt: tilt, shadow: shadow, cornerRadius: cornerRadius))
    }
}

struct ComicPanel: ViewModifier {
    var tilt: Angle
    var shadow: CGFloat
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        content
            .background(shape.fill(.paper))
            .overlay(shape.strokeBorder(.ink, lineWidth: ComicMetrics.border))
            .background(shape.fill(.ink).offset(x: shadow, y: shadow))
            .rotationEffect(tilt)
    }
}

/// A panel-shaped button that loses its shadow when pressed, so it looks pushed into the page.
struct ComicButtonStyle: ButtonStyle {
    var size: CGFloat = 26

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.comic(size, relativeTo: .title2))
            .foregroundStyle(.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .frame(minWidth: 44, minHeight: 44)
            .comicPanel(shadow: pressed ? 0 : 5)
            .offset(x: pressed ? 5 : 0, y: pressed ? 5 : 0)
            .animation(.snappy(duration: 0.12), value: pressed)
    }
}

extension ButtonStyle where Self == ComicButtonStyle {
    static var comic: ComicButtonStyle { ComicButtonStyle() }

    static func comic(size: CGFloat) -> ComicButtonStyle { ComicButtonStyle(size: size) }
}
