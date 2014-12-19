//
//  SBAPIManager.m
//  Video Player
//
//  Created by Venj Chu on 14/12/19.
//  Copyright (c) 2014年 Home. All rights reserved.
//

#import "SBAPIManager.h"

@implementation SBAPIManager

#pragma mark - Methods

- (void)setUsername:(NSString *)username andPassword:(NSString *)password
{
    [self clearAuthorizationHeader];
    [self setAuthorizationHeaderWithUsername:username password:password];
}

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if(!self)
        return nil;
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setParameterEncoding:AFJSONParameterEncoding];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    return self;
}

#pragma mark - Singleton Methods

+ (SBAPIManager *)sharedManagerWithURLString:(NSString *)string
{
    static dispatch_once_t pred;
    static SBAPIManager *_sharedManager = nil;
    
    dispatch_once(&pred, ^{ _sharedManager = [[self alloc] initWithBaseURL:[NSURL URLWithString:string]]; });
    return _sharedManager;
}

@end
