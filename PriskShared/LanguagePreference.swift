// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import Foundation

public struct LanguagePreference: Codable, Equatable {
    /// BCP-47 language tag, e.g. "en-US", "ja-JP". "auto" = auto-detect.
    public let code: String
    public let displayName: String
    public let flag: String

    public init(code: String, displayName: String, flag: String) {
        self.code = code
        self.displayName = displayName
        self.flag = flag
    }
}

public extension LanguagePreference {
    static let english    = LanguagePreference(code: "en-US", displayName: "English",  flag: "🇺🇸")
    static let japanese   = LanguagePreference(code: "ja-JP", displayName: "日本語",    flag: "🇯🇵")
    static let autoDetect = LanguagePreference(code: "auto",  displayName: "Auto-detect", flag: "🌐")

    /// All languages shown in the language picker
    static let all: [LanguagePreference] = [english, japanese, autoDetect]

    // MARK: — App Group persistence

    static func savePreferences(_ prefs: [LanguagePreference], to defaults: UserDefaults = AppGroup.defaults) {
        let codes = prefs.map(\.code)
        if let data = try? JSONEncoder().encode(codes) {
            defaults.set(data, forKey: AppGroupKey.selectedLanguages)
        }
    }

    static func loadPreferences(from defaults: UserDefaults = AppGroup.defaults) -> [LanguagePreference] {
        guard let data = defaults.data(forKey: AppGroupKey.selectedLanguages),
              let codes = try? JSONDecoder().decode([String].self, from: data) else {
            return [.english, .autoDetect]  // default
        }
        return codes.compactMap { code in all.first(where: { $0.code == code }) }
    }

    /// Primary language for STT (first non-auto entry, or nil for auto)
    static func primaryLanguageCode(from defaults: UserDefaults = AppGroup.defaults) -> String? {
        let prefs = loadPreferences(from: defaults)
        return prefs.first(where: { $0.code != "auto" })?.code
    }
}
