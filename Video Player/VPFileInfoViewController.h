//
//  VPFileInfoViewController.h
//  Video Player
//
//  Created by venj on 13-6-6.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VPFileInfoViewControllerDelegate <NSObject>
@optional
- (void)fileDidRemovedFromServerForParentIndexPath:(NSIndexPath *)indexPath;
@end

@interface VPFileInfoViewController : UITableViewController
@property (nonatomic, weak) id<VPFileInfoViewControllerDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *parentIndexPath;
@property (nonatomic, strong) NSDictionary *fileInfo;
@end

