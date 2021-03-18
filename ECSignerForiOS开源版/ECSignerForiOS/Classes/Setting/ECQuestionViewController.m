//
//  ECQuestionViewController.m
//  ECSignerForiOS
//
//  Created by 快游 on 2020/9/28.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECQuestionViewController.h"
#import "ECFileQuestionView.h"

@interface ECQuestionViewController ()

@end

@implementation ECQuestionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.whiteColor;
    
    if (self.showPrivacyRules) {
        
        self.title = @"服务与隐私协议";
        UITextView* textView = [[UITextView alloc]initWithFrame:self.view.bounds];
        textView.text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"privacy" ofType:@"txt"] encoding:4 error:nil];
        [self.view addSubview:textView];
        
    } else {
        
        self.title = @"常见问题";
        ECFileQuestionView* questionView = [[ECFileQuestionView alloc]initWithFrame:self.view.bounds];
        [self.view addSubview:questionView];
    }
}


@end
