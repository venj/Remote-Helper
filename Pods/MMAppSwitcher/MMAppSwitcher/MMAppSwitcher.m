//
//  MMAppSwitcher.m
//  ClockShots
//
//  Created by Vinh Phuc Dinh on 23.11.13.
//  Copyright (c) 2013 Mocava Mobile. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MMAppSwitcher.h"

@interface UIView(Rasterize)
- (UIImageView *)mm_rasterizedView;
@end

@interface MMAppSwitcher()

@property (nonatomic, weak) id<MMAppSwitcherDataSource> dataSource;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIWindow *window;

@end

static MMAppSwitcher *_sharedInstance;

@implementation MMAppSwitcher

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [MMAppSwitcher new];
        _sharedInstance.window = [[UIApplication sharedApplication] delegate].window;
        _sharedInstance.window.backgroundColor = [UIColor clearColor];
    });
    return _sharedInstance;
}

- (void)setDataSource:(id<MMAppSwitcherDataSource>)dataSource {
    _dataSource = dataSource;
    if (_dataSource) {
        [self enableNotifications];
    } else {
        [self disableNotifications];
    }
}

- (void)enableNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)disableNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadCard {
    if ([self.dataSource respondsToSelector:@selector(viewForCard)]) {
        CGSize cardSize = [self cardSizeForCurrentOrientation];
        CGRect cardFrame = (CGRect){0, 0, cardSize};
        UIView *view = [self.dataSource viewForCard];
        view.frame = cardFrame;
        [view layoutIfNeeded];
        if (view) {
            [self.view removeFromSuperview];
            UIImageView *cardView = [view mm_rasterizedView];
            self.view = cardView;
            self.view.frame = cardFrame;
            [self.window addSubview:self.view];
        } else {
            [self.view removeFromSuperview];
            self.view = nil;
        }
    }
}

- (void)setNeedsUpdate {
    [self loadCard];
}

#pragma mark - Helper methods

- (CGSize)cardSizeForCurrentOrientation {
    CGFloat x, y;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    screenSize.width > screenSize.height ? (x = screenSize.width, y = screenSize.height) : (y = screenSize.width, x = screenSize.height);
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
        return CGSizeMake(x, y);
    }
    else {
        return CGSizeMake(y, x);
    }
}

#pragma mark - Notifications

- (void)appWillEnterForeground {
    [self.view removeFromSuperview];
    self.view = nil;
}

- (void)appDidEnterBackground {
    [self loadCard];
}

@end



#pragma mark - Helper category

@implementation UIView(Rasterize)

- (UIImageView *)mm_rasterizedView {
    self.layer.magnificationFilter = kCAFilterNearest;
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [[UIImageView alloc] initWithImage:img];
}

@end
