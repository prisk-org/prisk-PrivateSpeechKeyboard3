// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0
//
// SherpaONNXWrapper — Base class for Sherpa-ONNX backed engines (Phase 5)
// Currently a stub. Sherpa-ONNX XCFramework integration happens in Phase 5.

import Foundation

// MARK: — SherpaONNXBaseEngine

/// Abstract base for all Sherpa-ONNX powered engines.
/// Subclasses provide the model-specific configuration.
open class SherpaONNXBaseEngine: STTEngine {
    public let engineType: STTEngineType
    public weak var delegate: (any STTEngineDelegate)?
    public private(set) var state: STTEngineState = .idle
    public var preferredLanguage: String?

    public init(engineType: STTEngineType) {
        self.engineType = engineType
    }

    public func startRecording() async throws {
        throw SherpaONNXError.notImplemented(engineType)
    }

    public func stopRecording() {
        setState(.idle)
    }

    // MARK: — State

    func setState(_ newState: STTEngineState) {
        state = newState
        delegate?.engine(self, didChangeState: newState)
    }
}

// MARK: — Errors

public enum SherpaONNXError: LocalizedError {
    case notImplemented(STTEngineType)
    case modelNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let t):
            return "\(t.displayName) is not yet implemented (Phase 5)."
        case .modelNotFound(let path):
            return "Sherpa-ONNX model not found at: \(path)"
        }
    }
}
