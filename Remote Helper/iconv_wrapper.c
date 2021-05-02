//
//  iconv_wrapper.c
//  Convert
//
//  Created by Venj Chu on 2017/4/7.
//  Copyright © 2017年 ZHU WEN JIE. All rights reserved.
//

// https://www.lemoda.net/c/iconv-example/iconv-example.html

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <iconv.h>
#include <errno.h>
#include <string.h>

#include "iconv_wrapper.h"

/* Initialize the library. */
iconv_t initialize(const char *from_encoding, const char *to_encoding, _Bool allow_lossy) {
    iconv_t conv_desc = iconv_open(to_encoding, from_encoding);
    if ((long) conv_desc == -1) {
        /* Initialization failure. */
        if (errno == EINVAL) {
            fprintf(stderr, "Conversion from '%s' to '%s' is not supported.\n", from_encoding, to_encoding);
        }
        else {
            fprintf(stderr, "Initialization failure: %s\n", strerror (errno));
        }
        // exit ok
        return (iconv_t)(-1);
    }
    if (allow_lossy) {
        int ignore = 1;
        int result = iconvctl(conv_desc, ICONV_SET_DISCARD_ILSEQ, &ignore);
        if (result != 0) {
            fprintf(stderr, "Set discard illegal sequence error: %s\n", strerror(errno));
            return (iconv_t)(-1);
        }
    }

    return conv_desc;
}

/* Convert GBK into UTF-8 using the iconv library. */
char *convert_encoding(iconv_t conv_desc, char *gbk) {
    size_t iconv_value;
    char *utf8;
    size_t len;
    size_t utf8len;
    /* The variables with "start" in their name are solely for display
     of what the function is doing. As iconv runs, it alters the
     values of the variables, so these are for keeping track of the
     start points and start lengths. */
    char *utf8start;
    char *gbk_start;
    long len_start;
    long utf8len_start;

    len = strlen(gbk);
    if (!len) {
        fprintf(stderr, "Input string is empty.\n");
        return NULL;
    }
    /* Assign enough space to put the UTF-8. */
    utf8len = 2 * len; // use 4 times of string length to ensure enough space.
    utf8 = calloc(utf8len, sizeof (char));
    if (!utf8) {
        fprintf(stderr, "Calloc failed.\n");
        return NULL;
    }
    /* Keep track of the variables. */
    len_start = len;
    utf8len_start = utf8len;
    utf8start = utf8;
    gbk_start = gbk;
    /* Display what is in the variables before calling iconv. */
    iconv_value = iconv(conv_desc, &gbk, &len, &utf8, &utf8len);
    /* Handle failures. */
    if (iconv_value == (size_t) -1) {
        //fprintf(stderr, "iconv failed: in string '%s', length %zu, out string '%s', length %zu\n", gbk, len, utf8start, utf8len);
        switch (errno) {
            /* See "man 3 iconv" for an explanation. */
            case EILSEQ:
                fprintf(stderr, "Invalid multibyte sequence.\n");
                break;
            case EINVAL:
                fprintf(stderr, "Incomplete multibyte sequence.\n");
                // Allow this error return result.
                return utf8start;
                break;
            case E2BIG:
                fprintf(stderr, "No more room.\n");
                break;
            default:
                fprintf(stderr, "Error: %s.\n", strerror(errno));
        }
        // exit ok
        return NULL;
    }

    return utf8start;
}

/* Close the connection with the library. */
int finalize(iconv_t conv_desc) {
    int v;
    v = iconv_close(conv_desc);
    if (v != 0) {
        fprintf(stderr, "iconv_close failed: %s\n", strerror (errno));
        // exit ok
        return -1;
    }
    return 0;
}
