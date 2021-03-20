//
//  NSString+Length.h
//  JTime
//
//  Created by Even on 2016/12/30.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Length)

//获取字符串的宽度
+ (float) widthForString:(NSString *)string font:(CGFloat )font height:(CGFloat )heigth;

//获取字符串的高度
+ (float) heightForString:(NSString *)string font:(CGFloat )font width:(CGFloat )width;


+ (float) heightForString:(NSString *)string font:(CGFloat )font width:(CGFloat )width lineSpacing:(CGFloat )lineSpace;

 
//获取字符串长度  数字/英文：1个字节，汉字:2个字节，表情：4个字节
- (NSUInteger)textLength;


@end
