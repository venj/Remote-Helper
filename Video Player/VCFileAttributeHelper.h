//
//  VCFileAttributeHelper.h
//  iGolf
//
//  Created by 朱 文杰 on 12-8-1.
//  Copyright (c) 2012年 com.emobilesoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VCFileAttributeHelper : NSObject
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;
@end
