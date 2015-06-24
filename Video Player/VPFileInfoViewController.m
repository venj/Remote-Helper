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
#import <MBProgressHUD/MBProgressHUD.h>

@interface VPFileInfoViewController ()
@property (nonatomic, strong) MPMoviePlayerViewController *mpViewController;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemPlay handler:^(id sender) {
        if (!self.fileInfo) return;
        NSString *moviePath;
        NSURL *url;
        if (self.isLocalFile) {
            moviePath = self.fileInfo[@"file"];
            url = [NSURL fileURLWithPath:moviePath];
        }
        else {
            url = [[AppDelegate shared] videoPlayURLWithPath:self.fileInfo[@"file"]];
            if ([[url absoluteString] rangeOfString:@"http"].location != NSNotFound && ![[AppDelegate shared] shouldSendWebRequest]) {
                [[AppDelegate shared] showNetworkAlert];
                return;
            }
        }
        
        self.mpViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
        
        [self presentMoviePlayerViewControllerAnimated:self.mpViewController];
    }];
    
    self.button = [self deleteButton];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 320, 60.)];
    footerView.backgroundColor = [UIColor clearColor];
    [footerView addSubview:self.button];
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
        if (!self.isLocalFile && ![[NSFileManager defaultManager] fileExistsAtPath:[[AppDelegate shared] fileToDownloadWithPath:self.fileInfo[@"file"]]]) {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
    }
    else if (indexPath.row == 1) {
        k = NSLocalizedString(@"Path", @"Path");
        v = [path stringByReplacingOccurrencesOfString:[[AppDelegate shared] documentsDirectory] withString:@""];
    }
    else if (indexPath.row == 2) {
        k = NSLocalizedString(@"Size", @"Size");
        NSInteger size = [self.fileInfo[@"size"] unsignedLongLongValue];
        v = [[AppDelegate shared] fileSizeStringWithInteger:size];
    }
    cell.textLabel.text = k;
    cell.detailTextLabel.text = v;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (self.isLocalFile) {
        return;
    }
    if (indexPath.row == 0) {
        if ([self.fileInfo[@"size"] unsignedLongLongValue] > [[AppDelegate shared] freeDiskSpace]) {
            [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"No Space", @"No Space") message:[NSString stringWithFormat:NSLocalizedString(@"You don't have enough free space on your device to download \"%@\".", @"You don't have enough free space on your device to download \"%@\"."), [self.fileInfo[@"file"] lastPathComponent]] cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {}];
            return;
        }
        __weak VPFileInfoViewController *blockSelf = self;
        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Comfirm Download", @"Comfirm Download") message:[NSString stringWithFormat:NSLocalizedString(@"Are you sure to download \"%@\" to your device?", @"Are you sure to download \"%@\" to your device?"), [self.fileInfo[@"file"] lastPathComponent]] cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") otherButtonTitles:@[NSLocalizedString(@"Download", @"Download")] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != [alertView cancelButtonIndex]) {
                if (!blockSelf.progressHUD)
                    blockSelf.progressHUD = [MBProgressHUD showHUDAddedTo:blockSelf.tableView.window animated:YES];
                blockSelf.progressHUD.labelText = NSLocalizedString(@"Downloading", @"Downloading");
                NSString *path = [[AppDelegate shared] fileLinkWithPath:[blockSelf.fileInfo[@"file"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                NSURL *url = [NSURL URLWithString:path];
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
                request.timeoutInterval = REQUEST_TIME_OUT;
                AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
                NSOutputStream *oStream = [[NSOutputStream alloc] initToFileAtPath:[[AppDelegate shared] fileToDownloadWithPath:blockSelf.fileInfo[@"file"]] append:NO];
                [operation setOutputStream:oStream];
                [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                    unsigned long long staticFileSize = [self.fileInfo[@"size"] unsignedLongLongValue];
                    if (totalBytesExpectedToRead < 0)
                        totalBytesExpectedToRead = staticFileSize;
                    if (totalBytesExpectedToRead <= 0) { // In case file size returned from server less than 0.
                        blockSelf.progressHUD.mode = MBProgressHUDModeIndeterminate;
                        blockSelf.progressHUD.labelText = [NSString stringWithFormat:NSLocalizedString(@"Downloading(%@)", @"Downloading(%@)"), [[AppDelegate shared] fileSizeStringWithInteger:totalBytesRead]];
                    }
                    else {
                        blockSelf.progressHUD.mode = MBProgressHUDModeDeterminate;
                        blockSelf.progressHUD.progress = totalBytesRead / (totalBytesExpectedToRead * 1.0);
                        blockSelf.progressHUD.labelText = [NSString stringWithFormat:NSLocalizedString(@"Downloading(%.0f%%)", @"Downloading(%.0%%)"), blockSelf.progressHUD.progress * 100];
                    }
                }];
                [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [MBProgressHUD hideHUDForView:blockSelf.tableView.window animated:YES];
                    [NSTimer bk_scheduledTimerWithTimeInterval:0.3 block:^(NSTimer *timer) {
                        blockSelf.progressHUD = nil;
                    } repeats:NO];
                    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    [NSTimer bk_scheduledTimerWithTimeInterval:0.25 block:^(NSTimer *timer) {
                        [blockSelf.navigationController popToRootViewControllerAnimated:YES];
                    } repeats:NO];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [MBProgressHUD hideHUDForView:blockSelf.tableView.window animated:YES];
                    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    [NSTimer bk_scheduledTimerWithTimeInterval:0.3 block:^(NSTimer *timer) {
                        blockSelf.progressHUD = nil;
                    } repeats:NO];
                    [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Download Failed", @"Download Failed") message:[NSString stringWithFormat:NSLocalizedString(@"Failed to download \"%@\", please try agian later.", @"Failed to download \"%@\", please try agian later."), [blockSelf.fileInfo[@"file"] lastPathComponent]] cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                        [[NSFileManager defaultManager] removeItemAtPath:[[AppDelegate shared] fileToDownloadWithPath:self.fileInfo[@"file"]] error:NULL];
                    }];
                }];
                [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
                    [MBProgressHUD hideHUDForView:blockSelf.tableView.window animated:NO];
                    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                    NSFileManager *fm = [NSFileManager defaultManager];
                    NSString *path = [[AppDelegate shared] fileToDownloadWithPath:self.fileInfo[@"file"]];
                    NSDictionary *attributes = [fm attributesOfItemAtPath:path error:NULL];
                    if ([attributes[NSFileSize] unsignedLongLongValue] < [self.fileInfo[@"size"] unsignedLongLongValue]) {
                        [fm removeItemAtPath:[[AppDelegate shared] fileToDownloadWithPath:self.fileInfo[@"file"]] error:NULL];
                    }
                }];
                if ([[AppDelegate shared] useSSL]) { [operation setAllowsInvalidSSLCertificate:YES]; }
                [operation start];
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            }
        }];
    }
}

#pragma mark - Action method

- (void)deleteFile:(id)sender {
    if (!self.fileInfo) {
        return;
    }
    __weak VPFileInfoViewController *blockSelf = self;
    [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Delete File", @"Delete File") message:[NSString stringWithFormat:NSLocalizedString(@"Are you sure to delete \"%@\".", @"Are you sure to delete \"%@\"."), [[self.fileInfo[@"file"] componentsSeparatedByString:@"/"] lastObject]] cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") otherButtonTitles:@[NSLocalizedString(@"Delete", @"Delete")] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            if (blockSelf.isLocalFile) {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error;
                [fileManager removeItemAtPath:blockSelf.fileInfo[@"file"] error:&error];
                NSString *message = nil;
                if (error)
                    message = [NSString stringWithFormat:NSLocalizedString(@"Failed to delete file \"%@\".", @"Failed to delete file \"%@\"."), [blockSelf.fileInfo[@"file"] lastPathComponent]];
                else
                    message = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" has been deleted from your device.", @"\"%@\" has been deleted from your device."), [blockSelf.fileInfo[@"file"] lastPathComponent]];
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Delete File", @"Delete File") message:message cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (error) return;
                    if ([blockSelf.delegate respondsToSelector:@selector(fileDidRemovedFromServerForParentIndexPath:)]) {
                        [NSTimer bk_scheduledTimerWithTimeInterval:0.3 block:^(NSTimer *timer) {
                            [blockSelf.delegate fileDidRemovedFromServerForParentIndexPath:blockSelf.parentIndexPath];
                        } repeats:NO];
                    }
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                        [blockSelf.navigationController popViewControllerAnimated:YES];
                    }
                    else {
                        blockSelf.fileInfo = nil;
                        [blockSelf.tableView reloadData];
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
                [request setAllHTTPHeaderFields:@{@"User-Agent" : [[AppDelegate shared] customUserAgent]}];
                request.HTTPMethod = @"DELETE";
                
                AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                    [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Delete File", @"Delete File") message:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" has been deleted from the server.", @"\"%@\" has been deleted from the server."), [[self.fileInfo[@"file"] componentsSeparatedByString:@"/"] lastObject]] cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                        if ([blockSelf.delegate respondsToSelector:@selector(fileDidRemovedFromServerForParentIndexPath:)]) {
                            [NSTimer bk_scheduledTimerWithTimeInterval:0.3 block:^(NSTimer *timer) {
                                [blockSelf.delegate fileDidRemovedFromServerForParentIndexPath:blockSelf.parentIndexPath];
                            } repeats:NO];
                        }
                        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                            [blockSelf.navigationController popViewControllerAnimated:YES];
                        }
                        else {
                            blockSelf.fileInfo = nil;
                            [blockSelf.tableView reloadData];
                        }
                    }];
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:NSLocalizedString(@"Connection failed.", @"Connection failed.") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
                    [alert show];
                }];
                if ([[AppDelegate shared] useSSL]) { [operation setAllowsInvalidSSLCertificate:YES]; }
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        button.frame = CGRectMake(8., 8., 304., 36.);
    }
    else {
        button.frame = CGRectMake(40., 8., 240., 36.);
    }
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return button;
}

@end
