//
//  AppDelegate.swift
//  Video Player
//
//  Created by 朱文杰 on 15/11/4.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import MMAppSwitcher
import SDWebImage
import MBProgressHUD
import PasscodeLock
import Alamofire

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate, MMAppSwitcherDataSource, UITabBarControllerDelegate {
    var window: UIWindow?
    var fileListViewController: WebContentTableViewController!
    var tabbarController: UITabBarController!
    var xunleiUserLoggedIn: Bool = false

    lazy var passcodeLockPresenter: PasscodeLockPresenter = {
        let configuration = PasscodeLockConfiguration()
        let presenter = PasscodeLockPresenter(mainWindow: self.window, configuration: configuration)
        return presenter
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        // App Swicher
        MMAppSwitcher.sharedInstance().setDataSource(self)
        // Configure Alamofire Request Manager
        configureAlamofireManager()
        // FileList
        fileListViewController = WebContentTableViewController()
        fileListViewController.title = NSLocalizedString("Addresses", comment: "Addresses")
        fileListViewController.tabBarItem.image = UIImage(named: "tab_cloud")
        let fileListNavigationController = UINavigationController(rootViewController: fileListViewController)
        let torrentListViewController = VPTorrentsListViewController()
        torrentListViewController.title = NSLocalizedString("Torrents", comment: "Torrents")
        torrentListViewController.tabBarItem.image = UIImage(named: "tab_torrents")
        let torrentListNavigationController = UINavigationController(rootViewController: torrentListViewController)
        // Tabbar
        tabbarController = UITabBarController()
        tabbarController.delegate = self
        tabbarController.viewControllers = [fileListNavigationController, torrentListNavigationController]
        tabbarController.tabBar.tintColor = Helper.defaultHelper.mainThemeColor()
        window?.rootViewController = tabbarController
        // Passcode Lock
        passcodeLockPresenter.presentPasscodeLock()
        // Window
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        passcodeLockPresenter.presentPasscodeLock()

        let repository = UserDefaultsPasscodeRepository()
        if !repository.hasPasscode {
            MMAppSwitcher.sharedInstance().setNeedsUpdate()
        }

        if UserDefaults.standard.bool(forKey: ClearCacheOnExitKey) == true {
            let app = UIApplication.shared
            var identifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
            identifier = app.beginBackgroundTask(expirationHandler: { () -> Void in
                app.endBackgroundTask(identifier)
                identifier = UIBackgroundTaskInvalid
            })
            SDImageCache.shared().clearDisk(onCompletion: { () -> Void in
                app.endBackgroundTask(identifier)
                identifier = UIBackgroundTaskInvalid
            })
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
    }

    @available(iOS 9.0, *)
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "me.venj.Video-Player.openaddresses" {
            self.tabbarController.selectedIndex = 0
        }
        else if shortcutItem.type == "me.venj.Video-Player.opentorrents" {
            self.tabbarController.selectedIndex = 1
        }
        else if shortcutItem.type == "me.venj.Video-Player.torrentsearch" {
            Helper.defaultHelper.showTorrentSearchAlertInViewController(window?.rootViewController)
        }
    }

    //MARK: - Use as singleton
    class func shared() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    //MARK: - MMAppSwitch
    func viewForCard() -> UIView! {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }

    //MARK: - Alamofire Manager
    func configureAlamofireManager() {
        let manager = SessionManager.default
        manager.session.configuration.timeoutIntervalForRequest = REQUEST_TIME_OUT
        manager.delegate.sessionDidReceiveChallenge = { session, challenge in
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?

            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                disposition = URLSession.AuthChallengeDisposition.useCredential
                credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            } else {
                if challenge.previousFailureCount > 0 {
                    disposition = .cancelAuthenticationChallenge
                } else {
                    credential = manager.session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)

                    if credential != nil {
                        disposition = .useCredential
                    }
                }
            }
            return (disposition, credential)
        }
    }
}
