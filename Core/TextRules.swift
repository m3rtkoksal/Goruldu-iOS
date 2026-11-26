import Foundation

/// Text rules shared by the parser and the report builder.
///
/// Everything works on Unicode scalars, never on grapheme clusters or canonical equivalence,
/// so the result is identical to the reference implementation and to Android.
enum TextRules {
    typealias Scalars = [Unicode.Scalar]

    static let bidiMarks: Set<Unicode.Scalar> = [
        "\u{200E}", "\u{200F}", "\u{202A}", "\u{202B}", "\u{202C}", "\u{202D}", "\u{202E}",
        "\u{2066}", "\u{2067}", "\u{2068}", "\u{2069}", "\u{FEFF}",
    ]
    static let leftToRightMark: Unicode.Scalar = "\u{200E}"

    private static let whitespace: Set<Unicode.Scalar> = [
        " ", "\t", "\n", "\r", "\u{0B}", "\u{0C}", "\u{1C}", "\u{1D}", "\u{1E}", "\u{1F}", "\u{85}",
        "\u{A0}", "\u{1680}", "\u{2000}", "\u{2001}", "\u{2002}", "\u{2003}", "\u{2004}", "\u{2005}",
        "\u{2006}", "\u{2007}", "\u{2008}", "\u{2009}", "\u{200A}", "\u{2028}", "\u{2029}", "\u{202F}",
        "\u{205F}", "\u{3000}",
    ]
    private static let vowels: Set<Unicode.Scalar> = ["a", "e", "i", "o", "u", "y", "ı", "ö", "ü"]
    private static let turkishMarkers: Set<Unicode.Scalar> = ["ı", "ğ", "ş", "İ", "Ğ", "Ş"]

    static func scalars(_ text: String) -> Scalars { Array(text.unicodeScalars) }

    static func string(_ scalars: Scalars) -> String {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars)
        return String(view)
    }

    static func stripBidi(_ scalars: Scalars) -> Scalars { scalars.filter { !bidiMarks.contains($0) } }

    static func trim(_ scalars: Scalars) -> Scalars {
        var start = 0
        var end = scalars.count
        while start < end, whitespace.contains(scalars[start]) { start += 1 }
        while end > start, whitespace.contains(scalars[end - 1]) { end -= 1 }
        return Array(scalars[start..<end])
    }

    /// `İ → i` and `’ → '` always, `I → ı` only in Turkish chats, then locale-independent lowercase.
    static func lower(_ scalars: Scalars, turkish: Bool) -> Scalars {
        var mapped = String.UnicodeScalarView()
        for scalar in scalars {
            switch scalar {
            case "İ": mapped.append("i")
            case "\u{2019}": mapped.append("'")
            case "I" where turkish: mapped.append("ı")
            default: mapped.append(scalar)
            }
        }
        return Array(String(mapped).lowercased().unicodeScalars)
    }

    static func isTokenScalar(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x61...0x7A, 0xDF...0xF6, 0xF8...0xFF, 0x100...0x17F: return true
        default: return false
        }
    }

    /// Words of an already lowered text. Chunks that look like links are skipped.
    static func tokens(_ lowered: Scalars) -> [Scalars] {
        var result: [Scalars] = []
        for chunk in lowered.split(omittingEmptySubsequences: true, whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }) {
            if linkPrefixes.contains(where: { chunk.starts(with: $0) }) { continue }
            var current: Scalars = []
            for scalar in chunk {
                if isTokenScalar(scalar) {
                    current.append(scalar)
                } else if !current.isEmpty {
                    result.append(current)
                    current = []
                }
            }
            if !current.isEmpty { result.append(current) }
        }
        return result
    }

    /// Random keyboard laughter such as "sjsjsj" or "asdfghjkl".
    static func isKeysmash(_ token: Scalars) -> Bool {
        let vowelCount = token.reduce(0) { $0 + (vowels.contains($1) ? 1 : 0) }
        if vowelCount == 0 { return token.count >= 6 }
        return token.count >= 8 && vowelCount * 4 < token.count
    }

    static func isTurkishMarker(_ scalar: Unicode.Scalar) -> Bool { turkishMarkers.contains(scalar) }

    /// First scalar of the lowered form, or nil when lowering leaves the scalar unchanged.
    static func lowerFirstScalar(_ scalar: Unicode.Scalar, turkish: Bool) -> Unicode.Scalar? {
        switch scalar {
        case "İ": return "i"
        case "\u{2019}": return "'"
        case "I": return turkish ? "ı" : "i"
        default: break
        }
        if scalar.value < 0x80 {
            guard scalar.value >= 0x41, scalar.value <= 0x5A else { return nil }
            return Unicode.Scalar(scalar.value + 0x20)
        }
        let mapped = scalar.properties.lowercaseMapping.unicodeScalars
        guard let first = mapped.first else { return nil }
        if mapped.count == 1, first == scalar { return nil }
        return first
    }

    static func contains(_ haystack: Scalars, _ needle: Scalars) -> Bool {
        guard !needle.isEmpty, haystack.count >= needle.count else { return needle.isEmpty }
        let first = needle[0]
        let lastStart = haystack.count - needle.count
        var index = 0
        while index <= lastStart {
            if haystack[index] == first {
                var offset = 1
                while offset < needle.count, haystack[index + offset] == needle[offset] { offset += 1 }
                if offset == needle.count { return true }
            }
            index += 1
        }
        return false
    }

    static func containsAny(_ haystack: Scalars, _ needles: [Scalars]) -> Bool {
        needles.contains { contains(haystack, $0) }
    }

    static func hasSuffix(_ scalars: Scalars, _ suffix: Scalars) -> Bool {
        scalars.count >= suffix.count && Array(scalars[(scalars.count - suffix.count)...]) == suffix
    }

    /// Integer division rounding half up, for non-negative values.
    static func roundDiv(_ numerator: Int, _ denominator: Int) -> Int {
        (2 * numerator + denominator) / (2 * denominator)
    }

    /// Ordering by code point, used wherever the rules say "alphabetical".
    static func precedes(_ lhs: Scalars, _ rhs: Scalars) -> Bool {
        lhs.lexicographicallyPrecedes(rhs) { $0.value < $1.value }
    }

    private static let linkPrefixes: [Scalars] = ["http://", "https://", "www."].map(scalars)

    static let mediaExact: Set<Scalars> = Set([
        "<medya dahil edilmedi>", "<media omitted>", "null",
        "görüntü dahil edilmedi", "video dahil edilmedi", "ses dahil edilmedi",
        "çıkartma dahil edilmedi", "gif dahil edilmedi", "belge dahil edilmedi",
        "kişi kartı dahil edilmedi",
        "image omitted", "video omitted", "audio omitted", "sticker omitted",
        "gif omitted", "document omitted", "contact card omitted",
    ].map(scalars))
    static let mediaPrefixes: [Scalars] = ["<ekli: ", "<attached: "].map(scalars)
    static let mediaSuffixes: [Scalars] = ["(dosya ekli)", "(file attached)"].map(scalars)
    static let deletedExact: Set<Scalars> = Set([
        "bu mesaj silindi", "bu mesajı sildiniz",
        "this message was deleted", "you deleted this message",
    ].map(scalars))
    static let systemContains: [Scalars] = ["uçtan uca şifreli", "end-to-end encrypted"].map(scalars)
    static let editedSuffixes: [Scalars] = ["<bu mesaj düzenlendi>", "<this message was edited>"].map(scalars)
    static let planPhrases: [Scalars] = [
        "gelemiyorum", "gelemem", "gelemicem", "gelemiycem", "gelemeyeceğim",
        "gelemiyoruz", "gelemeyiz", "iptal",
        "can't come", "cant come", "can't make it", "cant make it",
    ].map(scalars)
    static let dramaMarks: [Scalars] = ["!!", "??", "?!", "!?"].map(scalars)
    static let laughEmoji: [Scalars] = ["\u{1F602}", "\u{1F923}"].map(scalars)
    static let laughParts: [Scalars] = ["haha", "hehe", "ahah", "jaja"].map(scalars)
}
