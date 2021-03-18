//
//  UINavigationController+TM_HiddenShadow.m
//  Petpet
//
//  Created by Even on 2018/11/14.
//  Copyright © 2018年 Even-Cheng. All rights reserved.
//

#import "UINavigationController+TM_HiddenShadow.h"
#import "SwizzlingDefine.h"
#import "ECConst.h"
#import "UIWindow+Current.h"

@implementation UINavigationController (TM_HiddenShadow)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzling_exchangeMethod(self, @selector(viewWillAppear:), @selector(TM_viewWillAppear:));
        swizzling_exchangeMethod(self, @selector(pushViewController:animated:), @selector(TM_pushViewController:animated:));
    });
}

- (void)TM_viewWillAppear:(BOOL)animated{
    [self TM_viewWillAppear:animated];

    [self.navigationBar setTitleTextAttributes:
     @{NSFontAttributeName:[UIFont systemFontOfSize:16.0f],
       NSForegroundColorAttributeName:[UIColor colorWithHexString:@"#333333"]}];
    [self.navigationBar setBarTintColor:[UIColor whiteColor]];
}

- (void)back{
    [self popViewControllerAnimated:YES];
}

- (void)TM_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIViewController* currentVc = [UIWindow currentViewController];
    if (currentVc == viewController) {
        return;
    }
    if (self.childViewControllers.count > 0) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    [self TM_pushViewController:viewController animated:animated];
}

@end
