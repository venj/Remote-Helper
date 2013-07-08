//
//  VPFileInfoViewController.h
//  Video Player
//
//  Created by venj on 13-6-6.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @protocol VPFileInfoViewControllerDelegate
 @brief An optional protocal for file remove from the server call back.
 */
@protocol VPFileInfoViewControllerDelegate <NSObject>
@optional
/*!
 @param indexPath The <code>indexPath</code> associated with the file in the video list table view.
 */
- (void)fileDidRemovedFromServerForParentIndexPath:(NSIndexPath *)indexPath;
@end

/*!
 @class VPFileInfoViewController
 @brief The view controller to show brief file infomation.
 */
@interface VPFileInfoViewController : UITableViewController
@property (nonatomic, weak) id<VPFileInfoViewControllerDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *parentIndexPath;
@property (nonatomic, strong) NSDictionary *fileInfo;
@property (nonatomic, assign) BOOL isLocalFile;
@end

