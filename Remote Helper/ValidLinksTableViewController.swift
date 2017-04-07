//
//  ValidLinksTableViewController.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import iOS8Colors

class ValidLinksTableViewController: UITableViewController {
    let reuseIdentifier = "ValidLinksTableViewCellIdentifier"
    var validLinks: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String(format: NSLocalizedString("Found %ld links", comment: "Found %ld links"), arguments: [self.validLinks.count])
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)

        if self.validLinks.count > 1 {
            let rightItem = UIBarButtonItem(title: NSLocalizedString("Copy All", comment:"Copy All"), style: .plain, target: self, action: #selector(copyAll))
            self.navigationItem.rightBarButtonItem = rightItem
        }

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    //MARK: - TableView Delegates and Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return validLinks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as UITableViewCell
        cell.textLabel?.text = parseName(self.validLinks[(indexPath as NSIndexPath).row])
        return cell;
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) { }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let link = validLinks[(indexPath as NSIndexPath).row]
        let alertController = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: NSLocalizedString("Do you want to download this link?", comment: "Do you want to download this link?"), preferredStyle: .alert)
        let downloadAction = UIAlertAction(title: NSLocalizedString("Download", comment: "Download"), style: .default) { [unowned self ] _ in
            self.download(link)
        }
        alertController.addAction(downloadAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler:nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let link = self.validLinks[(indexPath as NSIndexPath).row]
        // Copy Link
        let copyAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Copy", comment: "Copy")) { [unowned self] (_, _) in
            if self.tableView.isEditing { self.tableView.setEditing(false, animated: true) }
            UIPasteboard.general.string = link
            Helper.shared.showHudWithMessage(NSLocalizedString("Copied", comment: "Copied"))
        }
        copyAction.backgroundColor = UIColor.iOS8purple()

        // Download Link
        let downloadAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Download", comment: "Download")) { [unowned self] (_, _) in
            if self.tableView.isEditing { self.tableView.setEditing(false, animated: true) }
            self.download(link)
        }

        // Mi Download
        let miAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Mi", comment: "Mi")) { [unowned self] (_, _) in
            if self.tableView.isEditing { self.tableView.setEditing(false, animated: true) }
            Helper.shared.miDownload(for: link, fallbackIn: self)
        }

        miAction.backgroundColor = UIColor.iOS8green()
        return [miAction, downloadAction, copyAction]
    }

    //MARK: - Helper

    func copyAll() {
        UIPasteboard.general.string = self.validLinks.joined(separator: "\n")
        Helper.shared.showHudWithMessage(NSLocalizedString("Copied", comment: "Copied"))
    }

    func download(_ link:String) {
        let protocal = link.components(separatedBy: ":")[0]
        if protocal == "magnet" {
            let hud = Helper.shared.showHUD()
            Helper.shared.parseSessionAndAddTask(link, completionHandler: {
                hud.hide()
                Helper.shared.showHudWithMessage(NSLocalizedString("Task added.", comment: "Task added."))
            }, errorHandler: {
                Helper.shared.showHudWithMessage(NSLocalizedString("Transmission server error.", comment: "Transmission server error."))
            })
        }
        else {
            guard let url = URL(string: link) else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
            else {
                Helper.shared.showHudWithMessage(NSLocalizedString("No 'DS Download' found.", comment: "No 'DS Download' found."))
            }
        }
    }

    fileprivate func parseName(_ link: String) -> String {

        guard let decodedLink = link.removingPercentEncoding else { return link }
        let protocal = decodedLink.components(separatedBy: ":")[0].lowercased()
        if protocal == "thunder" || protocal == "flashget" || protocal == "qqdl" {
            guard let decodedThunderLink = try? URLConverter.decode(link) else { return decodedLink }
            guard let result = decodedThunderLink.removingPercentEncoding else { return decodedThunderLink }
            return parseName(result)
        }
        else if protocal == "magnet" {
            guard let queryString = decodedLink.components(separatedBy: "?").last else { return decodedLink }
            let kvs = queryString.replacingOccurrences(of: "&amp;", with: "&").components(separatedBy: "&")
            var name = decodedLink
            for kv in kvs {
                let kvPair = kv.components(separatedBy: "=")
                if (kvPair[0].lowercased() == "dn" || kvPair[0].lowercased() == "btname") && kvPair[1] != "" {
                    name = kvPair[1].replacingOccurrences(of: "+", with: " ")
                    break
                }
            }
            return name
        }
        else if protocal == "ed2k" {
            let parts = decodedLink.components(separatedBy: "|")
            let index: Int? = parts.index(of: "file")
            if index != nil && parts.count > index! + 2 {
                return parts[index! + 1]
            }
            else {
                return decodedLink
            }
        }
        else if protocal == "ftp" || protocal == "http" || protocal == "https" {
            guard let result = decodedLink.components(separatedBy: "/").last else { return decodedLink }
            return result
        }
        else {
            return decodedLink
        }
    }
}
