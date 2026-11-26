import Foundation

/// Number, duration and name formatting shared by the screens and the share card.
enum Format {
    static func number(_ value: Int, locale: Locale = .current) -> String {
        value.formatted(.number.grouping(.automatic).locale(locale))
    }

    /// "%38" in Turkish, "38%" in English.
    static func percent(_ value: Int) -> String {
        L10n.tr("format.percent", String(value))
    }

    /// "9 sa 14 dk" / "9h 14m"; days appear from 24 hours on.
    static func duration(minutes: Int) -> String {
        let parts = durationParts(minutes: minutes)
        if parts.days > 0 {
            return L10n.tr("format.duration.daysHours", String(parts.days), String(parts.hours))
        }
        if parts.hours > 0 {
            return L10n.tr("format.duration.hoursMinutes", String(parts.hours), String(parts.minutes))
        }
        return L10n.tr("format.duration.minutes", String(parts.minutes))
    }

    static func durationParts(minutes: Int) -> (days: Int, hours: Int, minutes: Int) {
        let total = max(0, minutes)
        return (total / 1_440, (total % 1_440) / 60, total % 60)
    }

    static func clock(hour: Int, minute: Int = 0) -> String {
        "\(hour < 10 ? "0" : "")\(hour):\(minute < 10 ? "0" : "")\(minute)"
    }

    /// "Burak" becomes "B." when names are hidden on a shared card.
    static func masked(_ name: String) -> String {
        guard let first = name.trimmingCharacters(in: .whitespaces).first else { return "?" }
        return "\(String(first).uppercased())."
    }

    /// "Lise Tayfa" becomes "LT".
    static func initials(_ title: String) -> String {
        let letters = title.split(separator: " ").prefix(2).compactMap(\.first).map { String($0).uppercased() }
        return letters.isEmpty ? "?" : letters.joined()
    }
}
