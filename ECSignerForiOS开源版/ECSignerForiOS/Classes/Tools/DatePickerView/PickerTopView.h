//
//  PickerTopView.h
//  JTime
//
//  Created by Even on 2017/3/17.
//  Copyright © 2017年 Cube. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^pickTopViewCancelBlock)(void);
typedef void(^pickTopViewSureBlock)(void);

@interface PickerTopView : UIView

- (instancetype)initWithFrame:(CGRect)frame pickViewCancelBlock:(pickTopViewCancelBlock )cancel pickViewSureBlock:(pickTopViewSureBlock )sure;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, weak) UIButton *cancelButton;
@property (nonatomic, weak) UIButton *confirmButton;


@end
