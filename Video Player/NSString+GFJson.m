//
//  NSString+GFJson.m
//  iGolf
//
//  Created by venj on 13-9-9.
//  Copyright (c) 2013年 Dong Qiu. All rights reserved.
//

#import "NSString+GFJson.h"

@implementation NSString (GFJson)
- (id)JSONObject {
    NSError *error;
    NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
#if DEBUG
        NSLog(@"JSON Parse Error: %@", [error localizedDescription]);
        NSLog(@"Original String: %@", self);
#endif
        return nil;
    }
    else {
        return json;
    }
}
@end
