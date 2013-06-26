//
//  VPFileListViewController.m
//  Video Player
//
//  Created by 朱 文杰 on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import "VPFileListViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <MediaPlayer/MediaPlayer.h>
#import <IASKAppSettingsViewController.h>
#import <IASKSettingsReader.h>
#import <SDWebImage/SDImageCache.h>
#import <KKPasscodeLock/KKPasscodeLock.h>
#import <KKPasscodeLock/KKPasscodeSettingsViewController.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "VPTorrentsListViewController.h"
#import "Common.h"
#import "VPFileInfoViewController.h"
#import "AppDelegate.h"

@interface VPFileListViewController () <IASKSettingsDelegate>
@property (nonatomic, strong) NSMutableArray *movieFiles;
@property (nonatomic, strong) MPMoviePlayerViewController *mpViewController;
@end

@implementation VPFileListViewController

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
    self.title = NSLocalizedString(@"Movies List", @"Movies List");
    __block VPFileListViewController *blockSelf = self;
    __block UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"More", @"More") style:UIBarButtonItemStyleBordered handler:^(id sender) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Please select your operation", @"Please select your operation")];
        [sheet addButtonWithTitle:NSLocalizedString(@"Gallary", @"Gallary") handler:^{
            [blockSelf showTorrentsViewer:sender];
        }];
        [sheet addButtonWithTitle:NSLocalizedString(@"Settings", @"Settings") handler:^{
            [blockSelf showSettings:sender];
        }];
        __block BOOL isPasscodeRequired = [[KKPasscodeLock sharedLock] isPasscodeRequired];
        NSString *title = @"";
        if (isPasscodeRequired)
            title = NSLocalizedString(@"Turn off Password", @"Turn off Password");
        else
            title = NSLocalizedString(@"Turn on Password", @"Turn on Password");  
        [sheet addButtonWithTitle:title handler:^{
            KKPasscodeSettingsViewController *vc = [[KKPasscodeSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [self.navigationController pushViewController:vc animated:YES];
        }];
        [sheet setCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel") handler:nil];
        [sheet showFromBarButtonItem:leftButton animated:YES];
    }];
    self.navigationItem.leftBarButtonItem = leftButton;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:ServerSetupDone]) {
        [self loadMovieList:nil];
    }
    else {
        [self showSettings:nil];
    }
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.movieFiles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FileListTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    cell.textLabel.text = [[self.movieFiles[indexPath.row] componentsSeparatedByString:@"/"] lastObject];
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSString *moviePath = [[AppDelegate shared] fileLinkWithPath:[self.movieFiles[indexPath.row] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [[NSURL alloc] initWithString:moviePath];
    if (self.mpViewController)
        self.mpViewController.moviePlayer.contentURL = url;
    else
        self.mpViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    
    [self presentMoviePlayerViewControllerAnimated:self.mpViewController];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![[AppDelegate shared] shouldSendWebRequest]) {
        [[AppDelegate shared] showNetworkAlert];
        return;
    }
    NSString *fileName = [self.movieFiles[indexPath.row] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"%252F"];
    __block VPFileListViewController *blockSelf = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [defaults objectForKey:ServerPathKey];
    NSString *movieInfoPath = [[AppDelegate shared] fileOperation:@"info" withPath:path fileName:fileName];
    NSURL *movieInfoURL = [[NSURL alloc] initWithString:movieInfoPath];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:movieInfoURL];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            VPFileInfoViewController *fileInfoViewController = [[VPFileInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
            fileInfoViewController.delegate = self;
            fileInfoViewController.parentIndexPath = indexPath;
            fileInfoViewController.fileInfo = JSON;
            [blockSelf.navigationController pushViewController:fileInfoViewController animated:YES];
        }
        else {
            [[AppDelegate shared] fileInfoViewController].fileInfo = JSON;
            [[[AppDelegate shared] fileInfoViewController].tableView reloadData];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connection failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }];
    [operation start];
}

#pragma mark - Action methods
- (void)showSettings:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger cacheSizeInBytes = [[SDImageCache sharedImageCache] getSize];
    NSString *cacheSize = @"0B";
    if (cacheSizeInBytes < 1000 * 1000)
        cacheSize = [NSString stringWithFormat:@"%.1f KB", cacheSizeInBytes / 1000.];
    else
        cacheSize = [NSString stringWithFormat:@"%.1f MB", cacheSizeInBytes / (1000. * 1000.)];
    [defaults setObject:cacheSize forKey:ImageCacheSizeKey];
    [defaults synchronize];
    IASKAppSettingsViewController *settingsViewController = [[IASKAppSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    settingsViewController.delegate = self;
    settingsViewController.showCreditsFooter = NO;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        settingsNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:settingsNavigationController animated:YES completion:^{}];
}

- (void)showTorrentsViewer:(id)sender {
    if (![[AppDelegate shared] shouldSendWebRequest]) {
        [[AppDelegate shared] showNetworkAlert];
        return;
    }
    __block VPFileListViewController *blockSelf = self;
    NSURL *torrentsListURL = [[NSURL alloc] initWithString:[[AppDelegate shared] torrentsListPath]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:torrentsListURL];
    UIView *aView = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        aView = [AppDelegate shared].window;
    else
        aView = self.view;
    [MBProgressHUD showHUDAddedTo:aView animated:NO];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [MBProgressHUD hideHUDForView:aView animated:NO];
        VPTorrentsListViewController *torrentsListViewController = [[VPTorrentsListViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *torrentsListNavigationController = [[UINavigationController alloc] initWithRootViewController:torrentsListViewController];
        torrentsListViewController.datesList = JSON;
        [blockSelf presentViewController:torrentsListNavigationController animated:YES completion:^{}];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [MBProgressHUD hideHUDForView:aView animated:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connection failed." delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
        [alert show];
    }];
    [operation start];
}

- (void)loadMovieList:(id)sender {
    if (![[AppDelegate shared] shouldSendWebRequest]) {
        [self showActivityIndicatorInBarButton:NO];
        return;
    }
    [self showActivityIndicatorInBarButton:YES];
    __block VPFileListViewController *blockSelf = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [defaults objectForKey:ServerPathKey];
    NSURL *movieListURL = [[NSURL alloc] initWithString:[[AppDelegate shared] fileLinkWithPath:path]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:movieListURL];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        blockSelf.movieFiles = [NSMutableArray arrayWithArray:JSON];
        [blockSelf.tableView reloadData];
        [blockSelf showActivityIndicatorInBarButton:NO];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connection failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [blockSelf showActivityIndicatorInBarButton:NO];
    }];
    [operation start];
}

#pragma mark - IASKSettingsDelegate
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {
    VPFileListViewController *blockSelf = self;
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:ServerSetupDone];
        [sender synchronizeSettings];
        [blockSelf loadMovieList:nil];
    }];
}

#pragma mark - File Info View Controller Delegate

- (void)fileDidRemovedFromServerForParentIndexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        [self.movieFiles removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else {
        [self loadMovieList:nil];
    }
}

#pragma mark - Helper methods
- (void)showActivityIndicatorInBarButton:(BOOL)show {
    UIBarButtonItem *rightButtom;
    if (show) {
        CGRect frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
        UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithFrame:frame];
        [loading startAnimating];
        [loading sizeToFit];
        loading.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                    UIViewAutoresizingFlexibleRightMargin |
                                    UIViewAutoresizingFlexibleTopMargin |
                                    UIViewAutoresizingFlexibleBottomMargin);
        rightButtom = [[UIBarButtonItem alloc] initWithCustomView:loading];
    }
    else {
        rightButtom = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadMovieList:)];
    }
    self.navigationItem.rightBarButtonItem = rightButtom;
}

@end
