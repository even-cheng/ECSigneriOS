//
//  UILabel+AttributeString.m
//  jishijian
//
//  Created by Even on 2017/8/31.
//  Copyright © 2017年 JiShiJian. All rights reserved.
//

#import "UILabel+AttributeString.h"

@implementation UILabel (AttributeString)

- (void)setText:(NSString*)text font:(UIFont*)font color:(UIColor*)color;{
    self.text = text;
    self.textColor = color;
    self.font = font;
}

- (CGSize)setAttributeText:(NSString*)text font:(UIFont*)font color:(UIColor*)color linespace:(CGFloat)linespace{
   
    CGSize size = [self setAttributeText:text font:font color:color withLowerString:nil andFont:nil andColor:nil withLowerOtherString:nil andFont:nil andColor:nil andLinespace:linespace];
    
    return size;
}

-(CGSize)setAttributeText:(NSString*)text
                   font:(UIFont*)fontText
                  color:(UIColor*)color
        withLowerString:(NSString*)lowerString
                andFont:(UIFont*)fontLower
               andColor:(UIColor*)colorLower
   withLowerOtherString:(NSString*)lowerOtherString
                andFont:(UIFont*)fontLowerOther
               andColor:(UIColor*)colorLowerOther
           andLinespace:(CGFloat)linespace{
    
    self.textColor = color;
    self.font = fontText;
    self.text = text;
    if (!text) {
        return CGSizeZero;
    }
    NSMutableAttributedString *noteString = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange totalRange = [text rangeOfString:text];
    [noteString addAttribute:NSFontAttributeName value:fontText range:totalRange];
    [noteString addAttribute:NSForegroundColorAttributeName value:color range:totalRange];
    
    if (lowerString) {
        NSRange lowerRange = [text rangeOfString:lowerString];
        [noteString addAttribute:NSFontAttributeName value:fontLower range:lowerRange];
        [noteString addAttribute:NSForegroundColorAttributeName value:colorLower range:lowerRange];
    }
    if (lowerOtherString) {
        NSRange lowerOtherRange = [text rangeOfString:lowerOtherString];
        [noteString addAttribute:NSFontAttributeName value:fontLowerOther range:lowerOtherRange];
        [noteString addAttribute:NSForegroundColorAttributeName value:colorLowerOther range:lowerOtherRange];
    }
    
    NSMutableParagraphStyle   *paragraphStyle   = [[NSMutableParagraphStyle alloc] init];
    //行间距
    [paragraphStyle setLineSpacing:linespace];
    [noteString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];
    
    [self setAttributedText:noteString];
    
    [self sizeToFit];
    CGSize size = self.frame.size;
    size = CGSizeMake(ceil(size.width), ceil(size.height));
    return size;
}

-(CGSize)setAttributeText:(NSString*)text
                     font:(UIFont*)fontText
                    color:(UIColor*)color
          withAttributeRange:(NSRange)firstRange
                  andFont:(UIFont*)firstFont
                 andColor:(UIColor*)firstColor
     withOtherAttributeRange:(NSRange)lastRange
                  andFont:(UIFont*)lastFont
                 andColor:(UIColor*)lastColor
             andLinespace:(CGFloat)linespace{
    
    self.textColor = color;
    self.font = fontText;
    self.text = text;
    if (!text) {
        return CGSizeZero;
    }
    NSMutableAttributedString *noteString = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange totalRange = [text rangeOfString:text];
    [noteString addAttribute:NSFontAttributeName value:fontText range:totalRange];
    [noteString addAttribute:NSForegroundColorAttributeName value:color range:totalRange];
    
    [noteString addAttribute:NSFontAttributeName value:firstFont range:firstRange];
    [noteString addAttribute:NSForegroundColorAttributeName value:firstColor range:firstRange];
 
    [noteString addAttribute:NSFontAttributeName value:lastFont range:lastRange];
    [noteString addAttribute:NSForegroundColorAttributeName value:lastColor range:lastRange];
    
    NSMutableParagraphStyle   *paragraphStyle   = [[NSMutableParagraphStyle alloc] init];
    //行间距
    [paragraphStyle setLineSpacing:linespace];
    [noteString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];
    
    [self setAttributedText:noteString];
    
    [self sizeToFit];
    CGSize size = self.frame.size;
    size = CGSizeMake(ceil(size.width), ceil(size.height));
    return size;
}

@end
