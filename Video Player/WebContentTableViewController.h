//
//  VPFileListViewController.h
//  Video Player
//
//  Created by Venj Chu on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @class VPFileListViewController
 @brief This class is used to present a local or remote video list for users.
 */
@interface WebContentTableViewController : UITableViewController
@property (nonatomic, readonly) UIActionSheet *sheet;

/*!
 @brief The action method to show the Settings modal.
 @param sender Sender for the action.
 */
- (void)showSettings:(id)sender;

@end
