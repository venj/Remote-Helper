//
//  UINavigationController+StatusBarStyle.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/6.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit

extension UINavigationController {
    override open var preferredStatusBarStyle : UIStatusBarStyle {
        if let presentingViewController = presentingViewController {
            return presentingViewController.preferredStatusBarStyle
        }
        else {
            guard let topViewController = topViewController else { return .default }
            return topViewController.preferredStatusBarStyle
        }
    }
}
