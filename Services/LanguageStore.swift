import Foundation
import Observation

/// The language of the interface. The phone language stays as it is.
@Observable
final class LanguageStore {
    static let shared = LanguageStore()

    enum Choice: String, CaseIterable {
        case system
        case turkish = "tr"
        case english = "en"
    }

    private static let key = "goruldu.language"

    var choice: Choice {
        didSet { UserDefaults.standard.set(choice.rawValue, forKey: Self.key) }
    }

    private init() {
        choice = Choice(rawValue: UserDefaults.standard.string(forKey: Self.key) ?? "") ?? .system
    }

    /// "tr" or "en", after applying the phone language when the choice is system.
    var code: String {
        switch choice {
        case .turkish: return "tr"
        case .english: return "en"
        case .system:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("tr") ? "tr" : "en"
        }
    }

    var locale: Locale {
        Locale(identifier: code == "tr" ? "tr_TR" : "en_US")
    }

    /// The compiled string catalog for the chosen language.
    var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }
}
