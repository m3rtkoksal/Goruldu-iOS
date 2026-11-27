import SwiftUI

/// Colors of the brand. Values come from the design prototype (`goruldu-tasarim`).
enum Palette {
    static let ink = Color(hex: 0x0B0B0F)
    static let ink2 = Color(hex: 0x16161D)
    static let ink3 = Color(hex: 0x23232D)
    static let paper = Color(hex: 0xF6F2EA)
    static let muted = Color(hex: 0x9A9AA6)
    static let lime = Color(hex: 0xC8F751)
    static let pink = Color(hex: 0xFF4D8D)
    static let blue = Color(hex: 0x2F5BFF)
    static let orange = Color(hex: 0xFF7A1A)
    static let violet = Color(hex: 0x7B3FF2)
    static let navy = Color(hex: 0x101A4D)
    /// Soft fills for the stacked result cards. Poster colors stay on the share images.
    static let cardMint = Color(hex: 0xC6F3DC)
    static let cardBlush = Color(hex: 0xF6B7C8)
    static let cardLilac = Color(hex: 0xD9CCF7)
    static let cardPeach = Color(hex: 0xF8CBA8)
    static let cardApricot = Color(hex: 0xF8D7B0)
    static let roseInk = Color(hex: 0x7A1E3A)
    static let clayInk = Color(hex: 0x6B3E16)
    static let tick = Color(hex: 0x34B7F1)
    static let switchOff = Color(hex: 0x3A3A47)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
