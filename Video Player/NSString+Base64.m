//
//  NSString+Base64.m
//  Video Player
//
//  Created by 朱 文杰 on 15/8/1.
//  Copyright (c) 2015年 Home. All rights reserved.
//

#import "NSString+Base64.h"

@implementation NSString (Base64)
- (NSString *)base64String {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}
@end
