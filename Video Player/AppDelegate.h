//
//  AppDelegate.h
//  Video Player
//
//  Created by Venj Chu on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HYXunleiLixianAPI.h"

@class WebContentTableViewController, AFHTTPSessionManager;

/*!
 @class AppDelegate
 @brief The application delegate for current App.
 */
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) WebContentTableViewController *fileListViewController;
// Record Xunlei login status for app life cycle
@property (nonatomic, assign, getter=isXunleiUserLoggedIn) BOOL xunleiUserLoggedIn;
/*!
 @brief Return the AppDelegate singleton for sharing data and states between View Controllers.
 @return The AppDelegate singleton.
 */
+ (AppDelegate *)shared;

- (void)showTorrentSearchAlertInNavigationController:(UINavigationController *)navigationController;
- (void)showHudWithMessage:(NSString *)message inView:(UIView *)aView;
- (void)parseSessionAndAddTask:(NSString *)magnet completionHandler:(void (^__strong)(void))completionHandler errorHandler:(void (^__strong)(void))errorHandler;
- (BOOL)showCellularHUD;
@end
