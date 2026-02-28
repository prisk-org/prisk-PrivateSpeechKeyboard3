// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0
//
// KeyboardViewController — Main keyboard extension controller.
// QWERTY layout with mic button, suggestion bar, number/symbol switching,
// and cursor drag on spacebar.

import UIKit

// MARK: — KeyboardViewController

final class KeyboardViewController: UIInputViewController {

    // MARK: — Constants

    private enum Layout {
        static let keyHeight: CGFloat = 42
        static let suggestionBarHeight: CGFloat = 44
        static let keyCornerRadius: CGFloat = 5
        static let keySpacing: CGFloat = 6

        static let qwertyRows: [[String]] = [
            ["q","w","e","r","t","y","u","i","o","p"],
            ["a","s","d","f","g","h","j","k","l"],
            ["⇧","z","x","c","v","b","n","m","⌫"],
            ["123","space","return"]
        ]

        static let numbersRows: [[String]] = [
            ["1","2","3","4","5","6","7","8","9","0"],
            ["-","/",":",";","(",")",  "$","&","@","\""],
            ["#+=",".","  ,","?","!","'",  "⌫"],
            ["ABC","space","return"]
        ]

        static let symbolsRows: [[String]] = [
            ["[","]","{","}","#","%","^","*","+","="],
            ["_","\\","|","~","<",">","€","£","¥","•"],
            ["123",".","  ,","?","!","'",  "⌫"],
            ["ABC","space","return"]
        ]
    }

    // MARK: — State

    private enum KeyboardMode { case letters, numbers, symbols }
    private var mode: KeyboardMode = .letters
    private var isShifted = false
    private var isShiftLocked = false

    // MARK: — Subviews

    private let suggestionBar = SuggestionBarView()
    private let voiceButton = VoiceInputButton()
    private let cursorTracker = CursorTrackingView()
    private var keyStackView: UIStackView!
    private var keyButtons: [UIButton] = []

    // MARK: — IPC

    private let bridge = AppGroupBridge()

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupSuggestionBar()
        setupKeyboard()
        setupVoiceButton()
        setupBridge()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    // MARK: — Setup: Suggestion Bar

    private func setupSuggestionBar() {
        suggestionBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(suggestionBar)
        NSLayoutConstraint.activate([
            suggestionBar.topAnchor.constraint(equalTo: view.topAnchor),
            suggestionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionBar.heightAnchor.constraint(equalToConstant: Layout.suggestionBarHeight),
        ])
    }

    // MARK: — Setup: Keyboard Grid

    private func setupKeyboard() {
        keyStackView = UIStackView()
        keyStackView.axis = .vertical
        keyStackView.spacing = 8
        keyStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyStackView)

        NSLayoutConstraint.activate([
            keyStackView.topAnchor.constraint(equalTo: suggestionBar.bottomAnchor, constant: 8),
            keyStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 3),
            keyStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
            keyStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
        ])

        buildKeys(for: .letters)
    }

    private func buildKeys(for mode: KeyboardMode) {
        // Remove existing
        keyStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyButtons.removeAll()

        let rows: [[String]]
        switch mode {
        case .letters:  rows = Layout.qwertyRows
        case .numbers:  rows = Layout.numbersRows
        case .symbols:  rows = Layout.symbolsRows
        }

        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Layout.keySpacing
            rowStack.distribution = .fillEqually

            for key in row {
                let button = makeKeyButton(label: key)
                rowStack.addArrangedSubview(button)
                keyButtons.append(button)

                if key == "space" {
                    // Add cursor tracking overlay
                    cursorTracker.translatesAutoresizingMaskIntoConstraints = false
                    button.addSubview(cursorTracker)
                    NSLayoutConstraint.activate([
                        cursorTracker.topAnchor.constraint(equalTo: button.topAnchor),
                        cursorTracker.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                        cursorTracker.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                        cursorTracker.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                    ])
                    cursorTracker.onCursorOffset = { [weak self] offset in
                        self?.moveCursor(by: offset)
                    }
                }
            }

            // Special widths for bottom row
            if row.contains("space") {
                rowStack.distribution = .fill
                for view in rowStack.arrangedSubviews {
                    guard let btn = view as? UIButton,
                          let title = btn.title(for: .normal) else { continue }
                    if title == "space" {
                        btn.setContentHuggingPriority(.defaultLow, for: .horizontal)
                    } else {
                        btn.widthAnchor.constraint(equalToConstant: 80).isActive = true
                    }
                }
            }

            keyStackView.addArrangedSubview(rowStack)
            rowStack.heightAnchor.constraint(equalToConstant: Layout.keyHeight).isActive = true
        }
    }

    private func makeKeyButton(label: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(label == "space" ? "" : label, for: .normal)

        // Spacebar gets a label
        if label == "space" {
            button.setTitle("space", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
        } else if label.count == 1 {
            button.titleLabel?.font = .systemFont(ofSize: 22, weight: .light)
        } else {
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        }

        button.backgroundColor = specialKeys.contains(label)
            ? UIColor.systemGray4
            : UIColor.systemBackground

        button.layer.cornerRadius = Layout.keyCornerRadius
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0.5
        button.tintColor = .label
        button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)

        // Long press on spacebar → voice input
        if label == "space" {
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(spacebarLongPressed(_:)))
            lp.minimumPressDuration = 0.5
            button.addGestureRecognizer(lp)
        }

        return button
    }

    private let specialKeys: Set<String> = ["⇧", "⌫", "123", "ABC", "#+=", "return", "space"]

    // MARK: — Setup: Voice Button

    private func setupVoiceButton() {
        voiceButton.translatesAutoresizingMaskIntoConstraints = false
        suggestionBar.addSubview(voiceButton)
        NSLayoutConstraint.activate([
            voiceButton.trailingAnchor.constraint(equalTo: suggestionBar.trailingAnchor, constant: -8),
            voiceButton.centerYAnchor.constraint(equalTo: suggestionBar.centerYAnchor),
            voiceButton.widthAnchor.constraint(equalToConstant: 36),
            voiceButton.heightAnchor.constraint(equalToConstant: 36),
        ])
        voiceButton.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
    }

    // MARK: — Setup: App Group Bridge

    private func setupBridge() {
        bridge.startListening()
        bridge.onTranscriptionReady = { [weak self] result in
            self?.insertTranscription(result)
        }
        bridge.onPartialTranscription = { [weak self] partial in
            self?.suggestionBar.showPartial(partial)
        }
        bridge.onStateChanged = { [weak self] state in
            switch state {
            case .recording:   self?.voiceButton.setState(.recording)
            case .processing:  self?.voiceButton.setState(.processing); self?.suggestionBar.showProcessing()
            case .done, .idle: self?.voiceButton.setState(.idle); self?.suggestionBar.showIdle()
            case .error:       self?.voiceButton.setState(.idle); self?.suggestionBar.showIdle()
            }
        }
    }

    // MARK: — Key Actions

    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        handleKey(title)
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            textDocumentProxy.deleteBackward()
        case "return":
            textDocumentProxy.insertText("\n")
        case "space":
            textDocumentProxy.insertText(" ")
        case "⇧":
            toggleShift()
        case "123":
            switchMode(.numbers)
        case "ABC":
            switchMode(.letters)
        case "#+=":
            switchMode(.symbols)
        default:
            let text = isShifted ? key.uppercased() : key.lowercased()
            textDocumentProxy.insertText(text)
            if isShifted && !isShiftLocked {
                isShifted = false
                updateShiftButton()
            }
        }
    }

    @objc private func spacebarLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        startVoiceInput()
    }

    @objc private func voiceButtonTapped() {
        startVoiceInput()
    }

    // MARK: — Voice Input

    private func startVoiceInput() {
        voiceButton.setState(.recording)
        suggestionBar.showPartial("Listening…")
        RecordingState.recording.save()

        // Launch PriskApp via URL scheme
        let lang = LanguagePreference.primaryLanguageCode()
        guard let url = URLScheme.startRecordingURL(lang: lang) else { return }
        openURL(url)
    }

    private func openURL(_ url: URL) {
        // Keyboard extensions must use the responder chain to open URLs
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = r.next
        }
    }

    private func insertTranscription(_ result: TranscriptionResult) {
        textDocumentProxy.insertText(result.text)
        suggestionBar.showFinal(result.text)
        voiceButton.setState(.idle)

        // Clear after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.suggestionBar.showIdle()
        }
    }

    // MARK: — Cursor Movement

    private func moveCursor(by offset: Int) {
        let direction: UITextLayoutDirection = offset < 0 ? .left : .right
        for _ in 0..<abs(offset) {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: offset < 0 ? -1 : 1)
        }
    }

    // MARK: — Shift / Mode

    private func toggleShift() {
        if isShiftLocked {
            isShifted = false
            isShiftLocked = false
        } else if isShifted {
            isShiftLocked = true
        } else {
            isShifted = true
        }
        updateShiftButton()
    }

    private func updateShiftButton() {
        for button in keyButtons {
            guard let title = button.title(for: .normal), title == "⇧" else { continue }
            button.tintColor = isShiftLocked ? .systemBlue : (isShifted ? .systemBlue : .label)
        }
    }

    private func switchMode(_ newMode: KeyboardMode) {
        mode = newMode
        buildKeys(for: newMode)
    }

    // MARK: — Text Input Tracking

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
    }

    deinit {
        bridge.stopListening()
    }
}
