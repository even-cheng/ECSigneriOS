//
//  UIView+Extension.m
//
//  Created by apple on 14-10-7.
//  Copyright (c) 2014年. All rights reserved.
//

#import "UIView+Extension.h"

@implementation UIView (Extension)

- (void)setX:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void)setY:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)x
{
    return self.frame.origin.x;
}

- (CGFloat)y
{
    return self.frame.origin.y;
}

- (void)setCenterX:(CGFloat)centerX
{
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}

- (CGFloat)centerX
{
    return self.center.x;
}

- (void)setCenterY:(CGFloat)centerY
{
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

- (CGFloat)centerY
{
    return self.center.y;
}

- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (CGFloat)width
{
    return self.frame.size.width;
}

- (void)setSize:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGSize)size
{
    return self.frame.size;
}

- (void)setOrigin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGPoint)origin
{
    return self.frame.origin;
}
-(CGFloat)right{
    
    return CGRectGetMaxX(self.frame);
    
}

-(void)setRight:(CGFloat)right{
    CGRect  frame=self.frame;
    
    frame.origin.x=right-self.frame.size.width;
    
    self.frame=frame;
    
}

-(CGFloat)bottom{
    
    return CGRectGetMaxY(self.frame);
}

-(void)setBottom:(CGFloat)bottom{
    CGRect frame=self.frame;
    
    frame.origin.y=bottom-self.frame.size.height;
    
    self.frame=frame;
    
}
-(void)setTop:(CGFloat)top{
    self.y=top;
    
}

-(CGFloat)top{
    
    return self.y;
}

-(void)setLeft:(CGFloat)left{
    
    self.x=left;
    
    
    
}
-(CGFloat)left{
    
    return self.x;
}
@end
