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
#import <BlocksKit+UIKit.h>
#import "VPTorrentsListViewController.h"
#import "SBAPIManager.h"
#import <MBProgressHUD/MBProgressHUD.h>
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airplayStateChanged:) name:MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification object:nil];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification object:nil];
}

#pragma mark - Singleton

+ (AppDelegate *)shared {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

+ (HYXunleiLixianAPI *)sharedAPI {
    if (__api == nil) {
        __api = [[HYXunleiLixianAPI alloc] init];
    }
    return __api;
}

#pragma mark - AirPlay Status Change Notification

- (void)airplayStateChanged:(NSNotification *)note {
    if ([(MPMoviePlayerController *)(note.object) isAirPlayVideoActive]) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    else {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
}

#pragma mark - UISplitViewController Delegate
- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}


#pragma mark - MMAppSwitcher
- (UIView *)appSwitcher:(MMAppSwitcher *)appSwitcher viewForCardWithSize:(CGSize)size {
    CGRect frame = CGRectMake(0.0, 0.0, size.width, size.height);
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

#pragma mark - Helper Methods

- (BOOL)useSSL {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:RequestUseSSL] == nil) {
        [defaults setBool:YES forKey:RequestUseSSL];
        return YES;
    }
    else {
        return [defaults boolForKey:RequestUseSSL];
    }
}

- (NSString *)customUserAgent {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:CustomRequestUserAgent] == nil) {
        return @"";
    }
    else {
        return [defaults stringForKey:CustomRequestUserAgent];
    }
}

- (void)showPassLock {
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES withLogout:NO andLogoutTitle:nil];
    }
}

- (NSString *)torrentsListPath {
    NSString *link = [[NSString alloc] initWithFormat:@"http%@://%@/torrents", SSL_ADD_S, [self baseLink]];
    return link;
}

- (NSString *)dbSearchPathWithKeyword:(NSString *)keyword {
    NSString *link = [[NSString alloc] initWithFormat:@"http%@://%@/db_search?keyword=%@", SSL_ADD_S, [self baseLink], [keyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return link;
}

- (NSString *)searchPathWithKeyword:(NSString *)keyword {
    NSString *link = [[NSString alloc] initWithFormat:@"http%@://%@/search/%@", SSL_ADD_S, [self baseLink], keyword];
    return link;
}

- (NSString *)addTorrentWithName:(NSString *)name async:(BOOL)async {
    NSString *link = [[NSString alloc] initWithFormat:@"http%@://%@/lx/%@", SSL_ADD_S, [self baseLink], name];
    if (async) {
        link = [link stringByAppendingFormat:@"/1"];
    }
    else {
        link = [link stringByAppendingFormat:@"/0"];
    }
    return link;
}

- (NSString *)hashTorrentWithName:(NSString *)name {
    NSString *link = [[NSString alloc] initWithFormat:@"http%@://%@/hash/%@", SSL_ADD_S, [self baseLink], name];
    return link;
}

- (NSString *)fileLinkWithPath:(NSString *)path {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if (!host) host = @"192.168.1.1";
    NSString *port = [defaults objectForKey:ServerPortKey];
    if (!port) port = @"80";
    if (!path || [path isEqualToString:@""])
        path = @"/";
    else if (![[path substringToIndex:1] isEqualToString:@"/"])
        path = [[NSString alloc]  initWithFormat:@"/%@", path];
    NSString *link = [[NSString alloc] initWithFormat:@"http%@://%@:%@%@", SSL_ADD_S, host, port, path];
    return link;
}

- (NSString *)fileOperation:(NSString *)operation withPath:(NSString *)path fileName:(NSString *)fileName {
    if (!path) {
        path = @"/";
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:path forKey:ServerPathKey];
        [defaults synchronize];
    }
    NSString *link = [[NSString alloc] initWithFormat:@"http%@://%@%@%@/%@", SSL_ADD_S, [self baseLink], path, operation, fileName];
    return link;
}

- (NSString *)baseLink {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if (!host) host = @"192.168.1.1";
    NSString *port = [defaults objectForKey:ServerPortKey];
    if (!port) port = @"80";
    NSString *subpath = [defaults objectForKey:ServerPathKey];
    if (!subpath || [subpath isEqualToString:@"/"]) {
        subpath = @"";
    }
    else {
        if (![[subpath substringToIndex:1] isEqualToString:@"/"])
            subpath = [[NSString alloc] initWithFormat:@"/%@", subpath];
        if ([[subpath substringFromIndex:(subpath.length - 1)] isEqualToString:@"/"])
            subpath = [subpath substringToIndex:subpath.length - 1];
    }
    return [[NSString alloc] initWithFormat:@"%@:%@%@", host, port, subpath];
}

- (NSString *)getTransmissionServerAddress {
    return [self getTransmissionServerAddressWithUserNameAndPassword:YES];
}

- (NSString *)getTransmissionRPCAddress {
    NSString *server = [self getTransmissionServerAddressWithUserNameAndPassword:NO];
    return [server stringByAppendingPathComponent:@"transmission/rpc"];
}

- (NSString *)getTransmissionServerAddressWithUserNameAndPassword:(BOOL)withUserNameAndPassword {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *address = [defaults objectForKey:TransmissionAddressKey];
    if (address == nil) {
        address = @"127.0.0.1:9091";
    }
    NSArray *userpass = [self getUsernameAndPassword];
    if ([userpass[0] length] > 0 && [userpass[1] length] > 0 && withUserNameAndPassword) {
        return [NSString stringWithFormat:@"http://%@:%@@%@",userpass[0], userpass[1], address];
    }
    else {
        return [NSString stringWithFormat:@"http://%@", address];
    }
}

- (NSArray *)getUsernameAndPassword {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:TransmissionUserNameKey];
    NSString *password = [defaults objectForKey:TransmissionPasswordKey];
    if (username && password) {
        return @[username, password];
    }
    else {
        return @[@"username", @"password"];
    }
}

- (NSArray *)getXunleiUsernameAndPassword {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:XunleiUserNameKey];
    NSString *password = [defaults objectForKey:XunleiPasswordKey];
    if (username && password) {
        return @[username, password];
    }
    else {
        return @[@"username", @"password"];
    }
}

- (BOOL)shouldSendWebRequest {
    // Return YES for all
    return YES;
}

- (uint64_t)freeDiskSpace {
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    }
    
    return totalFreeSpace;
}

- (NSString *)fileSizeStringWithInteger:(uint64_t)size {
    NSString *sizeString;
    if (size > 1024 * 1024 * 1024) {
        sizeString = [NSString stringWithFormat:@"%.1f GB", size / (1024. * 1024 * 1024)];
    }
    else if (size > 1024 * 1024) {
        sizeString = [NSString stringWithFormat:@"%.1f MB", size / (1024. * 1024)];
    }
    else if (size > 1024) {
        sizeString = [NSString stringWithFormat:@"%.1f KB", size / 1024.];
    }
    else {
        sizeString = [NSString stringWithFormat:@"%llu B", size];
    }
    return sizeString;
}

- (uint64_t)localFileSize {
    uint64_t size = 0;
    NSString *documentsDirectory = [self documentsDirectory];
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:documentsDirectory];
    for (NSString *fileName in fileEnumerator)
    {
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}

- (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

- (NSString *)fileToDownloadWithPath:(NSString *)path {
    NSString *documentsDirectory = [[AppDelegate shared] documentsDirectory];
    NSString *fileToDownload = [documentsDirectory stringByAppendingPathComponent:[path lastPathComponent]];
    return fileToDownload;
}

- (NSURL *)videoPlayURLWithPath:(NSString *)path {
    NSString *localFile = [self fileToDownloadWithPath:path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:localFile])
        return [NSURL fileURLWithPath:localFile];
    else
        return [NSURL URLWithString:[[[AppDelegate shared] fileLinkWithPath:path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark - Add magnet task

- (void)parseSessionAndAddTask:(NSString *)magnet completionHandler:(void (^__strong)(void))completionHandler errorHandler:(void (^__strong)(void))errorHandler {
    __weak typeof(self) weakself = self;
    NSDictionary *sessionParams = @{@"method" : @"session-get"};
    SBAPIManager *manager = [self refreshedManager];
    [manager setDefaultHeader:@"X-Transmission-Session-Id" value:weakself.sessionHeader];
    [manager postPath:@"/transmission/rpc" parameters:sessionParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *result = [responseObject objectForKey:@"result"];
        if ([result isEqualToString:@"success"]) {
            NSDictionary *responseDict = responseObject;
            NSString *result = responseDict[@"result"];
            if ([result isEqualToString:@"success"]) {
                weakself.downloadPath = responseDict[@"arguments"][@"download-dir"];
                [weakself downloadTask:magnet toDir:weakself.downloadPath completionHandler:completionHandler errorHandler:errorHandler];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([operation.response statusCode] == 409) {
            // GetSession
            weakself.sessionHeader = [operation.response allHeaderFields][@"X-Transmission-Session-Id"];
            [manager setDefaultHeader:@"X-Transmission-Session-Id" value:weakself.sessionHeader];
            [manager postPath:@"/transmission/rpc" parameters:sessionParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSDictionary *responseDict = responseObject;
                NSString *result = responseDict[@"result"];
                if ([result isEqualToString:@"success"]) {
                    weakself.downloadPath = responseDict[@"arguments"][@"download-dir"];
                    [weakself downloadTask:magnet toDir:weakself.downloadPath completionHandler:completionHandler errorHandler:errorHandler];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                // error stuff here
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:NSLocalizedString(@"Unkown error.", @"Unknow error.") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
                [alert show];
            }];
        }
    }];
}

- (void)downloadTask:(NSString *)magnet toDir:(NSString *)dir completionHandler:(void (^__strong)(void))completionHandler errorHandler:(void (^__strong)(void))errorHandler {
    NSDictionary *params = @{@"method" : @"torrent-add", @"arguments": @{ @"paused" : @(NO), @"download-dir" : dir, @"filename" : magnet } };
    __weak typeof(self) weakself = self;
    SBAPIManager *manager = [self refreshedManager];
    [manager setDefaultHeader:@"X-Transmission-Session-Id" value:weakself.sessionHeader];
    [manager postPath:@"/transmission/rpc" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *result = [responseObject objectForKey:@"result"];
        if ([result isEqualToString:@"success"]) {
            completionHandler();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        errorHandler();
    }];
}

- (SBAPIManager *)refreshedManager {
    NSString *link = [[AppDelegate shared] getTransmissionServerAddressWithUserNameAndPassword:NO];
    NSArray *userNameAndPassword = [[AppDelegate shared] getUsernameAndPassword];
    SBAPIManager *manager = [[SBAPIManager alloc] initWithBaseURL:[[NSURL alloc] initWithString:link]];
    [manager setUsername:userNameAndPassword[0] andPassword:userNameAndPassword[1]];
    return manager;
}

- (void)showHudWithMessage:(NSString *)message inView:(UIView *)aView {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:aView animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = message;
    [hud hide:YES afterDelay:1];
}


@end
