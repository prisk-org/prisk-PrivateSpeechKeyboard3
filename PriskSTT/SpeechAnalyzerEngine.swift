// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0
//
// SpeechAnalyzerEngine — iOS 26+ only stub.
// On earlier OS versions this engine is unavailable and STTEngineType.isAvailable returns false.

import Foundation

// MARK: — SpeechAnalyzerEngine

public final class SpeechAnalyzerEngine: STTEngine {
    public let engineType: STTEngineType = .speechAnalyzer
    public weak var delegate: (any STTEngineDelegate)?
    public private(set) var state: STTEngineState = .idle
    public var preferredLanguage: String? = nil

    public init() {}

    public func startRecording() async throws {
        if #available(iOS 26, *) {
            try await startRecordingIOS26()
        } else {
            throw SpeechAnalyzerError.requiresiOS26
        }
    }

    public func stopRecording() {
        if #available(iOS 26, *) {
            stopRecordingIOS26()
        }
    }

    // MARK: — iOS 26+ implementation

    @available(iOS 26, *)
    private func startRecordingIOS26() async throws {
        // TODO: integrate SpeechAnalyzer API when iOS 26 SDK ships
        setState(.listening)
    }

    @available(iOS 26, *)
    private func stopRecordingIOS26() {
        setState(.idle)
    }

    // MARK: — State

    private func setState(_ newState: STTEngineState) {
        state = newState
        delegate?.engine(self, didChangeState: newState)
    }
}

// MARK: — Errors

enum SpeechAnalyzerError: LocalizedError {
    case requiresiOS26

    var errorDescription: String? {
        "SpeechAnalyzer requires iOS 26 or later."
    }
}
