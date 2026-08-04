//
//  XunleiFileSelectionViewController.swift
//  Remote Helper
//

import UIKit
import SwiftEntryKit

final class XunleiFileSelectionViewController: UITableViewController {
    private let resource: XunleiResource
    private let magnet: String
    private let downloader: XunleiDownloader
    private var selectedRows: Set<Int>
    private let completion: (Swift.Result<Void, XunleiDownloaderError>) -> Void

    private static let videoExtensions: Set<String> = [
        "mp4", "mkv", "avi", "mov", "m4v", "wmv", "ts", "m2ts", "webm", "flv", "rm", "rmvb"
    ]

    init(resource: XunleiResource,
         magnet: String,
         downloader: XunleiDownloader,
         completion: @escaping (Swift.Result<Void, XunleiDownloaderError>) -> Void) {
        self.resource = resource
        self.magnet = magnet
        self.downloader = downloader
        self.completion = completion
        self.selectedRows = Self.defaultSelection(for: resource.files)
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Xunlei NAS", comment: "Download service name")
        navigationItem.prompt = NSLocalizedString("Only the largest video file is selected by default. You can change the selection.", comment: "Xunlei file selection instructions")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: NSLocalizedString("Select All", comment: "Select all files"), style: .plain, target: self, action: #selector(selectAllTapped)),
            UIBarButtonItem(title: NSLocalizedString("Download", comment: "Start download"), style: .done, target: self, action: #selector(downloadTapped))
        ]
        tableView.allowsSelection = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resource.files.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "XunleiFileCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        let file = resource.files[indexPath.row]
        cell.textLabel?.text = file.name
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.text = CLongLong(file.size).fileSizeString
        cell.accessoryType = selectedRows.contains(indexPath.row) ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedRows.contains(indexPath.row) {
            selectedRows.remove(indexPath.row)
        } else {
            selectedRows.insert(indexPath.row)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
        updatePrompt()
    }

    @objc private func cancelTapped() {
        navigationController?.dismiss(animated: true)
    }

    @objc private func selectAllTapped() {
        selectedRows = Set(resource.files.indices)
        tableView.reloadData()
        updatePrompt()
    }

    @objc private func downloadTapped() {
        let selectedFiles = resource.files.enumerated()
            .filter { selectedRows.contains($0.offset) }
            .map { $0.element }
        guard !selectedFiles.isEmpty else {
            Helper.shared.showNote(withMessage: NSLocalizedString("Select at least one file.", comment: "No Xunlei files selected"), type: .warning)
            return
        }

        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Creating the Xunlei task...", comment: "Xunlei progress"))
        downloader.addTask(for: magnet, resource: resource, selectedFiles: selectedFiles) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                SwiftEntryKit.dismiss()
                self.navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
                switch result {
                case .success:
                    if let navigationController = self.navigationController {
                        navigationController.dismiss(animated: true) {
                            self.completion(result)
                        }
                    } else {
                        self.completion(result)
                    }
                case .failure:
                    self.completion(result)
                }
            }
        }
    }

    private func updatePrompt() {
        navigationItem.prompt = String(format: NSLocalizedString("Selected %ld of %ld files", comment: "Xunlei file selection count"), selectedRows.count, resource.files.count)
    }

    private static func defaultSelection(for files: [XunleiTaskFile]) -> Set<Int> {
        guard !files.isEmpty else { return [] }

        let videoFiles = files.enumerated().filter { item in
            let name = item.element.name
            let ext = URL(fileURLWithPath: name).pathExtension.lowercased()
            return videoExtensions.contains(ext)
        }
        if let largestVideo = videoFiles.max(by: { $0.element.size < $1.element.size }) {
            return [largestVideo.offset]
        }
        if let largestFile = files.enumerated().max(by: { $0.element.size < $1.element.size }) {
            return [largestFile.offset]
        }
        return [0]
    }
}
