//
//  ViewController.swift
//  Remote Helper Mac
//
//  Created by venj on 7/18/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Cocoa
import Alamofire

class SidebarViewController: NSViewController {

    var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension SidebarViewController: NSTableViewDelegate, NSTableViewDataSource {

}
