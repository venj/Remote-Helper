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
import AFNetworking
import PasscodeLock

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
        // Reachability
        AFNetworkReachabilityManager.sharedManager().startMonitoring()
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

    func applicationDidEnterBackground(application: UIApplication) {
        passcodeLockPresenter.presentPasscodeLock()
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
        AFNetworkReachabilityManager.sharedManager().stopMonitoring()
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
}