// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import Foundation

@MainActor
public final class STTEngineManager {
    public static let shared = STTEngineManager()

    private var engines: [STTEngineType: any STTEngine] = [:]
    private(set) public var activeEngine: (any STTEngine)?

    private init() {}

    // MARK: — Engine Registration

    public func register(_ engine: any STTEngine) {
        engines[engine.engineType] = engine
    }

    public func engine(for type: STTEngineType) -> (any STTEngine)? {
        engines[type]
    }

    // MARK: — Activation

    public func activate(_ type: STTEngineType, delegate: any STTEngineDelegate) throws {
        PriskLogger.stt.info("STTEngineManager: activating engine \(type.rawValue, privacy: .public)")
        guard let engine = engines[type] else {
            throw STTManagerError.engineNotRegistered(type)
        }
        guard type.isAvailable else {
            throw STTManagerError.engineUnavailable(type)
        }
        activeEngine?.cancel()
        activeEngine = engine
        engine.delegate = delegate
    }

    // MARK: — Recording Control

    public func startRecording() async throws {
        PriskLogger.stt.info("STTEngineManager: startRecording")
        guard let engine = activeEngine else {
            throw STTManagerError.noActiveEngine
        }
        try await engine.startRecording()
    }

    public func stopRecording() {
        activeEngine?.stopRecording()
    }

    public func cancel() {
        activeEngine?.cancel()
    }

    // MARK: — App Group Publishing

    /// Write a partial result to App Group for keyboard preview
    public func publishPartial(_ text: String) {
        let defaults = AppGroup.defaults
        defaults.set(text, forKey: AppGroupKey.partialTranscription)
        RecordingState.recording.save()
        postDarwinNotification(DarwinNotification.recordingStateChanged)
    }

    /// Write the final result to App Group and notify keyboard
    public func publishResult(_ result: TranscriptionResult) {
        PriskLogger.stt.info("STTEngineManager: publishResult text='\(result.text.prefix(50), privacy: .private)'")
        result.save()
        RecordingState.done.save()
        // Clear partial
        AppGroup.defaults.removeObject(forKey: AppGroupKey.partialTranscription)
        postDarwinNotification(DarwinNotification.transcriptionReady)
    }

    public func publishError(_ error: Error) {
        RecordingState.error.save()
        postDarwinNotification(DarwinNotification.recordingStateChanged)
    }

    // MARK: — Private

    private func postDarwinNotification(_ name: String) {
        let nc = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            nc,
            CFNotificationName(name as CFString),
            nil, nil, true
        )
    }
}

// MARK: — Errors

public enum STTManagerError: LocalizedError {
    case noActiveEngine
    case engineNotRegistered(STTEngineType)
    case engineUnavailable(STTEngineType)

    public var errorDescription: String? {
        switch self {
        case .noActiveEngine:
            return "No STT engine is active."
        case .engineNotRegistered(let t):
            return "\(t.displayName) is not registered."
        case .engineUnavailable(let t):
            return "\(t.displayName) requires \(t.minimumOSDescription)."
        }
    }
}
