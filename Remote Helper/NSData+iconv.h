//
//  NSString+iconv.h
//  Convert
//
//  Created by Venj Chu on 2017/4/7.
//  Copyright © 2017年 ZHU WEN JIE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (iconv)

- (NSString  * _Nullable)convertToUTF8StringFromEncoding:(NSString  * _Nonnull)from allowLoosy: (Boolean)lossy;

@end
