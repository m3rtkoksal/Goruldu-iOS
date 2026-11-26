import Foundation

/// Looks up strings in `Resources/Localizable.xcstrings`. Keys are symbolic (`home.title`).
enum L10n {
    /// Arguments are already formatted strings and are placed with `%1$@`, `%2$@`.
    static func tr(_ key: String, _ arguments: String...) -> String {
        let format = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale.current, arguments: arguments)
    }

    /// Language sent to the roast API: Turkish when the app runs in Turkish, English otherwise.
    static var apiLocale: String {
        Bundle.main.preferredLocalizations.first?.hasPrefix("tr") == true ? "tr" : "en"
    }
}
