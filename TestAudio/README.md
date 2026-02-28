# TestAudio

Audio samples for STT accuracy testing.

Place `.mp3` (or `.wav`) files here along with a `.txt` file of the same name containing the expected transcription.

Example:
```
TestAudio/
├── english_hello_world.mp3   # "Hello, world!"
├── english_hello_world.txt   # Hello, world!
├── japanese_arigatou.mp3     # "ありがとうございます"
└── japanese_arigatou.txt     # ありがとうございます
```

These files are excluded from git (see `.gitignore`) to keep the repo lightweight.
Add your own samples for local testing.
