//
//  VPTorrentsListViewController.m
//  Video Player
//
//  Created by venj on 13-6-8.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import "VPTorrentsListViewController.h"
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <BlocksKit+UIKit.h>
#import <TOWebViewController/TOWebViewController.h>
#import <SDWebImage/SDWebImageManager.h>
#import "AppDelegate.h"
#import "VPSearchResultController.h"
#import "Common.h"
#import "NSString+Base64.h"

@interface VPTorrentsListViewController () <MWPhotoBrowserDelegate, UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *datesList;
@property (nonatomic, strong) NSArray *mwPhotos;
@property (nonatomic, strong) NSArray *photos;
@property (nonatomic, strong) NSMutableArray *filteredDatesList;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSDictionary *localizedStatusStrings;
@property (nonatomic, strong) UIBarButtonItem *cloudItem;
@property (nonatomic, strong) UIBarButtonItem *hashItem;
@property (nonatomic, strong) UIBarButtonItem *searchItem;
@end

@implementation VPTorrentsListViewController

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
    
    self.title = NSLocalizedString(@"Torrents", @"Torrents");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh handler:^(id sender) {
        [self loadTorrentList:sender];
    }];
    
    self.localizedStatusStrings = @{@"completed" : NSLocalizedString(@"completed", @"completed"),
                                    @"waiting" : NSLocalizedString(@"waiting", @"waiting"),
                                    @"downloading" : NSLocalizedString(@"downloading", @"downloading"),
                                    @"failed or unknown" : NSLocalizedString(@"failed or unknown", @"failed or unknown")
                                   };
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0., 0., 320., 44.)];
    searchBar.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    searchBar.delegate = self;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    // Revert back to old UITableView behavior
    if ([self.tableView respondsToSelector:@selector(cellLayoutMarginsFollowReadableWidth)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    self.searchController.delegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    self.tableView.tableHeaderView = searchBar;
    [self loadTorrentList:nil];
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
    NSArray *list;
    if (tableView == self.tableView) {
        list = self.datesList;
    }
    else {
        list = self.filteredDatesList;
    }
    if (list) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.tableView) {
        if (self.datesList) {
            return [self.datesList count];
        }
        return 0;
    }
    else {
        return [self.filteredDatesList count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"VPTorrentsListViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    NSArray *list;
    if (tableView == self.tableView) {
        list = self.datesList;
    }
    else {
        list = self.filteredDatesList;
    }
    cell.textLabel.text = list[indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showPhotoBrowserForTableView:tableView atIndexPath:indexPath initialPhotoIndex:0];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:NSLocalizedString(@"Initial Index", @"Initial Index") message:NSLocalizedString(@"Please enter a number for photo index(from 1).", @"Please enter a number for photo index(from 1).")];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField *textField = [alert textFieldAtIndex:0];
    textField.placeholder = @"1";
    [textField setKeyboardType:UIKeyboardTypeNumberPad];
    [alert bk_addButtonWithTitle:NSLocalizedString(@"OK", @"OK") handler:^{
        NSInteger index = [textField.text integerValue];
        if (index < 1) index = 1;
        [self showPhotoBrowserForTableView:tableView atIndexPath:indexPath initialPhotoIndex:(index - 1)];
    }];
    [alert bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel") handler:NULL];
    [alert show];
}

- (void)showPhotoBrowserForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath initialPhotoIndex:(NSInteger)index {
    [self.searchController.searchBar resignFirstResponder];
    NSArray *list;
    if (tableView == self.tableView) {
        list = self.datesList;
    }
    else {
        list = self.filteredDatesList;
    }
    NSString *date = [list[indexPath.row] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    __weak VPTorrentsListViewController *blockSelf = self;
    UIView *aView = self.navigationController.view;
    [MBProgressHUD showHUDAddedTo:aView animated:YES];
    AFHTTPSessionManager *manager = [[AppDelegate shared] refreshedManager];
    [manager GET:[[AppDelegate shared] searchPathWithKeyword:date] parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        [MBProgressHUD hideHUDForView:aView animated:YES];
        if ([responseObject count] == 0) { return; }
        blockSelf.mwPhotos = [blockSelf mwPhotosArrayWithPhothsArray:responseObject];
        MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:blockSelf];
        photoBrowser.displayActionButton = NO;
        photoBrowser.displayNavArrows = YES;
        photoBrowser.zoomPhotosToFill = NO;
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        NSInteger sIndex = index;
        if (sIndex > [responseObject count] - 1) sIndex = ([responseObject count] - 1);
        self.photos = responseObject; //Save for add torrent.
        [photoBrowser setCurrentPhotoIndex:sIndex];
        [blockSelf.navigationController pushViewController:photoBrowser animated:YES];
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:aView animated:YES];
        [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Connection failed.", @"Connection failed.") inView:self.navigationController.view];
    }];
}

#pragma mark - SearchDisplayController Delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    self.filteredDatesList = [NSMutableArray arrayWithArray:self.datesList];
    for (NSString *dateString in self.datesList) {
        if ([dateString rangeOfString:searchString].location == NSNotFound) {
            [self.filteredDatesList removeObject:dateString];
        }
    }
    [self.searchDisplayController.searchResultsTableView reloadData];
    return YES;
}

#pragma mark - Action Method

- (void)loadTorrentList:(id)sender {
    __weak VPTorrentsListViewController *blockSelf = self;
    UIView *aView = self.navigationController.view;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:aView animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    AFHTTPSessionManager *manager = [[AppDelegate shared] refreshedManager];
    [manager GET:[[AppDelegate shared] torrentsListPath] parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        [hud hide:YES];
        blockSelf.navigationItem.rightBarButtonItem.enabled = YES;
        blockSelf.datesList = responseObject;
        [blockSelf.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:aView animated:YES];
        [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Connection failed.", @"Connection failed.") inView:self.navigationController.view];
        blockSelf.navigationItem.rightBarButtonItem.enabled = YES;
    }];
}

#pragma mark - MWPhotoBrowser delegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.mwPhotos.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.mwPhotos.count)
        return self.mwPhotos[index];
    return nil;
}

#pragma mark - Helper

- (NSArray *)mwPhotosArrayWithPhothsArray:(NSArray *)photos {
    NSMutableArray *mwPhotos = [NSMutableArray array];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [defaults objectForKey:ServerPathKey];
    NSString *linkBase = [[AppDelegate shared] fileLinkWithPath:path];
    for (NSString *photo in photos) {
        NSString *fileName = [photo stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        MWPhoto *p = [MWPhoto photoWithURL:[NSURL URLWithString:[linkBase stringByAppendingPathComponent:fileName]]];
        p.caption = [photo lastPathComponent];
        [mwPhotos addObject:p];
    }
    return mwPhotos;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    photoBrowser.navigationItem.rightBarButtonItems  = @[[self theSearchItem], [self hashItemWithIndex:index]];
}

- (UIBarButtonItem *)hashItemWithIndex:(NSUInteger)index {
    self.hashItem = [[UIBarButtonItem alloc] bk_initWithImage:[UIImage imageNamed:@"magnet"] style:UIBarButtonItemStylePlain handler:^(id sender) {
        NSString *base64FileName = [self.photos[index] base64String];
        __weak typeof(self) weakself = self;
        AFHTTPSessionManager *manager = [[AppDelegate shared] refreshedManager];
        [manager GET:[[AppDelegate shared] hashTorrentWithName:base64FileName] parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            NSString *message = [NSString stringWithFormat:@"magnet:?xt=urn:btih:%@", [responseObject[@"hash"] uppercaseString]];
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            pb.string = message;
            [[AppDelegate shared] parseSessionAndAddTask:message completionHandler:^{
                [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Task added.", @"Task added.") inView:weakself.navigationController.view];
            } errorHandler:^{
                [[AppDelegate shared]  showHudWithMessage:NSLocalizedString(@"Unknow error.", @"Unknow error.") inView:weakself.navigationController.view];
            }];
        } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
            NSLog(@"%@", [error localizedDescription]);
            [[AppDelegate shared]  showHudWithMessage:NSLocalizedString(@"Connection failed.", @"Connection failed.") inView:weakself.navigationController.view];
        }];
    }];
    return self.hashItem;
}

- (UIBarButtonItem *)theSearchItem {
    if (self.searchItem) { return self.searchItem; }
    __weak typeof(self) weakSelf = self;
    self.searchItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemSearch handler:^(id sender) {
        [[AppDelegate shared] showTorrentSearchAlertInNavigationController:weakSelf.navigationController];
    }];
    
    return self.searchItem;
}

@end
