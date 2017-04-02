//
//  ResourceSiteCatagoriesViewController.swift
//  Remote Helper
//
//  Created by 朱文杰 on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import UIKit
import Alamofire

class ResourceSiteCatagoriesViewController: UITableViewController {
    let CellIdentifier = "ResourceSiteCatagoriesTableCell"

    var siteName: String = "电影天堂"
    var catagoryLinks: [[String: String]] = [["name": "国内电影", "link": "http://www.dygod.net/html/gndy/china/index.html"],
                                             ["name": "欧美电影", "link": "http://www.dygod.net/html/gndy/oumei/index.html"],
                                             ["name": "日韩电影", "link": "http://www.dygod.net/html/gndy/rihan/index.html"],
                                             ["name": "华语电视", "link": "http://www.dygod.net/html/tv/hytv/index.html"],
                                             ["name": "日韩电视", "link": "http://www.dygod.net/html/tv/rihantv/index.html"],
                                             ["name": "欧美电视", "link": "http://www.dygod.net/html/tv/oumeitv/index.html"],
                                             ["name": "最新综艺", "link": "http://www.dygod.net/html/zongyi2013/index.html"],
                                             ["name": "旧版综艺", "link": "http://www.dygod.net/html/zongyijiemu2009/index.html"],
                                             ["name": "动漫资源", "link": "http://www.dygod.net/html/dongman/index.html"],
                                             ["name": "游戏下载", "link": "http://www.dygod.net/html/game/index.html"],
                                             ["name": "手机电影", "link": "http://www.dygod.net/html/3gp/3gpmovie/index.html"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = siteName
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        process(link)
    }

    func process(_ link: String) {
        let request = Alamofire.request(link)
        request.responseData { [weak self] response in
            guard let `self` = self else { return }
            if response.result.isFailure { return } // Fail
            guard let data = response.result.value else { return }
            guard let page = Page.parse(data: data, isGBK: true) else { return }
            let rpvc = ResourcePageViewController()
            rpvc.bangumiLinks = page.bangumiLinks
            self.navigationController?.pushViewController(rpvc, animated: true)
        }
    }
}
