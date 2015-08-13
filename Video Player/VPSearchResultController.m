//
//  VPSearchResultController.m
//  
//
//  Created by 朱 文杰 on 15/6/19.
//
//

#import "AppDelegate.h"
#import "VPSearchResultController.h"
#import <BlocksKit+UIKit.h>
#import <TOWebViewController/TOWebViewController.h>

@implementation VPSearchResultController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [[NSString alloc] initWithFormat:@"%@: %@ (%lu)", NSLocalizedString(@"Search", @"Search"), self.keyword, (unsigned long)[self.torrents count]];
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^[A-Za-z]{2,6}-\\d{2,4}$" options:NSRegularExpressionCaseInsensitive error:nil];
    if ([regex matchesInString:self.keyword options:NSMatchingAnchored range:NSMakeRange(0, [self.keyword length])] > 0) {
        __weak typeof(self) weakself = self;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithImage:[UIImage imageNamed:@"wiki"] style:UIBarButtonItemStylePlain handler:^(id sender) {
            TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURLString:[NSString stringWithFormat:@"http://www.javlibrary.com/cn/vl_searchbyid.php?keyword=%@", [[self.keyword stringByReplacingOccurrencesOfString:@" " withString:@""] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            webViewController.showUrlWhileLoading = NO;
            webViewController.hidesBottomBarWhenPushed = YES;
            [weakself.navigationController pushViewController:webViewController animated:YES];
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    if ([UIApplication sharedApplication].statusBarHidden) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
    self.navigationController.navigationBar.tintColor = nil;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
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
    return [self.torrents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FileListTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    NSDictionary *torrent = self.torrents[indexPath.row];
    cell.textLabel.text = torrent[@"name"];
    
    id size = torrent[@"size"];
    NSString *sizeString = NSLocalizedString(@"Unknown size", @"Unknown size");
    if (![size isKindOfClass:[NSNull class]]) {
        long long sizeValue = [size longLongValue];
        sizeString = [self stringForSize:sizeValue];
    }
    
    NSString *dateString = [self formattedDate:[torrent[@"upload_date"] integerValue]];
    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@, %@%@, %@", sizeString, torrent[@"seeders"], NSLocalizedString(@"seeders", @"seeders"), dateString];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *torrent = self.torrents[indexPath.row];
    [self addTorrentToTransmission:torrent];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *torrent = self.torrents[indexPath.row];
    UIAlertView *alert = [[UIAlertView alloc] bk_initWithTitle:NSLocalizedString(@"Info", @"Info") message:[self torrentDescription:torrent]];
    __weak typeof(self) weakself = self;
    [alert bk_addButtonWithTitle:NSLocalizedString(@"Download", @"Download") handler:^{
        [weakself addTorrentToTransmission:torrent];
    }];
    [alert bk_setCancelButtonWithTitle:NSLocalizedString(@"OK", @"OK") handler:nil];
    [alert show];
}

- (NSString *)formattedDate:(NSInteger)timeStamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *locale = [NSLocale currentLocale];
    [formatter setLocale:locale];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    return [formatter stringFromDate:date];
}

- (NSString *)torrentDescription:(NSDictionary *)dict {
    return [[NSString alloc] initWithFormat:@"%@, \n"
                                             "%@, \n"
                                             "%@, \n"
                                             "%@, \n"
                                             "%@"
                                             " seeders",
                                            dict[@"name"],
                                            [self stringForSize:[dict[@"size"] longLongValue] ],
                                            dict[@"magnet"],
                                            [self formattedDate:[dict[@"upload_date"] integerValue]],
                                            dict[@"seeders"],
                                            NSLocalizedString(@"seeders", @"seeders")];
}

- (NSString *)stringForSize:(long long)size {
    NSString *sizeString = @"";
    double mbValue = size / (1024.0 * 1024.0);
    if (mbValue > 1024.0) {
        sizeString = [[NSString alloc] initWithFormat:@"%.2f GB", mbValue / 1024.0];
    }
    else {
        sizeString = [[NSString alloc] initWithFormat:@"%.1f MB", mbValue];
    }
    return sizeString;
}

- (void)addTorrentToTransmission:(NSDictionary *)torrent {
    __weak typeof(self) weakself = self;
    [[AppDelegate shared] parseSessionAndAddTask:torrent[@"magnet"] completionHandler:^{
        [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Task added.", @"Task added.") inView:weakself.navigationController.view];
    } errorHandler:^{
        [[AppDelegate shared]  showHudWithMessage:NSLocalizedString(@"Unknow error.", @"Unknow error.") inView:weakself.navigationController.view];
    }];
}

@end
