# Prisk — Private Speech Keyboard

**100% on-device speech-to-text keyboard for iPhone and iPad.**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-lightgrey.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](https://swift.org)

> "Your voice stays on your device." — No cloud. No tracking. No compromises.

---

## Features

- **100% on-device** — all speech recognition runs locally, nothing leaves your iPhone
- **Multiple STT engines** — WhisperKit (default), SFSpeechRecognizer, SpeechAnalyzer (iOS 26+)
- **Multilingual** — English, Japanese, and more via WhisperKit
- **Privacy-first** — open source, auditable, Apache 2.0 licensed
- **Standard QWERTY** — familiar layout with mic button for voice input

## Architecture

Prisk uses a "Typeless-style" architecture to work around the keyboard extension's ~70MB memory limit:

```
[PriskKeyboard] ──prisk://start-recording──▶ [PriskApp]
                                                  │ STT (WhisperKit, ~200MB+)
                                                  │ App Group UserDefaults
                ◀──Darwin Notification────────────┘
                   io.prisk.transcriptionReady
```

## STT Engines

| Engine | Availability | Languages |
|--------|-------------|-----------|
| WhisperKit | iOS 16+ (default) | 99 languages |
| SFSpeechRecognizer | iOS 16+ | System languages |
| SpeechAnalyzer | iOS 26+ | System languages |
| Moonshine | Phase 5 | English |
| ReazonSpeech-k2-v2 | Phase 5 | Japanese |
| Vosk | Phase 5 | Multiple |
| Kotoba-Whisper | Phase 5 | Japanese |

## Requirements

- iOS 16.0+ / iPadOS 16.0+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Getting Started

```bash
# Clone the repository
git clone https://github.com/prisk-org/prisk-PrivateSpeechKeyboard3.git
cd prisk-PrivateSpeechKeyboard3

# Generate Xcode project
xcodegen generate

# Open in Xcode
open Prisk.xcodeproj
```

Then in Xcode:
1. Select your development team in Signing & Capabilities
2. Build and run on a real device (keyboard extensions require a physical device for full testing)
3. Go to Settings → General → Keyboard → Keyboards → Add New Keyboard → Prisk

## Project Structure

```
prisk-PrivateSpeechKeyboard3/
├── PriskApp/         # Main app (STT host, settings, onboarding)
├── PriskKeyboard/    # Keyboard extension (giellakbd-ios based)
├── PriskSTT/         # STT engine abstraction layer
├── PriskShared/      # Shared types (App Group communication)
├── Tests/            # Unit and UI tests
├── TestAudio/        # Audio samples for STT accuracy testing
├── docs/             # GitHub Pages site
└── project.yml       # XcodeGen configuration
```

## License

Apache 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE) for details.

This project is derived from [giellakbd-ios](https://github.com/divvun/giellakbd-ios) (Apache 2.0, Divvun / UiT The Arctic University of Norway).

## Contributing

Contributions welcome! See [CONTRIBUTORS.md](CONTRIBUTORS.md).

---

*"prisk" (Norwegian/Swedish): lively, sprightly — just like your keyboard should be.*
