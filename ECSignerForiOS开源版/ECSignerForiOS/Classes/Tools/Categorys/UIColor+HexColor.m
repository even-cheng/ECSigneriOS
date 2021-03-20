//
//  UIColor+HexColor.m
//  JTime
//
//  Created by Even on 16/10/27.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "UIColor+HexColor.h"

@implementation UIColor (HexColor)

+ (UIColor*) colorWithHex:(long)hexColor;
{
    return [UIColor colorWithHex:hexColor alpha:1.];
}

+ (UIColor *)colorWithHex:(long)hexColor alpha:(float)opacity
{
    float red = ((float)((hexColor & 0xFF0000) >> 16))/255.0;
    float green = ((float)((hexColor & 0xFF00) >> 8))/255.0;
    float blue = ((float)(hexColor & 0xFF))/255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:opacity];
}


+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha
{
    //删除字符串中的空格
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6)
    {
        return [UIColor clearColor];
    }
    // strip 0X if it appears
    //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"])
    {
        cString = [cString substringFromIndex:2];
    }
    //如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"])
    {
        cString = [cString substringFromIndex:1];
    }
    if ([cString length] != 6)
    {
        return [UIColor clearColor];
    }
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}

//默认alpha值为1
+ (UIColor *)colorWithHexString:(NSString *)color
{
    return [self colorWithHexString:color alpha:1.0f];
}


+ (UIColor *)transitionColorWithBeginColor:(UIColor *)beginColor endColor:(UIColor *)endColor progress:(CGFloat)progress {
    
    
    CGFloat beginRed,beginGreen,beginBlue,beginAlpha = 0;
    CGFloat endRed,endGreen,endBlue,endAlpha = 0;
    [beginColor getRed:&beginRed green:&beginGreen blue:&beginBlue alpha:&beginAlpha];
    [endColor getRed:&endRed green:&endGreen blue:&endBlue alpha:&endAlpha];
    
    CGFloat red = beginRed    + (endRed   - beginRed)     * progress;
    CGFloat green = beginGreen  + (endGreen - beginGreen)   * progress;
    CGFloat blue = beginBlue   + (endBlue  - beginBlue)    * progress;
    CGFloat alpha = beginAlpha  + (endAlpha - beginAlpha)   * progress;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    
}

+ (NSArray *)getRGBColorWithUIColor:(UIColor *)color;{
    
    CGColorRef colorRef = color.CGColor;
    size_t count = CGColorGetNumberOfComponents(colorRef);
    const CGFloat *components = CGColorGetComponents(colorRef);
    if (count == 2) {
        NSUInteger white = (NSUInteger)(components[0] * 255.0f);
        CGFloat alpha = (CGFloat)components[1];
        return @[@(white),@(alpha)];
    } else if (count == 4) {
        NSUInteger red = (NSUInteger)(components[0] * 255.0f);
        NSUInteger green = (NSUInteger)(components[1] * 255.0f);
        NSUInteger blue = (NSUInteger)(components[2] * 255.0f);
        CGFloat alpha = (CGFloat)components[1];
        return @[@(red),@(green),@(blue),@(alpha)];
    }
    return @[];
}

@end
