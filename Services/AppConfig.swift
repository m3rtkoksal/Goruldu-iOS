import Foundation

/// Values that differ per build. They come from `Configuration/*.xcconfig` through Info.plist,
/// so nothing secret or environment specific is written in source files.
struct AppConfig {
    var apiBaseURL: URL?
    var appKey: String?
    var privacyURL: URL?
    var termsURL: URL?

    static let current = AppConfig(bundle: .main)

    init(bundle: Bundle) {
        apiBaseURL = Self.url(bundle, "GorulduAPIBaseURL")
        appKey = Self.string(bundle, "GorulduAppKey")
        privacyURL = Self.url(bundle, "GorulduPrivacyURL")
        termsURL = Self.url(bundle, "GorulduTermsURL")
    }

    init(apiBaseURL: URL?, appKey: String?, privacyURL: URL? = nil, termsURL: URL? = nil) {
        self.apiBaseURL = apiBaseURL
        self.appKey = appKey
        self.privacyURL = privacyURL
        self.termsURL = termsURL
    }

    private static func string(_ bundle: Bundle, _ key: String) -> String? {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func url(_ bundle: Bundle, _ key: String) -> URL? {
        guard let value = string(bundle, key), let url = URL(string: value), url.scheme != nil, url.host != nil else { return nil }
        return url
    }
}
