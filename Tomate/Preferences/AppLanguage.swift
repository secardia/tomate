import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case french

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .english: "en_US"
        case .french: "fr_FR"
        }
    }

    var displayName: String {
        switch self {
        case .english: "English"
        case .french: "Français"
        }
    }

    /// Matches macOS preferred language when supported, otherwise English.
    static var systemDefault: AppLanguage {
        let candidates = Locale.preferredLanguages + [Locale.current.identifier]
        for identifier in candidates {
            let code = Locale(identifier: identifier).language.languageCode?.identifier
                ?? String(identifier.prefix(2))
            if code == "fr" { return .french }
            if code == "en" { return .english }
        }
        return .english
    }
}
