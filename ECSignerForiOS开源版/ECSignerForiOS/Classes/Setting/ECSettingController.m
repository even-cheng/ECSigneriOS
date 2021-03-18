//
//  ECSettingController.m
//  ECSignerForiOS
//
//  Created by even on 2020/9/7.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECSettingController.h"
#import "ECConst.h"
#import "ECAlertView.h"
#import "ECFileManager.h"
#import "LCManager.h"
#import "ECConst.h"
#import "NSDate+HandleDate.h"
#import "ECAlertController.h"
#import "ECAboutDeveloperController.h"
#import "ECQuestionViewController.h"
#import "ECSignProgressView.h"
#import <Masonry/Masonry.h>
#import "ECSignSettingController.h"
#import "LCAccountChooseView.h"
#import "LCAddAccountView.h"

@interface ECSettingController ()

@property (nonatomic, strong) ECSignProgressView *signProgressView;

@property (weak, nonatomic) IBOutlet UIButton *cacheButton;
@property (weak, nonatomic) IBOutlet UILabel *udidLabel;
@property (weak, nonatomic) IBOutlet UIButton *udidButton;
@property (weak, nonatomic) IBOutlet UILabel *serverLabel;

@property (nonatomic, copy) NSString* totalCacheSize;

@end

@implementation ECSettingController

-(instancetype)init{
    
    if (self = [super init]) {
        self =[[UIStoryboard storyboardWithName:@"ECSettingController" bundle:nil]instantiateViewControllerWithIdentifier:@"ECSettingController"];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self reloadWithCurrentAccount];
    [self loadCaches];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView* bgImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon"]];
    bgImg.userInteractionEnabled = YES;
    bgImg.alpha = 0.1;
    [self.view insertSubview:bgImg atIndex:0];
    [bgImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    if (!isiPhone) {
        self.udidLabel.text = @"设备识别码";
    }

    [[NSNotificationCenter defaultCenter] addObserverForName:@"ECSigner_GetUDID" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        
        NSString* udid = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecsigner_udid"];
        [self.udidButton setTitle:udid forState:UIControlStateNormal];
    }];
}

- (void)loadCaches{
 
    dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                   , ^{
        float tmpCache = [self folderSizeAtPath:[ECFileManager sharedManager].tmpPath];
        float unzipCache = [self folderSizeAtPath:[ECFileManager sharedManager].unzipPath];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.totalCacheSize = [NSString stringWithFormat:@"%.2fM",tmpCache+unzipCache];
            [self.cacheButton setTitle:self.totalCacheSize forState:UIControlStateNormal];
        });
    });
}


//遍历文件夹获得文件夹大小，返回多少M
- (float)folderSizeAtPath:(NSString *)cachPath{

    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:cachPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:cachPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [cachPath stringByAppendingPathComponent:fileName];
        if ([fileName containsString:@"com.apple"]){
            continue;
        }
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/(1024.0*1024.0);
}

- (long long) fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

-(void)clearCacheSuccess
{
    [self loadCaches];
}

- (IBAction)cleanCache:(id)sender {
        
    self.signProgressView.progress = 1;
    self.signProgressView.title = @"正在清理...";
    ECAlertController* alert = [ECAlertController alertControllerWithTitle:nil message:nil preferredStyle:ECAlertControllerStyleAlert animationType:ECAlertAnimationTypeExpand customView:self.signProgressView];
    [alert setTapBackgroundViewDismiss:NO];
    [self presentViewController:alert animated:YES completion:nil];

    dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    , ^{
        [[ECFileManager sharedManager]removeAll: [ECFileManager sharedManager].tmpPath];
        [[ECFileManager sharedManager]removeAll: [ECFileManager sharedManager].unzipPath];

        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:^{
                [self clearCacheSuccess];
            }];
        });
    });
}


- (IBAction)signSetting:(id)sender {
    
    ECSignSettingController* setting = [ECSignSettingController new];
    [self.navigationController pushViewController:setting animated:YES];
}

- (IBAction)questionAction:(id)sender {
    
    ECQuestionViewController* questionVc = [ECQuestionViewController new];
    [self.navigationController pushViewController:questionVc animated:YES];
}

- (IBAction)rulesAction:(id)sender {
    ECQuestionViewController* questionVc = [ECQuestionViewController new];
    questionVc.showPrivacyRules = YES;
    [self.navigationController pushViewController:questionVc animated:YES];
}

- (IBAction)contactAction:(id)sender {
    ECAboutDeveloperController* dev = [ECAboutDeveloperController new];
    [self.navigationController pushViewController:dev animated:YES];
}

- (IBAction)installMobileConfig:(UIButton *)sender {
    
    NSString* udid = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecsigner_udid"];
    if (!udid) {
        
        [self configUDID];
        return;
    }
    
    
    ECAlertActionBlock copyUDID = ^{
        
        UIPasteboard* paste = [UIPasteboard generalPasteboard];
        paste.string = udid;
        [ECAlertView alertMessageUnderNavigationBar:@"设备号已复制" subTitle:@"" type:TSMessageNotificationTypeSuccess];
    };

    ECAlertActionBlock config = ^{
        [self configUDID];
    };
    
    NSArray* sortArray = @[
        @{@"name":@"复制", @"action":copyUDID},
        @{@"name":@"重新获取", @"action":config},
    ];
    
    UIAlertController* alert = [ECAlertView alertWithTitle:@"选择操作" message:nil actions:sortArray];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)configUDID{
    
    NSString* config = [[NSBundle mainBundle] pathForResource:@"getudid" ofType:@"mobileconfig"];
    NSString* installConfig = [[ECFileManager sharedManager].installPath stringByAppendingPathComponent:config.lastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:installConfig]) {
        BOOL res = [[NSFileManager defaultManager] copyItemAtPath:config toPath:installConfig error:nil];
        if (!res) {
            [ECAlertView alertMessageUnderNavigationBar:@"获取UDID失败" subTitle:nil type:TSMessageNotificationTypeError];
            return;
        }
    }
    
    NSURL* configUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:13140/%@", config.lastPathComponent]];
    if ([[UIApplication sharedApplication] openURL:configUrl]) {
        [ECAlertView alertMessageUnderNavigationBar:@"正在安装配置文件，请前往系统设置查看" subTitle:@"" type:TSMessageNotificationTypeMessage];
    } else {
        [ECAlertView alertMessageUnderNavigationBar:@"配置文件安装失败" subTitle:@"请检查leancloud配置是否正常" type:TSMessageNotificationTypeError];
    }
}

- (ECSignProgressView *)signProgressView{
    if (!_signProgressView) {
        _signProgressView = [[ECSignProgressView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    }
    return _signProgressView;
}

- (IBAction)serverSetting:(id)sender {
    [self clickServerButtonAction];
}

- (void)clickServerButtonAction{

    if ([LCManager sharedManager].accounts.count == 0) {
        [self addLeanAccount:nil withEdit:NO];
    } else {

        LCAccountChooseView* chooseView = [[LCAccountChooseView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH-60, 290) accounts:[LCManager sharedManager].accounts currentAccount:[LCManager sharedManager].current_account.appID];

        ECAlertController* alertVc = [ECAlertController alertControllerWithTitle:nil message:nil preferredStyle:ECAlertControllerStyleAlert animationType:ECAlertAnimationTypeExpand customView:chooseView];
        [self presentViewController:alertVc animated:YES completion:nil];

        chooseView.chooseAccount = ^(LCAccount* account) {

            [[LCManager sharedManager] switchToAccount:account.appID];
            [alertVc dismissViewControllerAnimated:YES completion:nil];
            [self reloadWithCurrentAccount];
        };

        chooseView.addAccount = ^{

            [alertVc dismissViewControllerAnimated:NO completion:^{
                [self addLeanAccount:nil withEdit:NO];
            }];
        };

        chooseView.editAccount = ^(LCAccount* account, BOOL is_delete) {

            [alertVc dismissViewControllerAnimated:NO completion:^{

                if (is_delete) {
                    [[LCManager sharedManager] removeAccount:account.appID];
                    [self reloadWithCurrentAccount];
                } else {
                    [self addLeanAccount:account withEdit:YES];
                }
            }];
        };
    }
}

- (void)addLeanAccount:(LCAccount *_Nullable)account withEdit:(BOOL)edit{

    LCAddAccountView* addView = [LCAddAccountView addView];
    addView.account = account;
    addView.frame = CGRectMake(0, 0, SCREEN_WIDTH-60, 290);

    ECAlertController* alertVc = [ECAlertController alertControllerWithTitle:nil message:nil preferredStyle:ECAlertControllerStyleAlert animationType:ECAlertAnimationTypeExpand customView:addView];
    [self presentViewController:alertVc animated:YES completion:nil];

    addView.confirmBlock = ^(NSString * _Nonnull name, NSString * _Nonnull appid, NSString * _Nonnull appkey, NSString * _Nonnull appurl) {

        [[LCManager sharedManager] cacheAccountWithName:name andAppID:appid andAppKey:appkey andServerUrl:appurl];
        [self reloadWithCurrentAccount];
        [alertVc dismissViewControllerAnimated:YES completion:nil];
    };
}

- (void)reloadWithCurrentAccount{
    self.serverLabel.text = [LCManager sharedManager].current_account.name?:@"未设置";
}

@end
