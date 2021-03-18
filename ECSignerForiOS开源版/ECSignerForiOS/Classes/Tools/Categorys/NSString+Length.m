//
//  NSString+Length.m
//  JTime
//
//  Created by Even on 2016/12/30.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "NSString+Length.h"

@implementation NSString (Length)

//获取字符串的宽度
+ (float) widthForString:(NSString *)string font:(CGFloat)font height:(CGFloat)heigth
{
    return ceilf([string boundingRectWithSize:CGSizeMake(MAXFLOAT, heigth) options:NSStringDrawingTruncatesLastVisibleLine |
            NSStringDrawingUsesLineFragmentOrigin |
            NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:font]} context:nil].size.width);
    
}


+ (float)heightForString:(NSString *)string font:(CGFloat )font width:(CGFloat)width {
    return ceilf([string boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:
            NSStringDrawingUsesLineFragmentOrigin |
            NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:font]} context:nil].size.height);
}

+ (float)heightForString:(NSString *)string font:(CGFloat)font width:(CGFloat)width lineSpacing:(CGFloat)lineSpace {
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpace;// 字体的行间距
    
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName:[UIFont systemFontOfSize:font],
                                 NSParagraphStyleAttributeName:paragraphStyle
                                 };
    
    return [string boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingTruncatesLastVisibleLine |
            NSStringDrawingUsesLineFragmentOrigin |
            NSStringDrawingUsesFontLeading attributes:attributes context:nil].size.height;
}



- (NSUInteger)textLength {
    
    NSUInteger asciiLength = 0;
    
    for (NSUInteger i = 0; i < self.length; i++) {
        
        unichar uc = [self characterAtIndex: i];
        asciiLength += isascii(uc) ? 1 : 2;
    }
    
    NSUInteger unicodeLength = asciiLength;
    
    return unicodeLength;
}



@end
