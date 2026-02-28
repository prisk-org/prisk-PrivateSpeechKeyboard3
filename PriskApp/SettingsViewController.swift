// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import UIKit

// MARK: — SettingsViewController

final class SettingsViewController: UIViewController {

    private enum Section: Int, CaseIterable {
        case engine, languages, about
        var title: String {
            switch self {
            case .engine: return "STT Engine"
            case .languages: return "Languages"
            case .about: return "About"
            }
        }
    }

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private var currentEngine: STTEngineType = .load()
    private var selectedLanguages: [LanguagePreference] = LanguagePreference.loadPreferences()
    private let allLanguages = LanguagePreference.all

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
}

// MARK: — UITableViewDataSource / Delegate

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .engine:    return STTEngineType.allCases.count
        case .languages: return allLanguages.count
        case .about:     return 1
        default:         return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var content = cell.defaultContentConfiguration()

        switch Section(rawValue: indexPath.section) {
        case .engine:
            let engine = STTEngineType.allCases[indexPath.row]
            content.text = engine.displayName
            content.secondaryText = engine.minimumOSDescription
            cell.accessoryType = (engine == currentEngine) ? .checkmark : .none
            cell.isUserInteractionEnabled = engine.isAvailable
            cell.contentView.alpha = engine.isAvailable ? 1.0 : 0.4

        case .languages:
            let lang = allLanguages[indexPath.row]
            content.text = "\(lang.flag)  \(lang.displayName)"
            cell.accessoryType = selectedLanguages.contains(lang) ? .checkmark : .none

        case .about:
            content.text = "Prisk v1.0 — Apache 2.0"
            content.secondaryText = "prisk-org/prisk-PrivateSpeechKeyboard3"
            cell.accessoryType = .none
            cell.isUserInteractionEnabled = false

        default: break
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section) {
        case .engine:
            let engine = STTEngineType.allCases[indexPath.row]
            guard engine.isAvailable else { return }
            currentEngine = engine
            engine.save()
            tableView.reloadSections([Section.engine.rawValue], with: .automatic)

        case .languages:
            let lang = allLanguages[indexPath.row]
            if let idx = selectedLanguages.firstIndex(of: lang) {
                if selectedLanguages.count > 1 { selectedLanguages.remove(at: idx) }
            } else {
                selectedLanguages.append(lang)
            }
            LanguagePreference.savePreferences(selectedLanguages)
            tableView.reloadSections([Section.languages.rawValue], with: .automatic)

        default: break
        }
    }
}
