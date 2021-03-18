//
//  CoverView.h
//  JTime
//
//  Created by Even on 2017/3/6.
//  Copyright © 2017年 Cube. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CloseCoverViewBlock)(void);
typedef void(^PopCoverViewBlock)(void);

@interface TM_CoverView : UIView

//渐变效果(默认0.65,默认渐变时间0.35s)
@property (nonatomic, assign) CGFloat animationAlpha;

/*
 view : 放在背景上的弹框
 block: 移除coverview的回调
 */
-(void)coverWithView:(UIView*)view andCloseBlock:(CloseCoverViewBlock)block;

/*
 view : 替换弹框,背景不变
 */
-(void)coverWithOtherView:(UIView*)view;


/**
 自定义前景view的弹出动画

 @param view 前景view
 @param popCoverViewBlock 添加方式
 @param closeCoverViewBlock 移除方式
 */
-(void)coverWithView:(UIView*)view andPopCoverViewBlock:(PopCoverViewBlock)popCoverViewBlock andCloseBlock:(CloseCoverViewBlock)closeCoverViewBlock;

-(void)removeCover;

//禁用手势
-(void)disEnabledTouch;

@end
