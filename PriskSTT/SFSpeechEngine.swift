// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import AVFoundation
import Foundation
import Speech

// MARK: — SFSpeechEngine

public final class SFSpeechEngine: NSObject, STTEngine {
    public let engineType: STTEngineType = .sfSpeech
    public weak var delegate: (any STTEngineDelegate)?
    public private(set) var state: STTEngineState = .idle
    public var preferredLanguage: String? = "en-US"

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var recordingStartTime: Date?

    // MARK: — STTEngine

    public func prepare() async throws {
        let status = await SFSpeechRecognizer.requestAuthorization()
        PriskLogger.stt.info("SFSpeechEngine: requestAuthorization status=\(status.rawValue)")
        guard status == .authorized else {
            throw SFSpeechError.notAuthorized(status)
        }
    }

    public func startRecording() async throws {
        try await prepare()
        setState(.preparing)

        let locale = Locale(identifier: preferredLanguage ?? "en-US")
        let _lang = preferredLanguage ?? "nil"
        PriskLogger.stt.info("SFSpeechEngine: startRecording locale=\(_lang, privacy: .public)")
        recognizer = SFSpeechRecognizer(locale: locale)
        recognizer?.defaultTaskHint = .dictation

        guard let recognizer, recognizer.isAvailable else {
            throw SFSpeechError.recognizerUnavailable
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        #if targetEnvironment(simulator)
        request.requiresOnDeviceRecognition = false
        #else
        request.requiresOnDeviceRecognition = true  // 100% on-device
        #endif
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recordingStartTime = Date()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        setState(.listening)

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                PriskLogger.stt.info("SFSpeechEngine: result isFinal=\(result.isFinal)")
                if result.isFinal {
                    let duration = Date().timeIntervalSince(self.recordingStartTime ?? Date())
                    let finalResult = TranscriptionResult(
                        text: text,
                        language: self.preferredLanguage,
                        engineType: .sfSpeech,
                        durationSeconds: duration
                    )
                    self.setState(.finished)
                    self.delegate?.engine(self, didFinishWith: finalResult)
                } else {
                    self.delegate?.engine(self, didProducePartialText: text)
                }
            }
            if let error {
                self.setState(.failed(error.localizedDescription))
                self.delegate?.engine(self, didFailWith: error)
            }
        }
    }

    public func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        setState(.processing)
    }

    public func cancel() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        setState(.idle)
    }

    // MARK: — State

    private func setState(_ newState: STTEngineState) {
        state = newState
        delegate?.engine(self, didChangeState: newState)
    }
}

// MARK: — SFSpeechRecognizer.requestAuthorization async

extension SFSpeechRecognizer {
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}

// MARK: — Errors

enum SFSpeechError: LocalizedError {
    case notAuthorized(SFSpeechRecognizerAuthorizationStatus)
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthorized(let status):
            return "Speech recognition not authorized (status: \(status.rawValue))."
        case .recognizerUnavailable:
            return "SFSpeechRecognizer is not available for the selected locale."
        }
    }
}
