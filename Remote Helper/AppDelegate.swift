//
//  AppDelegate.swift
//  Video Player
//
//  Created by Venj Chu on 15/11/4.
//  Copyright © 2015年 Home. All rights reserved.
//

import UIKit
import Alamofire
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureAlamofireManager()
        observeCloudKeyValueChanges()

        return true
    }

    private func observeCloudKeyValueChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    @objc
    private func storeDidChange(_ notification: NSNotification) {
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
        } else {
            defaults.set(remoteViewedTitles, forKey: key)
        }
        defaults.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name.viewedTitlesDidChangeNotification, object: nil)
    }

    // MARK: - Alamofire Manager

    private func configureAlamofireManager() {
        let manager = SessionManager.default
        manager.session.configuration.timeoutIntervalForRequest = REQUEST_TIME_OUT
        manager.delegate.sessionDidReceiveChallenge = { session, challenge in
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?

            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                disposition = .useCredential
                credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            } else if challenge.previousFailureCount > 0 {
                disposition = .cancelAuthenticationChallenge
            } else {
                credential = manager.session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                if credential != nil {
                    disposition = .useCredential
                }
            }
            return (disposition, credential)
        }
    }
}
