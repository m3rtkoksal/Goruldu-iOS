import Foundation

/// Looks up strings in `Resources/Localizable.xcstrings`. Keys are symbolic (`home.title`).
enum L10n {
    /// Arguments are already formatted strings and are placed with `%1$@`, `%2$@`.
    static func tr(_ key: String, _ arguments: String...) -> String {
        let language = LanguageStore.shared
        let format = language.bundle.localizedString(forKey: key, value: key, table: nil)
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: language.locale, arguments: arguments)
    }

    /// Language sent to the roast API. Follows the choice in Settings, not only the phone.
    static var apiLocale: String {
        LanguageStore.shared.code
    }
}
