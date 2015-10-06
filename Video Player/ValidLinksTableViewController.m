//
//  ValidLinksTableViewController.m
//  
//
//  Created by 朱文杰 on 15/8/3.
//
//

#import "ValidLinksTableViewController.h"
#import "AppDelegate.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "NSString+Base64.h"
#import <iOS8Colors/UIColor+iOS8Colors.h>
#import "HYXunleiLixianAPI.h"
#import <BlocksKit+UIKit.h>

static NSString *reuseIdentifier = @"ValidLinksTableViewCellIdentifier";

@interface ValidLinksTableViewController ()

@end

@implementation ValidLinksTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:NSLocalizedString(@"Found %ld links", @"Found %ld links"), (long)[self.validLinks count]];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseIdentifier];
    
    if ([self.validLinks count] > 1) {
        __weak typeof(self) weakself = self;
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] bk_initWithTitle:NSLocalizedString(@"Copy All", @"Copy All") style:UIBarButtonItemStylePlain handler:^(id sender) {
            [UIPasteboard generalPasteboard].string = [self.validLinks componentsJoinedByString:@"\n"];
            [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Copied", @"Copied") inView:weakself.navigationController.view];
        }];
        self.navigationItem.rightBarButtonItem = rightItem;
    }

    // Revert back to old UITableView behavior
    if ([self.tableView respondsToSelector:@selector(cellLayoutMarginsFollowReadableWidth)]) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.validLinks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

    cell.textLabel.text = [self processLinkToName:self.validLinks[indexPath.row]];
    
    return cell;
}

- (NSString *)processLinkToName:(NSString *)link {
    NSString *decodedLink = [link stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *protocal = [[decodedLink componentsSeparatedByString:@":"] firstObject];
    if ([protocal isEqualToString:@"thunder"]) {   // thunder
        NSString *encodedString = [link substringFromIndex:10];
        NSString *decodedString = [encodedString decodedBase64String];
        if (decodedString == nil) {
            return decodedLink;
        }
        else {
            NSString *normalizedThunderLink = [decodedString substringWithRange:NSMakeRange(2, [decodedString length] - 4)];
            return [self processLinkToName:normalizedThunderLink];
        }
    }
    else if ([protocal isEqualToString:@"magnet"]) { // magnet
        NSString *queryString = [[decodedLink componentsSeparatedByString:@"?"] lastObject];
        NSArray *kvPairs = [[queryString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"] componentsSeparatedByString:@"&"];
        NSString *name = decodedLink;
        for (NSString *kvStr in kvPairs) {
            NSArray *kv = [kvStr componentsSeparatedByString:@"="];
            if (([kv[0] isEqualToString:@"dn"] || [kv[0] isEqualToString:@"btname"]) && ![kv[1] isEqualToString:@""]) {
                name = [kv[1] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                break;
            }
        }
        return name;
    }
    else if ([protocal isEqualToString:@"ed2k"]) { // ed2k
        NSArray *parts = [decodedLink componentsSeparatedByString:@"|"];
        NSUInteger index = [parts indexOfObject:@"file"];
        if (index != NSNotFound && [parts count] > index + 2) {
            return parts[index + 1];
        }
        else {
            return decodedLink;
        }
    }
    else if ([protocal isEqualToString:@"ftp"] || [protocal isEqualToString:@"http"] || [protocal isEqualToString:@"https"]) {
        return [[decodedLink componentsSeparatedByString:@"/"] lastObject];
    }
    else {
        return decodedLink;
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakself = self;
    UITableViewRowAction *copyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Copy Link", @"Copy Link") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        NSString *link = weakself.validLinks[indexPath.row];
        [UIPasteboard generalPasteboard].string = link;
        [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Copied", @"Copied") inView:weakself.navigationController.view];
        if ([self.tableView isEditing]) {
            [self.tableView setEditing:NO animated:YES];
        }
    }];
    copyAction.backgroundColor = [UIColor iOS8purpleColor ];
    UITableViewRowAction *downloadAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Download", @"Download") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        NSString *link = weakself.validLinks[indexPath.row];
        [weakself download:link];
        if ([self.tableView isEditing]) {
            [self.tableView setEditing:NO animated:YES];
        }
    }];
    downloadAction.backgroundColor = [UIColor iOS8orangeColor];
    UITableViewRowAction *lixianAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Lixian", @"Lixian") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        if ([self.tableView isEditing]) {
            [self.tableView setEditing:NO animated:YES];
        }
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.navigationController.view animated:YES];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *link = weakself.validLinks[indexPath.row];
            NSString *protocal = [[link componentsSeparatedByString:@":"] firstObject];
            // Login Test
            HYXunleiLixianAPI *tondarAPI = [AppDelegate sharedAPI];
            NSArray *xunleiAccount = [[AppDelegate shared] getXunleiUsernameAndPassword];
            if (![AppDelegate shared].xunleiUserLoggedIn) {
                [AppDelegate shared].xunleiUserLoggedIn = [tondarAPI loginWithUsername:xunleiAccount[0] Password:xunleiAccount[1] isPasswordEncode:NO];
                if (![AppDelegate shared].isXunleiUserLoggedIn) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [hud hide:YES];
                        [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Login Failed.", @"Login Failed.") inView:weakself.navigationController.view];
                    });
                    // Failed to login.
                    return;
                }
            }
            // Delay 2 second to make task add more successful.
            sleep(2);
            // Login success.
            NSString *dcid = @"";
            if ([protocal isEqualToString:@"magnet"]) {
                dcid = [tondarAPI addMegnetTask:link];
            }
            else {
                dcid = [tondarAPI addNormalTask:link];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([dcid isEqualToString:@""]) {
                    [hud hide:YES];
                    [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Failed to add task.", @"Failed to add task.") inView:weakself.navigationController.view];
                }
                else {
                    [hud hide:YES];
                    [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Lixian added.", @"Lixian added.") inView:weakself.navigationController.view];
                }
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hide:YES];
            });
        });
    }];
    lixianAction.backgroundColor = [UIColor iOS8greenColor];
    return @[copyAction, lixianAction, downloadAction];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath { }

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *link = self.validLinks[indexPath.row];
    UIAlertView *alert = [[UIAlertView alloc] bk_initWithTitle:NSLocalizedString(@"Info", @"Info") message:NSLocalizedString(@"Do you want to download this link?", @"Do you want to download this link?")];
    __weak typeof(self) weakself = self;
    [alert bk_addButtonWithTitle:NSLocalizedString(@"Download", @"Download") handler:^{
        [weakself download:link];
    }];
    [alert bk_setCancelButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel") handler:nil];
    [alert show];
}

#pragma mark - Actions

- (void)download:(NSString *)link {
    __weak typeof(self) weakself = self;
    NSString *protocal = [[link componentsSeparatedByString:@":"] firstObject];
    if ([protocal isEqualToString:@"magnet"]) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        [[AppDelegate shared] parseSessionAndAddTask:link completionHandler:^{
            [hud hide:YES];
            [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Task added.", @"Task added.") inView:weakself.navigationController.view];
        } errorHandler:^{
            [[AppDelegate shared]  showHudWithMessage:NSLocalizedString(@"Unknow error.", @"Unknow error.") inView:weakself.navigationController.view];
        }];
    }
    else {
        NSURL *url = [NSURL URLWithString:link];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
        else {
            [[AppDelegate shared]  showHudWithMessage:NSLocalizedString(@"No 'DS Download' found.", @"No 'DS Download' found.") inView:weakself.navigationController.view];
        }
    }
}

#pragma mark - Helpers

- (NSString *)processThunderLink:(NSString *)link {
    NSString *thunderProtocalString = @"thunder://";
    if ([link rangeOfString:thunderProtocalString].location == 0) {
        NSString *encodedString = [link substringFromIndex:[thunderProtocalString length]];
        NSString *decodedString = [encodedString decodedBase64String];
        if (decodedString == nil) {
            return link;
        }
        else {
            NSString *escapedLink = [decodedString substringWithRange:NSMakeRange(2, [decodedString length] - 4)];
            return [escapedLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }
    else {
        return link;
    }
}

@end
