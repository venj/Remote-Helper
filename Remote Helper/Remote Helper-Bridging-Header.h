//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "NSData+iconv.h"
#import <CommonCrypto/CommonDigest.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static inline unsigned char *RH_CC_MD5(const void *data, CC_LONG len, unsigned char *md) {
    return CC_MD5(data, len, md);
}
#pragma clang diagnostic pop
