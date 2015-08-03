// UIColor+iOS8Colors.h
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

#import <UIKit/UIKit.h>

@interface UIColor (iOS8Colors)

// Plain Colors
+ (instancetype)iOS8redColor;
+ (instancetype)iOS8orangeColor;
+ (instancetype)iOS8yellowColor;
+ (instancetype)iOS8greenColor;
+ (instancetype)iOS8lightBlueColor;
+ (instancetype)iOS8darkBlueColor;
+ (instancetype)iOS8purpleColor;
+ (instancetype)iOS8pinkColor;
+ (instancetype)iOS8darkGrayColor;
+ (instancetype)iOS8lightGrayColor;

// Gradient Colors
+ (instancetype)iOS8redGradientStartColor;
+ (instancetype)iOS8redGradientEndColor;

+ (instancetype)iOS8orangeGradientStartColor;
+ (instancetype)iOS8orangeGradientEndColor;

+ (instancetype)iOS8yellowGradientStartColor;
+ (instancetype)iOS8yellowGradientEndColor;

+ (instancetype)iOS8greenGradientStartColor;
+ (instancetype)iOS8greenGradientEndColor;

+ (instancetype)iOS8tealGradientStartColor;
+ (instancetype)iOS8tealGradientEndColor;

+ (instancetype)iOS8blueGradientStartColor;
+ (instancetype)iOS8blueGradientEndColor;

+ (instancetype)iOS8violetGradientStartColor;
+ (instancetype)iOS8violetGradientEndColor;

+ (instancetype)iOS8magentaGradientStartColor;
+ (instancetype)iOS8magentaGradientEndColor;

+ (instancetype)iOS8blackGradientStartColor;
+ (instancetype)iOS8blackGradientEndColor;

+ (instancetype)iOS8silverGradientStartColor;
+ (instancetype)iOS8silverGradientEndColor;

@end
