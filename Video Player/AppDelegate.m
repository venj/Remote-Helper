//
//  AppDelegate.m
//  Video Player
//
//  Created by 朱 文杰 on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import "AppDelegate.h"
#import "VPFileListViewController.h"
#import "VPFileInfoViewController.h"
#import "Common.h"
#import <SDWebImage/SDImageCache.h>
#import <KKPasscodeLock/KKPasscodeLock.h>
#import "VPTorrentsListViewController.h"
#import "ipaddress.h"

@interface AppDelegate () <UISplitViewControllerDelegate, KKPasscodeViewControllerDelegate, UITabBarControllerDelegate, VPFileInfoViewControllerDelegate>
@property (nonatomic, strong) VPFileListViewController *localFileListViewController;
@property (nonatomic, strong) UITabBarController *tabbarController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // File List
    self.fileListViewController = [[VPFileListViewController alloc] initWithStyle:UITableViewStylePlain];
    self.fileListViewController.isLocal = NO;
    self.fileListViewController.title = NSLocalizedString(@"Server", @"Server");
    self.fileListViewController.tabBarItem.image = [UIImage imageNamed:@"tab_cloud"];
    UINavigationController *fileListNavController = [[UINavigationController alloc] initWithRootViewController:self.fileListViewController];
    // Local File List
    self.localFileListViewController = [[VPFileListViewController alloc] initWithStyle:UITableViewStylePlain];
    self.localFileListViewController.isLocal = YES;
    self.localFileListViewController.title = NSLocalizedString(@"Local", @"Local");
    self.localFileListViewController.tabBarItem.image = [UIImage imageNamed:@"tab_local"];
    UINavigationController *localFileListNavController = [[UINavigationController alloc] initWithRootViewController:self.localFileListViewController];
    // Torrent List
    VPTorrentsListViewController *torrentsListViewController = [[VPTorrentsListViewController alloc] initWithStyle:UITableViewStylePlain];
    torrentsListViewController.title = NSLocalizedString(@"Torrents", @"Torrents");
    torrentsListViewController.tabBarItem.image = [UIImage imageNamed:@"tab_torrents"];
    UINavigationController *torrentsListNavigationController = [[UINavigationController alloc] initWithRootViewController:torrentsListViewController];
    // Tabbar
    self.tabbarController = [[UITabBarController alloc] init];
    self.tabbarController.delegate = self;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.tabbarController.viewControllers = @[fileListNavController, localFileListNavController, torrentsListNavigationController];
        self.window.rootViewController = self.tabbarController;
    }
    else {
        self.tabbarController.viewControllers = @[fileListNavController, localFileListNavController];
        self.fileInfoViewController = [[VPFileInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
        self.fileInfoViewController.delegate = self;
        UINavigationController *fileInfoNavController = [[UINavigationController alloc] initWithRootViewController:self.fileInfoViewController];
        self.splitViewController = [[UISplitViewController alloc] init];
        self.splitViewController.viewControllers = @[self.tabbarController, fileInfoNavController];
        self.splitViewController.delegate = self;
        self.window.rootViewController = self.splitViewController;
    }
    NSUserDefaults *defults = [NSUserDefaults standardUserDefaults];
    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [defults setObject:[NSString stringWithFormat:@"%@(%@)", appVersionString, appBuildString] forKey:CurrentVersionKey];
    [defults synchronize];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if ([[KKPasscodeLock sharedLock] isPasscodeRequired]) {
        [self.fileListViewController.sheet dismissWithClickedButtonIndex:self.fileListViewController.sheet.cancelButtonIndex animated:NO];
        [self.window.rootViewController dismissModalViewControllerAnimated:NO];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:ClearCacheOnExitKey]) {
        [[SDImageCache sharedImageCache] clearDisk]; // Clear Image Cache
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if ([[KKPasscodeLock sharedLock] isPasscodeRequired]) {
        KKPasscodeViewController *vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
        vc.mode = KKPasscodeModeEnter;
        vc.delegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.window.rootViewController presentModalViewController:nav animated:NO];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Singleton

+ (AppDelegate *)shared {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark - UISplitViewController Delegate
- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

#pragma mark - File Info View Controller Delegate
- (void)fileDidRemovedFromServerForParentIndexPath:(NSIndexPath *)indexPath {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        VPFileListViewController *fileListController = (VPFileListViewController *)[(UINavigationController *)[self.tabbarController selectedViewController] topViewController];
        if (indexPath) {
            [fileListController.dataList removeObjectAtIndex:indexPath.row];
            [fileListController.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            [fileListController loadMovieList:nil];
        }
    }
}


#pragma mark - Helper Methods
- (NSString *)torrentsListPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if (!host) host = @"192.168.1.1";
    NSString *port = [defaults objectForKey:ServerPortKey];
    if (!port) port = @"80";
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@:%@/torrents", host, port];
    return link;
}

- (NSString *)searchPathWithKeyword:(NSString *)keyword {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if (!host) host = @"192.168.1.1";
    NSString *port = [defaults objectForKey:ServerPortKey];
    if (!port) port = @"80";
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@:%@/search/%@", host, port, keyword];
    return link;
}

- (NSString *)addTorrentWithName:(NSString *)name async:(BOOL)async {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if (!host) host = @"192.168.1.1";
    NSString *port = [defaults objectForKey:ServerPortKey];
    if (!port) port = @"80";
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@:%@/lx/%@", host, port, name];;
    if (async) {
        link = [link stringByAppendingFormat:@"/1"];
    }
    else {
        link = [link stringByAppendingFormat:@"/0"];
    }
    return link;
}

- (NSString *)fileLinkWithPath:(NSString *)path {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if (!host) host = @"192.168.1.1";
    NSString *port = [defaults objectForKey:ServerPortKey];
    if (!port) port = @"80";
    if (!path)
        path = @"/";
    else if (![[path substringToIndex:1] isEqualToString:@"/"])
        path = [[NSString alloc]  initWithFormat:@"/%@", path];
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@:%@%@", host, port, path];
    return link;
}

- (NSString *)fileOperation:(NSString *)operation withPath:(NSString *)path fileName:(NSString *)fileName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if (!host) host = @"192.168.1.1";
    NSString *port = [defaults objectForKey:ServerPortKey];
    if (!port) port = @"80";
    if (!path)
        path = @"/";
    else if (![[path substringToIndex:1] isEqualToString:@"/"])
        path = [[NSString alloc]  initWithFormat:@"/%@", path];
    else if (![[path substringFromIndex:[path length] - 1] isEqualToString:@"/"])
        path = [[NSString alloc]  initWithFormat:@"%@/", path];
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@:%@%@%@/%@", host, port, path, operation, fileName];
    return link;
}

- (BOOL)shouldSendWebRequest {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    NSString *myAddress = [self getIPAddress];
    
    if (host && myAddress) {
        NSArray *hostComponents = [host componentsSeparatedByString:@"."];
        NSArray *myAddressComponents = [myAddress componentsSeparatedByString:@"."];
        if (([hostComponents[0] isEqualToString:myAddressComponents[0]]) &&
            ([hostComponents[1] isEqualToString:myAddressComponents[1]]) &&
            ([hostComponents[2] isEqualToString:myAddressComponents[2]])) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)getIPAddress {
    InitAddresses();
    GetIPAddresses();
    GetHWAddresses();
    NSString *address = [NSString stringWithFormat:@"%s", ip_names[1]];
    return address;
}

#pragma mark - KKPasscode View Controller Delegate
- (void)shouldEraseApplicationData:(KKPasscodeViewController*)viewController
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"You have entered an incorrect passcode too many times. All account data in this app has been deleted.", @"You have entered an incorrect passcode too many times. All account data in this app has been deleted.") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
    [alert show];
}

- (void)didPasscodeEnteredIncorrectly:(KKPasscodeViewController*)viewController
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"You have entered an incorrect passcode too many times.", @"You have entered an incorrect passcode too many times.") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK")  otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Shared action
- (void)showNetworkAlert {
    [UIAlertView showAlertViewWithTitle:NSLocalizedString(@"Network Error", @"Network Error") message:NSLocalizedString(@"Your device is not in the same LAN with the server.", @"Your device is not in the same LAN with the server.") cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:@[NSLocalizedString(@"Settings", @"Settings")] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [self.fileListViewController showSettings:nil];
        }
    }];
}

@end
