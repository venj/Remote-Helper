//
//  VPFileListViewController.h
//  Video Player
//
//  Created by Venj Chu on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VPFileInfoViewController.h"

/*!
 @class VPFileListViewController
 @brief This class is used to present a local or remote video list for users.
 */
@interface VPFileListViewController : UITableViewController <VPFileInfoViewControllerDelegate>
@property (nonatomic, readonly) UIActionSheet *sheet;
@property (nonatomic, assign) BOOL isLocal;
@property (nonatomic, strong) NSMutableArray *dataList;

/*!
 @brief The action method to show the Settings modal.
 @param sender Sender for the action.
 */
- (void)showSettings:(id)sender;

/*!
 @brief The action method to reload the local or remote videos list.
 @param sender Sender for the action.
 */
- (void)loadMovieList:(id)sender;
@end
