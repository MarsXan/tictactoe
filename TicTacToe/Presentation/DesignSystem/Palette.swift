import SwiftUI
import UIKit

/// The only two colours in the app. Dark mode swaps them: white ink on black paper. Greys are only
/// ever halftone dots, never grey fills.
extension Color {
    nonisolated static let ink = Color(light: Palette.ink, dark: Palette.paper)
    nonisolated static let paper = Color(light: Palette.paper, dark: Palette.ink)
}

extension ShapeStyle where Self == Color {
    static var ink: Color { .ink }
    static var paper: Color { .paper }
}

private nonisolated enum Palette {
    static let ink = RGB(red: 0x14, green: 0x14, blue: 0x14)
    static let paper = RGB(red: 0xFB, green: 0xF8, blue: 0xF1)

    struct RGB {
        let red: Double
        let green: Double
        let blue: Double

        init(red: Int, green: Int, blue: Int) {
            self.red = Double(red) / 255
            self.green = Double(green) / 255
            self.blue = Double(blue) / 255
        }
    }
}

private extension Color {
    nonisolated init(light: Palette.RGB, dark: Palette.RGB) {
        self.init(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
        })
    }
}
