//
//  VPFileListViewController.h
//  Video Player
//
//  Created by 朱 文杰 on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VPFileInfoViewController.h"
@interface VPFileListViewController : UITableViewController <VPFileInfoViewControllerDelegate>
@property (nonatomic, strong) UIActionSheet *sheet;
@property (nonatomic, assign) BOOL isLocal;
@property (nonatomic, strong) NSMutableArray *dataList;
- (void)showSettings:(id)sender;
- (void)loadMovieList:(id)sender;
@end
