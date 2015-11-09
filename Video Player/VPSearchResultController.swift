//
//  VPSearchResultController.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import TOWebViewController

class VPSearchResultController: UITableViewController {
    let CellIdentifier = "FileListTableViewCell"
    var torrents: [[String:AnyObject]] = []
    var keyword: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(format: NSLocalizedString("%@: %@ (%lu)", comment: "%@: %@ (%lu)"), arguments: [NSLocalizedString("Search", comment:"Search"), keyword, torrents.count])

        if keyword.matches("^[A-Za-z]{2,6}-\\d{2,6}$", regularExpressionOptions: [.CaseInsensitive], matchingOptions:[.Anchored]) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "wiki"), style: .Plain, target: self, action: "showWiki")
        }

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.defaultHelper.mainThemeColor()
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        tableView.tintColor = Helper.defaultHelper.mainThemeColor()

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if UIApplication.sharedApplication().statusBarHidden {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Slide)
        }
        
        navigationController?.setToolbarHidden(true, animated: true)
        navigationController?.navigationBar.barStyle = .Default
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: - Table view delegate and data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return torrents.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: CellIdentifier)
        }

        // Configure the cell...
        let torrent = torrents[indexPath.row]
        cell.textLabel?.text = torrent["name"] as? String
        cell.accessoryType = .DetailDisclosureButton;

        let size = convertSizeToString(torrent["size"])
        let dateString = formattedDateString(torrent["upload_date"] as? Int)
        let seeders = torrent["seeders"] as? Int
        cell.detailTextLabel?.text = "\(size), \(seeders == nil ? 0 : seeders!)\(NSLocalizedString("seeders", comment:"seeders")), \(dateString)"

        return cell
    }

    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let torrent = torrents[indexPath.row]
        self.addTorrentToTransmission(torrent)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let torrent = torrents[indexPath.row]
        let alertController = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: describe(torrent), preferredStyle: .Alert)
        let addTorrentAction = UIAlertAction(title: NSLocalizedString("Download", comment: "Download") , style: .Default) { [unowned self] _ in
            self.addTorrentToTransmission(torrent)
        }
        alertController.addAction(addTorrentAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }

    //MARK: - Action
    func showWiki() {
        let webViewController = TOWebViewController(URLString: "http://www.javlib3.com/cn/vl_searchbyid.php?keyword=\(keyword)")
        webViewController.showUrlWhileLoading = false
        webViewController.hidesBottomBarWhenPushed = true
        webViewController.loadingBarTintColor = Helper.defaultHelper.mainThemeColor()
        webViewController.buttonTintColor = Helper.defaultHelper.mainThemeColor()
        navigationController?.pushViewController(webViewController, animated: true)
    }

    //MARK: - Helper
    func describe(torrent: NSDictionary) -> String {
        let name = torrent["name"] as! String
        let size = convertSizeToString(torrent["size"])
        let magnet = torrent["magnet"] as! String
        let date = formattedDateString((torrent["upload_date"] as? Int))
        let seeders = torrent["seeders"] as? Int
        return "\(name), \n\(size), \n\(magnet), \n\(date), \n\(seeders == nil ? 0 : seeders!) " + NSLocalizedString("seeders", comment:"")
    }

    func formattedDateString(timeStamp:Int?) -> String {
        guard let ts = timeStamp else { return NSLocalizedString("Unknown date", comment: "Unknown date") }
        let date = NSDate(timeIntervalSince1970: Double(ts))
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        return formatter.stringFromDate(date)
    }

    func convertSizeToString(size:AnyObject?) -> String {
        let number = size as! NSNumber
        return number.longLongValue.fileSizeString
    }

    func addTorrentToTransmission(torrent: [String:AnyObject]) {
        Helper.defaultHelper.parseSessionAndAddTask(torrent["magnet"] as! String, completionHandler: {
            Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Task added.", comment: "Task added."))
        }, errorHandler: {
            Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Unknow error.", comment: "Unknow error."))
        })
    }
}
