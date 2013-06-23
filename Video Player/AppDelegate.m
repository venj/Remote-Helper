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

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    VPFileListViewController *fileListViewController = [[VPFileListViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *fileListNavController = [[UINavigationController alloc] initWithRootViewController:fileListViewController];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.window.rootViewController = fileListNavController;
    }
    else {
        self.fileInfoViewController = [[VPFileInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
        UINavigationController *fileInfoNavController = [[UINavigationController alloc] initWithRootViewController:self.fileInfoViewController];
        UISplitViewController *rootViewController = [[UISplitViewController alloc] init];
        rootViewController.viewControllers = @[fileListNavController, fileInfoNavController];
        rootViewController.delegate = self;
        self.window.rootViewController = rootViewController;
    }
    
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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

- (NSString *)addTorrentWithName:(NSString *)name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if (!host) host = @"192.168.1.1";
    NSString *port = [defaults objectForKey:ServerPortKey];
    if (!port) port = @"80";
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@:%@/lx/%@", host, port, name];
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

- (NSString *)fileInfoWithPath:(NSString *)path fileName:(NSString *)fileName {
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
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@:%@%@info/%@", host, port, path, fileName];
    return link;
}

@end
