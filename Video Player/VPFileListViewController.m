//
//  VPFileListViewController.m
//  Video Player
//
//  Created by Venj Chu on 13-5-27.
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
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "VPTorrentsListViewController.h"
#import "Common.h"
#import "VPFileInfoViewController.h"
#import "VCFileAttributeHelper.h"
#import "AppDelegate.h"

@interface VPFileListViewController () <IASKSettingsDelegate, KKPasscodeSettingsViewControllerDelegate, MWPhotoBrowserDelegate>
@property (nonatomic, strong) MPMoviePlayerViewController *mpViewController;
@property (nonatomic, strong) IASKAppSettingsViewController *settingsViewController;
@property (nonatomic, strong) UIActionSheet *sheet;
@property (nonatomic, strong) NSArray *mwPhotos;
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
    __weak VPFileListViewController *blockSelf = self;
    
    if (self.isLocal) {
        self.title = NSLocalizedString(@"Local", @"Local");
        UIBarButtonItem *rightButtom = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadMovieList:)];
        self.navigationItem.rightBarButtonItem = rightButtom;
        [self loadMovieList:nil];
    }
    else {
        self.title = NSLocalizedString(@"Server", @"Server");
        __block UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] bk_initWithTitle:NSLocalizedString(@"More", @"More") style:UIBarButtonItemStyleBordered handler:^(id sender) {
            blockSelf.sheet = [[UIActionSheet alloc] bk_initWithTitle:NSLocalizedString(@"Please select your operation", @"Please select your operation")];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [self.sheet bk_addButtonWithTitle:NSLocalizedString(@"Torrents", @"Torrents") handler:^{
                    [blockSelf showTorrentsViewer:sender];
                }];
            }
            [blockSelf.sheet bk_addButtonWithTitle:NSLocalizedString(@"Settings", @"Settings") handler:^{
                [blockSelf showSettings:sender];
            }];
            [blockSelf.sheet bk_addButtonWithTitle:NSLocalizedString(@"Cache Browser", @"Cache Browser") handler:^{
                [blockSelf browseCache:sender];
            }];
            [blockSelf.sheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel") handler:^{}];
            [blockSelf.sheet showFromBarButtonItem:leftButton animated:YES];
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
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.isLocal) {
        [NSTimer bk_scheduledTimerWithTimeInterval:0.5 block:^(NSTimer *timer) {
            [self loadMovieList:nil];
        } repeats:NO];
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
    return [self.dataList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FileListTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    if (self.isLocal) {
        NSURL *fileURL = self.dataList[indexPath.row];
        cell.textLabel.text = [fileURL lastPathComponent];
    }
    else {
        cell.textLabel.text = [self.dataList[indexPath.row] lastPathComponent];
    }
    //cell.textLabel.font = [UIFont boldSystemFontOfSize:17.];
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSURL *url;
    if (self.isLocal) {
        url = self.dataList[indexPath.row];
    }
    else {
        url = [[AppDelegate shared] videoPlayURLWithPath:self.dataList[indexPath.row]];
        if ([[url absoluteString] rangeOfString:@"http"].location != NSNotFound && ![[AppDelegate shared] shouldSendWebRequest]) {
            [[AppDelegate shared] showNetworkAlert];
            return;
        }
    }
    
    self.mpViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    
    [self presentMoviePlayerViewControllerAnimated:self.mpViewController];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isLocal) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *currentFile = [self.dataList[indexPath.row] path];
        NSError *error;
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:currentFile error:&error];
        if (error) {
            NSLog(NSLocalizedString(@"Error read file attributes. Reason: %@", @"Error read file attributes. Reason: %@"), [error description]);
            return;
        }
        NSDictionary *fileInfo = @{@"file": currentFile, @"size": attributes[NSFileSize]};
        VPFileInfoViewController *fileInfoViewController = [[VPFileInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
        fileInfoViewController.delegate = self;
        fileInfoViewController.parentIndexPath = indexPath;
        fileInfoViewController.fileInfo = fileInfo;
        fileInfoViewController.isLocalFile = YES;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self.navigationController pushViewController:fileInfoViewController animated:YES];
        }
        else {
            VPFileInfoViewController *fileInfoViewController = [[AppDelegate shared] fileInfoViewController];
            fileInfoViewController.fileInfo = fileInfo;
            fileInfoViewController.parentIndexPath = indexPath;
            fileInfoViewController.isLocalFile = NO;
            [fileInfoViewController.tableView reloadData];
        }
    }
    else {
        if (![[AppDelegate shared] shouldSendWebRequest]) {
            [[AppDelegate shared] showNetworkAlert];
            return;
        }
        NSString *fileName = [self.dataList[indexPath.row] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"%252F"];
        __weak VPFileListViewController *blockSelf = self;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *path = [defaults objectForKey:ServerPathKey];
        NSString *movieInfoPath = [[AppDelegate shared] fileOperation:@"info" withPath:path fileName:fileName];
        NSURL *movieInfoURL = [[NSURL alloc] initWithString:movieInfoPath];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:movieInfoURL];
        request.timeoutInterval = REQUEST_TIME_OUT;
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            if ((JSON[@"exist"] != nil) && ([JSON[@"exist"] boolValue] == NO)) {
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:NSLocalizedString(@"%@ was deleted from the server.", @"%@ was deleted from the server."), [self.dataList[indexPath.row] lastPathComponent]] cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    [blockSelf.dataList removeObjectAtIndex:indexPath.row];
                    [blockSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                }];
                return;
            }
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                VPFileInfoViewController *fileInfoViewController = [[VPFileInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
                fileInfoViewController.delegate = self;
                fileInfoViewController.parentIndexPath = indexPath;
                fileInfoViewController.fileInfo = JSON;
                fileInfoViewController.isLocalFile = NO;
                [blockSelf.navigationController pushViewController:fileInfoViewController animated:YES];
            }
            else {
                VPFileInfoViewController *fileInfoViewController = [[AppDelegate shared] fileInfoViewController];
                fileInfoViewController.fileInfo = JSON;
                fileInfoViewController.parentIndexPath = indexPath;
                fileInfoViewController.isLocalFile = NO;
                [fileInfoViewController.tableView reloadData];
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [self showHudWithMessage:NSLocalizedString(@"Connection failed.", @"Connection failed.")];
        }];
        [operation start];
    }
}

#pragma mark - Action methods
- (void)showSettings:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger cacheSizeInBytes = [[SDImageCache sharedImageCache] getSize];
    NSString *cacheSize = [[AppDelegate shared] fileSizeStringWithInteger:cacheSizeInBytes];
    [defaults setObject:cacheSize forKey:ImageCacheSizeKey];
    NSString *status = [[KKPasscodeLock sharedLock] isPasscodeRequired] ? NSLocalizedString(@"On", @"On"): NSLocalizedString(@"Off", @"Off");
    [defaults setObject:status forKey:PasscodeLockStatus];
    NSString *localFileSize = [[AppDelegate shared] fileSizeStringWithInteger:[[AppDelegate shared] localFileSize]];
    [defaults setObject:localFileSize forKey:LocalFileSize];
    NSString *deviceFreeSpace = [[AppDelegate shared] fileSizeStringWithInteger:[[AppDelegate shared] freeDiskSpace]];
    [defaults setObject:deviceFreeSpace forKey:DeviceFreeSpace];
    [defaults synchronize];
    self.settingsViewController = [[IASKAppSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.settingsViewController];
    self.settingsViewController.delegate = self;
    self.settingsViewController.showCreditsFooter = NO;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        settingsNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:settingsNavigationController animated:YES completion:^{}];
}

- (void)showTorrentsViewer:(id)sender {
    VPTorrentsListViewController *torrentsListViewController = [[VPTorrentsListViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *torrentsListNavigationController = [[UINavigationController alloc] initWithRootViewController:torrentsListViewController];
    [self presentViewController:torrentsListNavigationController animated:YES completion:^{}];
}

- (void)loadMovieList:(id)sender {
    __weak VPFileListViewController *blockSelf = self;
    if (self.isLocal) {
        if (!self.dataList) {
            self.dataList = [[NSMutableArray alloc] init];
        }
        else {
            [self.dataList removeAllObjects];
        }
        NSString *documentsDirectory = [[AppDelegate shared] documentsDirectory];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *files = [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:documentsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
        if (error) {
            NSLog(NSLocalizedString(@"Error loading file list. Reason: %@", @"Error loading file list. Reason: %@"), [error description]);
            return;
        }
        [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [VCFileAttributeHelper addSkipBackupAttributeToItemAtURL:obj];
            NSString *fileExtension = [[(NSURL *)obj pathExtension] lowercaseString];
            if ([[@[@"mp4", @"m4v", @"mov"] indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                return [obj isEqualToString:fileExtension] ? YES : NO ;
            }] count] != 0) {
                [blockSelf.dataList addObject:obj];
            }
        }];
        [self.tableView reloadData];
    }
    else {
        if (![[AppDelegate shared] shouldSendWebRequest]) {
            if (sender) {
                [[AppDelegate shared] showNetworkAlert];
            }
            [self showActivityIndicatorInBarButton:NO];
            return;
        }
        [self showActivityIndicatorInBarButton:YES];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *path = [defaults objectForKey:ServerPathKey];
        NSURL *movieListURL = [[NSURL alloc] initWithString:[[AppDelegate shared] fileLinkWithPath:path]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:movieListURL];
        request.timeoutInterval = REQUEST_TIME_OUT;
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            blockSelf.dataList = [NSMutableArray arrayWithArray:JSON];
            [blockSelf.tableView reloadData];
            [blockSelf showActivityIndicatorInBarButton:NO];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            [self showHudWithMessage:NSLocalizedString(@"Connection failed.", @"Connection failed.")];
            [blockSelf showActivityIndicatorInBarButton:NO];
        }];
        [operation start];
    }
}

- (void)browseCache:(id)sender {
    self.mwPhotos = [self fetchCacheFileList];
    if (self.mwPhotos.count == 0) return;
    MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    photoBrowser.wantsFullScreenLayout = YES;
    photoBrowser.displayActionButton = NO;
    photoBrowser.displayNavArrows = YES;
    photoBrowser.zoomPhotosToFill = NO;
    [photoBrowser setCurrentPhotoIndex:0];
    [self.navigationController pushViewController:photoBrowser animated:YES];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.mwPhotos.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.mwPhotos.count)
        return self.mwPhotos[index];
    return nil;
}

- (NSArray *)fetchCacheFileList {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDir = [paths[0] stringByAppendingPathComponent:@"com.hackemist.SDWebImageCache.default"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSArray *arr = [fm contentsOfDirectoryAtPath:cacheDir error:&error];
    if (error) {
        return nil;
    }
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for (NSString *f in arr) {
        [files addObject:[MWPhoto photoWithURL:[NSURL fileURLWithPath:[cacheDir stringByAppendingPathComponent:f]]]];
    }
    return files;
}

- (void)showHudWithMessage:(NSString *)message forView:(UIView *)aView {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:aView animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    [hud hide:YES afterDelay:1];
}

- (void)showHudWithMessage:(NSString *)message {
    UIView *aView = self.navigationController.view;
    [self showHudWithMessage:message forView:aView];
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

- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
    if ([specifier.key isEqualToString:PasscodeLockConfig]) {
        KKPasscodeSettingsViewController *vc = [[KKPasscodeSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        vc.delegate = self;
        [sender.navigationController pushViewController:vc animated:YES];
    }
    else if ([specifier.key isEqualToString:ClearCacheNowKey]) {
        UIView *aView = sender.navigationController.view;
        [MBProgressHUD showHUDAddedTo:aView animated:YES];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[SDImageCache sharedImageCache] clearDisk]; // Clear Image Cache
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *localFileSize = [[AppDelegate shared] fileSizeStringWithInteger:[[AppDelegate shared] localFileSize]];
            [defaults setObject:localFileSize forKey:LocalFileSize];
            [defaults synchronize];
            [sender synchronizeSettings];
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:aView animated:YES];
                [self showHudWithMessage:NSLocalizedString(@"Cache Cleared!", @"Cache Cleared!") forView:aView];
                [sender.tableView reloadData];
            });
        });
    }
}

#pragma mark - KKPasscode View Controller Delegate

- (void)didSettingsChanged:(KKPasscodeViewController*)viewController {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *status = [[KKPasscodeLock sharedLock] isPasscodeRequired] ? NSLocalizedString(@"On", @"On"): NSLocalizedString(@"Off", @"Off");
    [defaults setObject:status forKey:PasscodeLockStatus];
    [defaults synchronize];
    [self.settingsViewController.tableView reloadData];
}

#pragma mark - File Info View Controller Delegate

- (void)fileDidRemovedFromServerForParentIndexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        [self.dataList removeObjectAtIndex:indexPath.row];
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
