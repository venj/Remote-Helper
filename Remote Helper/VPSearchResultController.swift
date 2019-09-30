//
//  VPSearchResultController.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import Alamofire

class VPSearchResultController: UITableViewController {
    let CellIdentifier = "FileListTableViewCell"

    //var torrents: [[String:Any]] = []
    var torrents: [Any] = []
    var keyword: String = "" {
        didSet {
            self.title = String(format: NSLocalizedString("%@: %@ (%lu)", comment: "%@: %@ (%lu)"), arguments: [NSLocalizedString("Search", comment:"Search"), keyword, torrents.count])
        }
    }
    var isKitten: Bool {
        return kittenTorrents != nil
    }
    var kittenTorrents: [KittenTorrent]? {
        return torrents as? [KittenTorrent]
    }
    var normalTorrents: [[String:Any]]? {
        return torrents as? [[String:Any]]
    }

    lazy var kittenItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "🐱", style: .plain, target: self, action: #selector(showKitten))
        return item
    }()

    lazy var wikiItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(named: "wiki"), style: .plain, target: self, action: #selector(showWiki))
        return item
    }()

    var currentPage: Int = 1

    var spinner : UIActivityIndicatorView = UIActivityIndicatorView(style: .gray) {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(format: NSLocalizedString("%@: %@ (%lu)", comment: "%@: %@ (%lu)"), arguments: [NSLocalizedString("Search", comment:"Search"), keyword, torrents.count])

        if isKitten {
            guard let torrents = torrents as? [KittenTorrent] else { return }
            guard let maxPage = torrents.first?.maxPage else { return }
            title = String(format: "%@: %@ (%@)", NSLocalizedString("Search", comment:"Search"), keyword, "\(maxPage) " + NSLocalizedString("pages", comment:"pages"))
        }

        if keyword.matches("^[A-Za-z]{2,6}-\\d{2,6}$", regularExpressionOptions: [.caseInsensitive], matchingOptions:[.anchored]) {
            navigationItem.rightBarButtonItems = [wikiItem, kittenItem]
        }
        else {
            navigationItem.rightBarButtonItems = [kittenItem]
        }

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        // Apply themimg for kitten search.
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var prefersStatusBarHidden: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone && UIApplication.shared.statusBarOrientation.isLandscape
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
        let torrent = torrents[indexPath.row]
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
            cell.detailTextLabel?.text = String(format: NSLocalizedString("Tr size: %@, Up date: %@", comment: "Tr size: %@, Up date: %@"), torrent.size, torrent.dateString)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let torrent = torrents[indexPath.row]
        let link = getMagnet(for: torrent)
        Helper.shared.transmissionDownload(for: link)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let torrent = torrents[indexPath.row]
        let link = getMagnet(for: torrent)
        let alertController = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: describe(torrent), preferredStyle: .alert)

        let miAction = UIAlertAction(title: NSLocalizedString("Mi", comment: "Mi") , style: .default) { _ in
            Helper.shared.miDownloadForLink(link, fallbackIn: self)
        }
        alertController.addAction(miAction)

        let addTorrentAction = UIAlertAction(title: "Transmission" , style: .default) { _ in
            Helper.shared.transmissionDownload(for: link)
        }

        alertController.addAction(addTorrentAction)

        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isKitten && indexPath.row == (torrents.count - 1) { // when showing last item
            guard let maxPage = kittenTorrents?.first?.maxPage else { return }
            if currentPage < maxPage {
                loadNextPage()
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if isKitten { // when showing last item
            return spinner
        }
        return nil
    }

    func loadNextPage() {
        let nextPage = currentPage + 1
        spinner.startAnimating()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }
            let url = URL(string: Helper.shared.kittenSearchPath(withKeyword: self.keyword, page: nextPage))!

            let request = Alamofire.request(url)
            request.responseData { [weak self] response in
                guard let `self` = self else { return }
                if let data = response.result.value {
                    let trs = KittenTorrent.parse(data: data, source: Configuration.shared.torrentKittenSource)
                    DispatchQueue.main.async {
                        self.spinner.stopAnimating()
                        let torrentsCount = self.torrents.count
                        self.torrents.append(contentsOf: (trs as [Any]))
                        let indexPaths = (torrentsCount..<torrentsCount + trs.count).map { IndexPath(row: $0, section: 0) }
                        self.tableView.insertRows(at: indexPaths, with: UITableView.RowAnimation.top)
                        self.currentPage = nextPage
                    }
                }
                else {
                    DispatchQueue.main.async {
                        //hud.hide()
                        self.spinner.stopAnimating()
                    }
                }
            }
        }
    }

    //MARK: - Action
    @objc func showWiki() {
        let webViewController = TOWebViewController(urlString: "http://www.javlibrary.com/cn/vl_searchbyid.php?keyword=\(keyword)")
        webViewController?.showUrlWhileLoading = false
        webViewController?.hidesBottomBarWhenPushed = true
        if UIDevice.current.userInterfaceIdiom == .phone {
            webViewController?.buttonTintColor = Helper.shared.mainThemeColor()
        }
        else {
            webViewController?.buttonTintColor = UIColor.white
        }
        navigationController?.pushViewController(webViewController!, animated: true)
    }

    @objc func showKitten() {
        Helper.shared.showTorrentSearchAlertInViewController(self.navigationController!)
    }

    //MARK: - Helper
    func describe(_ torrent: Any) -> String {
        var description = NSLocalizedString("Invalid torrent", comment: "Invalid torrent")
        if let torrent = torrent as? [String: Any] {
            let name = torrent["name"] as? String ?? ""
            let size = convertSizeToString(torrent["size"])
            let magnet = (torrent["magnet"] as? String ?? "").components(separatedBy: "&").first!
            let date = formattedDateString((torrent["upload_date"] as? Int))
            let seeders = torrent["seeders"] as? Int
            description = "\(name), \n\(size), \n\(magnet), \n\(date), \n\(seeders == nil ? 0 : seeders!) " + NSLocalizedString("seeders", comment:"")
        }
        else if let torrent = torrent as? KittenTorrent {
            description = "\(torrent.title), \(torrent.size), \(torrent.dateString), \(torrent.magnet.components(separatedBy: "&").first!)"
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

    func getMagnet(for torrent: Any) -> String {
        var magnet: String = ""
        if let torrent = torrent as? [String:Any] {
            magnet = torrent["magnet"] as? String ?? ""
        }
        else if let torrent = torrent as? KittenTorrent {
            magnet = torrent.magnet
        }
        return magnet
    }
}
