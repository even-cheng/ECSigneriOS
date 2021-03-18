//
//  UIBarButtonItem+SXCreate.m
//  UINavigationItem-SXFixSpace
//
//  Created by charles on 2017/9/8.
//  Copyright © 2017年 None. All rights reserved.
//

#import "UIBarButtonItem+SXCreate.h"

@implementation UIBarButtonItem (SXCreate)

+(UIBarButtonItem *)itemWithTarget:(id)target action:(SEL)action image:(UIImage *)image {
    return [self itemWithTarget:target action:action nomalImage:image higeLightedImage:nil imageEdgeInsets:UIEdgeInsetsZero];
}

+(UIBarButtonItem *)itemWithTarget:(id)target action:(SEL)action image:(UIImage *)image imageEdgeInsets:(UIEdgeInsets)imageEdgeInsets {
    return [self itemWithTarget:target action:action nomalImage:image higeLightedImage:nil imageEdgeInsets:imageEdgeInsets];
}

+(UIBarButtonItem *)itemWithTarget:(id)target
                            action:(SEL)action
                        nomalImage:(UIImage *)nomalImage
                  higeLightedImage:(UIImage *)higeLightedImage
                   imageEdgeInsets:(UIEdgeInsets)imageEdgeInsets {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    [button setImage:[nomalImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    if (!higeLightedImage) {
        higeLightedImage = nomalImage;
    }
    [button setImage:higeLightedImage forState:UIControlStateHighlighted];
    [button sizeToFit];
    if (button.bounds.size.width < 44) {
//        CGFloat width = button.bounds.size.height * button.bounds.size.width;
        button.bounds = CGRectMake(0, 0, 44, 44);
    }
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.imageEdgeInsets = imageEdgeInsets;
    return [[UIBarButtonItem alloc] initWithCustomView:button];
    
}

+(UIBarButtonItem *)itemWithTarget:(id)target action:(SEL)action title:(NSString *)title titleColor:(UIColor*)color withBorder:(BOOL)showBorder{
    return [self itemWithTarget:target action:action title:title font:nil titleColor:color highlightedColor:nil titleEdgeInsets:UIEdgeInsetsZero withBorder:showBorder];
}

+(UIBarButtonItem *)itemWithTarget:(id)target action:(SEL)action title:(NSString *)title titleEdgeInsets:(UIEdgeInsets)titleEdgeInsets {
    return [self itemWithTarget:target action:action title:title font:nil titleColor:[UIColor darkGrayColor] highlightedColor:nil titleEdgeInsets:titleEdgeInsets withBorder:NO];
}

+(UIBarButtonItem *)itemWithTarget:(id)target
                            action:(SEL)action
                             title:(NSString *)title
                              font:(UIFont *)font
                        titleColor:(UIColor *)titleColor
                  highlightedColor:(UIColor *)highlightedColor
                   titleEdgeInsets:(UIEdgeInsets)titleEdgeInsets
                        withBorder:(BOOL)showBorder {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = font?font:[UIFont systemFontOfSize:16];
    if (titleColor) {
        [button setTitleColor:titleColor forState:UIControlStateNormal];
    }
    if (showBorder) {
        button.layer.borderColor = titleColor.CGColor;
        button.layer.borderWidth = 1;
        button.layer.cornerRadius = 2;
        button.layer.masksToBounds = YES;
    }
    if (highlightedColor) {
        [button setTitleColor:highlightedColor forState:UIControlStateHighlighted];
    }
    
    [button sizeToFit];
    if (button.bounds.size.width < 40) {
        CGFloat width = 40 / button.bounds.size.height * button.bounds.size.width;
        button.bounds = CGRectMake(0, 0, width, 40);
    }
    if (showBorder) {
        button.titleLabel.font = [UIFont systemFontOfSize:15];
        button.bounds = CGRectMake(0, 0, button.bounds.size.width+10, 30);
    }
    button.titleEdgeInsets = titleEdgeInsets;
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}

+(UIBarButtonItem *)fixedSpaceWithWidth:(CGFloat)width {
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = width;
    return fixedSpace;
}

@end
