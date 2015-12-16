//
//  UITextView+UAExtension.m
//  UFoundation
//
//  Created by Think on 15/8/1.
//  Copyright (c) 2015年 think. All rights reserved.
//

#import "UITextView+UAExtension.h"
#import "NSString+UAExtension.h"
#import "UIView+UAExtension.h"
#import "UDefines.h"

@implementation UITextView (UAExtension)

#pragma mark - Methods

- (CGFloat)contentWidth
{
    return [self contentSizeWith:sizeMake(MAXFLOAT, self.sizeHeight)].width;
}

- (CGFloat)contentHeight
{
    return [self contentSizeWith:sizeMake(self.sizeWidth, MAXFLOAT)].height;
}

- (void)resizeToFitWidth
{
    self.sizeWidth = self.contentWidth;
}

- (void)resizeToFitHeight
{
    self.sizeHeight = self.contentHeight;
}

- (void)resizeToFitContent
{
    self.size = sizeMake(self.contentWidth, self.contentHeight);
}

- (CGSize)contentSizeWith:(CGSize)size
{
    return [self sizeThatFits:size];
}

@end
