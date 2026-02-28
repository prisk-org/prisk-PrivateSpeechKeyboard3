// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import AVFoundation
import Foundation
import WhisperKit

// MARK: — WhisperKitEngine

public final class WhisperKitEngine: NSObject, STTEngine {
    public let engineType: STTEngineType = .whisperKit
    public weak var delegate: (any STTEngineDelegate)?
    public private(set) var state: STTEngineState = .idle
    public var preferredLanguage: String? = nil

    private var whisperKit: WhisperKit?
    private var audioEngine: AVAudioEngine?
    private var isRecording = false
    private var audioBuffer: [Float] = []
    private let sampleRate: Double = 16_000
    private var recordingStartTime: Date?

    // WhisperKit model to use (tiny = fast; use "base" or larger for better accuracy)
    private let modelName: String

    public init(modelName: String = "openai_whisper-base") {
        self.modelName = modelName
        super.init()
    }

    // MARK: — STTEngine

    public func prepare() async throws {
        let _model = modelName
        PriskLogger.stt.info("WhisperKitEngine: prepare start model=\(_model, privacy: .public)")
        setState(.preparing)
        let config = WhisperKitConfig(model: modelName)
        whisperKit = try await WhisperKit(config)
        PriskLogger.stt.info("WhisperKitEngine: model loaded successfully")
        setState(.idle)
    }

    public func startRecording() async throws {
        PriskLogger.stt.info("WhisperKitEngine: startRecording")
        if whisperKit == nil {
            try await prepare()
        }
        setState(.preparing)
        try setupAudioEngine()
        audioBuffer = []
        recordingStartTime = Date()
        isRecording = true
        setState(.listening)
    }

    public func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        setState(.processing)
        Task { await transcribeBuffer() }
    }

    public func cancel() {
        isRecording = false
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioBuffer = []
        setState(.idle)
    }

    // MARK: — Private: Audio capture

    private func setupAudioEngine() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setPreferredSampleRate(sampleRate)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let engine = AVAudioEngine()
        audioEngine = engine
        let inputNode = engine.inputNode
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: sampleRate,
                                   channels: 1,
                                   interleaved: false)!

        inputNode.installTap(onBus: 0, bufferSize: 1600, format: format) { [weak self] buffer, _ in
            guard let self, self.isRecording else { return }
            let channelData = buffer.floatChannelData![0]
            let frameLength = Int(buffer.frameLength)
            self.audioBuffer.append(contentsOf: UnsafeBufferPointer(start: channelData, count: frameLength))

            // Publish partial every ~2 seconds of audio
            if self.audioBuffer.count % Int(self.sampleRate * 2) < 1600 {
                Task { await self.producePartialResult() }
            }
        }

        try engine.start()
    }

    // MARK: — Inference

    private func producePartialResult() async {
        guard let whisperKit, !audioBuffer.isEmpty else { return }
        let snapshot = audioBuffer
        do {
            let options = DecodingOptions(
                task: .transcribe,
                language: preferredLanguage,
                usePrefillPrompt: true
            )
            let results = try await whisperKit.transcribe(audioArray: snapshot, decodeOptions: options)
            let partial = results.first?.text ?? ""
            if !partial.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                delegate?.engine(self, didProducePartialText: partial)
            }
        } catch {
            // partial errors are non-fatal
        }
    }

    private func transcribeBuffer() async {
        let _bufSize = audioBuffer.count
        PriskLogger.stt.info("WhisperKitEngine: transcribeBuffer bufferSize=\(_bufSize)")
        guard let whisperKit, !audioBuffer.isEmpty else {
            setState(.idle)
            return
        }
        let duration = Date().timeIntervalSince(recordingStartTime ?? Date())
        do {
            let options = DecodingOptions(
                task: .transcribe,
                language: preferredLanguage,
                usePrefillPrompt: true
            )
            let results = try await whisperKit.transcribe(audioArray: audioBuffer, decodeOptions: options)
            let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            PriskLogger.stt.info("WhisperKitEngine: result='\(text.prefix(50), privacy: .private)'")
            let detectedLang = results.first?.language

            let result = TranscriptionResult(
                text: text,
                language: detectedLang ?? preferredLanguage,
                engineType: .whisperKit,
                confidence: nil,
                durationSeconds: duration
            )
            audioBuffer = []
            setState(.finished)
            delegate?.engine(self, didFinishWith: result)
        } catch {
            setState(.failed(error.localizedDescription))
            delegate?.engine(self, didFailWith: error)
        }
    }

    // MARK: — State

    private func setState(_ newState: STTEngineState) {
        state = newState
        delegate?.engine(self, didChangeState: newState)
    }
}
