//
//  WebContentTableViewController.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/4.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import PasscodeLock
import InAppSettingsKit
import CoreData
import Kingfisher
import UniformTypeIdentifiers

class WebContentTableViewController: UITableViewController, IASKSettingsDelegate, UIPopoverPresentationControllerDelegate {
    fileprivate let CellIdentifier = "WebContentTableViewCell"

    var webViewController:WebViewController!
    var settingsViewController: IASKAppSettingsViewController!
    var addresses: [ResourceSite] = [] {
        didSet {
            addresses.enumerated().forEach({ (args) in
                let (index, site) = args
                site.displayOrder = Int64(index)
            })
            PersistenceController.shared.saveContext()
        }
    }

    var previewingIndexPath: IndexPath?
    var collapseDetailViewController: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        readAddresses()
        migrateOldStorageIfNecessary()

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: ServerSetupDone) {
            self.showSettings()
        }

        tableView.dropDelegate = self
        tableView.dragDelegate = self

        // Revert back to old UITableView behavior
        tableView.cellLayoutMarginsFollowReadableWidth = false
        title = NSLocalizedString("Addresses", comment: "Addresses")
        
        if let leftItem = navigationItem.leftBarButtonItem {
            leftItem.target = nil
            leftItem.action = nil
            let transmissionAction = UIAction(title: NSLocalizedString("Transmission", comment: "Transmission"), image: UIImage(systemName: "arrow.down.circle")) { [weak self] _ in
                self?.showTransmission()
            }
            let searchKittenAction = UIAction(title: NSLocalizedString("Kitten Search", comment: "Kitten Search"), image: UIImage(systemName: "magnifyingglass")) { [weak self] _ in
                self?.torrentSearch()
            }
            let downloadFromPasteboardAction = UIAction(title: NSLocalizedString("Download from Pasteboard", comment: "Download from Pasteboard"), image: UIImage(systemName: "doc.on.clipboard")) { [weak self] _ in
                self?.downloadMagnetFromPasteboard()
            }
            let settingsAction = UIAction(title: NSLocalizedString("Settings", comment: "Settings"), image: UIImage(systemName: "gearshape")) { [weak self] _ in
                self?.showSettings()
            }
            leftItem.menu = UIMenu(title: "", children: [transmissionAction, searchKittenAction, downloadFromPasteboardAction, settingsAction])
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }

    func migrateOldStorageIfNecessary() {
        let defaults = UserDefaults.standard
        let key = "VPAddresses"
        guard let links = defaults.array(forKey: key) as? [String] else { return }
        links.forEach {
            guard let _ = URL(string: $0) else { return }
            let site = NSEntityDescription.insertNewObject(forEntityName: "ResourceSite", into: PersistenceController.shared.viewContext) as! ResourceSite
            site.link = $0
            self.addresses.append(site)
        }
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }

    func readAddresses() {
        let context = PersistenceController.shared.viewContext
        let fetchRequest = NSFetchRequest<ResourceSite>(entityName: "ResourceSite")
        let displayOrderDescriptor = NSSortDescriptor(key: "displayOrder", ascending: true)
        fetchRequest.sortDescriptors = [displayOrderDescriptor]
        if let addresses = try? context.fetch(fetchRequest) as [ResourceSite] {
            self.addresses = addresses
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.addresses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        let address = self.addresses[indexPath.row]
        
        cell.configurationUpdateHandler = { cell, state in
            var content = cell.defaultContentConfiguration()
            content.text = address.link
            #if targetEnvironment(macCatalyst)
            content.textProperties.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            #else
            content.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
            #endif
            
            if state.isSelected || state.isHighlighted {
                content.textProperties.color = .white
            } else {
                content.textProperties.color = .label
            }
            cell.contentConfiguration = content
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        #if targetEnvironment(macCatalyst)
        return 50.0
        #else
        return UITableView.automaticDimension
        #endif
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteCell(at: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath:IndexPath) -> Bool {
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAddressSegue" {
            if let nav = segue.destination as? UINavigationController,
                let webViewController = nav.topViewController as? WebViewController,
                let index = tableView.indexPathForSelectedRow?.row,
                let urlString = addresses[index].link {
                collapseDetailViewController = false
                webViewController.urlString = urlString
                self.webViewController = webViewController
            }
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        addresses.insert(addresses.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
    }

    //MARK: - UIPopoverPresentationControllerDelegate
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.barButtonItem = navigationItem.leftBarButtonItem
    }

    //MARK: - InAppSettingsKit Delegates
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController) {
        navigationController?.dismiss(animated: true) {
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: ServerSetupDone)
            sender.synchronizeSettings()
        }
    }

    func settingsViewController(_ sender: IASKAppSettingsViewController, buttonTappedFor specifier: IASKSpecifier) {
        if specifier.key == PasscodeLockConfig {
            let repository = UserDefaultsPasscodeRepository()
            let configuration = PasscodeLockConfiguration(repository: repository)
            if !repository.hasPasscode {
                let passcodeVC = PasscodeLockViewController(state: .setPasscode, configuration: configuration)
                passcodeVC.successCallback = { lock in
                    let status = NSLocalizedString("On", comment: "打开")
                    Configuration.shared.save(status, forKey: PasscodeLockStatus)
                }
                passcodeVC.dismissCompletionCallback = {
                    sender.tableView.reloadData()
                }
                passcodeVC.mainColor = Helper.shared.mainThemeColor()
                sender.navigationController?.pushViewController(passcodeVC, animated: true)
            }
            else {
                let alert = UIAlertController(title: NSLocalizedString("Disable passcode", comment: "Disable passcode lock alert title"), message: NSLocalizedString("You are going to disable passcode lock. Continue?", comment: "Disable passcode lock alert body"), preferredStyle: .alert)
                let confirmAction = UIAlertAction(title: NSLocalizedString("Continue", comment: "继续"), style: .default, handler: { _ in
                    let passcodeVC = PasscodeLockViewController(state: .removePasscode, configuration: configuration)
                    passcodeVC.successCallback = { lock in
                        lock.repository.deletePasscode()
                        let status = NSLocalizedString("Off", comment: "关闭")
                        Configuration.shared.save(status, forKey: PasscodeLockStatus)
                    }
                    passcodeVC.dismissCompletionCallback = {
                        sender.tableView.reloadData()
                    }
                    passcodeVC.mainColor = Helper.shared.mainThemeColor()
                    sender.navigationController?.pushViewController(passcodeVC, animated: true)
                })
                alert.addAction(confirmAction)
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "取消"), style: .cancel, handler: nil)
                alert.addAction(cancelAction)
                sender.present(alert, animated: true, completion: nil)
            }
        }
        else if specifier.key == ClearCacheNowKey {
            Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Loading...", comment: "Loading..."))
            ImageCache.default.clearDiskCache() {
                DispatchQueue.global(qos: .userInitiated).async {
                    let localFileSize = Helper.shared.fileSizeString(withInteger: Helper.shared.localFileSize())

                    ImageCache.default.calculateDiskStorageSize { result in
                        let cacheSizeInBytes = Int((try? result.get()) ?? 0)
                        let cacheSize = Helper.shared.fileSizeString(withInteger: cacheSizeInBytes)

                        DispatchQueue.main.async {
                            UserDefaults.standard.set(cacheSize, forKey: ImageCacheSizeKey)
                            UserDefaults.standard.set(localFileSize, forKey: LocalFileSize)
                            UserDefaults.standard.synchronize()
                            sender.synchronizeSettings()
                            Helper.shared.showNote(withMessage: NSLocalizedString("Cache Cleared!", comment: "Cache Cleared!"))
                            sender.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView!, cellFor specifier: IASKSpecifier!) -> UITableViewCell! {
        return nil
    }

    //MARK: - Action
    @IBAction func addAddress(_ sender: Any?) {
        #if targetEnvironment(macCatalyst)
        Helper.shared.showMacAlert(title: NSLocalizedString("Add address", comment: "Add address"), message: NSLocalizedString("Please input an address:", comment: "Please input an address:"), hasTextField: true, textFieldDefault: "http://", placeholder: "http://", okTitle: NSLocalizedString("Save", comment:"Save"), cancelTitle: NSLocalizedString("Cancel", comment: "Cancel")) { [weak self] (success, text) in
            guard let `self` = self, success, let address = text, let _ = URL(string: address) else { return }
            let site = NSEntityDescription.insertNewObject(forEntityName: "ResourceSite", into: PersistenceController.shared.viewContext) as! ResourceSite
            site.link = address
            self.addresses.append(site)
            let indexPath = IndexPath(row: self.addresses.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
        #else
        let alertController = UIAlertController(title: NSLocalizedString("Add address", comment: "Add address"), message: NSLocalizedString("Please input an address:", comment: "Please input an address:"), preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.keyboardType = .URL
            textField.clearButtonMode = .whileEditing
            textField.text = "http://"
        }
        let saveAction = UIAlertAction(title: NSLocalizedString("Save", comment:"Save"), style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            let address = alertController.textFields![0].text!
            guard let _ = URL(string: address) else { return }
            let site = NSEntityDescription.insertNewObject(forEntityName: "ResourceSite", into: PersistenceController.shared.viewContext) as! ResourceSite
            site.link = address
            self.addresses.append(site)
            let indexPath = IndexPath(row: self.addresses.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
        alertController.addAction(saveAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        #endif
    }

    @IBAction func showActionSheet(_ sender: Any?) {
        #if targetEnvironment(macCatalyst)
        let options = [
            NSLocalizedString("Transmission", comment: "Transmission"),
            NSLocalizedString("Kitten Search", comment: "Kitten Search"),
            NSLocalizedString("Download from Pasteboard", comment: "Download from Pasteboard"),
            NSLocalizedString("Settings", comment: "Settings"),
            NSLocalizedString("Cancel", comment: "Cancel")
        ]
        Helper.shared.showMacActionSheet(title: NSLocalizedString("Please select your operation", comment: "Please select your operation"), message: nil, options: options) { [weak self] index in
            guard let `self` = self else { return }
            switch index {
            case 0:
                self.showTransmission()
            case 1:
                self.torrentSearch()
            case 2:
                self.downloadMagnetFromPasteboard()
            case 3:
                self.showSettings()
            default:
                break
            }
        }
        #else
        let sheet = UIAlertController(title: NSLocalizedString("Please select your operation", comment: "Please select your operation"), message: nil, preferredStyle: .actionSheet)
        let transmissionAction = UIAlertAction(title: NSLocalizedString("Transmission", comment: "Transmission"), style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            self.showTransmission()
        }
        sheet.addAction(transmissionAction)
        let searchKittenAction = UIAlertAction(title: NSLocalizedString("Kitten Search", comment: "Kitten Search"), style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            self.torrentSearch()
        }
        sheet.addAction(searchKittenAction)
        let downloadFromPasteboardAction = UIAlertAction(title: NSLocalizedString("Download from Pasteboard", comment: "Download from Pasteboard"), style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            self.downloadMagnetFromPasteboard()
        }
        sheet.addAction(downloadFromPasteboardAction)
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            self.showSettings()
        }
        sheet.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        sheet.addAction(cancelAction)
        if let popover = sheet.popoverPresentationController {
            popover.delegate = self
            if let item = sender as? UIPopoverPresentationControllerSourceItem {
                popover.sourceItem = item
            } else {
                popover.barButtonItem = navigationItem.leftBarButtonItem
            }
        }
        present(sheet, animated: true) {
            sheet.popoverPresentationController?.passthroughViews = nil
        }
        #endif
    }

    @objc func showSettings() {
        let passcodeRepo = UserDefaultsPasscodeRepository()
        let status = passcodeRepo.hasPasscode ? NSLocalizedString("On", comment: "打开") : NSLocalizedString("Off", comment: "关闭")

        ImageCache.default.calculateDiskStorageSize { [weak self] result in
            let cacheSizeInBytes = Int((try? result.get()) ?? 0)

            DispatchQueue.global(qos: .userInitiated).async {
                let localFileSizeInBytes = Helper.shared.localFileSize()
                let deviceFreeSpaceInBytes = Helper.shared.freeDiskSpace()

                let cacheSize = Helper.shared.fileSizeString(withInteger: cacheSizeInBytes)
                let localFileSize = Helper.shared.fileSizeString(withInteger: localFileSizeInBytes)
                let deviceFreeSpace = Helper.shared.fileSizeString(withInteger: deviceFreeSpaceInBytes)
                let appVersion = Helper.shared.appVersionString()

                DispatchQueue.main.async {
                    guard let self = self else { return }
                    UserDefaults.standard.set(cacheSize, forKey: ImageCacheSizeKey)
                    UserDefaults.standard.set(status, forKey: PasscodeLockStatus)
                    UserDefaults.standard.set(localFileSize, forKey: LocalFileSize)
                    UserDefaults.standard.set(deviceFreeSpace, forKey: DeviceFreeSpace)
                    UserDefaults.standard.set(appVersion, forKey: CurrentVersionKey)
                    UserDefaults.standard.synchronize()

                    #if targetEnvironment(macCatalyst)
                    let macSettingsVC = MacSettingsViewController()
                    let settingsNavigationController = UINavigationController(rootViewController: macSettingsVC)
                    settingsNavigationController.modalPresentationStyle = .formSheet
                    self.present(settingsNavigationController, animated: true, completion: nil)
                    #else
                    self.settingsViewController = IASKAppSettingsViewController(style: .grouped)
                    self.settingsViewController.delegate = self
                    self.settingsViewController.showCreditsFooter = false
                    self.settingsViewController.showDoneButton = true
                    let settingsNavigationController = UINavigationController(rootViewController: self.settingsViewController)
                    if self.view.traitCollection.horizontalSizeClass == .regular {
                        settingsNavigationController.modalPresentationStyle = .pageSheet
                    }
                    self.present(settingsNavigationController, animated: true, completion: nil)
                    #endif
                }
            }
        }
    }

    func showTransmission() {
        if Helper.shared.showCellularHUD() { return }
        let link = Configuration.shared.transmissionServerAddress()
        let transmissionWebViewController = TransmissionWebViewController(urlString: link)
        transmissionWebViewController.urlRequest?.cachePolicy = .reloadIgnoringLocalCacheData
        transmissionWebViewController.title = "Transmission"
        let transmissionNavigationController = UINavigationController(rootViewController: transmissionWebViewController)
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.present(transmissionNavigationController, animated:true, completion: nil)
        }
    }

    public func addMagnet() {
        #if targetEnvironment(macCatalyst)
        let defaultText = UIPasteboard.general.hasStrings ? UIPasteboard.general.string : nil
        Helper.shared.showMacAlert(title: NSLocalizedString("Download magnet", comment: "Download magnet"), message: NSLocalizedString("Please paste in a magnet address:", comment: "Please paste in a magnet address:"), hasTextField: true, textFieldDefault: defaultText, placeholder: nil, okTitle: NSLocalizedString("Download", comment:"Download"), cancelTitle: NSLocalizedString("Cancel", comment: "Cancel")) { (success, text) in
            guard success, let address = text else { return }
            UIPasteboard.general.string = nil // Clear pasteboard
            Helper.shared.transmissionDownload(for: address)
        }
        #else
        let alert = UIAlertController(title: NSLocalizedString("Download magnet", comment: "Download magnet"), message: NSLocalizedString("Please paste in a magnet address:", comment: "Please paste in a magnet address:"), preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.keyboardType = .URL
            textField.clearButtonMode = .whileEditing
            if UIPasteboard.general.hasStrings {
                textField.text = UIPasteboard.general.string
            }
        }
        let saveAction = UIAlertAction(title: NSLocalizedString("Download", comment:"Download"), style: .default) { _ in
            let address = alert.textFields![0].text!
            UIPasteboard.general.string = nil // Clear pasteboard
            Helper.shared.transmissionDownload(for: address)
        }
        alert.addAction(saveAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        #endif
    }

    @objc func downloadMagnetFromPasteboard() {
        if #available(iOS 16.0, *) {
            let listVC = PasteboardListViewController()
            let navVC = UINavigationController(rootViewController: listVC)
            present(navVC, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Download magnet", comment: "Download magnet"), message: NSLocalizedString("Please paste in a magnet address:", comment: "Please paste in a magnet address:"), preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.keyboardType = .URL
                textField.clearButtonMode = .whileEditing
                if UIPasteboard.general.hasStrings {
                    textField.text = UIPasteboard.general.string
                }
            }
            let saveAction = UIAlertAction(title: NSLocalizedString("Download", comment:"Download"), style: .default) { _ in
                let address = alert.textFields![0].text!
                UIPasteboard.general.string = nil // Clear pasteboard
                Helper.shared.transmissionDownload(for: address)
            }
            alert.addAction(saveAction)
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
    }



    //MARK: - Helper
    func deleteCell(at indexPath: IndexPath) {
        let site = addresses[indexPath.row]
        PersistenceController.shared.viewContext.delete(site)
        addresses.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }

    func torrentSearch() {
        Helper.shared.showTorrentSearchAlertInViewController(navigationController!)
    }

    func deletePreviewingCell() {
        if let previewingIndexPath = previewingIndexPath {
            deleteCell(at: previewingIndexPath)
        }
    }

    private func makeWebPreviewController(for indexPath: IndexPath, peeking: Bool) -> WebViewController? {
        guard addresses.indices.contains(indexPath.row),
              let urlString = addresses[indexPath.row].link,
              let webViewController = storyboard?.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController else {
            return nil
        }
        webViewController.urlString = urlString
        webViewController.isPeeking = peeking
        self.webViewController = webViewController
        return webViewController
    }
}

extension WebContentTableViewController : UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        if coordinator.session.localDragSession != nil { return } // Skip drop-in to prevent copy existing value.
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: addresses.count, section: 0)
        coordinator.session.loadObjects(ofClass: NSString.self) { [weak self] (items) in
            guard let `self` = self, let items = items as? [String] else { return }
            let indexPathes = (0..<items.count).map { IndexPath(row: destinationIndexPath.row + $0, section: destinationIndexPath.section) }

            items.filter { str in
                if let _ = URL(string: str) {
                    return true
                }
                else {
                    return false
                }
            }
            .enumerated()
            .forEach({ (args) in
                let (index, link) = args
                let site = NSEntityDescription.insertNewObject(forEntityName: "ResourceSite", into: PersistenceController.shared.viewContext) as! ResourceSite
                site.link = link
                self.addresses.insert(site, at: destinationIndexPath.row + index)
            })

            self.tableView.insertRows(at: indexPathes, with: .bottom)
        }
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if session.localDragSession != nil {
            return UITableViewDropProposal(operation: .move, intent: .automatic)
        }
        else {
            return UITableViewDropProposal(operation: .copy, intent: .automatic)
        }
    }
}

extension WebContentTableViewController : UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let urlString = addresses[indexPath.row].link else { return [] }
        let itemProvider = NSItemProvider(object: urlString as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard let urlString = addresses[indexPath.row].link else { return [] }
        let itemProvider = NSItemProvider(object: urlString as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
}

extension WebContentTableViewController {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard addresses.indices.contains(indexPath.row), addresses[indexPath.row].link != nil else { return nil }
        previewingIndexPath = indexPath

        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { [weak self] in
            self?.makeWebPreviewController(for: indexPath, peeking: true)
        }, actionProvider: { [weak self] _ in
            let deleteAction = UIAction(
                title: NSLocalizedString("Delete", comment: "Delete"),
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self?.deleteCell(at: indexPath)
            }
            return UIMenu(title: "", children: [deleteAction])
        })
    }

    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let indexPath = configuration.identifier as? NSIndexPath else { return }
        animator.addCompletion { [weak self] in
            guard let self,
                  let webViewController = self.makeWebPreviewController(for: indexPath as IndexPath, peeking: false) else { return }
            self.navigationController?.pushViewController(webViewController, animated: false)
        }
    }
}

@available(iOS 16.0, *)
class PasteboardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var magnets: [String] = []
    var magnetNames: [String] = []
    var sourceSHA256: String = ""
    
    let tableView = UITableView()
    var pasteControl: UIPasteControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = NSLocalizedString("Download from Pasteboard", comment: "Download from Pasteboard")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: "Close"), style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Download", comment: "Download"), style: .done, target: self, action: #selector(downloadTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        // Paste Control
        let pasteControl = UIPasteControl(configuration: .init())
        pasteControl.target = self
        pasteControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pasteControl)
        self.pasteControl = pasteControl
        
        // Table View
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            pasteControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pasteControl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            pasteControl.heightAnchor.constraint(equalToConstant: 40),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        self.pasteConfiguration = UIPasteConfiguration(acceptableTypeIdentifiers: [UTType.text.identifier])
    }
    
    @objc func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc func downloadTapped() {
        guard !magnets.isEmpty else { return }
        
        if Helper.shared.canStartMiDownload {
            let alert = UIAlertController(title: NSLocalizedString("Please select your operation", comment: ""), message: nil, preferredStyle: .actionSheet)
            let miAction = UIAlertAction(title: NSLocalizedString("Mi", comment: "Mi"), style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                UserDefaults.standard.set(self.sourceSHA256, forKey: LastCopiedMagnetsSHA256Key)
                Helper.shared.miDownloadForLinks(self.magnets, fallbackIn: self)
                self.dismiss(animated: true)
            })
            alert.addAction(miAction)
            
            let transmissionAction = UIAlertAction(title: "Transmission", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                UserDefaults.standard.set(self.sourceSHA256, forKey: LastCopiedMagnetsSHA256Key)
                Helper.shared.transmissionDownload(forLinks: self.magnets)
                self.dismiss(animated: true)
            })
            alert.addAction(transmissionAction)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            
            alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            present(alert, animated: true)
        } else {
            UserDefaults.standard.set(sourceSHA256, forKey: LastCopiedMagnetsSHA256Key)
            Helper.shared.transmissionDownload(forLinks: magnets)
            dismiss(animated: true)
        }
    }
    
    override func paste(itemProviders: [NSItemProvider]) {
        for provider in itemProviders {
            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                _ = provider.loadObject(ofClass: String.self) { [weak self] str, error in
                    guard let self = self, let pasteString = str else { return }
                    DispatchQueue.main.async {
                        self.processMagnetString(pasteString)
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier("public.text") {
                _ = provider.loadObject(ofClass: String.self) { [weak self] str, error in
                    guard let self = self, let pasteString = str else { return }
                    DispatchQueue.main.async {
                        self.processMagnetString(pasteString)
                    }
                }
            }
        }
    }
    
    private func processMagnetString(_ pasteString: String) {
        let lines = pasteString.components(separatedBy: .newlines)
        let parsedMagnets = lines.filter { $0.hasPrefix("magnet:?") }.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        guard !parsedMagnets.isEmpty else {
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("No magnet links found in pasteboard.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            present(alert, animated: true)
            return
        }
        
        self.sourceSHA256 = pasteString.sha256
        
        struct MagnetInfo {
            var magnet: String
            var infoHash: String
            var name: String
            var hasDn: Bool
        }
        
        var magnetInfos: [MagnetInfo] = []
        for magnet in parsedMagnets {
            let infoHash = Helper.shared.infoHash(fromMagnet: magnet)
            let decoded = magnet.humanReadableFileName()
            let hasDn = (decoded != magnet.decodedLink)
            let name = hasDn ? decoded : infoHash
            
            if let index = magnetInfos.firstIndex(where: { $0.infoHash == infoHash }) {
                if !magnetInfos[index].hasDn && hasDn {
                    magnetInfos[index].magnet = magnet
                    magnetInfos[index].name = name
                    magnetInfos[index].hasDn = true
                }
            } else {
                magnetInfos.append(MagnetInfo(magnet: magnet, infoHash: infoHash, name: name, hasDn: hasDn))
            }
        }
        
        self.magnets = magnetInfos.map { $0.magnet }
        self.magnetNames = magnetInfos.map { $0.name }
        
        // Update UI
        navigationItem.rightBarButtonItem?.isEnabled = true
        pasteControl?.isHidden = true
        tableView.isHidden = false
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return magnetNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = magnetNames[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}

