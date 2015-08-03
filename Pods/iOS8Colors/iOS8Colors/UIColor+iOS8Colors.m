// UIColor+iOS8Colors
//
// Copyright (c) 2014 Doan Truong Thi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "UIColor+iOS8Colors.h"
#import <HexColors/HexColor.h>

@implementation UIColor (iOS8Colors)

#pragma mark - Plain Colors

+ (instancetype)iOS8redColor;
{
    return [UIColor colorWithHexString:@"FF3B30"];
}

+ (instancetype)iOS8orangeColor;
{
    return [UIColor colorWithHexString:@"FF9500"];
}

+ (instancetype)iOS8yellowColor;
{
    return [UIColor colorWithHexString:@"FFCC00"];
}

+ (instancetype)iOS8greenColor;
{
    return [UIColor colorWithHexString:@"4CD964"];
}

+ (instancetype)iOS8lightBlueColor;
{
    return [UIColor colorWithHexString:@"34AADC"];
}

+ (instancetype)iOS8darkBlueColor;
{
    return [UIColor colorWithHexString:@"007AFF"];
}

+ (instancetype)iOS8purpleColor;
{
    return [UIColor colorWithHexString:@"5856D6"];
}

+ (instancetype)iOS8pinkColor;
{
    return [UIColor colorWithHexString:@"FF2D55"];
}

+ (instancetype)iOS8darkGrayColor;
{
    return [UIColor colorWithHexString:@"8E8E93"];
}

+ (instancetype)iOS8lightGrayColor;
{
    return [UIColor colorWithHexString:@"C7C7CC"];
}

#pragma mark - Gradient Colors

+ (instancetype)iOS8redGradientStartColor;
{
    return [UIColor colorWithHexString:@"FF5E3A"];
}

+ (instancetype)iOS8redGradientEndColor;
{
    return [UIColor colorWithHexString:@"FF2A68"];
}

+ (instancetype)iOS8orangeGradientStartColor;
{
    return [UIColor colorWithHexString:@"FF9500"];
}

+ (instancetype)iOS8orangeGradientEndColor;
{
    return [UIColor colorWithHexString:@"FF5E3A"];
}

+ (instancetype)iOS8yellowGradientStartColor;
{
    return [UIColor colorWithHexString:@"FFDB4C"];
}

+ (instancetype)iOS8yellowGradientEndColor;
{
    return [UIColor colorWithHexString:@"FFCD02"];
}

+ (instancetype)iOS8greenGradientStartColor;
{
    return [UIColor colorWithHexString:@"87FC70"];
}

+ (instancetype)iOS8greenGradientEndColor;
{
    return [UIColor colorWithHexString:@"0BD318"];
}

+ (instancetype)iOS8tealGradientStartColor;
{
    return [UIColor colorWithHexString:@"52EDC7"];
}

+ (instancetype)iOS8tealGradientEndColor;
{
    return [UIColor colorWithHexString:@"5AC8FB"];
}

+ (instancetype)iOS8blueGradientStartColor;
{
    return [UIColor colorWithHexString:@"1AD6FD"];
}

+ (instancetype)iOS8blueGradientEndColor;
{
    return [UIColor colorWithHexString:@"1D62F0"];
}

+ (instancetype)iOS8violetGradientStartColor;
{
    return [UIColor colorWithHexString:@"C644FC"];
}

+ (instancetype)iOS8violetGradientEndColor;
{
    return [UIColor colorWithHexString:@"5856D6"];
}

+ (instancetype)iOS8magentaGradientStartColor;
{
    return [UIColor colorWithHexString:@"EF4DB6"];
}

+ (instancetype)iOS8magentaGradientEndColor;
{
    return [UIColor colorWithHexString:@"C643FC"];
}

+ (instancetype)iOS8blackGradientStartColor;
{
    return [UIColor colorWithHexString:@"4A4A4A"];
}

+ (instancetype)iOS8blackGradientEndColor;
{
    return [UIColor colorWithHexString:@"2B2B2B"];
}

+ (instancetype)iOS8silverGradientStartColor;
{
    return [UIColor colorWithHexString:@"DBDDDE"];
}

+ (instancetype)iOS8silverGradientEndColor;
{
    return [UIColor colorWithHexString:@"898C90"];
}

@end
