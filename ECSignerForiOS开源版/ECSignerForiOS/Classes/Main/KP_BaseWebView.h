//
//  KP_BaseWebView.h
//  YouXiSDK
//
//  Created by Even on 2019/11/9.
//  Copyright © 2019 zhengcong. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^DidDismissWebBlock)(NSString * _Nullable downloadUrl);

@interface KP_BaseWebView : UIView

- (void)loadUrl:(NSString*)web_url;
- (void)loadHTML:(NSString*)html;
- (BOOL)canBack;
- (void)backWeb;
- (void)reload;

@property (nonatomic, copy) DidDismissWebBlock dismissWebBlock;//关闭webView的回调

@end

NS_ASSUME_NONNULL_END
