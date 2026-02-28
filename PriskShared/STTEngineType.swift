// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import Foundation

public enum STTEngineType: String, Codable, CaseIterable {
    case whisperKit       = "whisperKit"
    case sfSpeech         = "sfSpeech"
    case speechAnalyzer   = "speechAnalyzer"   // iOS 26+ only
    case moonshine        = "moonshine"         // Phase 5
    case reazonSpeech     = "reazonSpeech"      // Phase 5
    case vosk             = "vosk"              // Phase 5
    case kotobaWhisper    = "kotobaWhisper"     // Phase 5

    public var displayName: String {
        switch self {
        case .whisperKit:     return "WhisperKit"
        case .sfSpeech:       return "SFSpeechRecognizer"
        case .speechAnalyzer: return "SpeechAnalyzer"
        case .moonshine:      return "Moonshine"
        case .reazonSpeech:   return "ReazonSpeech-k2-v2"
        case .vosk:           return "Vosk"
        case .kotobaWhisper:  return "Kotoba-Whisper"
        }
    }

    public var minimumOSDescription: String {
        switch self {
        case .speechAnalyzer: return "iOS 26+"
        default:              return "iOS 16+"
        }
    }

    public var isAvailable: Bool {
        switch self {
        case .speechAnalyzer:
            if #available(iOS 26, *) { return true }
            return false
        case .moonshine, .reazonSpeech, .vosk, .kotobaWhisper:
            return false  // Phase 5 — not yet implemented
        default:
            return true
        }
    }

    public static func load(from defaults: UserDefaults = AppGroup.defaults) -> STTEngineType {
        guard let raw = defaults.string(forKey: AppGroupKey.selectedEngine),
              let engine = STTEngineType(rawValue: raw) else { return .whisperKit }
        return engine
    }

    public func save(to defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(rawValue, forKey: AppGroupKey.selectedEngine)
    }
}
