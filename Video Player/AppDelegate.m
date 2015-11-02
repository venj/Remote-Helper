//
//  AppDelegate.m
//  Video Player
//
//  Created by Venj Chu on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import "AppDelegate.h"
#import "WebContentTableViewController.h"
#import "Common.h"
#import <SDWebImage/SDImageCache.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MMAppSwitcher/MMAppSwitcher.h>
#import <LTHPasscodeViewController/LTHPasscodeViewController.h>
#import "BlocksKit+UIKit.h"
#import <AFNetworking/AFNetworking.h>
#import "VPTorrentsListViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "VPSearchResultController.h"
#import "Video_Player-Swift.h"
#define SSL_ADD_S ([self useSSL] ? @"s" : @"")

@interface AppDelegate () <UISplitViewControllerDelegate, LTHPasscodeViewControllerDelegate, MMAppSwitcherDataSource, UITabBarControllerDelegate>
@property (nonatomic, strong) WebContentTableViewController *localFileListViewController;
@property (nonatomic, strong) UITabBarController *tabbarController;
@property (nonatomic, copy) NSString *sessionHeader;
@property (nonatomic, copy) NSString *downloadPath;
@end

static HYXunleiLixianAPI *__api;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // App Swicher
    [[MMAppSwitcher sharedInstance] setDataSource:self];
    // Reachability
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    // File List
    self.fileListViewController = [[WebContentTableViewController alloc] initWithStyle:UITableViewStylePlain];
    self.fileListViewController.title = NSLocalizedString(@"Addresses", @"Addresses");
    self.fileListViewController.tabBarItem.image = [UIImage imageNamed:@"tab_cloud"];
    UINavigationController *fileListNavController = [[UINavigationController alloc] initWithRootViewController:self.fileListViewController];
    // Torrent List
    VPTorrentsListViewController *torrentsListViewController = [[VPTorrentsListViewController alloc] initWithStyle:UITableViewStylePlain];
    torrentsListViewController.title = NSLocalizedString(@"Torrents", @"Torrents");
    torrentsListViewController.tabBarItem.image = [UIImage imageNamed:@"tab_torrents"];
    UINavigationController *torrentsListNavigationController = [[UINavigationController alloc] initWithRootViewController:torrentsListViewController];
    // Tabbar
    self.tabbarController = [[UITabBarController alloc] init];
    self.tabbarController.delegate = self;
    self.tabbarController.viewControllers = @[fileListNavController, torrentsListNavigationController];
    self.window.rootViewController = self.tabbarController;
    // Xunlei login status set NO;
    self.xunleiUserLoggedIn = NO;
    
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
    [[MMAppSwitcher sharedInstance] setNeedsUpdate];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:ClearCacheOnExitKey] boolValue] == YES) {
        UIApplication *app = [UIApplication sharedApplication];
        __block UIBackgroundTaskIdentifier identifier = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:identifier];
            identifier = UIBackgroundTaskInvalid;
        }];
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
            [app endBackgroundTask:identifier];
            identifier = UIBackgroundTaskInvalid;
        }];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self showPassLock];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Reachability
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if ([shortcutItem.type isEqualToString:@"me.venj.Video-Player.openaddresses"]) {
        [self.tabbarController setSelectedIndex:0];
    }
    else if ([shortcutItem.type isEqualToString:@"me.venj.Video-Player.opentorrents"]) {
        [self.tabbarController setSelectedIndex:1];
    }
}

#pragma mark - Singleton

+ (AppDelegate *)shared {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark - UISplitViewController Delegate
- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}


#pragma mark - MMAppSwitcher
- (UIView *)viewForCard {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

#pragma mark - Helper Methods

- (void)showPassLock {
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES withLogout:NO andLogoutTitle:nil];
    }
}

- (void)showTorrentSearchAlertInNavigationController:(UINavigationController *)navigationController {
    if ([[AppDelegate shared] showCellularHUD]) { return; }
    UIAlertView *alert = [[UIAlertView alloc] bk_initWithTitle:NSLocalizedString(@"Search", @"Search") message:NSLocalizedString(@"Please enter video serial:", @"Please enter video serial:")];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert bk_addButtonWithTitle:NSLocalizedString(@"Search", @"Search") handler:^{
        NSString *keyword = [alert textFieldAtIndex:0].text;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:navigationController.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.removeFromSuperViewOnHide = YES;
        AFHTTPSessionManager *manager = [[Helper defaultHelper] refreshedManager];
        [manager GET:[[Helper defaultHelper] dbSearchPathWithKeyword:keyword] parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            if ([responseObject[@"success"] boolValue] == true) {
                VPSearchResultController *searchController = [[VPSearchResultController alloc] initWithStyle:UITableViewStylePlain];
                searchController.torrents = responseObject[@"results"];
                searchController.keyword = keyword;
                [navigationController pushViewController:searchController animated:YES];
            }
            else {
                NSString *errorMessage = responseObject[@"message"];
                [[AppDelegate shared] showHudWithMessage:NSLocalizedString(errorMessage, errorMessage) inView:navigationController.view];
            }
            [hud hide:YES];
        } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
            [hud hide:YES];
            [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Connection failed.", @"Connection failed.") inView:navigationController.view];
        }];
    }];
    [alert bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel") handler:nil];
    [alert show];
}

#pragma mark - Add magnet task

- (void)parseSessionAndAddTask:(NSString *)magnet completionHandler:(void (^__strong)(void))completionHandler errorHandler:(void (^__strong)(void))errorHandler {
    __weak typeof(self) weakself = self;
    NSDictionary *sessionParams = @{@"method" : @"session-get"};
    AFHTTPSessionManager *manager = [[Helper defaultHelper] refreshedManagerWithAuthentication:YES withJSON:YES];
    [manager.requestSerializer setValue:weakself.sessionHeader forHTTPHeaderField:@"X-Transmission-Session-Id"];
    [manager POST:[[Helper defaultHelper] transmissionRPCAddress] parameters:sessionParams success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSString *result = [responseObject objectForKey:@"result"];
        if ([result isEqualToString:@"success"]) {
            NSDictionary *responseDict = responseObject;
            NSString *result = responseDict[@"result"];
            if ([result isEqualToString:@"success"]) {
                weakself.downloadPath = responseDict[@"arguments"][@"download-dir"];
                [weakself downloadTask:magnet toDir:weakself.downloadPath completionHandler:completionHandler errorHandler:errorHandler];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if ([response statusCode] == 409) {
            // GetSession
            weakself.sessionHeader = [response allHeaderFields][@"X-Transmission-Session-Id"];
            AFHTTPSessionManager *manager = [[Helper defaultHelper] refreshedManagerWithAuthentication:YES withJSON:YES];
            [manager.requestSerializer setValue:weakself.sessionHeader forHTTPHeaderField:@"X-Transmission-Session-Id"];
            [manager POST:[[Helper defaultHelper] transmissionRPCAddress] parameters:sessionParams success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                NSDictionary *responseDict = responseObject;
                NSString *result = responseDict[@"result"];
                if ([result isEqualToString:@"success"]) {
                    weakself.downloadPath = responseDict[@"arguments"][@"download-dir"];
                    [weakself downloadTask:magnet toDir:weakself.downloadPath completionHandler:completionHandler errorHandler:errorHandler];
                }
            } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:NSLocalizedString(@"Unkown error.", @"Unknow error.") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
                [alert show];
            }];
        }
    }];
}

- (void)downloadTask:(NSString *)magnet toDir:(NSString *)dir completionHandler:(void (^__strong)(void))completionHandler errorHandler:(void (^__strong)(void))errorHandler {
    NSDictionary *params = @{@"method" : @"torrent-add", @"arguments": @{ @"paused" : @(NO), @"download-dir" : dir, @"filename" : magnet } };
    __weak typeof(self) weakself = self;
    AFHTTPSessionManager *manager = [[Helper defaultHelper] refreshedManagerWithAuthentication:YES withJSON:YES];
    [manager.requestSerializer setValue:weakself.sessionHeader forHTTPHeaderField:@"X-Transmission-Session-Id"];
    [manager POST:[[Helper defaultHelper] transmissionRPCAddress] parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSString *result = [responseObject objectForKey:@"result"];
        if ([result isEqualToString:@"success"]) {
            completionHandler();
        }
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        errorHandler();
    }];
}

- (void)showHudWithMessage:(NSString *)message inView:(UIView *)aView {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:aView animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = message;
    [hud hide:YES afterDelay:1];
}

- (BOOL)showCellularHUD {
    // Show cellular network hud
    if (![[Helper defaultHelper] userCellularNetwork] && ![[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi]) {
        [self showHudWithMessage:NSLocalizedString(@"Cellular data is turned off.", @"Cellular data is turned off.") inView:self.window];
        return YES;
    }
    return NO;
}

@end
