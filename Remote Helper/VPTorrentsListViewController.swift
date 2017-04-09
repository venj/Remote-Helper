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

class VPTorrentsListViewController: UITableViewController, MWPhotoBrowserDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate {
    let CellIdentifier = "VPTorrentsListViewCell"
    let localizedStatusStrings: [String: String] = ["completed" : NSLocalizedString("completed", comment: "completed"),
        "waiting" : NSLocalizedString("waiting", comment:"waiting"),
        "downloading" : NSLocalizedString("downloading", comment:"downloading"),
        "failed or unknown" : NSLocalizedString("failed or unknown", comment: "failed or unknown")]

    var datesList: [String]!
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
    var filteredDatesList: [String]!
    var searchController: UISearchDisplayController!
    var cloudItem: UIBarButtonItem!
    lazy var hashItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(named:"magnet"), style: .plain, target: self, action: #selector(hashTorrent))
        return item
    }()
    lazy var searchItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "🔍", style: .plain, target: self, action: #selector(showSearch))

        return item
    }()
    lazy var kittenItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "🐱", style: .plain, target: self, action: #selector(showKitten))
        return item
    }()
    var currentSelectedIndexPath: IndexPath?

    var viewedTitles: [String] {
        get {
            guard let titles = UserDefaults.standard.array(forKey: "ViewdTitles") as? [String] else { return [] }
            return titles
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ViewdTitles")
            UserDefaults.standard.synchronize()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Torrents", comment: "Torrents")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(loadTorrentList(_:)))
        let searchBar = UISearchBar(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 44.0))
        searchBar.keyboardType = .numbersAndPunctuation
        searchBar.delegate = self
        searchBar.autoresizingMask = .flexibleWidth

        searchController = UISearchDisplayController(searchBar: searchBar, contentsController: self)
        searchController.delegate = self
        searchController.searchResultsDataSource = self
        searchController.searchResultsDelegate = self
        tableView.tableHeaderView = searchBar
        self.loadTorrentList(nil)

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        tableView.tintColor = Helper.shared.mainThemeColor()

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        NotificationCenter.default.addObserver(self, selector: #selector(photoPreloadFinished(_:)), name: NSNotification.Name(rawValue: MWPHOTO_LOADING_DID_END_NOTIFICATION), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showNoMorePhotosHUD(_:)), name: NSNotification.Name(rawValue: MWPHOTO_NO_MORE_PHOTOS_NOTIFICATION), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        let list = tableView == self.tableView ? self.datesList : self.filteredDatesList
        if (list != nil) {
            return 1
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.tableView) {
            return self.datesList.count
        }
        else {
            return self.filteredDatesList.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }
        cell.accessoryType = .detailDisclosureButton
        let list = tableView == self.tableView ? self.datesList : self.filteredDatesList
        let title = list?[(indexPath as NSIndexPath).row] ?? ""
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
            if !viewedTitles.contains(title) {
                viewedTitles.append(title)
            }
            // Clear up useless items
            var filteredViewedTitles = viewedTitles
            viewedTitles.forEach {
                if !datesList.contains($0) {
                    guard let i = filteredViewedTitles.index(of: $0) else { return }
                    filteredViewedTitles.remove(at: i)
                }
            }
            viewedTitles = filteredViewedTitles
        }
        self.showPhotoBrowser(forTableView: tableView, atIndexPath: indexPath)
    }

    func photoPreloadFinished(_ notification: Notification) {
        //print("Photo load fihished! \(notification.object)")
    }

    func showNoMorePhotosHUD(_ notification: Notification) {
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
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK") , style: .default) { [unowned self] _ in
            var index = 1
            if let i = Int((alertController.textFields?[0].text)!) { index = i }
            if index < 1 { index = 1 }
            self.showPhotoBrowser(forTableView: tableView, atIndexPath: indexPath, initialPhotoIndex: index - 1)
        }
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.view.tintColor = Helper.shared.mainThemeColor()
        present(alertController, animated: true, completion: nil)
    }

    //MARK: - SearchDisplayController Delegate
    func searchDisplayController(_ controller: UISearchDisplayController, shouldReloadTableForSearch searchString: String?) -> Bool {
        guard let unwrappedSearchString = searchString else { return false }
        filteredDatesList = datesList
        for dateString in datesList {
            if dateString.range(of: unwrappedSearchString) == nil {
                guard let index = filteredDatesList.index(of: dateString) else { continue }
                filteredDatesList.remove(at: index)
            }
        }
        searchDisplayController?.searchResultsTableView.reloadData()
        return true
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
        photoBrowser.navigationItem.rightBarButtonItems  = [kittenItem, searchItem, hashItem]
    }

    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, titleForPhotoAt index: UInt) -> String! {
        guard let indexPath = currentSelectedIndexPath else { return nil }
        let cellTitle = tableView.cellForRow(at: indexPath)?.textLabel?.text
        if cellTitle == nil {
            return nil
        }
        else {
            return "\(cellTitle!) (\(currentPhotoIndex + 1)/\(photos.count))"
        }
    }

    //MARK: - Action
    func showSearch() {
        Helper.shared.showTorrentSearchAlertInViewController(self.navigationController!)
    }

    func showKitten() {
        Helper.shared.showTorrentSearchAlertInViewController(self.navigationController!, forKitten: true)
    }

    func hashTorrent() {
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
    func showPhotoBrowser(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath, initialPhotoIndex index: Int = 0) {
        let list = tableView == self.tableView ? self.datesList : self.filteredDatesList
        guard (indexPath as NSIndexPath).row < (list?.count)! else { return }
        if Helper.shared.showCellularHUD() { return }
        searchController.searchBar.resignFirstResponder()
        guard let date = list?[(indexPath as NSIndexPath).row].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else { return }
        let hud = Helper.shared.showHUD()
        let request = Alamofire.request(Helper.shared.searchPath(withKeyword: date))
        request.responseJSON { [unowned self] response in
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

    func loadTorrentList(_ sender: Any?) {
        if Helper.shared.showCellularHUD() { return }
        let hud = Helper.shared.showHUD()
        navigationItem.rightBarButtonItem?.isEnabled = false
        let request = Alamofire.request(Helper.shared.torrentsListPath())
        request.responseJSON { [unowned self] response in
            if response.result.isSuccess {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.datesList = response.result.value as! [String]
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
}
