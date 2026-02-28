// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0
//
// MoonshineEngine — English-only ASR via Sherpa-ONNX (Phase 5 stub)

import Foundation

public final class MoonshineEngine: SherpaONNXBaseEngine {
    public init() {
        super.init(engineType: .moonshine)
        preferredLanguage = "en-US"
    }
}
