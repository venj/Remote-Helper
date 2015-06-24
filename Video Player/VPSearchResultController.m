//
//  VPSearchResultController.m
//  
//
//  Created by 朱 文杰 on 15/6/19.
//
//

#import "AppDelegate.h"
#import "VPSearchResultController.h"

@implementation VPSearchResultController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [[NSString alloc] initWithFormat:@"%@: %@", NSLocalizedString(@"Search", @"Search"), self.keyword];
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
        double mbValue = sizeValue / (1024.0 * 1024.0);
        if (mbValue > 1024.0) {
            sizeString = [[NSString alloc] initWithFormat:@"%.1f GB", mbValue / 1024.0];
        }
        else {
            sizeString = [[NSString alloc] initWithFormat:@"%.1f MB", mbValue];
        }
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", sizeString];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakself = self;
    NSDictionary *torrent = self.torrents[indexPath.row];
    [[AppDelegate shared] parseSessionAndAddTask:torrent[@"magnet"] completionHandler:^{
        [[AppDelegate shared] showHudWithMessage:NSLocalizedString(@"Task added.", @"Task added.") inView:weakself.navigationController.view];
    } errorHandler:^{
        [[AppDelegate shared]  showHudWithMessage:NSLocalizedString(@"Unknow error.", @"Unknow error.") inView:weakself.navigationController.view];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
