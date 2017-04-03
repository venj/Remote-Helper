//
//  ResourcePageViewController.swift
//  Remote Helper
//
//  Created by 朱文杰 on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import UIKit
import Alamofire

class ResourcePageViewController: UITableViewController {
    let CellIdentifier = "ResourcePageTableCell"
    var page: Page? = nil {
        didSet {
            guard let page = page else { return }
            let bangumiLinksCount = bangumiLinks.count
            bangumiLinks.append(contentsOf: page.bangumiLinks)
            let indexPaths = (bangumiLinksCount..<bangumiLinksCount + page.bangumiLinks.count).map { IndexPath(row: $0, section: 0) }
            self.tableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.top)
        }
    }

    var bangumiLinks: [[String: String]] = []

    var spinner : UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray) {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.defaultHelper.mainThemeColor()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
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
        return bangumiLinks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }

        let index = indexPath.row
        let bangumi = bangumiLinks[index]
        cell.textLabel?.text = bangumi["title"]
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let bangumi = bangumiLinks[index]
        var link = bangumi["link"]!
        if !link.contains("http://") {
            link = "http://www.dygod.net" + link
        }
        process(link)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return page?.isLastPage == true ? nil : spinner
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == (bangumiLinks.count - 1) { // when showing last item
            if page?.isLastPage == false {
                loadNextPage()
            }
        }
    }

    func process(_ link: String) {
        let hud = Helper.defaultHelper.showHUD()
        let request = Alamofire.request(link)
        request.responseString { [weak self] response in
            hud.hide()
            guard let `self` = self else { return }
            guard let data = response.data else { return }
            let bangumi = Bangumi.parse(data: data, isGBK: true)
            // Show bangumi
            if bangumi?.links.count == 0 {
                let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: NSLocalizedString("This program is online only, now available for download.", comment: "This program is online only, now available for download."), preferredStyle: .alert)
                let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            }
            else {
                let bvc = BangumiViewController()
                bvc.bangumi = bangumi
                self.navigationController?.pushViewController(bvc, animated: true)
            }
        }
    }

    func loadNextPage() {
        guard let nextPageLink = page?.nextPageLink else { return }
        spinner.startAnimating()
        let request = Alamofire.request(nextPageLink)
        request.responseData { [weak self] response in
            guard let `self` = self else { return }
            self.spinner.stopAnimating()
            if response.result.isFailure { return } // Fail
            guard let data = response.result.value else { return }
            guard let page = Page.parse(data: data, isGBK: true) else { return }
            self.page = page
        }
    }
}
