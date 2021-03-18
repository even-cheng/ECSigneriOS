//
//  ECMainTabbarController.m
//  ECSignerForiOS
//
//  Created by even on 2020/9/7.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECMainTabbarController.h"
#import "ECSignHomeController.h"
#import "ECFileManageController.h"
#import "ECSettingController.h"
#import "ECConst.h"

@interface ECMainTabbarController ()

@end

@implementation ECMainTabbarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setup];
}

- (void)setup{
    
    ECSignHomeController *homeCtrl = [ECSignHomeController new];
    ECFileManageController *hallCtrl = [ECFileManageController new];
    ECSettingController *profileCtrl = [ECSettingController new];
    
    [self addChildViewController:homeCtrl imageName:@"tab_sign" title:@"签名"];
    [self addChildViewController:hallCtrl imageName:@"tab_file" title:@"文件"];
    [self addChildViewController:profileCtrl imageName:@"tab_setting" title:@"设置"];
    
    [[UITabBar appearance] setShadowImage:[UIImage new]];
    [[UITabBar appearance] setBackgroundColor:UIColor.whiteColor];
    [[UITabBar appearance] setTranslucent:NO];
    [[UITabBar appearance] setTintColor:MAIN_COLOR];
}

//添加子控制器,设置标题与图片
- (void)addChildViewController:(UIViewController *)childCtrl imageName:(NSString *)imageName title:(NSString *)title{
    
    childCtrl.tabBarItem.image = [UIImage imageNamed:imageName];
    childCtrl.tabBarItem.selectedImage = [UIImage imageNamed:imageName];

    //设置标题
    childCtrl.title = title;
    
    //指定一下属性
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    //指定字体
    dic[NSFontAttributeName] = [UIFont systemFontOfSize:12];
    //指定选中状态下文字颜色
    dic[NSForegroundColorAttributeName] = MAIN_COLOR;
    
    [childCtrl.tabBarItem setTitleTextAttributes:dic forState:UIControlStateSelected];
    
    UINavigationController *navCtrl = [[UINavigationController alloc] initWithRootViewController:childCtrl];
    navCtrl.navigationBar.tintColor = UIColor.darkGrayColor;
    navCtrl.navigationBar.shadowImage = [UIImage new];
    [self addChildViewController:navCtrl];
}

@end
