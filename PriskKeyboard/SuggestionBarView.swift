// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import UIKit

// MARK: — SuggestionBarView
// Displays partial (interim) transcription in grey and final in black.
// Sits above the keyboard rows.

final class SuggestionBarView: UIView {

    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: — Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        backgroundColor = .systemBackground
        addSubview(label)
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            label.leadingAnchor.constraint(equalTo: activityIndicator.trailingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    // MARK: — Public API

    func showPartial(_ text: String) {
        label.text = text
        label.textColor = .secondaryLabel
        activityIndicator.startAnimating()
    }

    func showFinal(_ text: String) {
        label.text = text
        label.textColor = .label
        activityIndicator.stopAnimating()
    }

    func showIdle() {
        label.text = ""
        activityIndicator.stopAnimating()
    }

    func showProcessing() {
        label.text = "Processing…"
        label.textColor = .secondaryLabel
        activityIndicator.startAnimating()
    }
}
