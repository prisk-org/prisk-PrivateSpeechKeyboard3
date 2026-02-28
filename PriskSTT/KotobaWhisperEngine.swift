// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0
//
// KotobaWhisperEngine — Japanese-optimized Whisper via Sherpa-ONNX (Phase 5 stub)

import Foundation

public final class KotobaWhisperEngine: SherpaONNXBaseEngine {
    public init() {
        super.init(engineType: .kotobaWhisper)
        preferredLanguage = "ja-JP"
    }
}
