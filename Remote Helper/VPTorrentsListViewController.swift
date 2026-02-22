//
//  VPTorrentListViewController.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import MediaBrowser
import Alamofire
import SwiftEntryKit
import Kingfisher

class VPTorrentsListViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    let CellIdentifier = "VPTorrentsListViewCell"
    let localizedStatusStrings: [String: String] = ["completed" : NSLocalizedString("completed", comment: "completed"),
        "waiting" : NSLocalizedString("waiting", comment:"waiting"),
        "downloading" : NSLocalizedString("downloading", comment:"downloading"),
        "failed or unknown" : NSLocalizedString("failed or unknown", comment: "failed or unknown")]

    var datesDict: [String: [Any]] = [:] {
        didSet {
            dateList = datesDict.count == 0 ? [] : datesDict["items"] as! [String]
            countList = datesDict.count == 0 ? [] : datesDict["counts"] as! [Int]
            titles = dateList.enumerated().map { "\($1) (\(countList[$0]))"}
        }
    }
    var dateList: [String] = []
    var titles: [String] = []

    var filteredDateList: [String] = [] {
        didSet {
            filteredTitles = filteredDateList.enumerated().map { "\($1) (\(filteredCountList[$0]))"}
        }
    }
    var filteredTitles: [String] = []

    var countList: [Int] = []
    var filteredCountList: [Int] = []

    var photos: [String] = []
    var remotePhotos: [RemoteMedia] {
        return photos.compactMap { photo in
            let url = URL(string: Configuration.shared.baseLink)!
            let fullURL = url.appendingPathComponent(photo)
            return RemoteMedia(source: .remoteImage(imageURL: fullURL, thumbnailURL: nil))
        }
    }
    var collapseDetailViewController: Bool = true

    var currentPhotoIndex: Int = 0
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    var cloudItem: UIBarButtonItem!
    lazy var hashItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(named:"magnet"), style: .plain, target: self, action: #selector(hashTorrent))
        return item
    }()
    lazy var kittenItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "🐱", style: .plain, target: self, action: #selector(showKitten))
        return item
    }()
    var headers: HTTPHeaders = Configuration.shared.headers
    var currentSelectedTitle: String = ""
    var previewingIndexPath: IndexPath?

    var viewedTitles: Set<String> {
        get {
            let titlesArray = UserDefaults.standard.object(forKey: ViewedTitlesKey) as? [String]  ?? []
            return Set<String>(titlesArray)
        }
        set {
            UserDefaults.standard.set([String](newValue), forKey: ViewedTitlesKey)
            UserDefaults.standard.synchronize()
            NSUbiquitousKeyValueStore.default.set([String](newValue), forKey: ViewedTitlesKey)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    lazy var attachedProgressView: UIProgressView = {
        let v = UIProgressView(progressViewStyle: .default)
        return v
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        attachedProgressView.removeFromSuperview()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        let searchBar = searchController.searchBar
        searchBar.tintColor = .white
        searchBar.keyboardType = .numbersAndPunctuation
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar

        loadTorrentList(nil)

        // Revert back to old UITableView behavior
        tableView.cellLayoutMarginsFollowReadableWidth = false

        // Hide searchbar initially.
        tableView.contentOffset = CGPoint(x: 0.0, y: searchBar.frame.height)

        NotificationCenter.default.addObserver(self, selector: #selector(viewedTitlesDidChange(_:)), name: NSNotification.Name.viewedTitlesDidChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        ImageCache.default.clearMemoryCache()
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    func cleanupUselessViewedTitles() {
        viewedTitles = viewedTitles.intersection(titles)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !searchController.isActive {
            return titles.count
        }
        else {
            return filteredTitles.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        cell.accessoryType = .detailDisclosureButton
        let currentTitles = !searchController.isActive ? titles : filteredTitles
        let title = currentTitles[indexPath.row]
        cell.textLabel?.text = title
        if viewedTitles.contains(title) {
            cell.textLabel?.textColor = .secondaryLabel
        }
        else {
            cell.textLabel?.textColor = .label
        }

        return cell
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if Helper.shared.showCellularHUD() { return false }
        if identifier == "ShowTorrentsSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                showPhotoBrowser(forIndexPath: indexPath)
            }
            return false
        }
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowTorrentsSegue" {
            if let nav = segue.destination as? UINavigationController,
                let pb = nav.topViewController as? PhotosViewController,
                let indexPath = tableView.indexPathForSelectedRow {
                // Update currentSelectedTitle
                let list = !searchController.isActive ? dateList : filteredDateList
                currentSelectedTitle = list[indexPath.row]
                if Helper.shared.showCellularHUD() { return }
                if let cell = tableView.cellForRow(at: indexPath), let title = cell.textLabel?.text {
                    cell.textLabel?.textColor = UIColor.gray
                    viewedTitles.insert(title)
                    pb.title = title
                }
                pb.items = remotePhotos
                pb.overlayActionButtons = [
                    .init(
                        title: "🧲",
                        style: .default,
                        onTap: { [weak self] _ in
                            self?.hashTorrent()
                        }
                    ),
                    .init(
                        title: "🐱",
                        style: .default,
                        onTap: { [weak self] overlay in
                            self?.showKitten()
                        }
                    )
                ]
            }
        }
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    }

    //MARK: - Action
    @objc func showKitten() {
        Helper.shared.showTorrentSearchAlertInViewController(self.navigationController!)
    }

    @objc func hashTorrent() {
        guard let base64FileName = photos[currentPhotoIndex].base64String() else { return }
        Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Loading...", comment: "Loading..."))
        let request = Alamofire.request(Configuration.shared.hashTorrent(withName: base64FileName), headers: headers)
        request.responseJSON { [weak self] response in
            guard let self = self else { return }
            if response.result.isSuccess {
                SwiftEntryKit.dismiss()
                guard let json = response.result.value as? [String: Any] else { return }
                guard let responseObject = json["data"] as? [String: Any] else { return }
                guard let hash = responseObject["hash"] as? String, let torrent = responseObject["torrent"] as? String else { return }
                let message = "magnet:?xt=urn:btih:\(hash.uppercased())"
                Helper.shared.selectDownloadMethod(for: message, andTorrent: torrent, showIn: self)
            }
            else {
                Helper.shared.showNote(withMessage: NSLocalizedString("Connection failed.", comment: "Connection failed."), type:.error)
            }
        }
    }

    // MARK: - UIPopoverPresentationControllerDelegate

    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.barButtonItem =  navigationController?.topViewController?.navigationItem.rightBarButtonItems?.last
    }

    //MARK: - Helper
    func showPhotoBrowser(forIndexPath indexPath: IndexPath, initialPhotoIndex index: Int = 0) {
        let list = !searchController.isActive ? dateList : filteredDateList
        guard indexPath.row < (list.count) else { return }
        if Helper.shared.showCellularHUD() { return }
        guard let date = list[indexPath.row].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else { return }
        Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Loading...", comment: "Loading..."))
        let request = Alamofire.request(Configuration.shared.searchPath(withKeyword: date), headers: headers)
        request.responseJSON { [weak self] response in
            guard let `self` = self else { return }
            SwiftEntryKit.dismiss()
            if response.result.isSuccess {
                guard let json = response.result.value as? [String: Any] else { return }
                guard let photos = json["data"] as? [String] else { return }
                self.photos = photos
//                self.mediaStartIndex = index
//                self.mwPhotos.forEach {
//                    $0.loadUnderlyingImageAndNotify();
//                }
                // FIXME: Prepare for segue not executed.
                self.performSegue(withIdentifier: "ShowTorrentsSegue", sender: nil)
            }
            else {
                Helper.shared.showNote(withMessage: NSLocalizedString("Connection failed.", comment: "Connection failed."), type:.error)
            }
        }
    }

    @IBAction func loadTorrentList(_ sender: Any?) {
        if !Configuration.shared.hasTorrentServer {
            Helper.shared.showNote(withMessage: NSLocalizedString("No server configuration found.", comment: "No server configuration found."), type:.error)
            return
        }
        if Helper.shared.showCellularHUD() { return }
        Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Loading...", comment: "Loading..."))
        navigationItem.rightBarButtonItem?.isEnabled = false
        let request = Alamofire.request(Configuration.shared.torrentsListPath, headers: headers)
        request.responseJSON { [weak self] response in
            guard let `self` = self else { return }
            if response.result.isSuccess {
                let json = response.result.value as! [String: Any]
                self.datesDict = json["data"] as! [String: [Any]]
                DispatchQueue.global(qos: .background).async { [weak self] in
                    guard let `self` = self else { return }
                    self.cleanupUselessViewedTitles()
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                        SwiftEntryKit.dismiss()
                        self.tableView.reloadData()
                    }
                }
            }
            else {
                print(response.result.error?.localizedDescription ?? "")
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    Helper.shared.showNote(withMessage: NSLocalizedString("Connection failed.", comment: "Connection failed."), type:.error)
                }
            }
        }
    }

    @objc
    func viewedTitlesDidChange(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.tableView.reloadData()
        }
    }
}

extension VPTorrentsListViewController : UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else { return }
        filteredCountList = countList
        filteredDateList = dateList
        for dateString in dateList {
            if dateString.range(of: searchString) == nil {
                guard let index = filteredDateList.firstIndex(of: dateString) else { continue }
                filteredDateList.remove(at: index)
                filteredCountList.remove(at: index)
            }
        }
        self.tableView.reloadData()
    }
    
}
