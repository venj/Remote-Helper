//
//  VCFileAttributeHelper.m
//  iGolf
//
//  Created by 朱 文杰 on 12-8-1.
//  Copyright (c) 2012年 com.emobilesoft. All rights reserved.
//

#import "VCFileAttributeHelper.h"
#import <sys/xattr.h>

@implementation VCFileAttributeHelper
+ (BOOL)haveSkipBackupAttributeForItemAtURL:(NSURL *)URL {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    if ([version isEqualToString:@"5.0.1"]) {
#if TARGET_IS_TEST_DATA
        if (![[NSFileManager defaultManager] fileExistsAtPath: [URL path]]) {
            return NO;
        }
#endif
        const char* filePath = [[URL path] fileSystemRepresentation];
        
        const char* attrName = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        
        int result = getxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        return result == 0;
    }
    else if([[[version componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 5) {
        return YES;
    }
    else {
#if TARGET_IS_TEST_DATA
        if (![[NSFileManager defaultManager] fileExistsAtPath: [URL path]]) {
            return NO;
        }
#endif
        NSError *error = nil;
        id result;
        BOOL success = [URL getResourceValue: &result
                                      forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
#if TARGET_IS_TEST_DATA
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
#endif
        }
        return [result boolValue];
    }
}


+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL {
    if ([self haveSkipBackupAttributeForItemAtURL:URL]) {
        return YES;
    }
    
    NSString *version = [[UIDevice currentDevice] systemVersion];
    if ([version isEqualToString:@"5.0.1"]) {
#if TARGET_IS_TEST_DATA
        if (![[NSFileManager defaultManager] fileExistsAtPath: [URL path]]) {
            return NO;
        }
#endif
        const char* filePath = [[URL path] fileSystemRepresentation];
        
        const char* attrName = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        
        int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        return result == 0;
    }
    else {
#if TARGET_IS_TEST_DATA
        if (![[NSFileManager defaultManager] fileExistsAtPath: [URL path]]) {
            return NO;
        }
#endif
        NSError *error = nil;
        BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                      forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
#if TARGET_IS_TEST_DATA
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
#endif
        }
        
        return success;
    }
}
@end
