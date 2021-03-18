   //
//  KP_BaseWebView.m
//  YouXiSDK
//
//  Created by 快游 on 2019/11/9.
//  Copyright © 2019 zhengcong. All rights reserved.
//

#import "KP_BaseWebView.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <Masonry/Masonry.h>
#import "UIWindow+Current.h"
#import "ECConst.h"
#import "ECAlertView.h"

@interface KP_BaseWebView()<WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler>

//加载进度
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, assign) CGFloat delayTime;

@property (strong, nonatomic) WKWebView *webView;

//jS调用原生方法
@property (strong, nonatomic) NSArray *methodList;

//回调JS的方法
@property (nonatomic, strong) NSArray <NSString *>*scriptMsgNameArray;

@end

@implementation KP_BaseWebView

//注册方法列表
- (void)resignMethodList{
    
    for (NSString* methodName in self.methodList) {
        
        [self.webView.configuration.userContentController addScriptMessageHandler:self name:methodName];
    }
}
//注销方法列表
- (void)releaseMethodList{
    for (NSString* methodName in self.methodList) {
        
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:methodName];
    }
}

-(instancetype)init{
    
    if (self = [super init]) {
        
        [self setup];
    }
    
    return self;
}

- (void)setup{
    
    self.methodList = @[@"close",@"copy"];
    [self initWebView];
    //js交互
    [self.scriptMsgNameArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self.webView.configuration.userContentController addScriptMessageHandler:self name:obj];
    }];
    
    [self resignMethodList];
}

- (void)loadUrl:(NSString*)web_url;{
    if (!web_url || web_url.length == 0) {
        return;
    }
    if ([web_url containsString:@".ipa?"]){
        if ([self includeChinese:web_url]) {
            web_url = [self URLDecodedStringWithStr:web_url];
        }
        [self downloadIpa:web_url];
        return;
    }
    web_url = [self URLDecodedStringWithStr:web_url];
    NSURL* url = [NSURL URLWithString:web_url];
    if (!url) {
        return;
    }
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    [self.webView loadRequest:request];
}

- (void)loadHTML:(NSString*)html;{

    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)reload{
    [self.webView reloadFromOrigin];
}

- (void)initWebView{
    
    [self addSubview:self.webView];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self addSubview:self.progressView];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.webView);
        make.top.equalTo(self.webView).offset(5);
        make.height.mas_offset(2);
    }];
    
    // KVO 监听属性，除了下面列举的两个，还有其他的一些属性，具体参考 WKWebView 的头文件
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeFromSuperview{
    
    //关闭交互
    [self.scriptMsgNameArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:obj];
    }];
    
    [self releaseMethodList];
    [super removeFromSuperview];
}

//监听JS调用本地方法
- (void)contentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSString* methodName = message.name;
    if ([methodName isEqualToString:@"close"]) {

        self.dismissWebBlock?self.dismissWebBlock(nil):nil;
        
    } else if ([methodName isEqualToString:@"copy"]) {
        
        NSDictionary* params = message.body;
        [self copyAction:params[@"content"]];

    }
}

#pragma mark 本地方法列表
- (void)copyAction:(NSString*)content{
    
}

//处理请求头
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSURL* url = [navigationAction.request URL];
    NSString *urlString = url.absoluteString;
    
    if ([urlString containsString:@"//itunes.apple.com/"] || [urlString hasPrefix:@"weixin://"] || [urlString hasPrefix:@"alipay://"] || [urlString hasPrefix:@"alipays://"]){
        [[UIApplication sharedApplication]openURL:navigationAction.request.URL];

        decisionHandler(WKNavigationActionPolicyCancel);
        self.dismissWebBlock?self.dismissWebBlock(nil):nil;
        
    } else if ([urlString hasSuffix:@".plist"]){
        
        decisionHandler(WKNavigationActionPolicyCancel);
        [self analyzedPlist:urlString];
        
    } else if ([urlString hasSuffix:@".ipa"]) {
        
        decisionHandler(WKNavigationActionPolicyCancel);
        [self downloadIpa:urlString];
        
    } else if ([urlString hasPrefix:@"itms-services://"]) {
        
        decisionHandler(WKNavigationActionPolicyCancel);
        [self analyzedPlist:urlString];
        
    } else {
        
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)analyzedPlist:(NSString *)plistUrl{

    plistUrl = [self URLDecodedStringWithStr:plistUrl];
    if ([plistUrl hasPrefix:@"itms-services://"]) {
        plistUrl = [plistUrl componentsSeparatedByString:@"url="].lastObject;
    }
    NSDictionary* dic = [[NSDictionary alloc]initWithContentsOfURL:[NSURL URLWithString:plistUrl]];
    NSArray* items = [dic objectForKey:@"items"];
    NSArray* assets = [items.firstObject objectForKey:@"assets"];
    NSString* ipaUrl;
    for (NSDictionary* asset in assets) {
        if ([[asset objectForKey:@"kind"] isEqualToString: @"software-package"]) {
            ipaUrl = [asset objectForKey:@"url"];
        }
    }
    
    if (ipaUrl) {
        [self downloadIpa:ipaUrl];
    }
}

- (void)downloadIpa:(NSString *)ipaUrl {
    
    self.dismissWebBlock?self.dismissWebBlock(ipaUrl):nil;
}

// 设置请求头
- (BOOL)addRequestHeader:(NSMutableURLRequest*)request{
    
//    [request setValue:[TM_Tools currentUDID]?:@"" forHTTPHeaderField:@"UDID"];
//    [request setValue:[TM_Tools currentChannel]?:@"10000" forHTTPHeaderField:@"CHANNEL"];

    return YES;
}

#pragma mark- WKUIDelegate,WKNavigationDelegate
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"页面加载完成");
}

// 在代理方法中处理对应事件
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSLog(@"%@----%@",message.name,message.body);
    [self contentController:userContentController didReceiveScriptMessage:message];
}

//弹框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }])];
    [[UIWindow currentViewController] presentViewController:alertController animated:YES completion:nil];
    completionHandler();
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler;{    //    DLOG(@"msg = %@ frmae = %@",message,frame);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [[UIWindow currentViewController] presentViewController:alertController animated:YES completion:nil];
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    WKFrameInfo *frameInfo = navigationAction.targetFrame;
    if (![frameInfo isMainFrame]) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation;{
    
    [ECAlertView alertMessageUnderNavigationBar:@"加载失败,请刷新重试" subTitle:nil type:TSMessageNotificationTypeWarning];
//    [self backWeb];
}
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;{

    [ECAlertView alertMessageUnderNavigationBar:@"加载失败,请刷新重试" subTitle:nil type:TSMessageNotificationTypeWarning];
//    [self backWeb];
}

-(void)back{
    [self backWeb];
}

- (BOOL)canBack;{
    return [self.webView canGoBack];
}

- (void)backWeb{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
        if (self.webView.estimatedProgress < 1.0) {
            self.delayTime = 1 - self.webView.estimatedProgress;
            return;
        } else if (self.webView.estimatedProgress == 1.0) {
            if (!self.webView.title.length && !self.webView.loading) {
                NSLog(@"404");
                [ECAlertView alertMessageUnderNavigationBar:@"网页加载失败，请刷新重试" subTitle:nil type:TSMessageNotificationTypeError];
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.progressView.progress = 0;
        });
    } else if ([keyPath isEqualToString:@"title"]) {
        
        NSLog(@"%@",self.webView.title);
    }
}

//解码
- (NSString *)URLDecodedStringWithStr:(NSString*)str
{
    NSString *result = str;
    if ([self includeChinese:str]) {
        
        result = [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    } else {
        
        result = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                                                 (CFStringRef)str,
                                                                                                                 CFSTR(""),
                                                                                                                 kCFStringEncodingUTF8));
    }

    
    return result;
}

- (BOOL)includeChinese:(NSString *)content
{
    for(int i=0; i< [content length];i++)
    {
        int a =[content characterAtIndex:i];
        if( a >0x4e00 && a <0x9fff){
            return YES;
        }
    }
    return NO;
}

#pragma mark -- 懒加载
- (WKWebView *)webView {
    if (!_webView) {
        
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        //        WKPreferences *preferences = [WKPreferences new];
        //        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        //        preferences.minimumFontSize = 14.0;
        //        configuration.preferences = preferences;
        // 支持内嵌视频播放，不然网页中的视频无法播放
        configuration.allowsInlineMediaPlayback = YES;
        _webView = [[WKWebView alloc]initWithFrame:CGRectZero configuration:configuration];
        _webView.scrollView.bounces = NO;
        _webView.scrollView.showsVerticalScrollIndicator = NO;
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
    }
    return _webView;
}

- (UIProgressView *)progressView {
    if(!_progressView) {
        
        _progressView = [[UIProgressView alloc]initWithFrame:CGRectZero];
        _progressView.progressTintColor = [UIColor greenColor];
        _progressView.trackTintColor = [UIColor clearColor];
    }
    return _progressView;
}


@end
