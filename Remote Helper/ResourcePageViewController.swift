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
            bangumiLinks.append(contentsOf: page.bangumiLinks)
        }
    }

    var bangumiLinks: [[String: String]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    func process(_ link: String) {
        let request = Alamofire.request(link)
        request.responseString { [weak self] response in
            guard let `self` = self else { return }
            guard let data = response.data else { return }
            let bangumi = Bangumi.parse(data: data, isGBK: true)
            // Show bangumi
            let bvc = BangumiViewController()
            bvc.bangumi = bangumi
            self.navigationController?.pushViewController(bvc, animated: true)
        }
    }

}
