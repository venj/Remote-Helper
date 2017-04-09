//
//  NSString+iconv.m
//  Convert
//
//  Created by Venj Chu on 2017/4/7.
//  Copyright © 2017年 ZHU WEN JIE. All rights reserved.
//

#import "NSData+iconv.h"
#import "iconv_wrapper.h"

@implementation NSData (iconv)

- (NSString  * _Nullable)convertToUTF8StringFromEncoding:(NSString  * _Nonnull)from allowLoosy: (Boolean)lossy {
    char *inString = (char *)([self bytes]);
    char *outString;
    iconv_t conv_desc;
    const char *from_encoding = [from cStringUsingEncoding:NSASCIIStringEncoding];
    const char *to_encoding = "UTF-8";

    if ((conv_desc = initialize(from_encoding, to_encoding, lossy)) == (iconv_t)(-1)) {
        return nil;
    }
    outString = convert_encoding(conv_desc, inString);
    finalize(conv_desc);
    if (outString != NULL) {
        NSString *result = [[NSString alloc] initWithCString:outString encoding:NSUTF8StringEncoding];
        free(outString);
        return result;
    }
    else {
        return nil;
    }
}

@end
