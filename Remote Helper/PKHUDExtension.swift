//
//  PKHUDExtension.swift
//  Remote Helper
//
//  Created by venj on 5/30/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import PKHUD

extension PKHUD {
    func showHudWithMessage(_ message: String, onView view: UIView? = nil, hideAfterDelay delay: Double = 1.0) {
        contentView = PKHUDTextView(text: message)
        show(onView: view ?? AppDelegate.shared.window)
        hide(afterDelay: delay)
    }

    @discardableResult func showHUD(onView view: UIView? = nil) -> PKHUD {
        contentView = PKHUDProgressView()
        show(onView: view ?? AppDelegate.shared.window)
        return self
    }
}

