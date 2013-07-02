//
//  AppDelegate.h
//  Video Player
//
//  Created by 朱 文杰 on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VPFileInfoViewController.h"

@class VPFileListViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) VPFileInfoViewController *fileInfoViewController;
@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) VPFileListViewController *fileListViewController;

+ (AppDelegate *)shared;
- (NSString *)fileLinkWithPath:(NSString *)path;
- (NSString *)fileOperation:(NSString *)operation withPath:(NSString *)path fileName:(NSString *)fileName;
- (NSString *)torrentsListPath;
- (NSString *)searchPathWithKeyword:(NSString *)keyword;
- (NSString *)addTorrentWithName:(NSString *)name async:(BOOL)async;
- (BOOL)shouldSendWebRequest;
- (void)showNetworkAlert;
- (NSString *)documentsDirectory;
- (uint64_t)freeDiskSpace;
- (uint64_t)localFileSize;
- (NSString *)fileSizeStringWithInteger:(uint64_t)size;
@end
