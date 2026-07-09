import UIKit
import PasscodeLock
import Kingfisher

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var shouldPresentPasscodeWhenActive = false
    private var privacyShieldView: UIView?

    #if targetEnvironment(macCatalyst)
    var tripleSplitViewController: UISplitViewController? {
        return window?.rootViewController as? UISplitViewController
    }
    
    var addressesNavController: UINavigationController?
    var addressesDetailController: UIViewController?
    
    var torrentsNavController: UINavigationController?
    var torrentsDetailController: UIViewController?
    
    var dyttNavController: UINavigationController?
    var dyttDetailController: UIViewController?
    #endif

    var tabBarController: UITabBarController? {
        #if targetEnvironment(macCatalyst)
        return nil
        #else
        return window?.rootViewController as? UITabBarController
        #endif
    }

    var addressesSplitViewController: UISplitViewController? {
        return tabBarController?.children.first { $0.restorationIdentifier == "AddressesSplitViewController" } as? UISplitViewController
    }

    var torrentsSplitViewController: UISplitViewController? {
        return tabBarController?.children.first { $0.restorationIdentifier == "TorrentsSplitViewController" } as? UISplitViewController
    }

    var dyttSplitViewController: UISplitViewController? {
        return tabBarController?.children.first { $0.restorationIdentifier == "DYTTSplitViewController" } as? UISplitViewController
    }

    var fileListViewController: WebContentTableViewController? {
        #if targetEnvironment(macCatalyst)
        return findViewController(ofType: WebContentTableViewController.self, from: addressesNavController)
        #else
        return findViewController(ofType: WebContentTableViewController.self, from: addressesSplitViewController)
        #endif
    }

    let bundleIdentifier = Bundle.main.bundleIdentifier!

    lazy var addressItem: UIApplicationShortcutItem = UIApplicationShortcutItem(type: "\(bundleIdentifier).openaddresses", localizedTitle: "Addresses", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "shortcut_addresses"), userInfo: nil)
    lazy var dyttItem: UIApplicationShortcutItem = UIApplicationShortcutItem(type: "\(bundleIdentifier).opendytt", localizedTitle: "DYTT", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "shortcut_dytt"), userInfo: nil)
    lazy var kittenItem: UIApplicationShortcutItem = UIApplicationShortcutItem(type: "\(bundleIdentifier).kittensearch", localizedTitle: "Kitten", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "shortcut_kittensearch"), userInfo: nil)
    lazy var torrentItem: UIApplicationShortcutItem = UIApplicationShortcutItem(type: "\(bundleIdentifier).opentorrents", localizedTitle: "Torrents", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "shortcut_torrents"), userInfo: nil)

    static var active: SceneDelegate? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let foreground = scenes.first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }) {
            return foreground.delegate as? SceneDelegate
        }
        return scenes.first?.delegate as? SceneDelegate
    }

    static var activeWindow: UIWindow? {
        return active?.window
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        applyTheme()
        window?.tintColor = Helper.shared.mainThemeColor()

        #if targetEnvironment(macCatalyst)
        if let tabVC = window?.rootViewController as? UITabBarController,
           let controllers = tabVC.viewControllers {
            
            if controllers.count > 0, let split = controllers[0] as? UISplitViewController {
                addressesNavController = split.viewControllers.first as? UINavigationController
                addressesDetailController = split.viewControllers.count > 1 ? split.viewControllers[1] : nil
            }
            if controllers.count > 1, let split = controllers[1] as? UISplitViewController {
                torrentsNavController = split.viewControllers.first as? UINavigationController
                torrentsDetailController = split.viewControllers.count > 1 ? split.viewControllers[1] : nil
            }
            if controllers.count > 2, let split = controllers[2] as? UISplitViewController {
                dyttNavController = split.viewControllers.first as? UINavigationController
                dyttDetailController = split.viewControllers.count > 1 ? split.viewControllers[1] : nil
            }
            
            let sidebarVC = SidebarViewController()
            sidebarVC.delegate = self
            
            let tripleSplit = UISplitViewController(style: .tripleColumn)
            tripleSplit.preferredDisplayMode = .twoBesideSecondary
            tripleSplit.setViewController(sidebarVC, for: .primary)
            
            if let nav = addressesNavController {
                tripleSplit.setViewController(nav, for: .supplementary)
            }
            if let detail = addressesDetailController {
                tripleSplit.setViewController(detail, for: .secondary)
            }
            
            window?.rootViewController = tripleSplit
        }
        #else
        if let tabBarController {
            tabBarController.viewControllers?.forEach { controller in
                if let splitController = controller as? MySplitViewController {
                    splitController.delegate = splitController
                }
            }
        }
        #endif

        createActionMenus()

        window?.makeKeyAndVisible()
        shouldPresentPasscodeWhenActive = true

        if let shortcutItem = connectionOptions.shortcutItem {
            _ = performShortcutAction(shortcutItem)
        }

        if !connectionOptions.urlContexts.isEmpty {
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        }

        presentPasscodeIfNeeded()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        createActionMenus()
        // Face ID prompt for PasscodeLock also triggers resign active.
        // Avoid re-arming lock while PasscodeLock is already on screen.
        shouldPresentPasscodeWhenActive = !isPasscodeLockPresented()
        installPrivacyShieldIfNeeded()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        shouldPresentPasscodeWhenActive = true

        if UserDefaults.standard.bool(forKey: ClearCacheOnExitKey) {
            let app = UIApplication.shared
            let identifier = app.beginBackgroundTask(withName: "ClearDiskCache", expirationHandler: nil)
            ImageCache.default.clearDiskCache {
                app.endBackgroundTask(identifier)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if shouldPresentPasscodeWhenActive {
            presentPasscodeIfNeeded()
        } else {
            if !isPasscodeLockPresented() {
                removePrivacyShieldIfNeeded()
            }
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }
        UIPasteboard.general.string = context.url.absoluteString
        openAddMagnetAlert()
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(performShortcutAction(shortcutItem))
    }

    func createActionMenus() {
        guard window?.rootViewController?.traitCollection.forceTouchCapability == .available else { return }
        if Configuration.shared.hasTorrentServer {
            UIApplication.shared.shortcutItems = [addressItem, torrentItem, dyttItem, kittenItem]
        } else {
            UIApplication.shared.shortcutItems = [addressItem, dyttItem, kittenItem]
        }
    }

    @discardableResult
    func performShortcutAction(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        #if targetEnvironment(macCatalyst)
        guard let sidebarVC = tripleSplitViewController?.viewController(for: .primary) as? SidebarViewController else { return false }
        if shortcutItem.type == "\(bundleIdentifier).openaddresses" {
            sidebarVC.selectedIndex = 0
            selectSidebarIndex(0)
            return true
        }
        if shortcutItem.type == "\(bundleIdentifier).opentorrents" {
            sidebarVC.selectedIndex = 1
            selectSidebarIndex(1)
            return true
        }
        if shortcutItem.type == "\(bundleIdentifier).opendytt" {
            sidebarVC.selectedIndex = 2
            selectSidebarIndex(2)
            return true
        }
        if shortcutItem.type == "\(bundleIdentifier).kittensearch" {
            Helper.shared.showTorrentSearchAlertInViewController(window?.rootViewController)
            return true
        }
        #else
        if shortcutItem.type == "\(bundleIdentifier).openaddresses" {
            tabBarController?.selectedIndex = 0
            return true
        }
        if shortcutItem.type == "\(bundleIdentifier).opentorrents" {
            tabBarController?.selectedIndex = 1
            return true
        }
        if shortcutItem.type == "\(bundleIdentifier).opendytt" {
            tabBarController?.selectedIndex = 2
            return true
        }
        if shortcutItem.type == "\(bundleIdentifier).kittensearch" {
            Helper.shared.showTorrentSearchAlertInViewController(window?.rootViewController)
            return true
        }
        #endif
        return false
    }

    func openAddMagnetAlert() {
        #if targetEnvironment(macCatalyst)
        guard let sidebarVC = tripleSplitViewController?.viewController(for: .primary) as? SidebarViewController else { return }
        sidebarVC.selectedIndex = 0
        selectSidebarIndex(0)
        let navController = addressesNavController
        (navController?.topViewController as? WebContentTableViewController)?.addMagnet()
        #else
        tabBarController?.selectedIndex = 0
        let splitController = tabBarController?.viewControllers?.first as? MySplitViewController
        splitController?.show(.primary)
        let navController = splitController?.viewControllers.first as? UINavigationController
        (navController?.topViewController as? WebContentTableViewController)?.addMagnet()
        #endif
    }

    private func applyTheme() {
        let navBarAppearance = UINavigationBarAppearance()
        #if targetEnvironment(macCatalyst)
        navBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = Helper.shared.mainThemeColor()
        #else
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = Helper.shared.mainThemeColor()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = .white
        #endif

        let searchBarAppearance = UISearchBar.appearance()
        searchBarAppearance.barTintColor = Helper.shared.mainThemeColor()
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .white

        UISwitch.appearance().onTintColor = Helper.shared.mainThemeColor()
        UIProgressView.appearance().progressTintColor = Helper.shared.mainThemeColor()
    }

    private func presentPasscodeIfNeeded() {
        guard shouldPresentPasscodeWhenActive else { return }
        shouldPresentPasscodeWhenActive = false
        DispatchQueue.main.async { [weak self] in
            self?.presentPasscodeLockIfNeeded()
        }
    }

    private func presentPasscodeLockIfNeeded() {
        let repository = UserDefaultsPasscodeRepository()
        guard repository.hasPasscode else {
            removePrivacyShieldIfNeeded()
            return
        }
        guard let root = window?.rootViewController else {
            removePrivacyShieldIfNeeded()
            return
        }
        if topPresentedController(from: root) as? PasscodeLockViewController != nil {
            removePrivacyShieldIfNeeded()
            return
        }

        let configuration = PasscodeLockConfiguration(repository: repository)
        let passcodeVC = PasscodeLockViewController(state: .enterPasscode, configuration: configuration)
        passcodeVC.mainColor = Helper.shared.mainThemeColor()
        passcodeVC.isModalInPresentation = true
        passcodeVC.modalPresentationStyle = .fullScreen
        passcodeVC.dismissCompletionCallback = { [weak self] in
            self?.removePrivacyShieldIfNeeded()
        }

        topPresentedController(from: root).present(passcodeVC, animated: false, completion: nil)
    }

    private func installPrivacyShieldIfNeeded() {
        guard !isPasscodeLockPresented() else { return }
        guard privacyShieldView == nil, let window else { return }
        let shield = UIView(frame: window.bounds)
        shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        shield.backgroundColor = .systemBackground
        window.addSubview(shield)
        privacyShieldView = shield
    }

    private func removePrivacyShieldIfNeeded() {
        privacyShieldView?.removeFromSuperview()
        privacyShieldView = nil
    }

    private func topPresentedController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topPresentedController(from: presented)
        }
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return topPresentedController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topPresentedController(from: selected)
        }
        if let split = root as? UISplitViewController, let last = split.viewControllers.last {
            return topPresentedController(from: last)
        }
        return root
    }


    private func isPasscodeLockPresented() -> Bool {
        guard let root = window?.rootViewController else { return false }
        return topPresentedController(from: root) is PasscodeLockViewController
    }

    private func findViewController<T: UIViewController>(ofType type: T.Type, from root: UIViewController?) -> T? {
        guard let root else { return nil }
        if let matched = root as? T { return matched }

        for child in root.children {
            if let matched = findViewController(ofType: type, from: child) {
                return matched
            }
        }

        if let nav = root as? UINavigationController {
            for controller in nav.viewControllers {
                if let matched = findViewController(ofType: type, from: controller) {
                    return matched
                }
            }
        }

        if let tab = root as? UITabBarController {
            for controller in tab.viewControllers ?? [] {
                if let matched = findViewController(ofType: type, from: controller) {
                    return matched
                }
            }
        }

        if let presented = root.presentedViewController {
            return findViewController(ofType: type, from: presented)
        }

        return nil
    }
}

#if targetEnvironment(macCatalyst)
extension SceneDelegate: SidebarViewControllerDelegate {
    func sidebarViewController(_ sidebar: SidebarViewController, didSelectIndex index: Int) {
        selectSidebarIndex(index)
    }
    
    func selectSidebarIndex(_ index: Int) {
        guard let splitVC = tripleSplitViewController else { return }
        let nav: UIViewController?
        let detail: UIViewController?
        
        switch index {
        case 0:
            nav = addressesNavController
            detail = addressesDetailController
        case 1:
            nav = torrentsNavController
            detail = torrentsDetailController
        case 2:
            nav = dyttNavController
            detail = dyttDetailController
        default:
            return
        }
        
        if let nav = nav {
            splitVC.setViewController(nav, for: .supplementary)
        }
        if let detail = detail {
            splitVC.setViewController(detail, for: .secondary)
        } else {
            let placeholder = UIViewController()
            placeholder.view.backgroundColor = .systemBackground
            splitVC.setViewController(placeholder, for: .secondary)
        }
    }
}
#endif
