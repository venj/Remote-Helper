//
//  SBAPIManager.h
//  Video Player
//
//  Created by Venj Chu on 14/12/19.
//  Copyright (c) 2014年 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>

@interface SBAPIManager : AFHTTPClient
- (void)setUsername:(NSString *)username andPassword:(NSString *)password;
+ (SBAPIManager *)sharedManagerWithURLString:(NSString *)string;
@end
