// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import Foundation

public enum AppGroup {
    public static let id = "group.io.prisk.keyboard"

    public static var defaults: UserDefaults {
        UserDefaults(suiteName: id)!
    }
}

public enum AppGroupKey {
    /// JSON-encoded TranscriptionResult
    public static let transcriptionResult = "io.prisk.transcriptionResult"
    /// Recording state: idle | recording | processing | done | error
    public static let recordingState = "io.prisk.recordingState"
    /// Real-time partial transcription preview (plain String)
    public static let partialTranscription = "io.prisk.partialTranscription"
    /// Selected STT engine (raw value of STTEngineType)
    public static let selectedEngine = "io.prisk.selectedEngine"
    /// Preferred languages (JSON-encoded [String], BCP-47 codes)
    public static let selectedLanguages = "io.prisk.selectedLanguages"
    /// Whether onboarding has been completed
    public static let onboardingCompleted = "io.prisk.onboardingCompleted"
}

public enum DarwinNotification {
    public static let transcriptionReady = "io.prisk.transcriptionReady"
    public static let recordingStateChanged = "io.prisk.recordingStateChanged"
}

public enum URLScheme {
    public static let startRecording = "prisk://start-recording"

    public static func startRecordingURL(lang: String? = nil) -> URL? {
        var components = URLComponents(string: startRecording)
        if let lang {
            components?.queryItems = [URLQueryItem(name: "lang", value: lang)]
        }
        return components?.url
    }
}
