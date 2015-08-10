//
//  NSString+GFJson.h
//  iGolf
//
//  Created by venj on 13-9-9.
//  Copyright (c) 2013年 Dong Qiu. All rights reserved.
//

#import <Foundation/Foundation.h>
/*!
 @class NSString+GFJson
 @brief <code>NSString</code> extension for easy JSON manipulation.
 */
@interface NSString (GFJson)
/*!
 @brief This method convert an <code>NSString</code> (JSON) object to an <code>NSObject</code> object.
 @return An <code>NSObject</code> object, mostly <code>NSArray</code> or <code>NSDictionary</code>, may return <code>nil</code>.
 */
- (id)JSONObject;
@end
