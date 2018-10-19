//
//  UIImage+TOWebViewControllerIcons.m
//
//  Copyright 2013-2015 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import "UIImage+TOWebViewControllerIcons.h"

const NSString *TOWebViewControllerButtonTintColor       = @"TOWebViewControllerButtonFillColor";
const NSString *TOWebViewControllerButtonBevelOpacity    = @"TOWebViewControllerButtonBevelOpacity";

/* Default iOS 6 Theming Properties */
#define DEFAULT_IPHONE_BUTTON_TINT [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f]
#define DEFAULT_IPAD_BUTTON_TINT   [UIColor colorWithRed:0.35f green:0.35f blue:0.35f alpha:1.0f]

#define DEFAULT_IPHONE_BEVEL_OPACITY    0.5f
#define DEFAULT_IPAD_BEVEL_OPACITY      0.9f

/* Detect which user idiom we're running on */
#define IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface UIImage (private)

+ (UIColor *)fillColorFromAttributes:(NSDictionary *)attributes;
+ (CGFloat)bevelOpacityFromAttributes:(NSDictionary *)attributes;
+ (void)drawBevelFromFillColor:(UIColor *)fillColor opacity:(CGFloat)opacity;

@end

@implementation UIImage (TOWebViewControllerIcons)

#pragma mark - Private Methods -
+ (UIColor *)fillColorFromAttributes:(NSDictionary *)attributes
{
    UIColor *fillColor = attributes[TOWebViewControllerButtonTintColor];
    if (fillColor == nil) {
        if (IPAD)
            fillColor = DEFAULT_IPAD_BUTTON_TINT;
        else
            fillColor = DEFAULT_IPHONE_BUTTON_TINT;
    }
    
    return fillColor;
}

+ (CGFloat)bevelOpacityFromAttributes:(NSDictionary *)attributes
{
    NSNumber *opacityNumber = attributes[TOWebViewControllerButtonBevelOpacity];
    if (opacityNumber == nil) {
        if (IPAD)
            return DEFAULT_IPAD_BEVEL_OPACITY;
        else
            return DEFAULT_IPHONE_BEVEL_OPACITY;
    }
    
    return opacityNumber.floatValue;
}

+ (void)drawBevelFromFillColor:(UIColor *)fillColor opacity:(CGFloat)opacity
{
    CGFloat hue = 0.0f, saturation = 0.0f, brightness = 0.0f, alpha = 0.0f;
    [fillColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    //Use dark beveling if the image is REALLY close to white
    BOOL shouldUseDarkBevel = (saturation < 0.3f && brightness > 0.85f);

    CGSize offset = (CGSize){0.0f, 1.0f};
    if (shouldUseDarkBevel)
        offset.height = -1.0f;
        
    //Set up the Core Graphics context to render a shadow
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *bevelColor = nil;
    if (shouldUseDarkBevel)
        bevelColor = [UIColor colorWithWhite:0.0f alpha:opacity];
    else
        bevelColor = [UIColor colorWithWhite:1.0f alpha:opacity];
    
    CGContextSetShadowWithColor(context, offset, 0.0f, bevelColor.CGColor);
    
    //Set the following draw commands to be offset one pixel if drawing the dark bevel above it
    if (shouldUseDarkBevel)
        CGContextTranslateCTM(context, 0, 1.0f);
}

#pragma mark - Navigation Buttons -
+ (instancetype)TOWebViewControllerIcon_backButtonWithAttributes:(NSDictionary *)attributes
{
    UIImage *backButtonImage = nil;

    UIGraphicsBeginImageContextWithOptions((CGSize){12,21}, NO, [[UIScreen mainScreen] scale]);
    {
        //// Color Declarations
        UIColor* backColor = [UIColor blackColor];

        //// BackButton Drawing
        UIBezierPath* backButtonPath = [UIBezierPath bezierPath];
        [backButtonPath moveToPoint: CGPointMake(10.9, 0)];
        [backButtonPath addLineToPoint: CGPointMake(12, 1.1)];
        [backButtonPath addLineToPoint: CGPointMake(1.1, 11.75)];
        [backButtonPath addLineToPoint: CGPointMake(0, 10.7)];
        [backButtonPath addLineToPoint: CGPointMake(10.9, 0)];
        [backButtonPath closePath];
        [backButtonPath moveToPoint: CGPointMake(11.98, 19.9)];
        [backButtonPath addLineToPoint: CGPointMake(10.88, 21)];
        [backButtonPath addLineToPoint: CGPointMake(0.54, 11.21)];
        [backButtonPath addLineToPoint: CGPointMake(1.64, 10.11)];
        [backButtonPath addLineToPoint: CGPointMake(11.98, 19.9)];
        [backButtonPath closePath];
        [backColor setFill];
        [backButtonPath fill];

        backButtonImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return backButtonImage;
}

+ (instancetype)TOWebViewControllerIcon_forwardButtonWithAttributes:(NSDictionary *)attributes
{
    UIImage *forwardButtonImage = nil;

    UIGraphicsBeginImageContextWithOptions((CGSize){12,21}, NO, [[UIScreen mainScreen] scale]);
    {
        //// Color Declarations
        UIColor* forwardColor = [UIColor blackColor];

        //// BackButton Drawing
        UIBezierPath* forwardButtonPath = [UIBezierPath bezierPath];
        [forwardButtonPath moveToPoint: CGPointMake(1.1, 0)];
        [forwardButtonPath addLineToPoint: CGPointMake(0, 1.1)];
        [forwardButtonPath addLineToPoint: CGPointMake(10.9, 11.75)];
        [forwardButtonPath addLineToPoint: CGPointMake(12, 10.7)];
        [forwardButtonPath addLineToPoint: CGPointMake(1.1, 0)];
        [forwardButtonPath closePath];
        [forwardButtonPath moveToPoint: CGPointMake(0.02, 19.9)];
        [forwardButtonPath addLineToPoint: CGPointMake(1.12, 21)];
        [forwardButtonPath addLineToPoint: CGPointMake(11.46, 11.21)];
        [forwardButtonPath addLineToPoint: CGPointMake(10.36, 10.11)];
        [forwardButtonPath addLineToPoint: CGPointMake(0.02, 19.9)];
        [forwardButtonPath closePath];
        [forwardColor setFill];
        [forwardButtonPath fill];

        forwardButtonImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return forwardButtonImage;
}

+ (instancetype)TOWebViewControllerIcon_refreshButtonWithAttributes:(NSDictionary *)attributes
{
    UIImage *refreshButtonImage = nil;
    UIGraphicsBeginImageContextWithOptions((CGSize){19,22}, NO, [[UIScreen mainScreen] scale]);
    {
        //// Color Declarations
        UIColor* refreshColor = [UIColor blackColor];

        //// RefreshButton Drawing
        UIBezierPath* refreshIconPath = [UIBezierPath bezierPath];
        [refreshIconPath moveToPoint: CGPointMake(18.98, 12)];
        [refreshIconPath addCurveToPoint: CGPointMake(19, 12.8) controlPoint1: CGPointMake(18.99, 12.11) controlPoint2: CGPointMake(19, 12.69)];
        [refreshIconPath addCurveToPoint: CGPointMake(9.5, 22) controlPoint1: CGPointMake(19, 17.88) controlPoint2: CGPointMake(14.75, 22)];
        [refreshIconPath addCurveToPoint: CGPointMake(0, 12.8) controlPoint1: CGPointMake(4.25, 22) controlPoint2: CGPointMake(0, 17.88)];
        [refreshIconPath addCurveToPoint: CGPointMake(10, 3.5) controlPoint1: CGPointMake(0, 7.72) controlPoint2: CGPointMake(4.75, 3.5)];
        [refreshIconPath addCurveToPoint: CGPointMake(10, 5) controlPoint1: CGPointMake(10.02, 3.5) controlPoint2: CGPointMake(10.02, 5)];
        [refreshIconPath addCurveToPoint: CGPointMake(1.69, 12.8) controlPoint1: CGPointMake(5.69, 5) controlPoint2: CGPointMake(1.69, 8.63)];
        [refreshIconPath addCurveToPoint: CGPointMake(9.5, 20.36) controlPoint1: CGPointMake(1.69, 16.98) controlPoint2: CGPointMake(5.19, 20.36)];
        [refreshIconPath addCurveToPoint: CGPointMake(17.31, 12) controlPoint1: CGPointMake(13.81, 20.36) controlPoint2: CGPointMake(17.31, 16.18)];
        [refreshIconPath addCurveToPoint: CGPointMake(17.28, 12) controlPoint1: CGPointMake(17.31, 11.89) controlPoint2: CGPointMake(17.28, 12.11)];
        [refreshIconPath addLineToPoint: CGPointMake(18.98, 12)];
        [refreshIconPath closePath];
        [refreshIconPath moveToPoint: CGPointMake(10, 0)];
        [refreshIconPath addLineToPoint: CGPointMake(17.35, 4.62)];
        [refreshIconPath addLineToPoint: CGPointMake(10, 9.13)];
        [refreshIconPath addLineToPoint: CGPointMake(10, 0)];
        [refreshIconPath closePath];
        [refreshColor setFill];
        [refreshIconPath fill];

        refreshButtonImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return refreshButtonImage;
}

+ (instancetype)TOWebViewControllerIcon_stopButtonWithAttributes:(NSDictionary *)attributes
{
    UIImage *stopButtonImage = nil;
    UIGraphicsBeginImageContextWithOptions((CGSize){19,19}, NO, [[UIScreen mainScreen] scale]);
    {
        //// Color Declarations
        UIColor* stopColor = [UIColor blackColor];

        //// StopButton Drawing
        UIBezierPath* stopButtonPath = [UIBezierPath bezierPath];
        [stopButtonPath moveToPoint: CGPointMake(19, 17.82)];
        [stopButtonPath addLineToPoint: CGPointMake(17.82, 19)];
        [stopButtonPath addLineToPoint: CGPointMake(9.5, 10.68)];
        [stopButtonPath addLineToPoint: CGPointMake(1.18, 19)];
        [stopButtonPath addLineToPoint: CGPointMake(0, 17.82)];
        [stopButtonPath addLineToPoint: CGPointMake(8.32, 9.5)];
        [stopButtonPath addLineToPoint: CGPointMake(0, 1.18)];
        [stopButtonPath addLineToPoint: CGPointMake(1.18, 0)];
        [stopButtonPath addLineToPoint: CGPointMake(9.5, 8.32)];
        [stopButtonPath addLineToPoint: CGPointMake(17.82, 0)];
        [stopButtonPath addLineToPoint: CGPointMake(19, 1.18)];
        [stopButtonPath addLineToPoint: CGPointMake(10.68, 9.5)];
        [stopButtonPath addLineToPoint: CGPointMake(19, 17.82)];
        [stopButtonPath closePath];
        [stopColor setFill];
        [stopButtonPath fill];

        stopButtonImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    return stopButtonImage;
}

+ (instancetype)TOWebViewControllerIcon_actionButtonWithAttributes:(NSDictionary *)attributes
{
    UIImage *actionButtonImage = nil;
    UIGraphicsBeginImageContextWithOptions((CGSize){19,30}, NO, [[UIScreen mainScreen] scale]);
    {
        //// Color Declarations
        UIColor* actionColor = [UIColor blackColor];

        //// ActionButton Drawing
        UIBezierPath* actionButtonPath = [UIBezierPath bezierPath];
        [actionButtonPath moveToPoint: CGPointMake(1, 9)];
        [actionButtonPath addLineToPoint: CGPointMake(1, 26.02)];
        [actionButtonPath addLineToPoint: CGPointMake(18, 26.02)];
        [actionButtonPath addLineToPoint: CGPointMake(18, 9)];
        [actionButtonPath addLineToPoint: CGPointMake(12, 9)];
        [actionButtonPath addLineToPoint: CGPointMake(12, 8)];
        [actionButtonPath addLineToPoint: CGPointMake(19, 8)];
        [actionButtonPath addLineToPoint: CGPointMake(19, 27)];
        [actionButtonPath addLineToPoint: CGPointMake(0, 27)];
        [actionButtonPath addLineToPoint: CGPointMake(0, 8)];
        [actionButtonPath addLineToPoint: CGPointMake(7, 8)];
        [actionButtonPath addLineToPoint: CGPointMake(7, 9)];
        [actionButtonPath addLineToPoint: CGPointMake(1, 9)];
        [actionButtonPath closePath];
        [actionButtonPath moveToPoint: CGPointMake(9, 0.98)];
        [actionButtonPath addLineToPoint: CGPointMake(10, 0.98)];
        [actionButtonPath addLineToPoint: CGPointMake(10, 17)];
        [actionButtonPath addLineToPoint: CGPointMake(9, 17)];
        [actionButtonPath addLineToPoint: CGPointMake(9, 0.98)];
        [actionButtonPath closePath];
        [actionButtonPath moveToPoint: CGPointMake(13.99, 4.62)];
        [actionButtonPath addLineToPoint: CGPointMake(13.58, 5.01)];
        [actionButtonPath addCurveToPoint: CGPointMake(13.25, 5.02) controlPoint1: CGPointMake(13.49, 5.1) controlPoint2: CGPointMake(13.34, 5.11)];
        [actionButtonPath addLineToPoint: CGPointMake(9.43, 1.27)];
        [actionButtonPath addCurveToPoint: CGPointMake(9.44, 0.94) controlPoint1: CGPointMake(9.34, 1.18) controlPoint2: CGPointMake(9.35, 1.04)];
        [actionButtonPath addLineToPoint: CGPointMake(9.85, 0.56)];
        [actionButtonPath addCurveToPoint: CGPointMake(10.18, 0.55) controlPoint1: CGPointMake(9.94, 0.46) controlPoint2: CGPointMake(10.09, 0.46)];
        [actionButtonPath addLineToPoint: CGPointMake(14, 4.29)];
        [actionButtonPath addCurveToPoint: CGPointMake(13.99, 4.62) controlPoint1: CGPointMake(14.09, 4.38) controlPoint2: CGPointMake(14.08, 4.53)];
        [actionButtonPath closePath];
        [actionButtonPath moveToPoint: CGPointMake(5.64, 4.95)];
        [actionButtonPath addLineToPoint: CGPointMake(5.27, 4.56)];
        [actionButtonPath addCurveToPoint: CGPointMake(5.26, 4.23) controlPoint1: CGPointMake(5.18, 4.47) controlPoint2: CGPointMake(5.17, 4.32)];
        [actionButtonPath addLineToPoint: CGPointMake(9.46, 0.07)];
        [actionButtonPath addCurveToPoint: CGPointMake(9.79, 0.07) controlPoint1: CGPointMake(9.55, -0.02) controlPoint2: CGPointMake(9.69, -0.02)];
        [actionButtonPath addLineToPoint: CGPointMake(10.16, 0.47)];
        [actionButtonPath addCurveToPoint: CGPointMake(10.17, 0.8) controlPoint1: CGPointMake(10.25, 0.56) controlPoint2: CGPointMake(10.26, 0.71)];
        [actionButtonPath addLineToPoint: CGPointMake(5.97, 4.96)];
        [actionButtonPath addCurveToPoint: CGPointMake(5.64, 4.95) controlPoint1: CGPointMake(5.88, 5.05) controlPoint2: CGPointMake(5.74, 5.05)];
        [actionButtonPath closePath];
        [actionColor setFill];
        [actionButtonPath fill];

        actionButtonImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();

    return actionButtonImage;
}

@end
