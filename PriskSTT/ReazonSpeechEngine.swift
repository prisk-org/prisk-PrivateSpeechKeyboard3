// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0
//
// ReazonSpeechEngine — Japanese ASR via Sherpa-ONNX (Phase 5 stub)

import Foundation

public final class ReazonSpeechEngine: SherpaONNXBaseEngine {
    public init() {
        super.init(engineType: .reazonSpeech)
        preferredLanguage = "ja-JP"
    }
}
