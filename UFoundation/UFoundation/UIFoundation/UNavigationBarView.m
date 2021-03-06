//
//  UNavigationBarView.m
//  UFoundation
//
//  Created by Think on 15/5/12.
//  Copyright (c) 2015年 think. All rights reserved.
//

#import "UNavigationBarView.h"
#import "UDefines.h"
#import "UView.h"
#import "UImageView.h"
#import "UIView+UAExtension.h"
#import "UIColor+UAExtension.h"
#import "NSObject+UAExtension.h"

#pragma mark - UNavigationBarButton class

@interface UNavigationBarButton ()
{
    BOOL _needsConstraint;
}

@property (nonatomic, copy) UIColor *imageColor;

@end

@implementation UNavigationBarButton

- (id)init
{
    self = [super init];
    if (self) {
        // Initialize
        self.needsAutoResize = YES;
        self.showMaskWhenHighlighted = NO;
        self.backgroundMaskHColor = nil;
    }
    
    return self;
}

- (void)setImageFrame:(CGRect)imageFrame
{
    [super setImageFrame:rectMake(0, 0, 24., naviHeight())];
    
    _needsConstraint = YES;
}

- (void)setTitleFrame:(CGRect)frame
{
    if (_needsConstraint) {
        [super setTitleFrame:rectMake(24., 0, frame.size.width, naviHeight())];
    }
}

#pragma mark - Method

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
}

- (void)setHTitle:(NSString *)title
{
    [super setHTitle:title];
}

- (void)setSTitle:(NSString *)title
{
    [super setSTitle:title];
}

- (void)setDTitle:(NSString *)title
{
    [super setDTitle:title];
}

- (void)setImageWithColor:(UIColor *)color
{
    _imageColor = color;
    
    [self setImage:[self imageWith:color]];
}

- (void)setHImageWithColor:(UIColor *)color
{
    [self setHImage:[self imageWith:color]];
}

- (void)setSImageWithColor:(UIColor *)color
{
    [self setSImage:[self imageWith:color]];
}

- (void)setDImageWithColor:(UIColor *)color
{
    [self setDImage:[self imageWith:color]];
}

- (UIImage *)imageWith:(UIColor *)color
{
    @autoreleasepool
    {
        // Color values
        CGFloat redValue = color.redValue;
        CGFloat greenValue = color.greenValue;
        CGFloat blueValue = color.blueValue;
        CGFloat alphaValue = color.alphaValue;
        
        CGRect rect = rectMake(0, 0, 48, 88);
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // Draw arrow
        CGContextSetRGBStrokeColor(context, redValue, greenValue, blueValue, alphaValue);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 16, 46);
        CGContextAddLineToPoint(context, 36, 24);
        CGContextMoveToPoint(context, 16, 42);
        CGContextAddLineToPoint(context, 36, 64);
        CGContextSetLineWidth(context, 6);
        CGContextSetLineJoin(context, kCGLineJoinBevel);
        CGContextStrokePath(context);
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
    }
}

@end

#pragma mark - UNavigationContentView class

@interface UNavigationContentView : UIImageView

@property (nonatomic, strong) ULabel *titleLabel;
@property (nonatomic, strong) UImageView *bottomLineView;

@end

@implementation UNavigationContentView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initliaze
        [self titleLabel];
        [self bottomLineView];
    }
    
    return self;
}

- (ULabel *)titleLabel
{
    if (_titleLabel) {
        return _titleLabel;
    }
    
    CGFloat width = screenWidth() - screenWidth() * 0.4;
    ULabel *titleLabel = [[ULabel alloc]init];
    titleLabel.frame = rectMake(0, 0, width, naviHeight());
    titleLabel.center = pointMake(screenWidth() / 2., naviHeight() / 2.);
    titleLabel.font = boldSystemFont(16);
    titleLabel.textColor = sysBlackColor();
    titleLabel.backgroundColor = sysClearColor();
    titleLabel.numberOfLines = 1;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self addSubview:titleLabel];
    _titleLabel = titleLabel;
    
    return _titleLabel;
}

- (UImageView *)bottomLineView
{
    if (_bottomLineView) {
        return _bottomLineView;
    }
    
    UImageView *bottomLineView = [[UImageView alloc]init];
    bottomLineView.frame = rectMake(0, naviHeight() - naviBLineH(), screenWidth(), naviBLineH());
    bottomLineView.backgroundColor = [sysDarkGrayColor() colorWithAlpha:0.3];
    [self addSubview:bottomLineView];
    _bottomLineView = bottomLineView;
    
    return _bottomLineView;
}

@end

@interface UNavigationBarView ()
{
    BOOL _needsStretch;
    BOOL _bottomLineHidden;
    UIColor *_backgroundColor;
}

@property (nonatomic, strong) UNavigationContentView *contentView;
@property (nonatomic, weak) UImageView *backgroundView;

// Paired bar view
@property (nonatomic, weak) UNavigationBarView *pairedBarView;

@end

@implementation UNavigationBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialize
        self.userInteractionEnabled = YES;
        super.backgroundColor = sysClearColor();
        self.backgroundColor = rgbColor(249., 249., 249.);
        
        [self contentView];
    }
    
    return self;
}

- (void)dealloc
{
    //
}

#pragma mark - Properties

- (UNavigationContentView *)contentView
{
    if (_contentView) {
        return _contentView;
    }
    
    UNavigationContentView *contentView = [[UNavigationContentView alloc]init];
    contentView.frame = rectMake(0, 0, screenWidth(), naviHeight());
    contentView.userInteractionEnabled = YES;
    contentView.backgroundColor = sysClearColor();
    [self addSubview:contentView];
    _contentView = contentView;
    
    return _contentView;
}

- (CGFloat)alpha
{
    return _contentView.alpha;
}

- (void)setAlpha:(CGFloat)alpha
{
    _contentView.alpha = alpha;
}

- (BOOL)hidden
{
    return _contentView.hidden;
}

- (void)setHidden:(BOOL)hidden
{
    _contentView.hidden = hidden;
}

- (UIColor *)backgroundColor
{
    return _backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)color
{
    _backgroundColor = color;
    
    if (self.backgroundView) {
        self.backgroundView.backgroundColor = color;
    }
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    _contentView.titleLabel.text = title;
    
    CGFloat sizeWidth = _contentView.titleLabel.contentWidth;
    CGFloat maxWidth = screenWidth() * 0.5;
    sizeWidth = (sizeWidth > maxWidth)?maxWidth:sizeWidth;
    
    _contentView.titleLabel.sizeWidth = sizeWidth;
    _contentView.titleLabel.centerX = screenWidth() / 2.;
}

- (void)setTitleColor:(UIColor *)color
{
    _titleColor = color;
    
    _contentView.titleLabel.textColor = color;
}

- (void)setBottomLineColor:(UIColor *)color
{
    _bottomLineColor = color;
    
    _contentView.bottomLineView.backgroundColor = color;
}

- (void)setBackgroundImage:(UIImage *)image
{
    _backgroundImage = image;
    
    _contentView.image = image;
}

- (void)setTitleFont:(UIFont *)font
{
    _titleFont = font;
    
    _contentView.titleLabel.font = font;
}

- (void)setBackgroundView:(UImageView *)backgroundView
{
    _backgroundView = backgroundView;
    _backgroundView.backgroundColor = _backgroundColor;
}

- (void)repositionWith:(NSNumber *)xvalue
{
    [self repositionWith:[xvalue floatValue] animated:NO before:NO];
}

- (void)repositionAnimationWith:(NSNumber *)xvalue
{
    [self repositionWith:[xvalue floatValue] animated:YES before:NO];
}

- (void)repositionBeforeAnimationWith:(NSNumber *)xvalue
{
    [self repositionWith:[xvalue floatValue] animated:YES before:YES];
}

- (void)repositionWith:(CGFloat)xvalue
              animated:(BOOL)animated
                before:(BOOL)before
{
    CGFloat leftValue = (screenWidth() - _contentView.titleLabel.sizeWidth) / 2.0;
    UIView *leftItemView = _leftView?_leftView:[_leftButton valueForKey:@"titleLabel"];
    UIView *rightItemView = _rightView?_rightView:[_rightButton valueForKey:@"titleLabel"];
    
    CGFloat alpha = 0;
    if (xvalue >= 0) {
        // Current contentView
        CGFloat progress = 1. - (screenWidth() - xvalue) / screenWidth(); // 0 -> 1
        CGFloat originX = 0;
        
        alpha = powf(1. - progress, 4.);
        
        if (animated) {
            originX = (screenWidth() - leftValue) * progress + leftValue;
        } else {
            if (before) {
                originX = leftValue * 2.;
            } else {
                originX = (screenWidth() - leftValue) * progress + leftValue;
            }
        }
        
        _contentView.alpha = animated?alpha:1.;
        _contentView.titleLabel.alpha = alpha;
        _contentView.bottomLineView.alpha = alpha;
        _contentView.titleLabel.originX = originX;

        if (_leftButton) {
            CGFloat centerX = leftItemView.sizeWidth / 2. + 24.;
            leftItemView.centerX = centerX + (screenWidth() * 0.5 - centerX) * progress;
        }
    } else {
        // Last contentView
        CGFloat progress = (screenWidth() + xvalue) / screenWidth(); // 1 -> 0
        CGFloat originX = progress * (leftValue - 24.) + 24.;

        alpha = powf(progress, 4.);
        
        _contentView.alpha = animated?alpha:1.;
        _contentView.titleLabel.alpha = alpha;
        _contentView.bottomLineView.alpha = alpha;
        _contentView.titleLabel.originX = originX;
        
        if (_leftButton) {
            leftItemView.originX = 24. - (1 - progress) * leftItemView.sizeWidth;
        }
    }
    
    leftItemView.alpha = alpha;
    rightItemView.alpha = alpha;
    
    // Left button icon
    if (_leftButton) {
        UNavigationBarButton *pairedButton = _pairedBarView.leftButton;
        UIColor *leftColor = [_leftButton valueForKey:@"imageColor"];
        UIColor *pairedColor = [pairedButton valueForKey:@"imageColor"];
        
        if (!pairedButton || pairedButton.hidden != _leftButton.hidden || !(leftColor && pairedColor) ||
            (![leftColor isEqualToColor:pairedColor]))
        {
            UImageView *imageView = [_leftButton valueForKey:@"imageView"];
            imageView.alpha = alpha;
        }
    }

    if (_centerView) {
        _centerView.alpha = _contentView.titleLabel.alpha;
        _centerView.centerX = _contentView.titleLabel.centerX;
    }
}

- (void)setBottomLineHidden:(BOOL)hidden
{
    _bottomLineHidden = hidden;
    
    _contentView.bottomLineView.hidden = hidden;
}

- (void)setEnable:(BOOL)enable
{
    _enable = enable;
    
    for (UIView *view in _contentView.subviews) {
        if (checkClass(view, UIControl)) {
            UIControl *control = (UIControl *)view;
            control.enabled = enable;
        }
    }
}

- (void)setLeftButton:(UNavigationBarButton *)leftButton
{
    if (_leftView) {
        return;
    }
    
    if (_leftButton) {
        [_leftButton removeFromSuperview];
    }
    _leftButton = leftButton;
    
    [_contentView addSubview:leftButton];
}

- (void)setRightButton:(UNavigationBarButton *)rightButton
{
    if (_rightView) {
        return;
    }
    
    if (_rightButton) {
        [_rightButton removeFromSuperview];
    }
    _rightButton = rightButton;
    
    [_contentView addSubview:rightButton];
}

- (void)setLeftView:(UIView *)leftView
{
    if (_leftView) {
        [_leftView removeFromSuperview];
    }
    _leftView = leftView;
    
    if (_leftButton) {
        [_leftButton removeFromSuperview];
        _leftButton = nil;
    }
    
    [_contentView addSubview:leftView];
}

- (void)setCenterView:(UIView *)centerView
{
    if (_centerView) {
        [_centerView removeFromSuperview];
    }
    _centerView = centerView;
    _contentView.titleLabel.text = @"";
    
    CGSize size = _contentView.size;
    centerView.center = pointMake(size.width / 2., size.height / 2.);
    [_contentView addSubview:centerView];
}

- (void)setRightView:(UIView *)rightView
{
    if (_rightView) {
        [_rightView removeFromSuperview];
    }
    _rightView = rightView;
    
    if (_rightButton) {
        [_rightButton removeFromSuperview];
        _rightButton = nil;
    }
    
    [_contentView addSubview:rightView];
}

- (void)stretch
{
    [self setStretch:NO animated:NO];
}

- (void)collapse
{
    [self setStretch:YES animated:NO];
}

- (void)stretchWithAnimation
{
    [self setStretch:NO animated:YES];
}

- (void)collapseWithAnimation
{
    [self setStretch:YES animated:YES];
}

- (void)setStretch:(BOOL)stretch animated:(BOOL)animated
{
    if (_needsStretch == stretch) {
        return;
    }
    _needsStretch = stretch;
    
    CGFloat originY = stretch?- naviHeight():statusHeight();
    if (self.originY != originY) {
        if (!animated) {
            self.originY = originY;
        } else {
            [UIView beginAnimations:@"UNavigationBarViewStretchAnimation" context:nil];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:animationDuration()];
            
            self.originY = originY;
            
            [UIView commitAnimations];
        }
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    //
}

@end
