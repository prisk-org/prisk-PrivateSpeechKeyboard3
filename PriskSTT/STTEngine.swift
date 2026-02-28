// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import Foundation

// MARK: — STTEngineDelegate

public protocol STTEngineDelegate: AnyObject {
    /// Called with partial (interim) transcription during recognition
    func engine(_ engine: any STTEngine, didProducePartialText text: String)
    /// Called with the final transcription result
    func engine(_ engine: any STTEngine, didFinishWith result: TranscriptionResult)
    /// Called when an error occurs
    func engine(_ engine: any STTEngine, didFailWith error: Error)
    /// Called when the engine state changes
    func engine(_ engine: any STTEngine, didChangeState state: STTEngineState)
}

// MARK: — STTEngineState

public enum STTEngineState: Equatable {
    case idle
    case preparing   // loading model / acquiring mic
    case listening   // actively recording
    case processing  // final inference pass
    case finished
    case failed(String)

    public static func == (lhs: STTEngineState, rhs: STTEngineState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.preparing, .preparing),
             (.listening, .listening), (.processing, .processing),
             (.finished, .finished): return true
        case let (.failed(a), .failed(b)): return a == b
        default: return false
        }
    }
}

// MARK: — STTEngine Protocol

public protocol STTEngine: AnyObject {
    var engineType: STTEngineType { get }
    var delegate: (any STTEngineDelegate)? { get set }
    var state: STTEngineState { get }

    /// Preferred language code (BCP-47). nil = auto-detect.
    var preferredLanguage: String? { get set }

    /// Start recording and transcribing
    func startRecording() async throws

    /// Stop recording (triggers final result)
    func stopRecording()

    /// Cancel without producing a result
    func cancel()

    /// Prepare model (pre-load, optional warm-up)
    func prepare() async throws
}

// MARK: — Default implementations

public extension STTEngine {
    func prepare() async throws {
        // Default: no-op. Engines that need model loading override this.
    }

    func cancel() {
        stopRecording()
    }
}
