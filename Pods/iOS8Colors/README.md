# iOS8Colors

A category on UIColor which provides you some of the standard colors used throughout iOS 8.

## Usage

The easiest way to integrate iOS8Colors is using CocoaPods. Just add this to your Podfile:

    pod 'iOS8Colors'

Usage is really simple. Just include `UIColor+iOS8Colors.h` & `UIColor+iOS8Colors.m` in your project if you're not using cocoapods and import the header file you need the colors.

    #import "UIColor+iOS8Colors.h"

    UILabel *label = [UILabel alloc] initWithFrame:CGRectZero];

    label.textColor = [UIColor iOS8redColor];

![Screenshot](https://raw.githubusercontent.com/thii/iOS8Colors/master/screenshot.png)

## Credits

The color values are taken from [Zenimot](http://zenimot.nl/)'s [iOS 8 colors](http://ios8colors.com/)

## License
[MIT](http://thi.mit-license.org/)
