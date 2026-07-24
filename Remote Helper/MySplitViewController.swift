//
//  MySplitViewController.swift
//  Remote Helper
//
//  Created by 朱文杰 on 10/31/19.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)
/// Pins navigation-bar content to the middle column of the Catalyst window toolbar.
final class SupplementaryNavigationController: UINavigationController {
    func navigationBarNSToolbarSection(
        _ navigationBar: UINavigationBar
    ) -> UINavigationBar.NSToolbarSection {
        return .supplementary
    }
}

/// Pins navigation-bar content to the detail column of the Catalyst window toolbar.
final class ContentNavigationController: UINavigationController {
    func navigationBarNSToolbarSection(
        _ navigationBar: UINavigationBar
    ) -> UINavigationBar.NSToolbarSection {
        return .content
    }
}
#else
// Keep the storyboard classes available on iOS without changing navigation behavior.
final class SupplementaryNavigationController: UINavigationController {}
final class ContentNavigationController: UINavigationController {}
#endif

class MySplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.preferredDisplayMode = .oneBesideSecondary
    }
    
    #if !targetEnvironment(macCatalyst)
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        return .primary
    }

    func splitViewController(
             _ splitViewController: UISplitViewController,
             collapseSecondary secondaryViewController: UIViewController,
             onto primaryViewController: UIViewController) -> Bool
    {
//        if (secondaryViewController.isKind(of: UINavigationController.self)) {
//            return true
//        } else {
//            return false
//        }
        return true
    }
    #endif
}
