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

static NSString *reuseIdentifier = @"ValidLinksTableViewCellIdentifier";

@interface ValidLinksTableViewController ()

@end

@implementation ValidLinksTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:NSLocalizedString(@"Found %ld links", @"Found %ld links"), (long)[self.validLinks count]];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseIdentifier];
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

    cell.textLabel.text = self.validLinks[indexPath.row];
    
    return cell;
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
    return @[copyAction, downloadAction];
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

@end
