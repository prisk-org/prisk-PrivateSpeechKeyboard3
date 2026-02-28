// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import UIKit

// MARK: — VoiceInputButton
// Microphone button for the keyboard. Shows recording state via icon + pulse animation.

final class VoiceInputButton: UIButton {

    // MARK: — State

    enum ButtonState {
        case idle, recording, processing
    }

    private(set) var buttonState: ButtonState = .idle {
        didSet { updateAppearance() }
    }

    // MARK: — Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAppearance()
    }

    // MARK: — Setup

    private func setupAppearance() {
        setImage(UIImage(systemName: "mic.fill"), for: .normal)
        tintColor = .systemBlue
        layer.cornerRadius = 8
        backgroundColor = .clear
    }

    // MARK: — Public

    func setState(_ state: ButtonState) {
        buttonState = state
    }

    // MARK: — Private

    private func updateAppearance() {
        layer.removeAllAnimations()
        switch buttonState {
        case .idle:
            tintColor = .systemBlue
            backgroundColor = .clear
        case .recording:
            tintColor = .systemRed
            backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
            pulseAnimation()
        case .processing:
            tintColor = .systemOrange
            backgroundColor = .clear
        }
    }

    private func pulseAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.4
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        layer.add(animation, forKey: "pulse")
    }
}
