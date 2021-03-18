//
//  CoverView.m
//  JTime
//
//  Created by Even on 2017/3/6.
//  Copyright © 2017年 Cube. All rights reserved.
//

#import "TM_CoverView.h"
#import "ECConst.h"

@interface TM_CoverView ()<UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *receiveView;
@property (nonatomic, copy) CloseCoverViewBlock closeBlock;
@property (nonatomic, weak) UITapGestureRecognizer *tapCoverViewGest;

@end

@implementation TM_CoverView


#pragma mark- --点击手势代理，为了去除手势冲突--
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if([touch.view isDescendantOfView:self.receiveView]){
        return NO;
    }
    return YES;
}

-(instancetype)initWithFrame:(CGRect)frame{

    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        self.animationAlpha = 0.65;
        UITapGestureRecognizer* tapCoverViewGest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeCoverView)];
        tapCoverViewGest.delegate = self;
        [self addGestureRecognizer:tapCoverViewGest];
        self.tapCoverViewGest = tapCoverViewGest;
    }
    
    return self;
}

//禁用手势
-(void)disEnabledTouch;{

    self.tapCoverViewGest.enabled = NO;
}

//关闭筛选
-(void)closeCoverView{
    
    TM_CoverView* cover = self;
    if (cover.closeBlock) {
        cover.closeBlock();
    }
    cover.backgroundColor = [UIColor colorWithWhite:0 alpha:self.animationAlpha];

    [UIView animateWithDuration:0.35 animations:^{
        
        cover.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        cover.alpha = 0;
        
    }  completion:^(BOOL finished) {
        
        cover.alpha = 1;
        for (UIView* vi in cover.subviews) {
            [vi removeFromSuperview];
        }
        [cover removeFromSuperview];
    }];
}

-(void)coverWithView:(UIView*)view andCloseBlock:(CloseCoverViewBlock)block;
{
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];

    self.closeBlock = block;
    [kWindow addSubview:self];
    if (view) {
    
        self.receiveView = view;
        [self addSubview:view];
    }
    [UIView animateWithDuration:0.35 animations:^{
        
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:self.animationAlpha];

    }];
}

/*
 view : 替换弹框,背景不变
 */
-(void)coverWithOtherView:(UIView*)view;{

    [self.receiveView removeFromSuperview];
    [self addSubview:view];
    self.receiveView = view;
    
}

-(void)coverWithView:(UIView*)view andPopCoverViewBlock:(PopCoverViewBlock)popCoverViewBlock andCloseBlock:(CloseCoverViewBlock)closeCoverViewBlock;
{
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    self.closeBlock = closeCoverViewBlock;
    [self addSubview:view];
    [kWindow addSubview:self];
    self.receiveView = view;

    if (popCoverViewBlock) {
        
        popCoverViewBlock();
    }
    
    [UIView animateWithDuration:0.35 animations:^{
        
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:self.animationAlpha];
    }];
}

-(void)removeCover;
{
    [self closeCoverView];
}

@end
