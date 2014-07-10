//
//  TransmissionWebViewController.m
//  Video Player
//
//  Created by Venj Chu on 14/7/9.
//  Copyright (c) 2014年 Home. All rights reserved.
//

#import "TransmissionWebViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "AppDelegate.h"

@interface TransmissionWebViewController () <UIWebViewDelegate, NSURLConnectionDelegate> {
    
}
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) BOOL authed;
@property (nonatomic, assign) BOOL useCredentialStorage;
@end

@implementation TransmissionWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        _authed = NO;
        _useCredentialStorage = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.webView];
    self.webView.delegate = self;
    self.webView.frame = self.view.frame;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self loadWebContent];
    
    __weak typeof(self) weakSelf = self;
    UIBarButtonItem *reloadItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh handler:^(id sender) {
        [weakSelf loadWebContent];
    }];
    self.navigationItem.rightBarButtonItem = reloadItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadWebContent {
    NSString *address = [[AppDelegate shared] getTransmissionServerAddress];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:address]];
    request.timeoutInterval = 10;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [self.webView loadRequest:request];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (!self.authed) {
        self.authed = NO;
        NSString *address = [[AppDelegate shared] getTransmissionServerAddress];
        if (![[[request URL] absoluteString] isEqualToString:address]) {
            self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            return NO;
        }
    }
    
    return YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge previousFailureCount] == 0) {
        self.authed = YES;
        NSArray *array = [[AppDelegate shared] getUsernameAndPassword];
        [[challenge sender] useCredential:[NSURLCredential credentialWithUser:array[0] password:array[1] persistence:NSURLCredentialPersistenceNone] forAuthenticationChallenge:challenge];
    } else {
        [self showHudWithMessage:NSLocalizedString(@"Wrong password.", @"Wrong password.")];
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSString *address = [[AppDelegate shared] getTransmissionServerAddress];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:address]];
    [self.webView loadRequest:urlRequest];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    //Fixme: what the fuck!
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = @"AlreadyUsedCredentialStorage";
    if ([defaults objectForKey:key] == nil) {
        [defaults setObject:@YES forKey:key];
        [defaults synchronize];
        return YES;
    }
    return NO;
}

- (void)showHudWithMessage:(NSString *)message {
    UIView *aView = self.navigationController.view;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:aView animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    [hud hide:YES afterDelay:1];
}

@end
