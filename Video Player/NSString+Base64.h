//
//  NSString+Base64.h
//  Video Player
//
//  Created by 朱 文杰 on 15/8/1.
//  Copyright (c) 2015年 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Base64)
- (NSString *)base64String;
- (NSString *)decodedBase64String;
@end
