//
//  UIColor+HexColor.h
//  JTime
//
//  Created by Even on 16/10/27.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (HexColor)

+ (UIColor *)colorWithHex:(long)hexColor;
+ (UIColor *)colorWithHex:(long)hexColor alpha:(float)opacity;


+ (UIColor *)colorWithHexString:(NSString *)color;

//从十六进制字符串获取颜色，
//color:支持@“#123456”、 @“0X123456”、 @“123456”三种格式
+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha;
+ (UIColor *)transitionColorWithBeginColor:(UIColor *)beginColor endColor:(UIColor *)endColor progress:(CGFloat)progress;

+ (NSArray *)getRGBColorWithUIColor:(UIColor *)color;

@end
