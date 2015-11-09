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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
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
        // Status Style
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        // Passcode Lock
        passcodeLockPresenter.presentPasscodeLock()
        // Window
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        passcodeLockPresenter.presentPasscodeLock()

        let repository = UserDefaultsPasscodeRepository()
        if !repository.hasPasscode {
            MMAppSwitcher.sharedInstance().setNeedsUpdate()
        }

        if NSUserDefaults.standardUserDefaults().boolForKey(ClearCacheOnExitKey) == true {
            let app = UIApplication.sharedApplication()
            var identifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
            identifier = app.beginBackgroundTaskWithExpirationHandler({ () -> Void in
                app.endBackgroundTask(identifier)
                identifier = UIBackgroundTaskInvalid
            })
            SDImageCache.sharedImageCache().clearDiskOnCompletion({ () -> Void in
                app.endBackgroundTask(identifier)
                identifier = UIBackgroundTaskInvalid
            })
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
        
    }

    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        if shortcutItem.type == "me.venj.Video-Player.openaddresses" {
            self.tabbarController.selectedIndex = 0
        }
        else if shortcutItem.type == "me.venj.Video-Player.opentorrents" {
            self.tabbarController.selectedIndex = 1
        }
    }

    //MARK: - Use as singleton
    class func shared() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }

    //MARK: - MMAppSwitch
    func viewForCard() -> UIView! {
        let view = UIView()
        view.backgroundColor = UIColor.whiteColor()
        return view
    }

    //MARK: - Alamofire Manager
    func configureAlamofireManager() {
        let manager = Manager.sharedInstance
        manager.session.configuration.timeoutIntervalForRequest = REQUEST_TIME_OUT
        manager.delegate.sessionDidReceiveChallenge = { session, challenge in
            var disposition: NSURLSessionAuthChallengeDisposition = .PerformDefaultHandling
            var credential: NSURLCredential?

            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                disposition = NSURLSessionAuthChallengeDisposition.UseCredential
                credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
            } else {
                if challenge.previousFailureCount > 0 {
                    disposition = .CancelAuthenticationChallenge
                } else {
                    credential = manager.session.configuration.URLCredentialStorage?.defaultCredentialForProtectionSpace(challenge.protectionSpace)

                    if credential != nil {
                        disposition = .UseCredential
                    }
                }
            }
            return (disposition, credential)
        }
    }
}