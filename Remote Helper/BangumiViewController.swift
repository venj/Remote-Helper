//
//  BangumiViewController.swift
//  Remote Helper
//
//  Created by 朱文杰 on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import UIKit

class BangumiViewController: UITableViewController {
    let CellIdentifier = "BangumiTableCell"
    var bangumi: Bangumi? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        title = bangumi?.title
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
        return bangumi?.links.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }

        let index = indexPath.row
        let link = bangumi?.links[index]
        cell.textLabel?.text = link // TODO: Make it human-readable.
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let link = bangumi?.links[index]
        //TODO: Do something with links
    }

}
