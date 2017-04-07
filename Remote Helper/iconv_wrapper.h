//
//  iconv_wrapper.h
//  Convert
//
//  Created by Venj Chu on 2017/4/7.
//  Copyright © 2017年 ZHU WEN JIE. All rights reserved.
//

#ifndef iconv_wrapper_h
#define iconv_wrapper_h

#include <iconv.h>

iconv_t initialize(const char *from_encoding, const char *to_encoding, _Bool allow_lossy);
char *convert_encoding(iconv_t conv_desc, char *gbk);
int finalize(iconv_t conv_desc);

#endif /* iconv_wrapper_h */
