//
//  BangumiViewController.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import UIKit
import PKHUD

class BangumiViewController: UITableViewController {
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

        title = bangumi?.title
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

        let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: link, preferredStyle: .alert)
        let copyAction = UIAlertAction(title: NSLocalizedString("Copy", comment: "Copy"), style: .default) { (action) in
            UIPasteboard.general.string = link
            Helper.shared.showHudWithMessage(NSLocalizedString("Copied", comment: "Copied"))
        }
        alert.addAction(copyAction)
        let downloadAction = UIAlertAction(title: NSLocalizedString("Mi", comment: "Mi"), style: .default) { (action) in
            Helper.shared.miDownload(for: link, fallbackIn: self)
        }
        alert.addAction(downloadAction)
        self.present(alert, animated: true, completion: nil)
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
