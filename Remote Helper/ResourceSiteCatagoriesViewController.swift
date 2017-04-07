//
//  ResourceSiteCatagoriesViewController.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import UIKit
import Alamofire

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

    var catagoryLinks: [[String: String]] = [["name": "最新电影", "link": "http://www.ygdy8.net/html/gndy/dyzz/index.html"],
                                             ["name": "国内电影", "link": "http://www.ygdy8.net/html/gndy/china/index.html"],
                                             ["name": "欧美电影", "link": "http://www.ygdy8.net/html/gndy/oumei/index.html"],
                                             ["name": "日韩电影", "link": "http://www.ygdy8.net/html/gndy/rihan/index.html"],
                                             ["name": "华语电视", "link": "http://www.ygdy8.net/html/tv/hytv/index.html"],
                                             ["name": "日韩电视", "link": "http://www.ygdy8.net/html/tv/rihantv/index.html"],
                                             ["name": "欧美电视", "link": "http://www.ygdy8.net/html/tv/oumeitv/index.html"],
                                             ["name": "最新综艺", "link": "http://www.ygdy8.net/html/zongyi2013/index.html"],
                                             ["name": "旧版综艺", "link": "http://www.ygdy8.net/html/2009zongyi/index.html"],
                                             ["name": "动漫资源", "link": "http://www.ygdy8.net/html/dongman/index.html"],
                                             ["name": "游戏下载", "link": "http://www.ygdy8.net/html/game/index.html"],
                                             ["name": "高分经典", "link": "http://www.ygdy8.net/html/gndy/jddy/20160320/50510.html"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.title = siteName

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.shared.mainThemeColor()
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
    }

    func process(_ title: String, _ link: String) {
        let hud = Helper.shared.showHUD()
        let request = Alamofire.request(link)
        request.responseData { [weak self] response in
            guard let `self` = self else { return }
            hud.hide()
            if response.result.isFailure { return } // Fail
            guard let data = response.result.value else { return }
            guard let page = Page.parse(data: data, pageLink: link, isGBK: true) else { return }

            if page.bangumiLinks.count == 0 {
                let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: "There's no program under this catagory, or catagory failed to load.", preferredStyle: .alert)
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
}
