//
//  KP_BaseWebViewController.h
//  YouXiSDK
//
//  Created by Even on 2020/10/14.
//  Copyright © 2020 zhengcong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KP_BaseWebView.h"
NS_ASSUME_NONNULL_BEGIN

@interface KP_BaseWebViewController : UIViewController

@property (nonatomic, copy) DidDismissWebBlock dismissWebBlock;//关闭webView的回调

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *html;

@property (nonatomic, assign) BOOL hiddenCloseButton;

@end

NS_ASSUME_NONNULL_END
