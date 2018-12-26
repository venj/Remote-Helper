//
//  ResourceSiteCatagoriesViewController.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import UIKit
import Alamofire
import SwiftEntryKit

class ResourceSiteCatagoriesViewController: UITableViewController {
    let CellIdentifier = "ResourceSiteCatagoriesTableCell"

    var siteName: String = "电影天堂"
    /*
    var catagoryLinks: [[String: String]] = [["name": "国内电影", "link": "http://www.dygod.net/html/gndy/china/index.html"],
                                             ["name": "欧美电影", "link": "http://www.dygod.net/html/gndy/oumei/index.html"],
                                             ["name": "日韩电影", "link": "http://www.dygod.net/html/gndy/rihan/index.html"],
                                             ["name": "华语电视", "link": "http://www.dygod.net/html/tv/hytv/index.html"],
                                             ["name": "日韩电视", "link": "http://www.dygod.net/html/tv/rihantv/index.html"],
                                             ["name": "欧美电视", "link": "http://www.dygod.net/html/tv/oumeitv/index.html"],
                                             ["name": "最新综艺", "link": "http://www.dygod.net/html/zongyi2013/index.html"],
                                             //["name": "旧版综艺", "link": "http://www.dygod.net/html/zongyijiemu2009/index.html"],
                                             ["name": "动漫资源", "link": "http://www.dygod.net/html/dongman/index.html"],
                                             ["name": "游戏下载", "link": "http://www.dygod.net/html/game/index.html"],
                                             ["name": "手机电影", "link": "http://www.dygod.net/html/3gp/3gpmovie/index.html"]]
 */

    var catagoryLinks: [[String: String]] = [["name": "最新电影", "link": "http://dytt8.net/html/gndy/dyzz/index.html"],
                                             ["name": "国内电影", "link": "http://dytt8.net/html/gndy/china/index.html"],
                                             ["name": "欧美电影", "link": "http://dytt8.net/html/gndy/oumei/index.html"],
                                             ["name": "日韩电影", "link": "http://dytt8.net/html/gndy/rihan/index.html"],
                                             ["name": "综合电影", "link": "http://dytt8.net/html/gndy/jddy/index.html"],
                                             ["name": "华语电视", "link": "http://dytt8.net/html/tv/hytv/index.html"],
                                             ["name": "日韩电视", "link": "http://dytt8.net/html/tv/rihantv/index.html"],
                                             ["name": "欧美电视", "link": "http://dytt8.net/html/tv/oumeitv/index.html"],
                                             ["name": "最新综艺", "link": "http://dytt8.net/html/zongyi2013/index.html"],
                                             ["name": "旧版综艺", "link": "http://dytt8.net/html/2009zongyi/index.html"],
                                             ["name": "动漫资源", "link": "http://dytt8.net/html/dongman/index.html"],
                                             ["name": "游戏下载", "link": "http://dytt8.net/html/game/index.html"],
                                             ["name": "高分经典", "link": "http://dytt8.net/html/gndy/jddy/20160320/50510.html"]]

    let dyttSearchBase = "http://s.ygdy8.com/plus/so.php?keyword="

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.title = siteName

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        let searchItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search(_:)))
        navigationItem.rightBarButtonItem = searchItem
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return catagoryLinks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }

        let index = indexPath.row
        let catagory = catagoryLinks[index]
        cell.textLabel?.text = catagory["name"]
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let catagory = catagoryLinks[index]
        var link = catagory["link"]!
        if !link.contains("http://") {
            link = "http://www.dygod.net" + link
        }
        let title = catagory["name"] ?? "未分类"
        process(title, link)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func process(_ title: String, _ link: String) {
        Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Loading...", comment: "Loading..."))
        let request = Alamofire.request(link)
        request.responseData { [weak self] response in
            guard let `self` = self else { return }
            SwiftEntryKit.dismiss()
            if !response.result.isSuccess {
                Helper.shared.showNote(withMessage: NSLocalizedString("Network Error", comment: "Network Error"), type:.error)
                return
            }
            if response.result.isFailure { return } // Fail
            guard let data = response.result.value, data.count > 0 else { return }
            guard let page = Page.parse(data: data, pageLink: link, isGBK: true) else { return }

            if page.bangumiLinks.count == 0 {
                let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: NSLocalizedString("There's no program under this catagory, or catagory failed to load.", comment: "There's no program under this catagory, or catagory failed to load."), preferredStyle: .alert)
                let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            }
            else {
                let rpvc = ResourcePageViewController()
                //rpvc.bangumiLinks = page.bangumiLinks
                rpvc.page = page
                rpvc.hidesBottomBarWhenPushed = true
                rpvc.title = title
                self.navigationController?.pushViewController(rpvc, animated: true)
            }
        }
    }

    @objc func search(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: NSLocalizedString("Search DYTT", comment: "Search DYTT"), message: NSLocalizedString("Please enter Movie/TV Show name.", comment: "Please enter film/TV show name."), preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = NSLocalizedString("Movie, TV Show etc.", comment: "Movie, TV Show etc.")
        }
        let searchAction = UIAlertAction(title: NSLocalizedString("Search", comment: "Search"), style: .default) { [weak self] (action) in
            guard let `self` = self else { return }
            guard let keyword = alert.textFields?.first?.text else { return }
            let cfgb18030encoding = CFStringEncodings.GB_18030_2000.rawValue
            let gbkEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfgb18030encoding))
            let gbk = String.Encoding(rawValue: gbkEncoding)
            let searchLink = self.dyttSearchBase + (keyword.percentEncodedString(gbk) ?? "")
            Helper.shared.showProcessingNote(withMessage: NSLocalizedString("Loading...", comment: "Loading..."))
            let request = Alamofire.request(searchLink)
            request.responseData { [weak self] response in
                guard let `self` = self else { return }
                SwiftEntryKit.dismiss()
                if response.result.isFailure { return } // Fail
                guard let data = response.result.value else { return }
                guard let page = SearchPage.parse(data: data, pageLink: searchLink, isGBK: true) else { return }

                if page.bangumiLinks.count == 0 {
                    let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: NSLocalizedString("There's no program under this catagory, or catagory failed to load.", comment: "There's no program under this catagory, or catagory failed to load."), preferredStyle: .alert)
                    let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
                    alert.addAction(action)
                    alert.view.tintColor = Helper.shared.mainThemeColor()
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    let rpvc = ResourcePageViewController()
                    rpvc.page = page
                    rpvc.hidesBottomBarWhenPushed = true
                    rpvc.title = NSLocalizedString("Search", comment: "Search") + ": " + keyword
                    self.navigationController?.pushViewController(rpvc, animated: true)
                }
            }
        }
        alert.addAction(searchAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        alert.view.tintColor = Helper.shared.mainThemeColor()
        present(alert, animated: true, completion: nil)
    }
}
