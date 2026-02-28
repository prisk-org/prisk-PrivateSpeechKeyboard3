// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import UIKit

// MARK: — RecordingViewController
// Shown when the keyboard opens the app via prisk:// URL scheme.
// Handles STT lifecycle and publishes results back to the keyboard via App Group.

final class RecordingViewController: UIViewController {

    // MARK: — Public

    /// Set by SceneDelegate when launched from keyboard URL scheme
    var autoStartLanguage: String?

    // MARK: — UI

    private let micButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 40))
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to start recording"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let transcriptionLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let engineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let settingsButton = UIBarButtonItem(
        image: UIImage(systemName: "gearshape"),
        style: .plain,
        target: nil,
        action: nil
    )

    // MARK: — State

    private var isRecording = false
    private var engineType: STTEngineType { STTEngineType.load() }

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        let _et = engineType.rawValue
        PriskLogger.app.info("RecordingVC: viewDidLoad engineType=\(_et, privacy: .public)")
        title = "Prisk"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = settingsButton
        settingsButton.target = self
        settingsButton.action = #selector(openSettings)
        setupLayout()
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        updateEngineLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateEngineLabel()
    }

    // MARK: — Layout

    private func setupLayout() {
        view.addSubview(engineLabel)
        view.addSubview(transcriptionLabel)
        view.addSubview(micButton)
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            engineLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            engineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            transcriptionLabel.topAnchor.constraint(equalTo: engineLabel.bottomAnchor, constant: 24),
            transcriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            transcriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 100),
            micButton.heightAnchor.constraint(equalToConstant: 100),

            statusLabel.topAnchor.constraint(equalTo: micButton.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: — Public API (called by SceneDelegate)

    func startRecordingIfNeeded() {
        if autoStartLanguage != nil {
            Task { await startRecording() }
        }
    }

    // MARK: — Actions

    @objc private func micTapped() {
        let _rec = isRecording
        PriskLogger.app.info("RecordingVC: micTapped isRecording=\(_rec)")
        if isRecording {
            STTEngineManager.shared.stopRecording()
        } else {
            Task { await startRecording() }
        }
    }

    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    // MARK: — Recording

    private func startRecording() async {
        let manager = STTEngineManager.shared
        do {
            try manager.activate(engineType, delegate: self)
            // Override language if specified by URL scheme
            if let lang = autoStartLanguage {
                manager.activeEngine?.preferredLanguage = lang
            }
            try await manager.startRecording()
            isRecording = true
            updateUI(for: .listening)
            RecordingState.recording.save()
        } catch {
            showError(error)
        }
    }

    // MARK: — UI Updates

    private func updateUI(for state: STTEngineState) {
        PriskLogger.app.info("RecordingVC: state changed to \(String(describing: state), privacy: .public)")
        switch state {
        case .idle, .finished:
            micButton.configuration?.baseBackgroundColor = .systemBlue
            statusLabel.text = "Tap to record"
            isRecording = false
            autoStartLanguage = nil
        case .preparing:
            statusLabel.text = "Preparing… (first run: downloading model ~75MB)"
        case .listening:
            micButton.configuration?.baseBackgroundColor = .systemRed
            statusLabel.text = "Listening… (tap to stop)"
        case .processing:
            micButton.configuration?.baseBackgroundColor = .systemOrange
            statusLabel.text = "Processing…"
        case .failed(let msg):
            micButton.configuration?.baseBackgroundColor = .systemBlue
            statusLabel.text = "Error"
            transcriptionLabel.text = msg
            isRecording = false
        }
    }

    private func updateEngineLabel() {
        engineLabel.text = "Engine: \(engineType.displayName)"
    }

    private func showError(_ error: Error) {
        PriskLogger.app.error("RecordingVC: error=\(error.localizedDescription, privacy: .public)")
        statusLabel.text = "Error: \(error.localizedDescription)"
        isRecording = false
        updateUI(for: .idle)
    }
}

// MARK: — STTEngineDelegate

extension RecordingViewController: STTEngineDelegate {
    func engine(_ engine: any STTEngine, didProducePartialText text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.transcriptionLabel.text = text
            self?.transcriptionLabel.textColor = .secondaryLabel
        }
        STTEngineManager.shared.publishPartial(text)
    }

    func engine(_ engine: any STTEngine, didFinishWith result: TranscriptionResult) {
        DispatchQueue.main.async { [weak self] in
            self?.transcriptionLabel.text = result.text
            self?.transcriptionLabel.textColor = .label
            self?.updateUI(for: .finished)
        }
        STTEngineManager.shared.publishResult(result)

        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Done — return to keyboard"
        }
    }

    func engine(_ engine: any STTEngine, didFailWith error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showError(error)
        }
        STTEngineManager.shared.publishError(error)
    }

    func engine(_ engine: any STTEngine, didChangeState state: STTEngineState) {
        DispatchQueue.main.async { [weak self] in
            self?.updateUI(for: state)
        }
    }
}
