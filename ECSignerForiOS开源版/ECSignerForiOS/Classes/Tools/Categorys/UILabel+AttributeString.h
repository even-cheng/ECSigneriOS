
//
//  UILabel+AttributeString.h
//  jishijian
//
//  Created by Even on 2017/8/31.
//  Copyright © 2017年 JiShiJian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (AttributeString)

- (void)setText:(NSString* _Nonnull)text
           font:(UIFont* _Nonnull)font
          color:(UIColor* _Nonnull)color;

- (CGSize)setAttributeText:(NSString* _Nonnull)text
                      font:(UIFont* _Nonnull)font
                     color:(UIColor* _Nonnull)color
                 linespace:(CGFloat)linespace;

- (CGSize)setAttributeText:(NSString* _Nonnull)text
                    font:(UIFont* _Nonnull)fontText
                   color:(UIColor* _Nonnull)color
         withLowerString:(NSString* _Nullable)lowerString
                 andFont:(UIFont* _Nullable)fontLower
                andColor:(UIColor* _Nullable)colorLower
    withLowerOtherString:(NSString* _Nullable)lowerOtherString
                 andFont:(UIFont* _Nullable)fontLowerOther
                andColor:(UIColor* _Nullable)colorLowerOther
            andLinespace:(CGFloat)linespace;

-(CGSize)setAttributeText:(NSString*)text
                     font:(UIFont*)fontText
                    color:(UIColor*)color
       withAttributeRange:(NSRange)firstRange
                  andFont:(UIFont*)firstFont
                 andColor:(UIColor*)firstColor
  withOtherAttributeRange:(NSRange)lastRange
                  andFont:(UIFont*)lastFont
                 andColor:(UIColor*)lastColor
             andLinespace:(CGFloat)linespace;
@end
