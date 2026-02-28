// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import Foundation

// MARK: — AppGroupBridge
// Keyboard-side bridge to App Group + Darwin Notification for IPC with PriskApp.

final class AppGroupBridge {

    // MARK: — Callbacks

    var onTranscriptionReady: ((TranscriptionResult) -> Void)?
    var onPartialTranscription: ((String) -> Void)?
    var onStateChanged: ((RecordingState) -> Void)?

    // MARK: — Darwin Notification

    func startListening() {
        let nc = CFNotificationCenterGetDarwinNotifyCenter()

        // Final result ready
        CFNotificationCenterAddObserver(
            nc,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, name, _, _ in
                guard let observer else { return }
                let bridge = Unmanaged<AppGroupBridge>.fromOpaque(observer).takeUnretainedValue()
                bridge.handleTranscriptionReady()
            },
            DarwinNotification.transcriptionReady as CFString,
            nil,
            .deliverImmediately
        )

        // State changes (including partials)
        CFNotificationCenterAddObserver(
            nc,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, name, _, _ in
                guard let observer else { return }
                let bridge = Unmanaged<AppGroupBridge>.fromOpaque(observer).takeUnretainedValue()
                bridge.handleStateChanged()
            },
            DarwinNotification.recordingStateChanged as CFString,
            nil,
            .deliverImmediately
        )
    }

    func stopListening() {
        let nc = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(nc, Unmanaged.passUnretained(self).toOpaque())
    }

    // MARK: — Trigger PriskApp

    func openPriskApp(lang: String? = nil) {
        guard let url = URLScheme.startRecordingURL(lang: lang) else { return }
        // In keyboard extension, open URL via UIApplication.shared on the main thread
        DispatchQueue.main.async {
            // Keyboard extensions use UIApplication via responder chain trick
            _ = url  // URL is passed; actual open is done in KeyboardViewController
        }
    }

    // MARK: — Handlers

    private func handleTranscriptionReady() {
        guard let result = TranscriptionResult.load() else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onTranscriptionReady?(result)
        }
    }

    private func handleStateChanged() {
        let state = RecordingState.load()
        DispatchQueue.main.async { [weak self] in
            self?.onStateChanged?(state)
            if state == .recording {
                let partial = AppGroup.defaults.string(forKey: AppGroupKey.partialTranscription) ?? ""
                if !partial.isEmpty {
                    self?.onPartialTranscription?(partial)
                }
            }
        }
    }
}
