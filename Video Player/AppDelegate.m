//
//  AppDelegate.m
//  Video Player
//
//  Created by Venj Chu on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import "AppDelegate.h"
#import "VPFileListViewController.h"
#import "VPFileInfoViewController.h"
#import "Common.h"
#import <SDWebImage/SDImageCache.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MMAppSwitcher/MMAppSwitcher.h>
#import <LTHPasscodeViewController/LTHPasscodeViewController.h>
#import <BlocksKit+UIKit.h>
#import "VPTorrentsListViewController.h"
#import "ipaddress.h"

@interface AppDelegate () <UISplitViewControllerDelegate, LTHPasscodeViewControllerDelegate, MMAppSwitcherDataSource, UITabBarControllerDelegate, VPFileInfoViewControllerDelegate>
@property (nonatomic, strong) VPFileListViewController *localFileListViewController;
@property (nonatomic, strong) UITabBarController *tabbarController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // App Swicher
    [[MMAppSwitcher sharedInstance] setDataSource:self];
    
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
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation:YES withLogout:NO andLogoutTitle:nil];
    }
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
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@/torrents", [self baseLink]];
    return link;
}

- (NSString *)searchPathWithKeyword:(NSString *)keyword {
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@/search/%@", [self baseLink], keyword];
    return link;
}

- (NSString *)addTorrentWithName:(NSString *)name async:(BOOL)async {
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@/lx/%@", [self baseLink], name];
    if (async) {
        link = [link stringByAppendingFormat:@"/1"];
    }
    else {
        link = [link stringByAppendingFormat:@"/0"];
    }
    return link;
}

- (NSString *)hashTorrentWithName:(NSString *)name {
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@/hash/%@", [self baseLink], name];
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
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@:%@%@", host, port, path];
    return link;
}

- (NSString *)fileOperation:(NSString *)operation withPath:(NSString *)path fileName:(NSString *)fileName {
    if (!path) {
        path = @"/";
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:path forKey:ServerPathKey];
        [defaults synchronize];
    }
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@%@%@/%@", [self baseLink], path, operation, fileName];
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
            subpath = [subpath substringToIndex:subpath.length - 2];
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

- (BOOL)shouldSendWebRequest {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if ([host length] == 0) {
        return NO;
    }
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^[^\\d+]" options:NSRegularExpressionCaseInsensitive error:nil];
    // By pass IP check for domain names (maybe mDNS domain names)
    if ([[regex matchesInString:host options:0 range:NSMakeRange(0, [host length])] count] > 0) {
        return YES;
    }
    
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
    NSString *address = nil;
    for (int i = 0; i < 5; i++) {
        NSString *tmp = [NSString stringWithFormat:@"%s", ip_names[i]];
        NSArray *addressComponents = [tmp componentsSeparatedByString:@"."];
        if ([addressComponents[0] isEqualToString:@"192"] && [addressComponents[1] isEqualToString:@"168"]) {
            address = tmp;
        }
    }
    return address;
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

#pragma mark - Shared action
- (void)showNetworkAlert {
    __weak typeof(self) weakSelf = self;
    UIAlertView *alert = [[UIAlertView alloc] bk_initWithTitle:NSLocalizedString(@"Network Error", @"Network Error") message:NSLocalizedString(@"Your device is not in the same LAN with the server.", @"Your device is not in the same LAN with the server.")];
    [alert bk_addButtonWithTitle:NSLocalizedString(@"Settings", @"Settings") handler:^{
        [weakSelf.fileListViewController showSettings:nil];
    }];
    [alert bk_setCancelButtonWithTitle:NSLocalizedString(@"OK", @"OK") handler:NULL];
    [alert show];
}

@end
