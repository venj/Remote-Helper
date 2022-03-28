//
//  TransmissionWebViewController.swift
//  Remote Helper
//
//  Created by 朱文杰 on 11/8/19.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class TransmissionWebViewController: WebViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let backItem = UIBarButtonItem(image: UIImage.backButtonIcon(), style: UIBarButtonItem.Style.plain, target: self, action: #selector(goBack(_:)))
        backItem.tintColor = .white
        navigationItem.leftBarButtonItem = backItem
    }

    @objc
    func goBack(_ sender: Any?) {
        if webView.canGoBack {
            webView.goBack()
        }
        else {
            if let _ = presentingViewController {
                Helper.shared.dismissMe(sender)
            }
            else {
                navigationController?.popViewController(animated: true)
            }
        }
    }
}
