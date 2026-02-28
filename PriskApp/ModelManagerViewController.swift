// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import UIKit

// MARK: — ModelManagerViewController
// Allows users to select and download WhisperKit models.
// Selected model name is stored in App Group for WhisperKitEngine to read.

final class ModelManagerViewController: UITableViewController {

    // MARK: — Model definitions

    private struct ModelOption {
        let name: String
        let displayName: String
        let description: String
    }

    private let models: [ModelOption] = [
        ModelOption(name: "openai_whisper-tiny",
                    displayName: "Tiny (~40 MB)",
                    description: "Fastest, lowest accuracy"),
        ModelOption(name: "openai_whisper-base",
                    displayName: "Base (~75 MB)",
                    description: "Balanced speed and accuracy"),
        ModelOption(name: "openai_whisper-small",
                    displayName: "Small (~240 MB)",
                    description: "Better accuracy, slower"),
    ]

    private var selectedIndex: Int = 0

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Whisper Model"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        loadCurrentSelection()
    }

    // MARK: — Persistence

    private func loadCurrentSelection() {
        let saved = AppGroupConstants.sharedDefaults?.string(forKey: "selectedModelName")
            ?? "openai_whisper-tiny"
        selectedIndex = models.firstIndex { $0.name == saved } ?? 0
    }

    private func saveSelection(_ name: String) {
        AppGroupConstants.sharedDefaults?.set(name, forKey: "selectedModelName")
    }

    // MARK: — UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        models.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let model = models[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = model.displayName
        content.secondaryText = model.description
        cell.contentConfiguration = content
        cell.accessoryType = indexPath.row == selectedIndex ? .checkmark : .none
        return cell
    }

    // MARK: — UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndex = indexPath.row
        saveSelection(models[indexPath.row].name)
        tableView.reloadData()
    }
}
