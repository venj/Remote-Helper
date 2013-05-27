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
#import "Common.h"

@interface VPFileListViewController ()
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
    [self loadMovieList:nil];
    UIBarButtonItem *rightButtom = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadMovieList:)];
    rightButtom.enabled = NO;
    self.navigationItem.rightBarButtonItem = rightButtom;
}

- (NSString *)fileLinkWithPath:(NSString *)path {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *host = [defaults objectForKey:ServerHostKey];
    if (!host) host = @"192.168.32.5";
    NSString *port = [defaults objectForKey:ServerPortKey];
    if (!port) port = @"4567";
    if (!path)
        path = @"/";
    else if (![[path substringToIndex:0] isEqualToString:@"/"]) {
        path = [[NSString alloc]  initWithFormat:@"/%@", path];
    }
    NSString *link = [[NSString alloc] initWithFormat:@"http://%@:%@%@", host, port, path];
    return link;
}

- (void)loadMovieList:(id)sender {
    __block VPFileListViewController *blockSelf = self;
    NSURL *movieListURL = [[NSURL alloc] initWithString:[self fileLinkWithPath:@"/"]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:movieListURL];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        blockSelf.movieFiles = JSON;
        blockSelf.navigationItem.rightBarButtonItem.enabled = YES;
        [blockSelf.tableView reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }];
    blockSelf.navigationItem.rightBarButtonItem.enabled = NO;
    [operation start];
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
    cell.textLabel.text = self.movieFiles[indexPath.row];
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *moviePath = [self fileLinkWithPath:[self.movieFiles[indexPath.row] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [[NSURL alloc] initWithString:moviePath];
    self.mpViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    
    [self.navigationController presentMoviePlayerViewControllerAnimated:self.mpViewController];
}

@end
