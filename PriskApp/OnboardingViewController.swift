// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import UIKit

// MARK: — OnboardingViewController
// Shown on first launch. User selects preferred language(s) + STT engine.

final class OnboardingViewController: UIViewController {

    // MARK: — UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to Prisk"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "100% on-device private speech input.\nChoose your language(s) to get started."
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.allowsMultipleSelection = true
        return tv
    }()

    private let continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Continue"
        config.cornerStyle = .large
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let languages = LanguagePreference.all
    private var selectedLanguages: [LanguagePreference] = [.english, .autoDetect]

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        view.backgroundColor = .systemBackground
        setupLayout()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LangCell")
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        // Pre-select defaults
        for (i, lang) in languages.enumerated() {
            if selectedLanguages.contains(lang) {
                tableView.selectRow(at: IndexPath(row: i, section: 0), animated: false, scrollPosition: .none)
            }
        }
    }

    // MARK: — Layout

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(tableView)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -16),

            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    // MARK: — Actions

    @objc private func continueTapped() {
        let selections = tableView.indexPathsForSelectedRows ?? []
        let chosen = selections.map { languages[$0.row] }
        let prefs = chosen.isEmpty ? [LanguagePreference.english] : chosen

        LanguagePreference.savePreferences(prefs)
        AppGroup.defaults.set(true, forKey: AppGroupKey.onboardingCompleted)

        // Navigate to recording screen
        let recordingVC = RecordingViewController()
        navigationController?.setViewControllers([recordingVC], animated: true)
    }
}

// MARK: — UITableViewDataSource / Delegate

extension OnboardingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        languages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LangCell", for: indexPath)
        let lang = languages[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = "\(lang.flag)  \(lang.displayName)"
        content.textProperties.font = .systemFont(ofSize: 17)
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Languages"
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Select one or more languages. You can change this later in Settings."
    }
}
