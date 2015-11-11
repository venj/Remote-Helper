//
//  UINavigationController+StatusBarStyle.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/6.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit

extension UINavigationController {
    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        if presentingViewController != nil {
            // When being presented, presentingViewController should always not nil.
            return presentingViewController!.preferredStatusBarStyle()
        }
        else {
            guard topViewController != nil else { return .Default }
            return topViewController!.preferredStatusBarStyle()
        }
    }
}
