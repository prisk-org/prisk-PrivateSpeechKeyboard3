// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        setupSTTEngines()
        return true
    }

    // MARK: — UISceneSession

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: — STT Engine Setup

    private func setupSTTEngines() {
        Task { @MainActor in
            let manager = STTEngineManager.shared
            manager.register(WhisperKitEngine())
            manager.register(SFSpeechEngine())
            manager.register(SpeechAnalyzerEngine())
            manager.register(MoonshineEngine())
            manager.register(ReazonSpeechEngine())
            manager.register(VoskEngine())
            manager.register(KotobaWhisperEngine())

            // Activate the user's preferred engine
            let engineType = STTEngineType.load()
            // Delegate will be set by RecordingViewController when it appears
            _ = try? manager.engine(for: engineType)
        }
    }
}
