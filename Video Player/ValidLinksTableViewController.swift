//
//  ValidLinksTableViewController.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import MBProgressHUD
import iOS8Colors

class ValidLinksTableViewController: UITableViewController {
    let reuseIdentifier = "ValidLinksTableViewCellIdentifier"
    var validLinks: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String(format: NSLocalizedString("Found %ld links", comment: "Found %ld links"), arguments: [self.validLinks.count])
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)

        func copyAll() {
            UIPasteboard.generalPasteboard().string = self.validLinks.joinWithSeparator("\n")
            Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Copied", comment: "Copied"), inView: navigationController?.view)
        }

        if self.validLinks.count > 1 {
            let rightItem = UIBarButtonItem(title: NSLocalizedString("Copy All", comment:"Copy All"), style: .Plain, target: self, action: "copyAll")
            self.navigationItem.rightBarButtonItem = rightItem
        }

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
    }


    //MARK: - TableView Delegates and Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return validLinks.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as UITableViewCell
        cell.textLabel?.text = parseName(self.validLinks[indexPath.row])
        return cell;
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) { }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let link = validLinks[indexPath.row]
        let alertController = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: NSLocalizedString("Do you want to download this link?", comment: "Do you want to download this link?"), preferredStyle: .Alert)
        let downloadAction = UIAlertAction(title: NSLocalizedString("Download", comment: "Download"), style: .Default) { [unowned self ] _ in
            self.download(link)
        }
        alertController.addAction(downloadAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler:nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let link = self.validLinks[indexPath.row]
        // Copy Link
        let copyAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("Copy Link", comment: "Copy Link")) { [unowned self] (_, _) in
            if self.tableView.editing { self.tableView.setEditing(false, animated: true) }
            UIPasteboard.generalPasteboard().string = link
            Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Copied", comment: "Copied"), inView: self.navigationController?.view)
        }
        copyAction.backgroundColor = UIColor.iOS8purpleColor()

        // Download Link
        let downloadAction = UITableViewRowAction(style: .Default, title: NSLocalizedString("Download", comment: "Download")) { [unowned self] (_, _) in
            if self.tableView.editing { self.tableView.setEditing(false, animated: true) }
            self.download(link)
        }
        downloadAction.backgroundColor = UIColor.iOS8orangeColor()

        // Lixian
        let lixianAction = UITableViewRowAction(style: .Default, title: NSLocalizedString("Lixian", comment: "Lixian")) { [unowned self] (_, _) in
            if self.tableView.editing { self.tableView.setEditing(false, animated: true) }
            let hud = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                let protocal = link.componentsSeparatedByString(":")[0]
                let xunleiAPI = Helper.sharedAPI
                let xunleiAccount = Helper.defaultHelper.xunleiUsernameAndPassword
                if !AppDelegate.shared().xunleiUserLoggedIn {
                    if !xunleiAPI.loginWithUsername(xunleiAccount[0], password: xunleiAccount[1], isPasswordEncode: false) {
                        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                            hud.hide(true)
                            Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Login Failed.", comment: "Login Failed."), inView:self.navigationController?.view)
                            return
                        }
                    }
                    else {
                        AppDelegate.shared().xunleiUserLoggedIn = true
                    }
                }
                sleep(2)
                var dcid = ""
                if protocal == "magnet" {
                    dcid = xunleiAPI.addMegnetTask(link)
                }
                else {
                    dcid = xunleiAPI.addNormalTask(link)
                }
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                    hud.hide(true)
                    if dcid == "" {
                        Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Failed to add task.", comment: "Failed to add task."), inView: self.navigationController?.view)
                    }
                    else {
                        Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Lixian added.", comment: "Lixian added."), inView: self.navigationController?.view)
                    }
                }
            }
        }

        lixianAction.backgroundColor = UIColor.iOS8greenColor()
        return [copyAction, lixianAction, downloadAction]
    }

    //MARK: - Helper
    func download(link:String) {
        let protocal = link.componentsSeparatedByString(":")[0]
        if protocal == "magnet" {
            let hud = MBProgressHUD.showHUDAddedTo(navigationController?.view, animated:true)
            hud.removeFromSuperViewOnHide = true
            Helper.defaultHelper.parseSessionAndAddTask(link, completionHandler: {
                hud.hide(true)
                }, errorHandler: { [unowned self] in
                    Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Unknow error.", comment: "Unknow error."), inView: self.navigationController?.view)
                })
        }
        else {
            guard let url = NSURL(string: link) else { return }
            if UIApplication.sharedApplication().canOpenURL(url) {
                UIApplication.sharedApplication().openURL(url)
            }
            else {
                Helper.defaultHelper.showHudWithMessage(NSLocalizedString("No 'DS Download' found.", comment: "No 'DS Download' found."), inView: self.navigationController?.view)
            }
        }
    }

    private func parseName(link: String) -> String {
        guard let decodedLink = link.stringByRemovingPercentEncoding else { return link }
        let protocal = decodedLink.componentsSeparatedByString(":")[0].lowercaseString
        if protocal == "thunder" {
            guard let decodedThunderLink = try? URLConverter.decode(link) else { return decodedLink }
            guard let result = decodedThunderLink.stringByRemovingPercentEncoding else { return decodedThunderLink }
            return parseName(result)
        }
        else if protocal == "magnet" {
            guard let queryString = decodedLink.componentsSeparatedByString("?").last else { return decodedLink }
            let kvs = queryString.stringByReplacingOccurrencesOfString("&amp;", withString: "&").componentsSeparatedByString("&")
            var name = decodedLink
            for kv in kvs {
                let kvPair = kv.componentsSeparatedByString("=")
                if (kvPair[0].lowercaseString == "dn" || kvPair[0].lowercaseString == "btname") && kvPair[1] != "" {
                    name = kvPair[1].stringByReplacingOccurrencesOfString("+", withString: " ")
                    break
                }
            }
            return name
        }
        else if protocal == "ed2k" {
            let parts = decodedLink.componentsSeparatedByString("|")
            let index: Int? = parts.indexOf("file")
            if index != nil && parts.count > index! + 2 {
                return parts[index! + 1]
            }
            else {
                return decodedLink
            }
        }
        else if protocal == "ftp" || protocal == "http" || protocal == "https" {
            guard let result = decodedLink.componentsSeparatedByString("/").last else { return decodedLink }
            return result
        }
        else {
            return decodedLink
        }
    }
}
