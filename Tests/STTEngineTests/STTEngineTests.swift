// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import XCTest
@testable import PriskApp  // for access to PriskSTT and PriskShared types

final class STTEngineTests: XCTestCase {

    // MARK: — AppGroupConstants

    func testAppGroupIDIsCorrect() {
        XCTAssertEqual(AppGroup.id, "group.io.prisk.keyboard")
    }

    func testURLSchemeGeneration() {
        let url = URLScheme.startRecordingURL(lang: "ja-JP")
        XCTAssertEqual(url?.absoluteString, "prisk://start-recording?lang=ja-JP")
    }

    func testURLSchemeWithoutLang() {
        let url = URLScheme.startRecordingURL()
        XCTAssertEqual(url?.absoluteString, "prisk://start-recording")
    }

    // MARK: — STTEngineType

    func testSTTEngineTypeDisplayNames() {
        XCTAssertEqual(STTEngineType.whisperKit.displayName, "WhisperKit")
        XCTAssertEqual(STTEngineType.sfSpeech.displayName, "SFSpeechRecognizer")
        XCTAssertEqual(STTEngineType.speechAnalyzer.displayName, "SpeechAnalyzer")
    }

    func testSpeechAnalyzerUnavailableOniOS16() {
        // On iOS 16 simulator, SpeechAnalyzer should not be available
        if #available(iOS 26, *) {
            XCTAssertTrue(STTEngineType.speechAnalyzer.isAvailable, "Should be available on iOS 26+")
        } else {
            XCTAssertFalse(STTEngineType.speechAnalyzer.isAvailable, "Should not be available below iOS 26")
        }
    }

    func testPhase5EnginesUnavailable() {
        XCTAssertFalse(STTEngineType.moonshine.isAvailable)
        XCTAssertFalse(STTEngineType.reazonSpeech.isAvailable)
        XCTAssertFalse(STTEngineType.vosk.isAvailable)
        XCTAssertFalse(STTEngineType.kotobaWhisper.isAvailable)
    }

    // MARK: — TranscriptionResult

    func testTranscriptionResultCodable() throws {
        let result = TranscriptionResult(
            text: "Hello, world!",
            language: "en-US",
            engineType: .whisperKit,
            confidence: 0.95,
            durationSeconds: 2.5
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(result)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TranscriptionResult.self, from: data)

        XCTAssertEqual(decoded.text, "Hello, world!")
        XCTAssertEqual(decoded.language, "en-US")
        XCTAssertEqual(decoded.engineType, .whisperKit)
        XCTAssertEqual(decoded.confidence, 0.95)
        XCTAssertEqual(decoded.durationSeconds, 2.5)
    }

    // MARK: — RecordingState

    func testRecordingStateRoundTrip() {
        for state in [RecordingState.idle, .recording, .processing, .done, .error] {
            XCTAssertEqual(RecordingState(rawValue: state.rawValue), state)
        }
    }

    // MARK: — LanguagePreference

    func testDefaultLanguagePreferences() {
        let prefs = LanguagePreference.all
        XCTAssertTrue(prefs.contains(.english))
        XCTAssertTrue(prefs.contains(.japanese))
        XCTAssertTrue(prefs.contains(.autoDetect))
    }

    func testLanguagePreferenceCodes() {
        XCTAssertEqual(LanguagePreference.english.code, "en-US")
        XCTAssertEqual(LanguagePreference.japanese.code, "ja-JP")
        XCTAssertEqual(LanguagePreference.autoDetect.code, "auto")
    }

    // MARK: — STTEngineManager

    @MainActor
    func testEngineRegistrationAndActivation() throws {
        let manager = STTEngineManager.shared
        let mockEngine = MockSTTEngine()
        manager.register(mockEngine)

        let delegate = MockSTTEngineDelegate()
        XCTAssertNoThrow(try manager.activate(.whisperKit, delegate: delegate))
    }
}

// MARK: — Mock Types

private final class MockSTTEngine: STTEngine {
    let engineType: STTEngineType = .whisperKit
    weak var delegate: (any STTEngineDelegate)?
    var state: STTEngineState = .idle
    var preferredLanguage: String? = nil

    func startRecording() async throws { state = .listening }
    func stopRecording() { state = .idle }
}

private final class MockSTTEngineDelegate: STTEngineDelegate {
    func engine(_ engine: any STTEngine, didProducePartialText text: String) {}
    func engine(_ engine: any STTEngine, didFinishWith result: TranscriptionResult) {}
    func engine(_ engine: any STTEngine, didFailWith error: Error) {}
    func engine(_ engine: any STTEngine, didChangeState state: STTEngineState) {}
}
