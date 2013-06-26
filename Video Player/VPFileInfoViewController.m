//
//  VPFileInfoViewController.m
//  Video Player
//
//  Created by venj on 13-6-6.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import "VPFileInfoViewController.h"
#import "AppDelegate.h"
#import "Common.h"
#import <AFNetworking/AFNetworking.h>
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
        NSString *moviePath;
        NSURL *url;
        if (self.isLocalFile) {
            moviePath = self.fileInfo[@"file"];
            url = [NSURL fileURLWithPath:moviePath];
        }
        else {
            moviePath = [[AppDelegate shared] fileLinkWithPath:[self.fileInfo[@"file"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            url = [[NSURL alloc] initWithString:moviePath];
        }
        
        if (self.mpViewController)
            self.mpViewController.moviePlayer.contentURL = url;
        else
            self.mpViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
        
        [self presentMoviePlayerViewControllerAnimated:self.mpViewController];
    }];
    
    UIButton *button = [self deleteButton];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 320., 60.)];
    footerView.backgroundColor = [UIColor clearColor];
    [footerView addSubview:button];
    self.tableView.tableFooterView = footerView;
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

#pragma mark - Action method

- (void)deleteFile:(id)sender {
    __block VPFileInfoViewController *blockSelf = self;
    [UIAlertView showAlertViewWithTitle:NSLocalizedString(@"Delete File", @"Delete File") message:[NSString stringWithFormat:NSLocalizedString(@"Are you sure to delete \"%@\".", @"Are you sure to delete \"%@\"."), [[self.fileInfo[@"file"] componentsSeparatedByString:@"/"] lastObject]] cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") otherButtonTitles:@[NSLocalizedString(@"Delete", @"Delete")] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            if (blockSelf.isLocalFile) {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error;
                [fileManager removeItemAtPath:blockSelf.fileInfo[@"file"] error:&error];
                NSString *message = nil;
                if (error)
                    message = [NSString stringWithFormat:NSLocalizedString(@"Failed to delete file \"%@\".", @"Failed to delete file \"%@\"."), [[self.fileInfo[@"file"] componentsSeparatedByString:@"/"] lastObject]];
                else
                    message = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" has been deleted from your device.", @"\"%@\" has been deleted from your device."), [[self.fileInfo[@"file"] componentsSeparatedByString:@"/"] lastObject]];
                [UIAlertView showAlertViewWithTitle:NSLocalizedString(@"Delete File", @"Delete File") message:message cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (error) return;
                    [blockSelf.navigationController popViewControllerAnimated:YES];
                    if ([blockSelf.delegate respondsToSelector:@selector(fileDidRemovedFromServerForParentIndexPath:)]) {
                        [NSTimer scheduledTimerWithTimeInterval:0.3 block:^(NSTimeInterval time) {
                            [blockSelf.delegate fileDidRemovedFromServerForParentIndexPath:self.parentIndexPath];
                        } repeats:NO];
                    }
                }];
            }
            else {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *path = [defaults objectForKey:ServerPathKey];
                NSString *fileName = [self.fileInfo[@"file"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"%252F"];
                NSString *movieRemovePath = [[AppDelegate shared] fileOperation:@"remove" withPath:path fileName:fileName];
                NSURL *movieRemoveURL = [[NSURL alloc] initWithString:movieRemovePath];
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:movieRemoveURL];
                request.HTTPMethod = @"DELETE";
                
                AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                    [UIAlertView showAlertViewWithTitle:NSLocalizedString(@"Delete File", @"Delete File") message:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" has been deleted from the server.", @"\"%@\" has been deleted from the server."), [[self.fileInfo[@"file"] componentsSeparatedByString:@"/"] lastObject]] cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                        [blockSelf.navigationController popViewControllerAnimated:YES];
                        if ([blockSelf.delegate respondsToSelector:@selector(fileDidRemovedFromServerForParentIndexPath:)]) {
                            [NSTimer scheduledTimerWithTimeInterval:0.3 block:^(NSTimeInterval time) {
                                [blockSelf.delegate fileDidRemovedFromServerForParentIndexPath:self.parentIndexPath];
                            } repeats:NO];
                        }
                    }];
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connection failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }];
                [operation start];
            }
        }
    }];
}

#pragma mark - Helper Methods

- (UIButton *)deleteButton {
    UIImage *originalImage = [UIImage imageNamed:@"redButton"];
    UIImage *originalHighlightImage = [UIImage imageNamed:@"redButtonHighlight"];
    UIImage *buttonImage, *buttonHighlightImage;
    if ([[UIImage class] respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
        buttonImage = [originalImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
    }
    else {
        buttonImage = [originalImage stretchableImageWithLeftCapWidth:8 topCapHeight:0];
    }
    if ([[UIImage class] respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
        buttonHighlightImage = [originalHighlightImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
    }
    else {
        buttonHighlightImage = [originalHighlightImage stretchableImageWithLeftCapWidth:8 topCapHeight:0];
    }
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:buttonHighlightImage forState:UIControlStateHighlighted];
    [button setTitle:NSLocalizedString(@"Delete", @"Delete") forState:UIControlStateNormal];
    [button addTarget:self action:@selector(deleteFile:) forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    button.titleLabel.shadowColor = [UIColor grayColor];
    button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    button.frame = CGRectMake(10., 8., 300., 36.);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return button;
}

@end
