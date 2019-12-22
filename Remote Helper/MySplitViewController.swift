//
//  MySplitViewController.swift
//  Remote Helper
//
//  Created by 朱文杰 on 10/31/19.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class MySplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.preferredDisplayMode = .allVisible
    }

    #if !targetEnvironment(macCatalyst)
    func splitViewController(
             _ splitViewController: UISplitViewController,
             collapseSecondary secondaryViewController: UIViewController,
             onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    #endif
}
