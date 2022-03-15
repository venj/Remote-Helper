//
//  VPTorrentListViewController.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/3.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import Alamofire
import SwiftEntryKit
import Kingfisher
import Lantern

class VPTorrentsListViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    let CellIdentifier = "VPTorrentsListViewCell"
    let localizedStatusStrings: [String: String] = ["completed" : NSLocalizedString("completed", comment: "completed"),
        "waiting" : NSLocalizedString("waiting", comment:"waiting"),
        "downloading" : NSLocalizedString("downloading", comment:"downloading"),
        "failed or unknown" : NSLocalizedString("failed or unknown", comment: "failed or unknown")]

    var datesDict: [String: [Any]] = [:] {
        didSet {
            dateList = datesDict.count == 0 ? [] : datesDict["items"] as! [String]
            countList = datesDict.count == 0 ? [] : datesDict["count"] as! [Int]
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

//    var mwPhotos: [Media] {
//        return photos.compactMap { photo in
//            guard let url = URL(string: Configuration.shared.baseLink) else { return nil }
//            let fullURL = url.appendingPathComponent(photo)
//            let p = Media(url: fullURL)
//            p.caption = fullURL.lastPathComponent
//            return p
//        }
//    }
    var collapseDetailViewController: Bool = true

    var photos: [String] = []

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
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        // Peek
        if #available(iOS 9.0, *), traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }

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
            if #available(iOS 13.0, *) {
                cell.textLabel?.textColor = .secondaryLabel
            } else {
                cell.textLabel?.textColor = .gray
            }
        }
        else {
            if #available(iOS 13.0, *) {
                cell.textLabel?.textColor = .label
            } else {
                cell.textLabel?.textColor = .black
            }
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


    var mediaStartIndex = 0

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowTorrentsSegue" {
            if let nav = segue.destination as? UINavigationController,
                let lantern = nav.topViewController as? Lantern,
                let indexPath = tableView.indexPathForSelectedRow {
                // Update currentSelectedTitle
                let list = !searchController.isActive ? dateList : filteredDateList
                currentSelectedTitle = list[indexPath.row]
                if Helper.shared.showCellularHUD() { return }
                if let cell = tableView.cellForRow(at: indexPath), let title = cell.textLabel?.text {
                    cell.textLabel?.textColor = UIColor.gray
                    viewedTitles.insert(title)
                }

                lantern.numberOfItems = { [weak self] in
                    guard let self = self else { return 0 }
                    return self.photos.count
                }
                
                lantern.reloadCellAtIndex = { [weak self] context in
                    guard let self = self else { return }
                    let lanternCell = context.cell as? LanternImageCell
                    self.configureLanternCell(lanternCell, index: context.index)
                }
                
                lantern.pageIndex = mediaStartIndex
            }
        }
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        print("image tapped!")
        if let cell = sender.view as? LanternImageCell, let nav = cell.lantern?.navigationController {
            print("nav: \(nav)")
        }
    }

    @objc func configureLanternCell(_ lanternCell: LanternImageCell?, index: Int) {
        guard let url = URL(string: Configuration.shared.baseLink) else { return }
        let fullURL = url.appendingPathComponent(self.photos[index])
        lanternCell?.imageView.kf.setImage(with: fullURL, placeholder: nil, options: nil, progressBlock: nil) { _ in
            lanternCell?.setNeedsLayout()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        lanternCell?.onSingleTap(tap)
    }
    
    @objc func photoPreloadFinished(_ notification: Notification) {
        //print("Photo load fihished! \(notification.object)")
    }

    @objc func showNoMorePhotosHUD(_ notification: Notification) {
        Helper.shared.showNote(withMessage: NSLocalizedString("No more photos.", comment: "No more photos."), type: .warning)
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let list = !searchController.isActive ? dateList : filteredDateList
        currentSelectedTitle = list[(indexPath as NSIndexPath).row]
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
            if index > self.photos.count { index = self.photos.count }
            if let cell = tableView.cellForRow(at: indexPath), let title = cell.textLabel?.text {
                cell.textLabel?.textColor = UIColor.gray
                self.viewedTitles.insert(title)
            }
            // self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.showPhotoBrowser(forIndexPath: indexPath, initialPhotoIndex: index - 1)
        }
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    //MARK: - Action
    @objc func showKitten() {
        Helper.shared.showTorrentSearchAlertInViewController(self.navigationController!)
    }

    @objc func hashTorrent() {
        guard let base64FileName = photos[currentPhotoIndex].base64String() else { return }
        Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Loading...", comment: "Loading..."))
        let request = Alamofire.request(Configuration.shared.hashTorrent(withName: base64FileName))
        request.responseJSON { [weak self] response in
            guard let self = self else { return }
            if response.result.isSuccess {
                SwiftEntryKit.dismiss()
                guard let responseObject = response.result.value as? [String: Any] else { return }
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
        let request = Alamofire.request(Configuration.shared.searchPath(withKeyword: date))
        request.responseJSON { [weak self] response in
            guard let `self` = self else { return }
            SwiftEntryKit.dismiss()
            if response.result.isSuccess {
                guard let photos = response.result.value as? [String] else { return }
                self.photos = photos
                self.mediaStartIndex = index
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
        let request = Alamofire.request(Configuration.shared.torrentsListPath)
        request.responseJSON { [weak self] response in
            guard let `self` = self else { return }
            if response.result.isSuccess {
                self.datesDict = response.result.value as! [String: [Any]]
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

    // Attach Progress View to a view (PhotoBrowser)
    // Works well on iOS 11, but not old iOS versions.
    func attachProgressView(to aView: UIView) {
        self.edgesForExtendedLayout = []
        let newView = attachedProgressView
        newView.removeFromSuperview()
        aView.addSubview(newView)
        newView.translatesAutoresizingMaskIntoConstraints = false
        let height: CGFloat = 2.0
        if #available(iOS 11.0, *) {
            let guide = aView.safeAreaLayoutGuide
            newView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
            newView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
            newView.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
            newView.heightAnchor.constraint(equalToConstant: height).isActive = true
        } else {
            NSLayoutConstraint(item: newView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: view, attribute: .bottom,
                               multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: newView,
                               attribute: .leading,
                               relatedBy: .equal, toItem: view,
                               attribute: .leading,
                               multiplier: 1.0,
                               constant: 0).isActive = true
            NSLayoutConstraint(item: newView, attribute: .trailing,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: .trailing,
                               multiplier: 1.0,
                               constant: 0).isActive = true

            newView.heightAnchor.constraint(equalToConstant: height).isActive = true
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

@available(iOS 9.0, *)
extension VPTorrentsListViewController : UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) ,
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        previewingIndexPath = indexPath
        if let title = cell.textLabel?.text {
            if #available(iOS 13.0, *) {
                cell.textLabel?.textColor = .secondaryLabel
            } else {
                cell.textLabel?.textColor = .gray
            }
            viewedTitles.insert(title)
        }
        let list = !searchController.isActive ? dateList : filteredDateList
        currentSelectedTitle = list[(indexPath as NSIndexPath).row]
        guard let date = list[indexPath.row].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else { return nil }
        // Reset photos
        photos = []
        let lantern = Lantern()

        let request = Alamofire.request(Configuration.shared.searchPath(withKeyword: date))
        request.responseJSON { [weak self] response in
            guard let `self` = self else { return }
            if response.result.isSuccess {
                guard let photos = response.result.value as? [String] else { return }
                self.photos = photos
                
                lantern.numberOfItems = { [weak self] in
                    guard let self = self else { return 0 }
                    return self.photos.count
                }
                
                lantern.reloadCellAtIndex = { [weak self] context in
                    guard let self = self else { return }
                    let lanternCell = context.cell as? LanternImageCell
                    self.configureLanternCell(lanternCell, index: context.index)
                }

                lantern.reloadData()
            }
        }

        previewingContext.sourceRect = cell.frame
        return lantern
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: false)

        if let indexPath = previewingIndexPath,
            let cell = tableView.cellForRow(at: indexPath),
            let title = cell.textLabel?.text {
            if #available(iOS 13.0, *) {
                cell.textLabel?.textColor = .secondaryLabel
            } else {
                cell.textLabel?.textColor = .gray
            }
            viewedTitles.insert(title)
        }

        (viewControllerToCommit as? Lantern)?.reloadData()
    }
}
