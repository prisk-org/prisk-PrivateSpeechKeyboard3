// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import OSLog

/// Centralized logging for Prisk. Subsystem: "io.prisk.keyboard"
/// View in: Xcode console (main app) or Console.app (keyboard extension).
/// Console.app filter: subsystem == "io.prisk.keyboard"
/// Simulator: xcrun simctl spawn booted log stream --predicate 'subsystem == "io.prisk.keyboard"'
public struct PriskLogger {
    /// Main app lifecycle, scene, onboarding
    public static let app      = Logger(subsystem: "io.prisk.keyboard", category: "app")
    /// Keyboard extension UI and input handling
    public static let keyboard = Logger(subsystem: "io.prisk.keyboard", category: "keyboard")
    /// STT engine operations (recording, transcription)
    public static let stt      = Logger(subsystem: "io.prisk.keyboard", category: "stt")
    /// App Group UserDefaults read/write
    public static let appGroup = Logger(subsystem: "io.prisk.keyboard", category: "appgroup")
    /// Darwin Notification IPC between keyboard and app
    public static let ipc      = Logger(subsystem: "io.prisk.keyboard", category: "ipc")
}
