import CoreText
import Foundation
import SwiftUI
import os

/// Bangers, a comic lettering face (SIL OFL 1.1, see `Resources/Fonts/Bangers-OFL.txt`).
/// Ships in the app bundle and registers itself on first use, so it needs no Info.plist entry.
enum ComicFont {
    static let name = "Bangers-Regular"

    /// Registers the face once per process.
    static func registerOnce() {
        _ = registration
    }

    private static let registration: Void = {
        guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
            Logger(subsystem: "mohsen.TicTacToe", category: "Design").error("Bangers-Regular.ttf is missing from the bundle")
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }()
}

extension Font {
    /// Comic lettering that scales with Dynamic Type. Falls back to the system font when the
    /// face is missing.
    static func comic(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(ComicFont.name, size: size, relativeTo: style)
    }
}
