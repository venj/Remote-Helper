//
//  WebContentTableViewController.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/4.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import SDWebImage
import PasscodeLock
import TOWebViewController
import MWPhotoBrowser
import InAppSettingsKit
import CoreData
import Fuzi

class WebContentTableViewController: UITableViewController, IASKSettingsDelegate, UIPopoverPresentationControllerDelegate {
    fileprivate let CellIdentifier = "WebContentTableViewCell"

    var webViewController:WebViewController!
    var settingsViewController: IASKAppSettingsViewController!
    var mwPhotos: [MWPhoto]!
    var addresses: [ResourceSite] = [] {
        didSet {
            addresses.enumerated().forEach({ (args) in
                let (index, site) = args
                site.displayOrder = Int64(index)
            })
            AppDelegate.shared.saveContext()
        }
    }

    var previewingIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Addresses", comment: "Addresses")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAddress))
        readAddresses()
        migrateOldStorageIfNecessary()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("More", comment: "More"), style: .plain, target: self, action: #selector(showActionSheet))

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: ServerSetupDone) {
            self.showSettings()
        }

        if #available(iOS 11.0, *) {
            tableView.dropDelegate = self
            tableView.dragDelegate = self
        }

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        // Peek
        if #available(iOS 9.0, *), traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }

        // Update Kittent Black list.
        updateKittenBlackList()
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
            let site = NSEntityDescription.insertNewObject(forEntityName: "ResourceSite", into: AppDelegate.shared.managedObjectContext) as! ResourceSite
            site.link = $0
            self.addresses.append(site)
        }
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }

    func readAddresses() {
        let context = AppDelegate.shared.managedObjectContext
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
        cell.textLabel?.text = address.link
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteCell(at: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath:IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if Helper.shared.showCellularHUD() { return }
        webViewController = createWebViewController(forIndexPath: indexPath)
        navigationController?.pushViewController(webViewController, animated: true)
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        addresses.insert(addresses.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
    }

    //MARK: - UIPopoverPresentationControllerDelegate
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.barButtonItem = navigationItem.leftBarButtonItem
    }

    //MARK: - InAppSettingsKit Delegates
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        navigationController?.dismiss(animated: true) {
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: ServerSetupDone)
            sender.synchronizeSettings()
            AppDelegate.shared.configureTabbarController()
        }
    }

    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        if specifier.key() == PasscodeLockConfig {
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
                    sender.navigationController?.pushViewController(passcodeVC, animated: true)
                })
                alert.addAction(confirmAction)
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "取消"), style: .cancel, handler: nil)
                alert.addAction(cancelAction)
                alert.view.tintColor = Helper.shared.mainThemeColor()
                sender.present(alert, animated: true, completion: nil)
            }
        }
        else if specifier.key() == ClearCacheNowKey {
            Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Loading...", comment: "Loading..."))
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                SDImageCache.shared().clearDisk()
                let defaults = UserDefaults.standard
                let localFileSize = Helper.shared.fileSizeString(withInteger: Helper.shared.localFileSize())
                defaults.set(localFileSize, forKey: LocalFileSize)
                defaults.synchronize()
                sender.synchronizeSettings()
                DispatchQueue.main.async {
                    Helper.shared.showNote(withMessage: NSLocalizedString("Cache Cleared!", comment: "Cache Cleared!"))
                    sender.tableView.reloadData()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView!, cellFor specifier: IASKSpecifier!) -> UITableViewCell! {
        return nil
    }

    //MARK: - Action
    @objc func fetchHTMLAndParse() {
        guard let html = webViewController.webView.stringByEvaluatingJavaScript(from: "document.body.innerHTML") else { return }
        processHTML(html)
    }

    @objc func addAddress() {
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
            let site = NSEntityDescription.insertNewObject(forEntityName: "ResourceSite", into: AppDelegate.shared.managedObjectContext) as! ResourceSite
            site.link = address
            self.addresses.append(site)
            let indexPath = IndexPath(row: self.addresses.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
        alertController.addAction(saveAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.view.tintColor = Helper.shared.mainThemeColor()
        present(alertController, animated: true, completion: nil)
    }

    @objc func showActionSheet() {
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
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            self.showSettings()
        }
        sheet.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        sheet.addAction(cancelAction)
        sheet.popoverPresentationController?.delegate = self
        sheet.view.tintColor = Helper.shared.mainThemeColor()
        present(sheet, animated: true) {
            sheet.popoverPresentationController?.passthroughViews = nil
        }
    }

    func showSettings() {
        let defaults = UserDefaults.standard
        let cacheSizeInBytes = SDImageCache.shared().getSize()
        let cacheSize = Helper.shared.fileSizeString(withInteger: Int(cacheSizeInBytes)) // Maybe problematic on 32-bit system
        defaults.set(cacheSize, forKey: ImageCacheSizeKey)
        let passcodeRepo = UserDefaultsPasscodeRepository()
        let status = passcodeRepo.hasPasscode ? NSLocalizedString("On", comment: "打开") : NSLocalizedString("Off", comment: "关闭")
        defaults.set(status, forKey: PasscodeLockStatus)
        let localFileSize = Helper.shared.fileSizeString(withInteger: Helper.shared.localFileSize())
        defaults.set(localFileSize, forKey: LocalFileSize)
        let deviceFreeSpace = Helper.shared.fileSizeString(withInteger: Helper.shared.freeDiskSpace())
        defaults.set(deviceFreeSpace, forKey: DeviceFreeSpace)
        defaults.set(Helper.shared.appVersionString(), forKey: CurrentVersionKey)
        defaults.synchronize()

        settingsViewController = IASKAppSettingsViewController(style: .grouped)
        settingsViewController.delegate = self
        settingsViewController.showCreditsFooter = false
        if #available(iOS 9.0, *) {
            UIView.appearance(whenContainedInInstancesOf: [IASKAppSettingsViewController.self]).tintColor = Helper.shared.mainThemeColor()
            UISwitch.appearance(whenContainedInInstancesOf: [IASKAppSettingsViewController.self]).onTintColor = Helper.shared.mainThemeColor()
        } else {
            //TODO: How to handle deprecated iOS 8 themeing? 
        }
        let settingsNavigationController = UINavigationController(rootViewController: settingsViewController)
        // Theme
        settingsNavigationController.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        settingsNavigationController.navigationBar.tintColor = UIColor.white
        settingsNavigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        if UIDevice.current.userInterfaceIdiom == .pad {
            settingsNavigationController.modalPresentationStyle = .formSheet
        }
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.present(settingsNavigationController, animated: true, completion: nil)
        }
    }

    func showTransmission() {
        if Helper.shared.showCellularHUD() { return }
        let link = Configuration.shared.transmissionServerAddress()
        let transmissionWebViewController = TOWebViewController(urlString: link)
        transmissionWebViewController?.urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        transmissionWebViewController?.title = "Transmission"
        transmissionWebViewController?.showUrlWhileLoading = false
        transmissionWebViewController?.loadingBarTintColor = Helper.shared.mainThemeColor()
        if UIDevice.current.userInterfaceIdiom == .phone {
            transmissionWebViewController?.buttonTintColor = Helper.shared.mainThemeColor()
        }
        else {
            transmissionWebViewController?.buttonTintColor = UIColor.white
        }
        let transmissionNavigationController = UINavigationController(rootViewController: transmissionWebViewController!)
        transmissionNavigationController.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        transmissionNavigationController.navigationBar.tintColor = UIColor.white
        transmissionNavigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.present(transmissionNavigationController, animated:true, completion: nil)
        }
    }

    //MARK: - Helper
    func deleteCell(at indexPath: IndexPath) {
        let site = addresses[indexPath.row]
        AppDelegate.shared.managedObjectContext.delete(site)
        addresses.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }

    func torrentSearch() {
        Helper.shared.showTorrentSearchAlertInViewController(navigationController!)
    }

    func processHTML(_ html: String) {
        var validAddresses: [Link] = []
        do {
            let doc = try HTMLDocument(string: html)
            let links: [Link] = doc.css("a").compactMap { e in
                guard let href = e.attr("href") else { return nil }
                let loweredLink = href.lowercased()
                if loweredLink.hasPrefix("magnet:?")
                    || loweredLink.hasPrefix("ed2k://")
                    || loweredLink.hasPrefix("thunder://")
                    || loweredLink.hasPrefix("ftp://")
                    || loweredLink.hasPrefix("ftps://")
                    || loweredLink.hasPrefix("qqdl://")
                    || loweredLink.hasPrefix("flashget://") {
                    return Link(href)
                }
                else {
                    return nil
                }
            }

            validAddresses = links

            if validAddresses.count == 0 {
                Helper.shared.showNote(withMessage: NSLocalizedString("No downloadable link.", comment: "No downloadable link."), type:.warning)
            }
            else {
                let linksViewController = BangumiViewController()
                let bangumi = Bangumi(title: String(format: NSLocalizedString("Found %ld links", comment: "Found %ld links"), validAddresses.count), links: validAddresses)
                linksViewController.bangumi = bangumi
                navigationController?.pushViewController(linksViewController, animated: true)
            }
        } catch let error as NSError {
            print("HTML Parse Error: \(error), \(error.userInfo)")
        }
    }

    // Update kitten ads black list.
    func updateKittenBlackList() {
        DispatchQueue.global(qos: .background).after(2.0) {
            guard let content = try? String(contentsOf: URL(string: "http" + "s://ww" + "w.ve" + "nj.m" + "e/kit" + "ten_bla" + "ckli" + "st.txt")!) else { return }
            let blackList = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            Helper.shared.kittenBlackList = blackList
        }
    }

    func createWebViewController(forIndexPath indexPath: IndexPath) -> WebViewController? {
        let urlString = addresses[indexPath.row].link
        let webViewController = WebViewController(urlString: urlString)
        webViewController?.showUrlWhileLoading = false
        webViewController?.hidesBottomBarWhenPushed = true
        webViewController?.urlRequest.cachePolicy = .returnCacheDataElseLoad
        webViewController?.additionalBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(fetchHTMLAndParse))]
        // Theme
        webViewController?.loadingBarTintColor = Helper.shared.mainThemeColor()
        if UIDevice.current.userInterfaceIdiom == .phone {
            webViewController?.buttonTintColor = Helper.shared.mainThemeColor()
        }
        else {
            webViewController?.buttonTintColor = UIColor.white
        }
        return webViewController
    }

    func deletePreviewingCell() {
        if let previewingIndexPath = previewingIndexPath {
            deleteCell(at: previewingIndexPath)
        }
    }
}

@available(iOS 11.0, *)
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
                let site = NSEntityDescription.insertNewObject(forEntityName: "ResourceSite", into: AppDelegate.shared.managedObjectContext) as! ResourceSite
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

@available(iOS 11.0, *)
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

@available(iOS 9.0, *)
extension WebContentTableViewController : UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        guard let webViewController = createWebViewController(forIndexPath: indexPath) else { return nil }
        webViewController.isPeeking = true
        previewingContext.sourceRect = cell.frame
        previewingIndexPath = indexPath
        self.webViewController = webViewController
        return webViewController
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: false)
        (viewControllerToCommit as? TOWebViewController)?.isPeeking = false
    }
}
