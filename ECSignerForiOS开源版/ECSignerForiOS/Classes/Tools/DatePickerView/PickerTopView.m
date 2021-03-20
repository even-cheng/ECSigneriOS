//
//  PickerTopView.m
//  JTime
//
//  Created by Even on 2017/3/17.
//  Copyright © 2017年 Cube. All rights reserved.
//

#import "PickerTopView.h"
#import "ECConst.h"

@interface PickerTopView ()

@property (nonatomic, copy) pickTopViewSureBlock sureBlock;
@property (nonatomic, copy) pickTopViewCancelBlock cancelBlock;

@end

@implementation PickerTopView

- (instancetype)initWithFrame:(CGRect)frame pickViewCancelBlock:(pickTopViewCancelBlock)cancel pickViewSureBlock:(pickTopViewSureBlock)sure {
    if (self = [super initWithFrame:frame]) {
        
        self.sureBlock = sure;
        self.cancelBlock = cancel;
        [self configureUI];
    }
    return self;
}

- (void)cancelAction:(UIButton *)sender {
    
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (void)sureAction:(UIButton *)sender {
    
    if (self.sureBlock) {
        self.sureBlock();
    }
}
 
- (void)configureUI{
    
        self.titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = HexColor(@"#333333");
        [self addSubview:_titleLabel];

        UIButton *sender = [[UIButton alloc]initWithFrame:CGRectMake(20, 0, 44, 44)];
        _cancelButton = sender;
        [self addSubview:sender];
        [sender setTitle:@"取消" forState:UIControlStateNormal];
        [sender setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        sender.titleLabel.font = [UIFont systemFontOfSize:15];
        [sender addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *sure = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 20 - 44, 0, 44, 44)];
        _confirmButton = sure;
        [self addSubview:sure];
        [sure setTitle:@"确定" forState:UIControlStateNormal];
        [sure setTitleColor:MAIN_COLOR forState:UIControlStateNormal];
        sure.titleLabel.font = [UIFont systemFontOfSize:15];
        [sure addTarget:self action:@selector(sureAction:) forControlEvents:UIControlEventTouchUpInside];
}

@end
