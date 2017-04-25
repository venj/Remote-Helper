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

class WebContentTableViewController: UITableViewController, IASKSettingsDelegate, UIPopoverPresentationControllerDelegate {
    fileprivate let CellIdentifier = "WebContentTableViewCell"

    var webViewController:TOWebViewController!
    var settingsViewController: IASKAppSettingsViewController!
    var mwPhotos: [MWPhoto]!
    var addresses: [String] = [] {
        didSet {
            saveAddresses()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Addresses", comment: "Addresses")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAddress))
        readAddresses()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("More", comment: "More"), style: .plain, target: self, action: #selector(showActionSheet))

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: ServerSetupDone) {
            self.showSettings()
        }

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.addresses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        let address = self.addresses[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = address
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            addresses.remove(at: (indexPath as NSIndexPath).row)
            saveAddresses()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath:IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if Helper.shared.showCellularHUD() { return }
        let urlString = self.addresses[(indexPath as NSIndexPath).row]
        webViewController = TOWebViewController(urlString: urlString)
        webViewController.showUrlWhileLoading = false
        webViewController.hidesBottomBarWhenPushed = true
        webViewController.urlRequest.cachePolicy = .returnCacheDataElseLoad
        webViewController.additionalBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(fetchHTMLAndParse))]
        // Theme
        webViewController.loadingBarTintColor = Helper.shared.mainThemeColor()
        if UIDevice.current.userInterfaceIdiom == .phone {
            webViewController.buttonTintColor = Helper.shared.mainThemeColor()
        }
        else {
            webViewController.buttonTintColor = UIColor.white
        }
        navigationController?.pushViewController(webViewController, animated: true)
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
                    Helper.shared.save(status, forKey: PasscodeLockStatus)
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
                        Helper.shared.save(status, forKey: PasscodeLockStatus)
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
            let hud = Helper.shared.showHUD()
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                SDImageCache.shared().clearDisk()
                let defaults = UserDefaults.standard
                let localFileSize = Helper.shared.fileSizeString(withInteger: Helper.shared.localFileSize())
                defaults.set(localFileSize, forKey: LocalFileSize)
                defaults.synchronize()
                sender.synchronizeSettings()
                DispatchQueue.main.async {
                    hud.hide()
                    Helper.shared.showHudWithMessage(NSLocalizedString("Cache Cleared!", comment: "Cache Cleared!"))
                    sender.tableView.reloadData()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView!, cellFor specifier: IASKSpecifier!) -> UITableViewCell! {
        return nil
    }

    //MARK: - Action
    func fetchHTMLAndParse() {
        guard let html = webViewController.webView.stringByEvaluatingJavaScript(from: "document.body.innerHTML") else { return }
        processHTML(html)
    }

    func addAddress() {
        let alertController = UIAlertController(title: NSLocalizedString("Add address", comment: "Add address"), message: NSLocalizedString("Please input an address:", comment: "Please input an address:"), preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.keyboardType = .URL
            textField.clearButtonMode = .whileEditing
            textField.text = "http://"
        }
        let saveAction = UIAlertAction(title: NSLocalizedString("Save", comment:"Save"), style: .default) { [unowned self] _ in
            let address = alertController.textFields![0].text!
            guard let _ = URL(string: address) else { return }
            self.addresses.append(address)
            self.saveAddresses()
            let indexPath = IndexPath(row: self.addresses.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
        alertController.addAction(saveAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.view.tintColor = Helper.shared.mainThemeColor()
        present(alertController, animated: true, completion: nil)
    }

    func showActionSheet() {
        let sheet = UIAlertController(title: NSLocalizedString("Please select your operation", comment: "Please select your operation"), message: nil, preferredStyle: .actionSheet)
        let transmissionAction = UIAlertAction(title: NSLocalizedString("Transmission", comment: "Transmission"), style: .default) { [unowned self] _ in
            self.showTransmission()
        }
        sheet.addAction(transmissionAction)
        let searchAction = UIAlertAction(title: NSLocalizedString("Torrent Search", comment: "Torrent Search"), style: .default) { [unowned self] _ in
            self.torrentSearch()
        }
        sheet.addAction(searchAction)
        let searchKittenAction = UIAlertAction(title: NSLocalizedString("Kitten Search", comment: "Kitten Search"), style: .default) { [unowned self] _ in
            self.torrentSearch(atKitten: true)
        }
        sheet.addAction(searchKittenAction)
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .default) { [unowned self] _ in
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
    
    func saveAddresses() {
        let defaults = UserDefaults.standard
        defaults.set(addresses, forKey: "VPAddresses")
        defaults.synchronize()
    }

    func readAddresses() {
        let defaults = UserDefaults.standard
        guard let addrs = defaults.object(forKey: "VPAddresses") as? [String] else {
            addresses = []
            return
        }
        self.addresses = addrs
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
        settingsNavigationController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        if UIDevice.current.userInterfaceIdiom == .pad {
            settingsNavigationController.modalPresentationStyle = .formSheet
        }
        DispatchQueue.main.async { [unowned self] in
            self.present(settingsNavigationController, animated: true, completion: nil)
        }
    }

    func showTransmission() {
        if Helper.shared.showCellularHUD() { return }
        let link = Helper.shared.transmissionServerAddress()
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
        transmissionNavigationController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        DispatchQueue.main.async { [unowned self] in
            self.present(transmissionNavigationController, animated:true, completion: nil)
        }
    }

    //MARK: - Helper
    func torrentSearch(atKitten: Bool = false) {
        Helper.shared.showTorrentSearchAlertInViewController(navigationController!, forKitten: atKitten)
    }

    func processHTML(_ html: String) {
        var validAddresses: Set<String> = []
        let patterns = ["magnet:\\?[^\"'<]+", "ed2k://[^\"'&<]+", "thunder://[^\"'&<]+", "ftp://[^\"'&<]+", "qqdl://[^\"'&<]+", "Flashget://[^\"'&<]+"]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            regex.enumerateMatches(in: html, options: [], range: NSRange(location: 0, length: html.characters.count), using: { (result, _, _) -> Void in
                if let nsRange = result?.range {
                    let range = html.range(from: nsRange)
                    let link = html.substring(with: range)
                    validAddresses.insert(link)
                }
            })
        }
        if validAddresses.count <= 0 {
            Helper.shared.showHudWithMessage(NSLocalizedString("No downloadable link.", comment: "No downloadable link."))
        }
        else {
            let linksViewController = ValidLinksTableViewController()
            linksViewController.validLinks = [String](validAddresses)
            navigationController?.pushViewController(linksViewController, animated: true)
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
}
