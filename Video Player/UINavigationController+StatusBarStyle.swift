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
        guard self.topViewController != nil else { return .Default }
        return (self.topViewController!.preferredStatusBarStyle());
    }
}
