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
#import "AppDelegate.h"
#import "Common.h"



@interface VPTorrentsListViewController () <MWPhotoBrowserDelegate, UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *datesList;
@property (nonatomic, strong) NSArray *mwPhotos;
@property (nonatomic, strong) NSMutableArray *filteredDatesList;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSDictionary *localizedStatusStrings;
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.title = NSLocalizedString(@"Torrents", @"Torrents");
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone handler:^(id sender) {
            [self dismissModalViewControllerAnimated:YES];
        }];
    }
    else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh handler:^(id sender) {
            [self loadTorrentList:sender];
        }];
    }
    
    self.localizedStatusStrings = @{@"completed" : NSLocalizedString(@"completed", @"completed"),
                                    @"waiting" : NSLocalizedString(@"waiting", @"waiting"),
                                    @"downloading" : NSLocalizedString(@"downloading", @"downloading"),
                                    @"failed or unknown" : NSLocalizedString(@"failed or unknown", @"failed or unknown")
                                   };
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0., 0., 320., 44.)];
    searchBar.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    searchBar.delegate = self;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
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
    UIAlertView *alert = [UIAlertView alertViewWithTitle:NSLocalizedString(@"Initial Index", @"Initial Index") message:NSLocalizedString(@"Please enter a number for photo index(from 1).", @"Please enter a number for photo index(from 1).")];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField *textField = [alert textFieldAtIndex:0];
    textField.placeholder = @"1";
    [textField setKeyboardType:UIKeyboardTypeNumberPad];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK") handler:^{
        NSInteger index = [textField.text integerValue];
        if (index < 1) index = 1;
        [self showPhotoBrowserForTableView:tableView atIndexPath:indexPath initialPhotoIndex:(index - 1)];
    }];
    [alert setCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel") handler:NULL];
    [alert show];
}

- (void)showPhotoBrowserForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath initialPhotoIndex:(NSInteger)index {
    [self.searchController.searchBar resignFirstResponder];
    if (![[AppDelegate shared] shouldSendWebRequest]) {
        [[AppDelegate shared] showNetworkAlert];
        return;
    }
    NSArray *list;
    if (tableView == self.tableView) {
        list = self.datesList;
    }
    else {
        list = self.filteredDatesList;
    }
    NSString *date = [list[indexPath.row] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    __weak VPTorrentsListViewController *blockSelf = self;
    NSURL *movieListURL = [[NSURL alloc] initWithString:[[AppDelegate shared] searchPathWithKeyword:date]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:movieListURL];
    UIView *aView = [AppDelegate shared].window;
    [MBProgressHUD showHUDAddedTo:aView animated:YES];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [MBProgressHUD hideHUDForView:aView animated:YES];
        if ([JSON count] == 0) { return; }
        blockSelf.mwPhotos = [blockSelf mwPhotosArrayWithPhothsArray:JSON];
        MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:blockSelf];
        photoBrowser.wantsFullScreenLayout = YES;
        photoBrowser.displayActionButton = NO;
        NSInteger sIndex = index;
        if (sIndex > [JSON count] - 1) sIndex = ([JSON count] - 1);
        [photoBrowser setInitialPageIndex:sIndex];
        __block UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cloud Download", @"Cloud Download") style:UIBarButtonItemStyleBordered handler:^(id sender) {
            [item setEnabled:NO];
            NSString *fileName = [JSON[photoBrowser.currentPageIndex] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"%252F"];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            BOOL asyncAddTask = [defaults boolForKey:AsyncAddCloudTaskKey];
            NSURLRequest *addTorrentRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[[AppDelegate shared] addTorrentWithName:fileName async:asyncAddTask]]];
            AFJSONRequestOperation *trOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:addTorrentRequest success:^(NSURLRequest *req, NSHTTPURLResponse *res, id anotherJSON) {
                NSString *title, *message;
                if (asyncAddTask) {
                    title = NSLocalizedString(@"Task added", @"Task added");
                    message = NSLocalizedString(@"Torrent added! Please check your Xunlei account.", @"Torrent added! Please check your Xunlei account.");
                }
                else {
                    title = NSLocalizedString(@"Result", @"Result");
                    message = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"Torrent added! Download status:\n", @"Torrent added! Download status:\n"), self.localizedStatusStrings[anotherJSON[@"status"]]];
                }
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
                [alert show];
                [item setEnabled:YES];
            } failure:^(NSURLRequest *req, NSHTTPURLResponse *res, NSError *err, id anotherJSON) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:NSLocalizedString(@"Connection failed.", @"Connection failed.") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
                [alert show];
                [item setEnabled:YES];
            }];
            [trOperation start];
        }];
        photoBrowser.navigationItem.rightBarButtonItem = item;
        [self.navigationController pushViewController:photoBrowser animated:YES];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [MBProgressHUD hideHUDForView:aView animated:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:NSLocalizedString(@"Connection failed.", @"Connection failed.") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
        [alert show];
    }];
    [operation start];
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
    if (![[AppDelegate shared] shouldSendWebRequest]) {
        if (sender != nil) [[AppDelegate shared] showNetworkAlert];
        return;
    }
    
    __weak VPTorrentsListViewController *blockSelf = self;
    NSURL *torrentsListURL = [[NSURL alloc] initWithString:[[AppDelegate shared] torrentsListPath]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:torrentsListURL];
    UIView *aView = [AppDelegate shared].window;
    [MBProgressHUD showHUDAddedTo:aView animated:YES];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [MBProgressHUD hideHUDForView:aView animated:YES];
        blockSelf.navigationItem.rightBarButtonItem.enabled = YES;
        blockSelf.datesList = JSON;
        [blockSelf.tableView reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [MBProgressHUD hideHUDForView:aView animated:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:NSLocalizedString(@"Connection failed.", @"Connection failed.") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
        [alert show];
        blockSelf.navigationItem.rightBarButtonItem.enabled = YES;
    }];
    [operation start];
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
        fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
        MWPhoto *p = [MWPhoto photoWithURL:[NSURL URLWithString:[linkBase stringByAppendingPathComponent:fileName]]];
        p.caption = [photo lastPathComponent];
        [mwPhotos addObject:p];
    }
    return mwPhotos;
}

@end
