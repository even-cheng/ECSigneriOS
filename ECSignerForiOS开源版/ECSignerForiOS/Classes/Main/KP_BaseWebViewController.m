//
//  KP_BaseWebViewController.m
//  YouXiSDK
//
//  Created by 快游 on 2020/10/14.
//  Copyright © 2020 zhengcong. All rights reserved.
//

#import "KP_BaseWebViewController.h"
#import "ECConst.h"
#import <Masonry/Masonry.h>
#import "ECAlertView.h"

@interface KP_BaseWebViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) KP_BaseWebView *webView;
@property (nonatomic, weak) UITextField *addressField;

@end

@implementation KP_BaseWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reload"] style:UIBarButtonItemStylePlain target:self action:@selector(reload)];

    // Do any additional setup after loading the view.
    KP_BaseWebView *webView = [[KP_BaseWebView alloc]init];
    _webView = webView;
    webView.dismissWebBlock = ^(NSString * _Nullable ipaUrl){
        [self closeAction:ipaUrl];
    };
    [self.view addSubview:webView];
    [webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self.view);
        make.top.equalTo(self.view).offset(NAV_HEIGHT);
    }];
    
    UITextField* addressField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH-100, 35)];
    _addressField = addressField;
    addressField.layer.cornerRadius = 5;
    addressField.backgroundColor = BG_COLOR;
    addressField.font = [UIFont systemFontOfSize:12];
    addressField.textColor = UIColor.darkGrayColor;
    addressField.placeholder = @" 请输入链接地址";
    addressField.returnKeyType = UIReturnKeyGo;
    addressField.delegate = self;
    self.navigationItem.titleView = addressField;

    if (self.url) {
        [self.webView loadUrl:self.url];
        [[NSUserDefaults standardUserDefaults] setObject:self.url forKey:@"ecsign_last_loadurl"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (self.html) {
        [self.webView loadHTML:self.html];
    } else {
        self.url = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecsign_last_loadurl"];
        self.addressField.text = self.url;
        [self.webView loadUrl:self.url];
    }
}

- (void)reload{
    [self.webView reload];
}

- (void)back{
    if ([self.webView canBack]) {
        [self.webView backWeb];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;{
    
    [textField resignFirstResponder];
    [self openWebUrl];
    return YES;
}

- (void)openWebUrl{
    
    NSString* url = self.addressField.text;
    if (![url hasPrefix:@"http"]) {
        url = [@"http://" stringByAppendingString:url];
    }
    [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"ecsign_last_loadurl"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.webView loadUrl:url];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)closeAction:(NSString* _Nullable)url{
    
    UIAlertController* alert = [ECAlertView alertWithTitle:@"检测到下载地址，是否立即下载？" message:nil cancelBlock:nil confirmBlock:^{
        
        self.dismissWebBlock?self.dismissWebBlock(url):nil;
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
