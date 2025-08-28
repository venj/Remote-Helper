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
    var torrents: [CatTorrent] = []
    var currentPage: Int = 1 {
        didSet {
            self.title = String(format: "%@: %@ (%@)", NSLocalizedString("Search", comment:"Search"), keyword, "\(currentPage)/\(total) " + NSLocalizedString("pages", comment:"pages"))
        }
    }
    var total: Int = 0 {
        didSet {
            self.title = String(format: "%@: %@ (%@)", NSLocalizedString("Search", comment:"Search"), keyword, "\(currentPage)/\(total) " + NSLocalizedString("pages", comment:"pages"))
        }
    }
    var keyword: String = "" {
        didSet {
            self.title = String(format: "%@: %@ (%@)", NSLocalizedString("Search", comment:"Search"), keyword, "\(currentPage)/\(total) " + NSLocalizedString("pages", comment:"pages"))
        }
    }
    lazy var kittenItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "🐱", style: .plain, target: self, action: #selector(showKitten))
        return item
    }()

    lazy var wikiItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(named: "wiki"), style: .plain, target: self, action: #selector(showWiki))
        return item
    }()

    var spinner : UIActivityIndicatorView = UIActivityIndicatorView(style: .medium) {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if keyword.matches("^[A-Za-z]{2,6}-\\d{2,6}$", regularExpressionOptions: [.caseInsensitive], matchingOptions:[.anchored]) {
            navigationItem.rightBarButtonItems = [wikiItem, kittenItem]
        }
        else {
            navigationItem.rightBarButtonItems = [kittenItem]
        }

        // Revert back to old UITableView behavior
        tableView.cellLayoutMarginsFollowReadableWidth = false

        // Apply themimg for kitten search.
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        cell.textLabel?.text = torrent.title
        cell.accessoryType = .detailDisclosureButton
        cell.detailTextLabel?.text = String(format: NSLocalizedString("Tr size: %@, Up date: %@", comment: "Tr size: %@, Up date: %@"), torrent.size, torrent.date)

        return cell
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let torrent = torrents[indexPath.row] as CatTorrent
        let link = getMagnet(for: torrent)
        Helper.shared.transmissionDownload(for: link)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let torrent = torrents[indexPath.row]
        let link = getMagnet(for: torrent)
        // Save to paste board.
        UIPasteboard.general.string = link
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
        if indexPath.row == (torrents.count - 1) { // when showing last item
            if currentPage < total {
                loadNextPage()
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return spinner
    }

    func loadNextPage() {
        let nextPage = currentPage + 1
        spinner.startAnimating()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }
            let headers: HTTPHeaders = Configuration.shared.headers
            let source = Configuration.shared.catTorrentSource
            let link = Configuration.shared.catSearchPath(withKeyword: keyword, source: source, page: nextPage)
            let url = URL(string: link)!
            let request = Alamofire.request(url, headers: headers)
            let decoder = JSONDecoder()
            request.responseData { [weak self] response in
                guard let `self` = self,
                      response.result.isSuccess,
                      let jsonData = response.result.value,
                      let json = try? decoder.decode(CatResponse.self, from: jsonData)
                else {
                    DispatchQueue.main.async {
                        Helper.shared.showNote(withMessage: NSLocalizedString("Connection failed.", comment: "Connection failed."), type: .error)
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.spinner.stopAnimating()
                    }
                    return
                }

                let nextPageTorrents = json.data.contents
                self.total = json.data.total
                
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    let torrentsCount = self.torrents.count
                    self.torrents.append(contentsOf: nextPageTorrents)
                    let indexPaths = (torrentsCount..<torrentsCount + nextPageTorrents.count).map { IndexPath(row: $0, section: 0) }
                    self.tableView.insertRows(at: indexPaths, with: UITableView.RowAnimation.top)
                    self.currentPage = nextPage
                }
            }            
        }
    }

    //MARK: - Action
    @objc func showWiki() {
        let webViewController = WebViewController(urlString: "http://www.javlibrary.com/cn/vl_searchbyid.php?keyword=\(keyword)")
        navigationController?.pushViewController(webViewController, animated: true)
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
        } else if let torrent = torrent as? CatTorrent {
            description = "\(torrent.title), \(torrent.size), \(torrent.date), \(torrent.magnet.components(separatedBy: "&").first!)"
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

    func getMagnet(for torrent: CatTorrent) -> String {
        return torrent.magnet
    }
}
