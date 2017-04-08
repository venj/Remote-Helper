//
//  BangumiViewController.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import UIKit
import PKHUD
import MWPhotoBrowser

class BangumiViewController: UITableViewController, MWPhotoBrowserDelegate, UIPopoverPresentationControllerDelegate {
    let CellIdentifier = "BangumiTableCell"
    var bangumi: Bangumi? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        navigationController?.toolbar.tintColor = Helper.shared.mainThemeColor()

        title = bangumi?.title ?? ""

        let imagesButton = UIBarButtonItem(title: NSLocalizedString("Images", comment: "Images"), style: .plain, target: self, action: #selector(showImages))
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let infoButton = UIBarButtonItem(title: NSLocalizedString("Infomation", comment: "Infomation"), style: .plain, target: self, action: #selector(showInfo))

        toolbarItems = [imagesButton, spaceItem, infoButton]
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.isToolbarHidden = true
        super.viewWillDisappear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = false
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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bangumi?.links.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }

        let index = indexPath.row
        let link = bangumi?.links[index]
        cell.textLabel?.text = link?.vc_lastPathComponent() // TODO: Make it human-readable.
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let index = indexPath.row
        guard let link = bangumi?.links[index] else { return }
        UIPasteboard.general.string = link

        let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: link, preferredStyle: .alert)

        let miAction = UIAlertAction(title: NSLocalizedString("Mi", comment: "Mi"), style: .default) { (action) in
            Helper.shared.miDownload(for: link, fallbackIn: self)
        }
        alert.addAction(miAction)

        if link.matches("^magnet:") {
            let transmissionAction = UIAlertAction(title: "Transmission", style: .default) { (action) in
                Helper.shared.transmissionDownload(for: link)
            }
            alert.addAction(transmissionAction)
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel)
        alert.addAction(cancelAction)

        alert.view.tintColor = Helper.shared.mainThemeColor()

        self.present(alert, animated: true, completion: nil)
    }


    // MARK: - Actions
    func showImages(_ sender: Any?) {
        let photoBrowser = MWPhotoBrowser(delegate: self)
        photoBrowser?.displayActionButton = false
        photoBrowser?.displayNavArrows = true
        photoBrowser?.zoomPhotosToFill = false
        self.navigationController?.pushViewController(photoBrowser!, animated: true)
    }

    func showInfo(_ sender: Any?) {
        if let info = bangumi?.info {
            let alert = UIAlertController(title: NSLocalizedString("Infomation", comment: "Infomation"), message: info, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            alert.popoverPresentationController?.delegate = self
            alert.view.tintColor = Helper.shared.mainThemeColor()
            present(alert, animated: true) {
                alert.popoverPresentationController?.passthroughViews = nil
            }
        }
        else {
            let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: NSLocalizedString("There's no infomation available.", comment: "There's no infomation available."), preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            alert.view.tintColor = Helper.shared.mainThemeColor()
            present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - UIPopoverPresentationControllerDelegate

    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.barButtonItem = navigationController?.toolbar.items?.last
    }

    // MARK: - MWPhotoBrowserDelegate

    func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(bangumi?.images.count ?? 0)
    }

    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        guard let imageLink = bangumi?.images[Int(index)] else { return nil }
        guard let url = URL(string: imageLink) else { return nil }
        let mwPhoto = MWPhoto(url: url)
        return mwPhoto
    }
}

public extension PKHUD {
    public func setMessage(_ message: String) {
        if let v = contentView as? PKHUDTextView {
            v.titleLabel.text = message
        }
        else {
            contentView = PKHUDTextView(text: message)
        }
    }
}
