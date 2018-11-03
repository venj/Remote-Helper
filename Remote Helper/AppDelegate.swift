//
//  AppDelegate.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/4.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import PasscodeLock
import Alamofire
import CoreData
import CloudKit
import Kingfisher

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {
    var window: UIWindow?
    var fileListViewController: WebContentTableViewController!
    lazy var tabbarController = UITabBarController()

    let bundleIdentifier = Bundle.main.bundleIdentifier!
    @available(iOS 9.0, *)
    lazy var addressItem: UIApplicationShortcutItem = UIApplicationShortcutItem(type: "\(bundleIdentifier).openaddresses", localizedTitle: "Addresses", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "shortcut_addresses"), userInfo: nil)
    @available(iOS 9.0, *)
    lazy var dyttItem: UIApplicationShortcutItem = UIApplicationShortcutItem(type: "\(bundleIdentifier).opendytt", localizedTitle: "DYTT", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "shortcut_dytt"), userInfo: nil)
    @available(iOS 9.0, *)
    lazy var kittenItem: UIApplicationShortcutItem = UIApplicationShortcutItem(type: "\(bundleIdentifier).kittensearch", localizedTitle: "Kitten" , localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "shortcut_kittensearch"), userInfo: nil)
    @available(iOS 9.0, *)
    lazy var torrentItem = UIApplicationShortcutItem(type: "\(bundleIdentifier).opentorrents", localizedTitle: "Torrents", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "shortcut_torrents"), userInfo: nil)

    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    lazy var passcodeLockPresenter: PasscodeLockPresenter = {
        let configuration = PasscodeLockConfiguration()
        let presenter = PasscodeLockPresenter(configuration: configuration)
        presenter.passcodeLockVC.mainColor = Helper.shared.mainThemeColor()
        return presenter
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        // Configure Alamofire Request Manager
        configureAlamofireManager()
        // Theming
        updateTheme()

        configureTabbarController()
        window?.rootViewController = tabbarController
        // Passcode Lock
        passcodeLockPresenter.presentPasscodeLock()
        // Quick actions
        if #available(iOS 9.0, *) {
            createActionMenus()
        }
        // iCloud Key-Value Setup
        NotificationCenter.default.addObserver(self, selector: #selector(storeDidChange(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
        NSUbiquitousKeyValueStore.default.synchronize()
        // Window
        self.window?.makeKeyAndVisible()
        return true
    }

    func updateTheme() {
        // Global tint
        window?.tintColor = Helper.shared.mainThemeColor()

        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.tintColor = .white
        navBarAppearance.barTintColor = Helper.shared.mainThemeColor()
        navBarAppearance.titleTextAttributes = [.foregroundColor : UIColor.white]

        let searchBarAppearance = UISearchBar.appearance()
        searchBarAppearance.tintColor = UIColor.white
        searchBarAppearance.barTintColor = Helper.shared.mainThemeColor()
        
        UISwitch.appearance().onTintColor = Helper.shared.mainThemeColor()
        UIProgressView.appearance().progressTintColor = Helper.shared.mainThemeColor()
    }

    @objc
    func storeDidChange(_ notification: NSNotification) {
        let key = ViewedTitlesKey
        let defaults = UserDefaults.standard
        let cloudDefaults = NSUbiquitousKeyValueStore.default
        guard let remoteViewedTitles = cloudDefaults.object(forKey: key) as? [String] else { return }
        if let localViewedTitles = defaults.value(forKey: key) as? [String] {
            let updatedViewdTitles = [String](Set<String>(localViewedTitles + remoteViewedTitles))
            defaults.set(updatedViewdTitles, forKey: key)
            if updatedViewdTitles.count != remoteViewedTitles.count {
                cloudDefaults.set(updatedViewdTitles, forKey: key)
                cloudDefaults.synchronize()
            }
        }
        else {
            defaults.set(remoteViewedTitles, forKey: key)
        }
        defaults.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name.viewedTitlesDidChangeNotification, object: nil)
    }

    func configureTabbarController() {
        // FileList
        fileListViewController = WebContentTableViewController()
        fileListViewController.title = NSLocalizedString("Addresses", comment: "Addresses")
        fileListViewController.tabBarItem.image = UIImage(named: "tab_cloud")
        let fileListNavigationController = UINavigationController(rootViewController: fileListViewController)
        // DYTT
        let resourceSiteViewController = ResourceSiteCatagoriesViewController()
        resourceSiteViewController.title = NSLocalizedString("DYTT", comment: "DYTT")
        resourceSiteViewController.tabBarItem.image = UIImage(named: "tab_dytt")
        let resourceSiteNavigationController = UINavigationController(rootViewController: resourceSiteViewController)

        // torrent list
        if Configuration.shared.hasTorrentServer {
            let torrentListViewController = VPTorrentsListViewController()
            torrentListViewController.title = NSLocalizedString("Torrents", comment: "Torrents")
            torrentListViewController.tabBarItem.image = UIImage(named: "tab_torrents")
            let torrentListNavigationController = UINavigationController(rootViewController: torrentListViewController)
            tabbarController.viewControllers = [fileListNavigationController, torrentListNavigationController, resourceSiteNavigationController]
        }
        else {
            tabbarController.viewControllers = [fileListNavigationController, resourceSiteNavigationController]
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Quick actions
        if #available(iOS 9.0, *) {
            createActionMenus()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Passcode Lock
        passcodeLockPresenter.presentPasscodeLock()

        if UserDefaults.standard.bool(forKey: ClearCacheOnExitKey) == true {
            let app = UIApplication.shared
            var identifier: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
            identifier = app.beginBackgroundTask(expirationHandler: { () -> Void in
                app.endBackgroundTask(convertToUIBackgroundTaskIdentifier(identifier.rawValue))
                identifier = UIBackgroundTaskIdentifier.invalid
            })
            ImageCache.default.clearDiskCache {
                app.endBackgroundTask(convertToUIBackgroundTaskIdentifier(identifier.rawValue))
                identifier = UIBackgroundTaskIdentifier.invalid
            }
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    @available(iOS 9.0, *)
    func createActionMenus() {
        if window?.rootViewController?.traitCollection.forceTouchCapability == .available {
            if Configuration.shared.hasTorrentServer {
                UIApplication.shared.shortcutItems = [addressItem, torrentItem, dyttItem, kittenItem]
            }
            else {
                UIApplication.shared.shortcutItems = [addressItem, dyttItem, kittenItem]
            }
        }
    }

    @available(iOS 9.0, *)
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        if shortcutItem.type == "\(bundleIdentifier).openaddresses" {
            tabbarController.selectedIndex = 0
        }
        else if shortcutItem.type == "\(bundleIdentifier).opentorrents" {
            tabbarController.selectedIndex = 1
        }
        else if shortcutItem.type == "\(bundleIdentifier).opendytt" {
            tabbarController.selectedIndex = 2
        }
        else if shortcutItem.type == "\(bundleIdentifier).kittensearch" {
            Helper.shared.showTorrentSearchAlertInViewController(window?.rootViewController)
        }
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

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.appcoda.CoreDataDemo" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Remote-Helper", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("remote-helper.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "me.venj.Remote-Helper", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIBackgroundTaskIdentifier(_ input: Int) -> UIBackgroundTaskIdentifier {
	return UIBackgroundTaskIdentifier(rawValue: input)
}
