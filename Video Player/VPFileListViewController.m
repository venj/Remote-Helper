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
#import "Common.h"
#import "VPFileInfoViewController.h"
#import "AppDelegate.h"

@interface VPFileListViewController () <IASKSettingsDelegate>
@property (nonatomic, strong) NSArray *movieFiles;
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
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", @"Settings") style:UIBarButtonItemStyleBordered handler:^(id sender) {
        [blockSelf showSettings:sender];
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
    NSString *fileName = [self.movieFiles[indexPath.row] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    __block VPFileListViewController *blockSelf = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [defaults objectForKey:ServerPathKey];
    NSString *movieInfoPath = [[AppDelegate shared] fileInfoWithPath:path fileName:fileName];
    NSURL *movieInfoURL = [[NSURL alloc] initWithString:movieInfoPath];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:movieInfoURL];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            VPFileInfoViewController *fileInfoViewController = [[VPFileInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
    IASKAppSettingsViewController *settingsViewController = [[IASKAppSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    settingsViewController.delegate = self;
    settingsViewController.showCreditsFooter = NO;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        settingsNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:settingsNavigationController animated:YES completion:^{}];
}

- (void)loadMovieList:(id)sender {
    [self showActivityIndicatorInBarButton:YES];
    __block VPFileListViewController *blockSelf = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [defaults objectForKey:ServerPathKey];
    NSURL *movieListURL = [[NSURL alloc] initWithString:[[AppDelegate shared] fileLinkWithPath:path]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:movieListURL];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        blockSelf.movieFiles = JSON;
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
