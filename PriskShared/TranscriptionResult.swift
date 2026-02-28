// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import Foundation

public struct TranscriptionResult: Codable, Equatable {
    public let text: String
    public let language: String?
    public let engineType: STTEngineType
    public let confidence: Double?
    public let durationSeconds: Double
    public let timestamp: Date

    public init(
        text: String,
        language: String? = nil,
        engineType: STTEngineType,
        confidence: Double? = nil,
        durationSeconds: Double = 0,
        timestamp: Date = Date()
    ) {
        self.text = text
        self.language = language
        self.engineType = engineType
        self.confidence = confidence
        self.durationSeconds = durationSeconds
        self.timestamp = timestamp
    }

    // MARK: — App Group persistence

    public func save(to defaults: UserDefaults = AppGroup.defaults) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(self) {
            defaults.set(data, forKey: AppGroupKey.transcriptionResult)
        }
    }

    public static func load(from defaults: UserDefaults = AppGroup.defaults) -> TranscriptionResult? {
        guard let data = defaults.data(forKey: AppGroupKey.transcriptionResult) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(TranscriptionResult.self, from: data)
    }
}

// MARK: — Recording State

public enum RecordingState: String, Codable {
    case idle
    case recording
    case processing
    case done
    case error

    public func save(to defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(rawValue, forKey: AppGroupKey.recordingState)
    }

    public static func load(from defaults: UserDefaults = AppGroup.defaults) -> RecordingState {
        guard let raw = defaults.string(forKey: AppGroupKey.recordingState),
              let state = RecordingState(rawValue: raw) else { return .idle }
        return state
    }
}
