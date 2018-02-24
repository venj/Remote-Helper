//
//  VPTorrentListViewController.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import SDWebImage
import TOWebViewController
import MWPhotoBrowser
import Alamofire

class VPTorrentsListViewController: UITableViewController, MWPhotoBrowserDelegate, UIPopoverPresentationControllerDelegate {
    let CellIdentifier = "VPTorrentsListViewCell"
    let localizedStatusStrings: [String: String] = ["completed" : NSLocalizedString("completed", comment: "completed"),
        "waiting" : NSLocalizedString("waiting", comment:"waiting"),
        "downloading" : NSLocalizedString("downloading", comment:"downloading"),
        "failed or unknown" : NSLocalizedString("failed or unknown", comment: "failed or unknown")]

    var datesDict: [String: [Any]] = [:]
    var dateList: [String] {
        get {
            if datesDict.count == 0 { return [] }
            return datesDict["items"] as! [String]
        }
    }
    var countList: [Int] {
        get {
            if datesDict.count == 0 { return [] }
            return datesDict["count"] as! [Int]
        }
    }

    var titles: [String] {
        return dateList.enumerated().map { "\($1) (\(countList[$0]))"}
    }

    var filteredTitles: [String] {
        return filteredDateList.enumerated().map { "\($1) (\(filteredCountList[$0]))"}
    }

    var mwPhotos: [MWPhoto]   = []
    var photos: [String] = [] {
        didSet {
            mwPhotos = []
            let defaults = UserDefaults.standard
            var path = "/"
            if let pt = defaults.object(forKey: ServerPathKey) as? String { path = pt }
            let linkBase = Helper.shared.fileLink(withPath: path)
            for photo in photos {
                guard let url = URL(string: linkBase) else { break }
                let fullURL = url.appendingPathComponent(photo)
                let p = MWPhoto(url: fullURL)
                p?.caption = photo.components(separatedBy: "/").last
                mwPhotos.append(p!)
            }
        }
    }

    var currentPhotoIndex: Int = 0
    var filteredDateList: [String] = []
    var filteredCountList: [Int] = []
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
    var currentSelectedIndexPath: IndexPath?

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

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Torrents", comment: "Torrents")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(loadTorrentList(_:)))

        self.definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        let searchBar = searchController.searchBar
        searchBar.tintColor = UIColor.white
        searchBar.barTintColor = Helper.shared.mainThemeColor()
        searchBar.keyboardType = .numbersAndPunctuation
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar

        self.loadTorrentList(nil)

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        tableView.tintColor = Helper.shared.mainThemeColor()

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        NotificationCenter.default.addObserver(self, selector: #selector(photoPreloadFinished(_:)), name: NSNotification.Name(rawValue: MWPHOTO_LOADING_DID_END_NOTIFICATION), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showNoMorePhotosHUD(_:)), name: NSNotification.Name(rawValue: MWPHOTO_NO_MORE_PHOTOS_NOTIFICATION), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewedTitlesDidChange(_:)), name: NSNotification.Name.viewedTitlesDidChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        SDWebImageManager.shared().imageCache?.clearMemory()
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    func cleanupUselessViewedTitles() {
        viewedTitles.forEach { title in
            if !titles.contains(title) { viewedTitles.remove(title) }
        }
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
            cell.textLabel?.textColor = UIColor.gray
        }
        else {
            cell.textLabel?.textColor = UIColor.black
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        currentSelectedIndexPath = indexPath
        if Helper.shared.showCellularHUD() { return }
        if let cell = tableView.cellForRow(at: indexPath), let title = cell.textLabel?.text {
            cell.textLabel?.textColor = UIColor.gray
            viewedTitles.insert(title)
        }
        self.showPhotoBrowser(forIndexPath: indexPath)
    }

    @objc func photoPreloadFinished(_ notification: Notification) {
        //print("Photo load fihished! \(notification.object)")
    }

    @objc func showNoMorePhotosHUD(_ notification: Notification) {
        Helper.shared.showHudWithMessage(NSLocalizedString("No more photos.", comment: "No more photos."));
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        currentSelectedIndexPath = indexPath
        if Helper.shared.showCellularHUD() { return }
        let alertController = UIAlertController(title: NSLocalizedString("Initial Index", comment: "Initial Index"), message: NSLocalizedString("Please enter a number for photo index(from 1).", comment: "Please enter a number for photo index(from 1)."), preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "1"
            textField.keyboardType = .numberPad
        }
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK") , style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            var index = 1
            if let i = Int((alertController.textFields?[0].text)!) { index = i }
            if index < 1 { index = 1 }
            self.showPhotoBrowser(forIndexPath: indexPath, initialPhotoIndex: index - 1)
        }
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.view.tintColor = Helper.shared.mainThemeColor()
        present(alertController, animated: true, completion: nil)
    }

    //MARK: - MWPhotoBrowser delegate

    func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(mwPhotos.count)
    }

    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        if (index < UInt(self.mwPhotos.count)) {
            return self.mwPhotos[Int(index)]
        }
        return nil
    }

    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, didDisplayPhotoAt index: UInt) {
        currentPhotoIndex = Int(index)
        photoBrowser.navigationItem.rightBarButtonItems  = [kittenItem, hashItem]
    }

    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, titleForPhotoAt index: UInt) -> String! {
        guard let indexPath = currentSelectedIndexPath else { return nil }
        let list = !searchController.isActive ? dateList : filteredDateList
        let title = list[indexPath.row]
        return "\(title) (\(currentPhotoIndex + 1)/\(photos.count))"
    }

    //MARK: - Action
    @objc func showKitten() {
        Helper.shared.showTorrentSearchAlertInViewController(self.navigationController!)
    }

    @objc func hashTorrent() {
        guard let base64FileName = photos[currentPhotoIndex].base64String() else { return }
        let hud = Helper.shared.showHUD()
        let request = Alamofire.request(Helper.shared.hashTorrent(withName: base64FileName))
        request.responseJSON { response in
            if response.result.isSuccess {
                hud.hide()
                guard let responseObject = response.result.value as? [String: Any] else { return }
                guard let hash = responseObject["hash"] as? String else { return }
                let message = "magnet:?xt=urn:btih:\(hash.uppercased())"
                UIPasteboard.general.string = message

                let alert = UIAlertController(title: NSLocalizedString("Choose...", comment: "Choose..."), message: NSLocalizedString("Please choose a download method.", comment: "Please choose a download method."), preferredStyle: .actionSheet)
                let miAction = UIAlertAction(title: NSLocalizedString("Mi", comment: "Mi"), style: .default, handler: { (action) in
                    Helper.shared.miDownloadForLink(message, fallbackIn: self)
                })
                alert.addAction(miAction)

                let transmissionAction = UIAlertAction(title: "Transmission", style: .default, handler: { (action) in
                    Helper.shared.transmissionDownload(for: message)
                })
                alert.addAction(transmissionAction)

                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
                alert.addAction(cancelAction)

                alert.popoverPresentationController?.delegate = self
                alert.view.tintColor = Helper.shared.mainThemeColor()
                DispatchQueue.main.async {
                    self.navigationController?.topViewController?.present(alert, animated: true) {
                        alert.popoverPresentationController?.passthroughViews = nil
                    }
                }
            }
            else {
                hud.hide()
                Helper.shared.showHudWithMessage(NSLocalizedString("Connection failed.", comment: "Connection failed."))
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
        searchController.isActive = false
        if Helper.shared.showCellularHUD() { return }
        guard let date = list[indexPath.row].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else { return }
        let hud = Helper.shared.showHUD()
        let request = Alamofire.request(Helper.shared.searchPath(withKeyword: date))
        request.responseJSON { [weak self] response in
            guard let `self` = self else { return }
            hud.hide()
            if response.result.isSuccess {
                guard let photos = response.result.value as? [String] else { return }
                self.photos = photos
                self.mwPhotos.forEach {
                    $0.loadUnderlyingImageAndNotify();
                }
                let photoBrowser = MWPhotoBrowser(delegate: self)
                photoBrowser?.displayActionButton = false
                photoBrowser?.displayNavArrows = true
                photoBrowser?.zoomPhotosToFill = false
                var sIndex = index
                if index > photos.count - 1 {
                    sIndex = photos.count - 1
                }
                photoBrowser?.setCurrentPhotoIndex(UInt(sIndex))
                self.navigationController?.pushViewController(photoBrowser!, animated: true)
            }
            else {
                Helper.shared.showHudWithMessage(NSLocalizedString("Connection failed.", comment: "Connection failed."))
            }
        }
    }

    @objc func loadTorrentList(_ sender: Any?) {
        if Helper.shared.showCellularHUD() { return }
        let hud = Helper.shared.showHUD()
        navigationItem.rightBarButtonItem?.isEnabled = false
        let request = Alamofire.request(Helper.shared.torrentsListPath())
        request.responseJSON { [weak self] response in
            guard let `self` = self else { return }
            if response.result.isSuccess {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.datesDict = response.result.value as! [String: [Any]]
                self.cleanupUselessViewedTitles()
                self.tableView.reloadData()
            }
            else {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print(response.result.error?.localizedDescription ?? "")
                Helper.shared.showHudWithMessage(NSLocalizedString("Connection failed.", comment: "Connection failed."))
            }
            hud.hide()
        }
    }

    @objc
    func viewedTitlesDidChange(_ notification: NSNotification) {
        tableView.reloadData()
    }
}

extension VPTorrentsListViewController : UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else { return }
        filteredDateList = dateList
        filteredCountList = countList
        for dateString in dateList {
            if dateString.range(of: searchString) == nil {
                guard let index = filteredDateList.index(of: dateString) else { continue }
                filteredDateList.remove(at: index)
                filteredCountList.remove(at: index)
            }
        }
        self.tableView.reloadData()
    }
    
}

