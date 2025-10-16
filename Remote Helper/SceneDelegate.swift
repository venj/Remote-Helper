import UIKit
import PasscodeLock
import Kingfisher

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    lazy var passcodeLockPresenter: PasscodeLockPresenter = {
        let configuration = PasscodeLockConfiguration()
        let presenter = PasscodeLockPresenter(configuration: configuration)
        presenter.passcodeLockVC.mainColor = Helper.shared.mainThemeColor()
        return presenter
    }()


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
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

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIBackgroundTaskIdentifier(_ input: Int) -> UIBackgroundTaskIdentifier {
    return UIBackgroundTaskIdentifier(rawValue: input)
}
