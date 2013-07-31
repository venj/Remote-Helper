//
//  VCFileAttributeHelper.h
//  iGolf
//
//  Created by Venj Chu on 12-8-1.
//  Copyright (c) 2012年 com.emobilesoft. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class VCFileAttributeHelper
 @brief A helper class for file attributes operations.
 */
@interface VCFileAttributeHelper : NSObject

/*!
 @brief Add an file attribute to avoid iTunes backup the video files.
 @param URL The file URL to change file attributes.
 @return Returns <code>YES</code> if the operation succeeded, <code>NO</code> if otherwise.
 */
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;
@end
