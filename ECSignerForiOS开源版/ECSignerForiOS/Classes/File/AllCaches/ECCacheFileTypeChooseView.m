//
//  ECCacheFileTypeChooseView.m
//  ECSignerForiOS
//
//  Created by 快游 on 2020/11/6.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECCacheFileTypeChooseView.h"
#import "ECConst.h"

@implementation ECCacheFileTypeChooseView

- (instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews{
    
    self.fileTypes = @[@"证书", @"描述文件", @"动态库", @"原包", @"已签名包", @"压缩文件", @"下载文件", @"P8文件", @"安装分享文件"];
    NSInteger countOfLine = 3;
    CGFloat margin = 15;
    CGFloat height = 44;
    CGFloat width = (self.width-(countOfLine+1)*margin)/countOfLine;
    
    for (int i = 0; i < self.fileTypes.count; i ++) {
        
        NSInteger hang = i / countOfLine;
        NSInteger lie = i % countOfLine;
        
        UIButton* typeButton = [[UIButton alloc]initWithFrame:CGRectMake(margin+lie*(width+margin), margin+hang*(height+margin), width, height)];
        typeButton.tag = i;
        [typeButton addTarget:self action:@selector(chooseTypeAction:) forControlEvents:UIControlEventTouchUpInside];
        [typeButton setTitle:self.fileTypes[i] forState:UIControlStateNormal];
        [typeButton setTitleColor:UIColor.darkGrayColor forState:UIControlStateNormal];
        typeButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [typeButton setBackgroundColor:BG_COLOR];
        typeButton.layer.cornerRadius = 5;
        [self addSubview:typeButton];
    }
}

- (void)chooseTypeAction:(UIButton *)sender{
    self.chooseBlock?self.chooseBlock(sender.tag):nil;
}

@end
