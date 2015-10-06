//
//  VPFileListViewController.m
//  Video Player
//
//  Created by Venj Chu on 13-5-27.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import "WebContentTableViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <MediaPlayer/MediaPlayer.h>
#import <IASKAppSettingsViewController.h>
#import <IASKSettingsReader.h>
#import <SDWebImage/SDImageCache.h>
#import <LTHPasscodeViewController/LTHPasscodeViewController.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <BlocksKit+UIKit.h>
#import <TOWebViewController/TOWebViewController.h>
#import "VPTorrentsListViewController.h"
#import "Common.h"
#import "VCFileAttributeHelper.h"
#import "AppDelegate.h"
#import "ValidLinksTableViewController.h"
#import "HYXunleiLixianAPI.h"

static NSString *reuseIdentifier = @"WebContentTableViewControllerReuseIdentifier";

@interface WebContentTableViewController () <IASKSettingsDelegate, MWPhotoBrowserDelegate>
@property (nonatomic, strong) MPMoviePlayerViewController *mpViewController;
@property (nonatomic, strong) IASKAppSettingsViewController *settingsViewController;
@property (nonatomic, strong) UIActionSheet *sheet;
@property (nonatomic, strong) NSArray *mwPhotos;
@property (nonatomic, strong) NSMutableArray *addresses;
@end

@implementation WebContentTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Addresses", @"Addresses");
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseIdentifier];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id sender) {
        // Add address
        UIAlertView *alert = [[UIAlertView alloc] bk_initWithTitle:NSLocalizedString(@"Add address", @"Add address") message:NSLocalizedString(@"Please input an address:", @"Please input an address:")];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textField = [alert textFieldAtIndex:0];
        textField.keyboardType = UIKeyboardTypeURL;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.text = @"http://";
        __weak typeof(self) weakself = self;
        [alert bk_addButtonWithTitle:NSLocalizedString(@"Save", @"Save") handler:^{
            NSString *address = textField.text;
            [weakself.addresses addObject:address];
            [weakself saveAddresses];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.addresses count] - 1 inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        [alert bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel") handler:^{}];
        [alert show];
    }];
    [self readAddresses];

    if (self.addresses == nil) {
        self.addresses = [[NSMutableArray alloc] init];
        [self saveAddresses];
    }

    __weak typeof(self) weakself = self;
    __block UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] bk_initWithTitle:NSLocalizedString(@"More", @"More") style:UIBarButtonItemStylePlain handler:^(id sender) {
        weakself.sheet = [[UIActionSheet alloc] bk_initWithTitle:NSLocalizedString(@"Please select your operation", @"Please select your operation")];
        [weakself.sheet bk_addButtonWithTitle:NSLocalizedString(@"Transmission", @"Transmission") handler:^{
            [weakself showTransmission:nil];
        }];
        [weakself.sheet bk_addButtonWithTitle:NSLocalizedString(@"Settings", @"Settings") handler:^{
            [weakself showSettings:sender];
        }];
        [weakself.sheet bk_addButtonWithTitle:NSLocalizedString(@"Torrent Search", @"Torrent Search") handler:^{
            [weakself torrentSearch:sender];
        }];
        [weakself.sheet bk_addButtonWithTitle:NSLocalizedString(@"Cache Browser", @"Cache Browser") handler:^{
            [weakself browseCache:sender];
        }];
        
        [weakself.sheet bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel") handler:^{}];
        [weakself.sheet showFromBarButtonItem:leftButton animated:YES];
    }];
    self.navigationItem.leftBarButtonItem = leftButton;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:ServerSetupDone]) {
        [self showSettings:nil];
    }

    // Revert back to old UITableView behavior
    if ([self.tableView respondsToSelector:@selector(cellLayoutMarginsFollowReadableWidth)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        return toInterfaceOrientation != UIInterfaceOrientationMaskPortraitUpsideDown;
    else
        return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.addresses count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

    NSString *address = self.addresses[indexPath.row];
    cell.textLabel.text = address;

    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.addresses removeObjectAtIndex:indexPath.row];
        [self saveAddresses];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *urlString = self.addresses[indexPath.row];
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:urlString]];
    webViewController.showUrlWhileLoading = NO;
    webViewController.hidesBottomBarWhenPushed = YES;
    webViewController.urlRequest.cachePolicy = NSURLCacheStorageAllowed;
    typeof(self) weakself = self;
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemSearch handler:^(id sender) {
        NSString *html = [webViewController.webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
        [weakself processHTML:html];
    }];
    webViewController.additionalBarButtonItems = @[rightBarButtonItem];
    [self.navigationController pushViewController:webViewController animated:YES];
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - Action methods

- (void)saveAddresses {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.addresses forKey:@"VPAddresses"];
    [defaults synchronize];
}

- (void)readAddresses {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.addresses = [[defaults objectForKey:@"VPAddresses"] mutableCopy];
}

- (void)showSettings:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger cacheSizeInBytes = [[SDImageCache sharedImageCache] getSize];
    NSString *cacheSize = [[AppDelegate shared] fileSizeStringWithInteger:cacheSizeInBytes];
    [defaults setObject:cacheSize forKey:ImageCacheSizeKey];
    NSString *status = [LTHPasscodeViewController doesPasscodeExist] ? NSLocalizedString(@"On", @"On"): NSLocalizedString(@"Off", @"Off");
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
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself presentViewController:settingsNavigationController animated:YES completion:^{}];
    });
}

- (void)showTorrentsViewer:(id)sender {
    VPTorrentsListViewController *torrentsListViewController = [[VPTorrentsListViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *torrentsListNavigationController = [[UINavigationController alloc] initWithRootViewController:torrentsListViewController];
    torrentsListNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself presentViewController:torrentsListNavigationController animated:YES completion:^{}];
    });
}

- (void)showTransmission:(id)sender {
    NSString *link = [[AppDelegate shared] getTransmissionServerAddress];
    TOWebViewController *transmissionWebViewController = [[TOWebViewController alloc] initWithURLString:link];
    transmissionWebViewController.urlRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    transmissionWebViewController.title = @"Transmission";
    transmissionWebViewController.showUrlWhileLoading = NO;
    UINavigationController *transmissionNavigationController = [[UINavigationController alloc] initWithRootViewController:transmissionWebViewController];
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself presentViewController:transmissionNavigationController animated:YES completion:^{}];
    });
}

- (void)browseCache:(id)sender {
    self.mwPhotos = [self fetchCacheFileList];
    if (self.mwPhotos.count == 0) return;
    MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    photoBrowser.displayActionButton = NO;
    photoBrowser.displayNavArrows = YES;
    photoBrowser.zoomPhotosToFill = NO;
    [photoBrowser setCurrentPhotoIndex:0];
    UINavigationController *pbNavigationController = [[UINavigationController alloc] initWithRootViewController:photoBrowser];
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself presentViewController:pbNavigationController animated:YES completion:NULL];
    });
}

- (void)torrentSearch:(id)sender {
    [[AppDelegate shared] showTorrentSearchAlertInNavigationController:self.navigationController];
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
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:ServerSetupDone];
        [sender synchronizeSettings];
    }];
}

- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
    if ([specifier.key isEqualToString:PasscodeLockConfig]) {
        if (![LTHPasscodeViewController doesPasscodeExist]) {
            [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController:sender asModal:NO];
        }
        else {
            [[LTHPasscodeViewController sharedUser] showForDisablingPasscodeInViewController:sender asModal:NO];
        }
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
    else if ([specifier.key isEqualToString:VerifyXunleiKey]) {
        HYXunleiLixianAPI *tondarAPI = [[HYXunleiLixianAPI alloc] init];
        [tondarAPI logOut];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:sender.navigationController.view animated:YES];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSArray *xunleiAccount = [[AppDelegate shared] getXunleiUsernameAndPassword];
            if ([tondarAPI loginWithUsername:xunleiAccount[0] Password:xunleiAccount[1] isPasswordEncode:NO]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hide:YES];
                    [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Logged in.", @"Logged in.") inView:sender.navigationController.view];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hide:YES];
                    [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Username or password error.", @"Username or password error.") inView:sender.navigationController.view];
                });
            }
        });
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

- (void)processHTML:(NSString *)html {
    NSMutableSet *validAddresses = [[NSMutableSet alloc] init];
    NSArray *patterns = @[@"magnet:\\?[^\"'<]+", @"ed2k://[^\"'&<]+", @"thunder://[^\"'&<]+"];
    for (NSString *pattern in patterns) {
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        [regex enumerateMatchesInString:html options:0 range:NSMakeRange(0, [html length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSString *link = [html substringWithRange:result.range];
            [validAddresses addObject:link];
        }];
    }
    if ([validAddresses count] <= 0) {
        [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"No downloadable link.", @"No downloadable link.") inView:self.navigationController.view];
    }
    else {
        ValidLinksTableViewController *linkViewController = [[ValidLinksTableViewController alloc] initWithStyle:UITableViewStylePlain];
        linkViewController.validLinks = [validAddresses allObjects];
        [self.navigationController pushViewController:linkViewController animated:YES];
    }
}

@end
