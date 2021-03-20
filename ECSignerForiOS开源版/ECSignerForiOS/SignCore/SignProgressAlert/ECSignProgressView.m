//
//  ECSignProgressView.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/11.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECSignProgressView.h"
#import "LXWaveProgressView.h"
#import "ECConst.h"

@interface ECSignProgressView()

@property (nonatomic, strong) LXWaveProgressView *progressView;

@end

@implementation ECSignProgressView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.progressView];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress{
    _progress = progress;
    
    self.progressView.progress = progress;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    
    self.progressView.waveHeight = 10;
    self.progressView.speed = 1;
    self.progressView.progressLabel.text = title;
}

- (LXWaveProgressView *)progressView{
    
    if (!_progressView) {
        
        _progressView = [[LXWaveProgressView alloc]initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        _progressView.progress = 0.1;
        _progressView.waveHeight = 3;
        _progressView.speed = 0.5;
        _progressView.progressLabel.text = @"签名中...";
        _progressView.progressLabel.font = [UIFont boldSystemFontOfSize:15];
        _progressView.firstWaveColor = [UIColor colorWithRed:134/255.0 green:116/255.0 blue:210/255.0 alpha:1];
        _progressView.secondWaveColor = [UIColor colorWithRed:90/255.0 green:167/255.0 blue:255/255.0 alpha:0.5];
    }
    
    return _progressView;
}


@end
