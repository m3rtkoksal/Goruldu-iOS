import Foundation

/// Derives the chat name from the name of the exported file.
enum ChatTitle {
    private static let prefixes = ["whatsapp chat with ", "whatsapp chat - ", "whatsapp sohbeti - "]
    private static let suffix = " ile whatsapp sohbeti"

    /// Returns an empty string when the file name carries no chat name (`_chat.txt`).
    static func from(fileName: String) -> String {
        var name = TextRules.scalars(fileName)
        if let slash = name.lastIndex(of: "/") { name = Array(name[(slash + 1)...]) }
        for ext in [".txt", ".zip"] {
            let extScalars = TextRules.scalars(ext)
            if TextRules.hasSuffix(TextRules.lower(name, turkish: false), extScalars) {
                name = Array(name.prefix(name.count - extScalars.count))
            }
        }
        name = TextRules.trim(name)
        let low = Array(TextRules.string(name).lowercased().unicodeScalars)
        for prefix in prefixes {
            let prefixScalars = TextRules.scalars(prefix)
            if low.starts(with: prefixScalars), name.count >= prefixScalars.count {
                return TextRules.string(TextRules.trim(Array(name[prefixScalars.count...])))
            }
        }
        let suffixScalars = TextRules.scalars(suffix)
        if TextRules.hasSuffix(low, suffixScalars), name.count >= suffixScalars.count {
            return TextRules.string(TextRules.trim(Array(name.prefix(name.count - suffixScalars.count))))
        }
        if low == TextRules.scalars("_chat") { return "" }
        return TextRules.string(name)
    }
}
