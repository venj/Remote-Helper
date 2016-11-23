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
    //var torrents: [[String:Any]] = []
    var torrents: [Any] = []
    var keyword: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(format: NSLocalizedString("%@: %@ (%lu)", comment: "%@: %@ (%lu)"), arguments: [NSLocalizedString("Search", comment:"Search"), keyword, torrents.count])

        if keyword.matches("^[A-Za-z]{2,6}-\\d{2,6}$", regularExpressionOptions: [.caseInsensitive], matchingOptions:[.anchored]) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "wiki"), style: .plain, target: self, action: #selector(showWiki))
        }

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.defaultHelper.mainThemeColor()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
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

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        navigationController?.navigationBar.barStyle = .default
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Table view delegate and data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return torrents.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }

        // Configure the cell...
        let torrent = torrents[(indexPath as NSIndexPath).row]
        if let torrent = torrent as? [String:Any] { // normal torrent
            cell.textLabel?.text = torrent["name"] as? String
            cell.accessoryType = .detailDisclosureButton

            let size = convertSizeToString(torrent["size"])
            let dateString = formattedDateString(torrent["upload_date"] as? Int)
            let seeders = torrent["seeders"] as? Int
            cell.detailTextLabel?.text = "\(size), \(seeders == nil ? 0 : seeders!)\(NSLocalizedString("seeders", comment:"seeders")), \(dateString)"
        }
        else if let torrent = torrent as? KittenTorrent { // kitten
            cell.textLabel?.text = torrent.title
            cell.accessoryType = .detailDisclosureButton
            cell.detailTextLabel?.text = String(format: NSLocalizedString("Tr size: %@, Up date: %@", comment: "Tr size: %@, Up date: %@"), torrent.size, torrent.date)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let torrent = torrents[(indexPath as NSIndexPath).row]
        self.addTorrentToTransmission(torrent)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let torrent = torrents[(indexPath as NSIndexPath).row]
        let alertController = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: describe(torrent), preferredStyle: .alert)
        let addTorrentAction = UIAlertAction(title: NSLocalizedString("Download", comment: "Download") , style: .default) { [unowned self] _ in
            self.addTorrentToTransmission(torrent)
        }
        alertController.addAction(addTorrentAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    //MARK: - Action
    func showWiki() {
        let webViewController = TOWebViewController(urlString: "http://www.jav11b.com/cn/vl_searchbyid.php?keyword=\(keyword)")
        webViewController?.showUrlWhileLoading = false
        webViewController?.hidesBottomBarWhenPushed = true
        webViewController?.loadingBarTintColor = Helper.defaultHelper.mainThemeColor()
        if UIDevice.current.userInterfaceIdiom == .phone {
            webViewController?.buttonTintColor = Helper.defaultHelper.mainThemeColor()
        }
        else {
            webViewController?.buttonTintColor = UIColor.white
        }
        navigationController?.pushViewController(webViewController!, animated: true)
    }

    //MARK: - Helper
    func describe(_ torrent: Any) -> String {
        var description = NSLocalizedString("Invalid torrent", comment: "Invalid torrent")
        if let torrent = torrent as? [String: Any] {
            let name = torrent["name"] as? String ?? ""
            let size = convertSizeToString(torrent["size"])
            let magnet = torrent["magnet"] as? String ?? ""
            let date = formattedDateString((torrent["upload_date"] as? Int))
            let seeders = torrent["seeders"] as? Int
            description = "\(name), \n\(size), \n\(magnet), \n\(date), \n\(seeders == nil ? 0 : seeders!) " + NSLocalizedString("seeders", comment:"")

        }
        else if let torrent = torrent as? KittenTorrent {
            description = "\(torrent.title), \(torrent.size), \(torrent.date), \(torrent.magnet)"
        }

        return description
    }

    func formattedDateString(_ timeStamp:Int?) -> String {
        guard let ts = timeStamp else { return NSLocalizedString("Unknown date", comment: "Unknown date") }
        let date = Date(timeIntervalSince1970: Double(ts))
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func convertSizeToString(_ size:Any?) -> String {
        let number = size as! NSNumber
        return number.int64Value.fileSizeString
    }

    func addTorrentToTransmission(_ torrent: Any) {
        var magnet = ""
        if let torrent = torrent as? [String:Any] {
            magnet = torrent["magnet"] as? String ?? ""
        }
        else if let torrent = torrent as? KittenTorrent {
            magnet = torrent.magnet
        }
        _ = Helper.defaultHelper.showHUD()
        Helper.defaultHelper.parseSessionAndAddTask(magnet, completionHandler: {
            Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Task added.", comment: "Task added."))
        }, errorHandler: {
            Helper.defaultHelper.showHudWithMessage(NSLocalizedString("Transmission server error.", comment: "Transmission server error."))
        })
    }
}
