//
//  VPLocalFileListViewController.m
//  Video Player
//
//  Created by venj on 13-6-26.
//  Copyright (c) 2013年 Home. All rights reserved.
//

#import "VPLocalFileListViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VPFileInfoViewController.h"

@interface VPLocalFileListViewController () <VPFileInfoViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray *localFiles;
@property (nonatomic, strong) MPMoviePlayerViewController *mpViewController;
@end

@implementation VPLocalFileListViewController

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
    self.title = NSLocalizedString(@"Local", @"Local");
    UIBarButtonItem *rightButtom = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadMovieList:)];
    self.navigationItem.rightBarButtonItem = rightButtom;
    [self loadMovieList:nil];
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
    return [self.localFiles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalFileListTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    NSURL *fileURL = self.localFiles[indexPath.row];
    cell.textLabel.text = [fileURL lastPathComponent];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17.];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSURL *url = self.localFiles[indexPath.row];
    if (self.mpViewController)
        self.mpViewController.moviePlayer.contentURL = url;
    else
        self.mpViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    
    [self presentMoviePlayerViewControllerAnimated:self.mpViewController];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *currentFile = [self.localFiles[indexPath.row] path];
    NSError *error;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:currentFile error:&error];
    if (error) {
        NSLog(@"Error read file attributes %@", [error description]);
        return;
    }
    NSDictionary *fileInfo = @{@"file": currentFile, @"size": attributes[NSFileSize]};
    VPFileInfoViewController *fileInfoViewController = [[VPFileInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
    fileInfoViewController.delegate = self;
    fileInfoViewController.parentIndexPath = indexPath;
    fileInfoViewController.fileInfo = fileInfo;
    fileInfoViewController.isLocalFile = YES;
    [self.navigationController pushViewController:fileInfoViewController animated:YES];
}

#pragma mark - Action Methods
- (void)loadMovieList:(id)sender {
    if (!self.localFiles) {
        self.localFiles = [[NSMutableArray alloc] init];
    }
    else {
        [self.localFiles removeAllObjects];
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *files = [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:documentsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if (error) {
        NSLog(@"Error loading file list %@", [error description]);
        return;
    }
    __block VPLocalFileListViewController *blockSelf = self;
    [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *fileExtension = [[(NSURL *)obj pathExtension] lowercaseString];
        if ([[@[@"mp4", @"m4v", @"mov"] indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [obj isEqualToString:fileExtension] ? YES : NO ;
        }] count] != 0) {
            [blockSelf.localFiles addObject:obj];
        }
    }];
    [self.tableView reloadData];
}

#pragma mark - File Info View Controller Delegate

- (void)fileDidRemovedFromServerForParentIndexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        [self.localFiles removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else {
        [self loadMovieList:nil];
    }
}

@end
