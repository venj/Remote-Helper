//
//  VPFileInfoViewController.m
//  Video Player
//
//  Created by venj on 13-6-6.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import "VPFileInfoViewController.h"
#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VPFileInfoViewController ()
@property (nonatomic, strong) MPMoviePlayerViewController *mpViewController;
@end

@implementation VPFileInfoViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.title = NSLocalizedString(@"File Info", @"File Info");
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay handler:^(id sender) {
        if (!self.fileInfo) return;
        NSString *moviePath = [[AppDelegate shared] fileLinkWithPath:[self.fileInfo[@"file"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURL *url = [[NSURL alloc] initWithString:moviePath];
        if (self.mpViewController)
            self.mpViewController.moviePlayer.contentURL = url;
        else
            self.mpViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
        
        [self presentMoviePlayerViewControllerAnimated:self.mpViewController];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        return toInterfaceOrientation != UIInterfaceOrientationMaskPortraitUpsideDown;
    else
        return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (self.fileInfo) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FileInfoTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSString *k, *v;
    NSString *path = self.fileInfo[@"file"];
    if (indexPath.row == 0) {
        k = NSLocalizedString(@"File", @"File");
        v = [[path componentsSeparatedByString:@"/"] lastObject];
    }
    else if (indexPath.row == 1) {
        k = NSLocalizedString(@"Path", @"Path");
        v = path;
    }
    else if (indexPath.row == 2) {
        k = NSLocalizedString(@"Size", @"Size");
        v = [NSString stringWithFormat:@"%.2f MB", [self.fileInfo[@"size"] integerValue] / (1024. * 1024)];
    }
    cell.textLabel.text = k;
    cell.detailTextLabel.text = v;
    
    return cell;
}

@end
