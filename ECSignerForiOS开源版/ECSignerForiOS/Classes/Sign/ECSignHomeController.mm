//
//  ECSignHomeController.m
//  ECSignerForiOS
//
//  Created by even on 2020/9/7.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECSignHomeController.h"
#import "SPButton.h"
#import "ECConst.h"
#import "DK_DatePicker.h"
#import "NSDate+HandleDate.h"
#import "ECFileManageController.h"
#import "ECCertificateDetailController.h"
#import <Masonry/Masonry.h>
#import "ecsign.h"
#import "ECFileManager.h"
#import "ECSignProgressView.h"
#import "ECAlertController.h"
#import "ECAlertView.h"
#import "LCManager.h"
#include <sys/stat.h>
#include <unistd.h>
#include <dlfcn.h>
#import "UIWindow+Current.h"
#import "MyObject.h"
#import "ECBundleInfoController.h"
#include "MyCPPClass.hpp"
#import "MyObject.h"

@interface ECSignHomeController ()

@property (nonatomic, weak) UISegmentedControl* segment;

@property (nonatomic, strong) ECSignProgressView *signProgressView;

@property (weak, nonatomic) IBOutlet SPButton *bundleSettingButton;

@property (weak, nonatomic) IBOutlet UIView *moreSettingView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *moreSettingViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *chooseProvView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chooseProvViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *cerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *cerLabel;
@property (weak, nonatomic) IBOutlet UILabel *provNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *provLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipaLabel;
@property (weak, nonatomic) IBOutlet UITextField *bundleIdField;
@property (weak, nonatomic) IBOutlet UITextField *bundleNameField;
@property (weak, nonatomic) IBOutlet UITextField *bundleVersionField;

@property (nonatomic, strong) ECCertificateFile *choosed_cer;
@property (nonatomic, strong) ECMobileProvisionFile *choosed_prov;
@property (nonatomic, strong) NSArray<ECFile *> *choosed_ipas;

@property (strong, nonatomic)  NSTimer *timer;
@property (nonatomic, assign) CGFloat timeStep;

@property (nonatomic, strong) NSMutableArray<ECApplicationFile *> *signd_success_ipas;

@property (nonatomic, strong) ECAlertController* alertController;

@end

@implementation ECSignHomeController

-(instancetype)init{
    if (self = [super init]) {
        self =[[UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil]instantiateViewControllerWithIdentifier:NSStringFromClass(self.class)];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImageView* bgImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon"]];
    bgImg.alpha = 0.1;
    bgImg.center = self.view.center;
    [self.view insertSubview:bgImg atIndex:0];
    [bgImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    self.signd_success_ipas = [NSMutableArray array];
        
    NSArray* segmentItems = @[@"证书签"];
    UISegmentedControl* segment = [[UISegmentedControl alloc]initWithItems:segmentItems];
    _segment = segment;
    segment.tintColor = UIColor.darkGrayColor;
    segment.selectedSegmentIndex = 0;
    [segment addTarget:self action:@selector(segmentChooseAction:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segment;

    self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithTarget:self action:@selector(startSignAction) title:@"开始签名" titleColor:[UIColor colorWithHexString:@"#00B066"] withBorder:NO];
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem itemWithTarget:self action:@selector(resetSignAction) title:@"重置" titleColor:[UIColor lightGrayColor] withBorder:NO];
  
    [self loadAndInputLastSignRecord];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    BOOL firstInstallPop = [[NSUserDefaults standardUserDefaults] boolForKey:@"ecsigner_first_install_pop"];
    if (!firstInstallPop) {
        
        NSString* rules = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"privacy" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
        [self popRules:rules];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ecsigner_first_install_pop"];
    }
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
    [[UIApplication sharedApplication] openURL:configUrl];
}

- (void)loadAndInputLastSignRecord{
    
    NSString* last_cer = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecsigner_lastSign_cer"];
    NSString* last_profile = [[NSUserDefaults standardUserDefaults] objectForKey:@"ecsigner_lastSign_prov"];
    NSString* cerPath = [[ECFileManager sharedManager] localPathForFile:last_cer resigned:NO];
    NSString* provPath = [[ECFileManager sharedManager] localPathForFile:last_profile resigned:NO];
    if (last_cer && last_profile && [[NSFileManager defaultManager] fileExistsAtPath:cerPath] && [[NSFileManager defaultManager] fileExistsAtPath:provPath]) {
        
        ECCertificateFile* p12 = [[ECFileManager sharedManager] getCertificateFileForPath:cerPath forceToUpdate:NO checkComplete:nil];
        ECMobileProvisionFile* prov = [[ECFileManager sharedManager] getMobileProvisionFileForPath:provPath];
        self.choosed_cer = p12;
        self.choosed_prov = prov;
        
        self.cerLabel.text = p12.file_name;
        self.provLabel.text = prov.file_name;
    }
}

- (void)segmentChooseAction:(UISegmentedControl *)sender{
    [self resetSignAction];
    
    switch (sender.selectedSegmentIndex) {
        case 0:
        {
            self.cerNameLabel.text = @"签名证书:";
            self.chooseProvViewHeightConstraint.constant = 50;
            [self updateConstraintsWithAnimationForView:self.chooseProvView completeAlpha:1];
            [self loadAndInputLastSignRecord];
        }
            break;
        default:
            break;
    }
}

- (void)popRules:(NSString *)rules{
    
    UIView* foot = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 50)];
    UIButton* confirmButton = [[UIButton alloc]initWithFrame:CGRectMake(15, 5, SCREEN_WIDTH*0.6-80-10, 40)];
    [confirmButton setTitle:@"已阅读并同意" forState:UIControlStateNormal];
    [confirmButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [confirmButton setBackgroundColor:MAIN_COLOR];
    confirmButton.layer.cornerRadius = 5;
    confirmButton.layer.masksToBounds = YES;
    [foot addSubview:confirmButton];
    [confirmButton addTarget:self action:@selector(iKnowRulesAction) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton* exitButton = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH*0.6-80+25, 5, SCREEN_WIDTH*0.6-80-10, 40)];
    [exitButton setTitle:@"不同意并退出" forState:UIControlStateNormal];
    [exitButton setTitleColor:UIColor.grayColor forState:UIControlStateNormal];
    exitButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [exitButton setBackgroundColor:BG_COLOR];
    exitButton.layer.cornerRadius = 5;
    exitButton.layer.masksToBounds = YES;
    [foot addSubview:exitButton];
    [exitButton addTarget:self action:@selector(disAgree) forControlEvents:UIControlEventTouchUpInside];

    
    ECAlertController* alertController = [ECAlertController alertControllerWithTitle:@"ECSigner服务与隐私协议" message:rules preferredStyle:ECAlertControllerStyleAlert animationType:ECAlertAnimationTypeRaiseUp customFooterView:foot];
    _alertController = alertController;
    alertController.tapBackgroundViewDismiss = NO;
    alertController.titleColor = MAIN_COLOR;
    alertController.titleFont = [UIFont boldSystemFontOfSize:19];
    alertController.cornerRadiusForAlert = 10;
    alertController.offsetYForAlert = SCREEN_HEIGHT*0.2;
    alertController.messageAlignment = UITextAlignmentLeft;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)disAgree{
    exit(0);
}

- (void)iKnowRulesAction{
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ecsigner_rules_pop_show"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.alertController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)resetSignAction{
    
    self.choosed_ipas = nil;
    self.ipaLabel.text = @"请选择";
    self.bundleIdField.text = nil;
    self.bundleNameField.text = nil;
    self.bundleVersionField.text = nil;
    self.bundleIdField.enabled = YES;
    self.bundleNameField.enabled = YES;
    self.bundleVersionField.enabled = YES;
    self.bundleIdField.text = nil;
    self.bundleNameField.text = nil;
    self.bundleVersionField.text = nil;
}


- (void)startSignAction{
    
    BOOL super_sign = self.segment.selectedSegmentIndex;
    if (!super_sign && (!self.choosed_ipas || self.choosed_ipas.count == 0 || !self.choosed_cer || !self.choosed_prov)) {
        [ECAlertView alertMessageUnderNavigationBar:@"签名参数未完善" subTitle:@"请检查必要参数后重试" type:TSMessageNotificationTypeWarning];
        return;
    }
    if (!super_sign && !self.choosed_cer.name) {
        [ECAlertView alertMessageUnderNavigationBar:@"所选证书状态异常" subTitle:@"请前往文件查看证书状态" type:TSMessageNotificationTypeWarning];
        return;
    }
    
    //清空已签名数据
    [self.signd_success_ipas removeAllObjects];
    
    ECAlertController* alert = [ECAlertController alertControllerWithTitle:nil message:nil preferredStyle:ECAlertControllerStyleAlert animationType:ECAlertAnimationTypeExpand customView:self.signProgressView];
    [alert setTapBackgroundViewDismiss:NO];
    [self presentViewController:alert animated:YES completion:nil];
    
    self.signProgressView.progress = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerBeginAction) userInfo:nil repeats:YES];
    CGFloat totalSize = 0;
    for (ECApplicationFile* ipa in self.choosed_ipas) {
        totalSize += ipa.file_size;
    }
    self.timeStep = 0.5/(totalSize/1024/1024/10);
    
    NSString* bundleId = self.bundleIdField.text.length > 0 ? self.bundleIdField.text : nil;
    NSString* bundleName = self.bundleNameField.text.length > 0 ? self.bundleNameField.text : nil;
    NSString* bundleVersion = self.bundleVersionField.text.length > 0 ? self.bundleVersionField.text : nil;
    BOOL autoDelete = [[NSUserDefaults standardUserDefaults] boolForKey:@"ecsigner_autoDeleteWhenSignDone"];
    
    int __block sign_count_success = 0;
    int __block sign_count_failed = 0;
    int __block sign_failed_code = 0;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSString* cerPath = [[ECFileManager sharedManager] localPathForFile:self.choosed_cer.file_name resigned:NO];
        NSString* provPath = [[ECFileManager sharedManager] localPathForFile:self.choosed_prov.file_name resigned:NO];
        NSString* cer_pwd = self.choosed_cer.password;
        
        [[NSUserDefaults standardUserDefaults] setObject:self.choosed_cer.file_name forKey:@"ecsigner_lastSign_cer"];
        [[NSUserDefaults standardUserDefaults] setObject:self.choosed_prov.file_name forKey:@"ecsigner_lastSign_prov"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSMutableArray* alreadyDone = [NSMutableArray array];
        for (ECApplicationFile* ipa in self.choosed_ipas) {
            
            NSString* ipaPath = [[ECFileManager sharedManager] localPathForFile:ipa.file_name resigned:ipa.resigned];
            
            //不自动删除原包就单独复制一个包出来签名
            if (autoDelete == NO && ipa.resigned == NO) {
                NSString* tmpPath = [[ECFileManager sharedManager].tmpPath stringByAppendingPathComponent:ipa.file_name];
                if ([[NSFileManager defaultManager] fileExistsAtPath:tmpPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
                }
                BOOL res = [[NSFileManager defaultManager] copyItemAtPath:ipaPath toPath:tmpPath error:nil];
                if (res){
                    ipaPath = tmpPath;
                }
            }
            
            //重签名清除原安装分享文件
            NSString* installIpa = [[ECFileManager sharedManager].installPath stringByAppendingPathComponent:[ipa.file_name stringByReplacingOccurrencesOfString:@".app" withString:@".ipa"]];
            NSString* installPlist = [[ECFileManager sharedManager].installPath stringByAppendingPathComponent:[ipa.file_name stringByReplacingOccurrencesOfString:@".app" withString:@".plist"]];
            if ([NSFileManager.defaultManager fileExistsAtPath:installIpa]) {
                [NSFileManager.defaultManager removeItemAtPath:installIpa error:nil];
            }
            if ([NSFileManager.defaultManager fileExistsAtPath:installPlist]) {
                [NSFileManager.defaultManager removeItemAtPath:installPlist error:nil];
            }
        
            ipa.resigned_cer_name = self.choosed_cer.name;
            NSString* signedIpa = [ECFileManager sharedManager].signedIpaPath;
            NSString* output = [NSString stringWithFormat:@"%@/%@.app",signedIpa, bundleId?:[ipa.file_name stringByReplacingOccurrencesOfString:@".app" withString:@""]];
            NSString* size = [NSString stringWithFormat:@"%.2fM", ipa.file_size*1.0/1024/1024];
            
            if (cerPath && provPath && ipaPath) {
            
                 int res = [ecsign signIPA:ipaPath
                                      size:size
                                       cer:cerPath
                                       pwd:cer_pwd
                                      prov:provPath
                                  bundleID:bundleId
                                bundleName:bundleName
                             bundleVersion:bundleVersion
                                  zipLevel:-1
                                    output:output];
                
                [alreadyDone addObject:ipa];
                if (res == 0) {
                    sign_count_success ++;
                    [self.signd_success_ipas addObject:ipa];
                } else {
                    sign_count_failed ++;
                    sign_failed_code = res;
                }
                
            } else {
                [alreadyDone addObject:ipa];
                sign_count_failed ++;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                CGFloat doneSize = 0;
                for (ECApplicationFile* ipa in alreadyDone) {
                    doneSize += ipa.file_size;
                }
                CGFloat progress = doneSize/totalSize;
                [self syncSignProgress:progress];
            });
        }

        if (sign_count_failed + sign_count_success == self.choosed_ipas.count) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetSignAction];
                [self resetTimer];
                [alert dismissViewControllerAnimated:YES completion:^{

                    [ECAlertView alertMessageUnderNavigationBar:[NSString stringWithFormat:@"签名完成"] subTitle:[NSString stringWithFormat:@"共%d个,成功%d个,失败%d个,状态：%@",sign_count_failed + sign_count_success, sign_count_success, sign_count_failed, [self checkSignStateStringWithCode:sign_failed_code]] type:sign_count_failed > 0 ? TSMessageNotificationTypeWarning : TSMessageNotificationTypeMessage];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[MyObject new] signDoneToCheck];
                    });
                    if (sign_count_failed == 0) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(2),@"resignd":@1}];
                    }
                }];
            });
        }
    });
}

- (NSString *)checkSignStateStringWithCode:(int)signdCode{
    
    switch (signdCode) {
        case 0:
            return @"正常";
        case -1:
            return @"待签名包不存在";
        case -2:
            return @"初始化签名参数失败";
        case -3:
            return @"解压失败";
        case -4:
            return @"移除动态库失败";
        case -5:
            return @"服务器链接失败,请检查LeanCloud账号是否正常";
        case -6:
            return @"屏蔽锁写入失败";
        case -7:
            return @"签名失败,包内存在文件格式异常";
        case -8:
            return @"保存已签名包失败";
        case -10:
            return @"保存路径异常";

        default:
            return @"未知";
    }
}

- (void)timerBeginAction{
    
    if (self.signProgressView.progress >= 1) {
        return;
    }
    
    self.signProgressView.progress += self.timeStep;
    if (self.signProgressView.progress >= 0.99) {
        self.signProgressView.progress = 0.99;
        return;
    }
}

- (void)syncSignProgress:(CGFloat)progress{
    
    if (self.signProgressView.progress > progress*2) {
        self.timeStep = 0;
    } else if (self.signProgressView.progress > progress) {
        self.timeStep = 0.01;
    } else if (self.signProgressView.progress*2 < progress) {
        self.timeStep = 0.5;
    } else if (self.signProgressView.progress*1.5 < progress) {
        self.timeStep = 0.3;
    } else if (self.signProgressView.progress*1.25 < progress) {
        self.timeStep = 0.2;
    } else if (self.signProgressView.progress < progress) {
        self.timeStep = 0.1;
    }
}

- (void)resetTimer{
    [_timer invalidate];
    _timer = nil;
}

- (IBAction)chooseFileAction:(UIButton *)sender {
    
    NSInteger index = sender.tag;
    ECSegmenteType type = ECSegmenteTypeCers;
    switch (index) {
            //p12
        case 0:
            if (self.segment.selectedSegmentIndex == 0) {
                
                type = ECSegmenteTypeCers;
                break;

            }
            //mobileprovision
        case 1:
        {
            if (!self.choosed_cer) {
                [ECAlertView alertMessageUnderNavigationBar:@"请先选择签名证书" subTitle:nil type:TSMessageNotificationTypeWarning];
                return;
            }
            ECCertificateDetailController* prov = [ECCertificateDetailController new];
            prov.choosed = YES;
            prov.cer = self.choosed_cer;
            @weakify(self);
            prov.fileChooseBlock = ^(NSArray<ECFile *>* files) {
                @strongify(self);
                
                if (files.count > 0) {
                    self.provLabel.text = files.firstObject.file_name;
                    self.choosed_prov = (ECMobileProvisionFile *)files.firstObject;
                }
            };
            [self.navigationController pushViewController:prov animated:YES];

        }
            return;
            //ipa
        case 2:
            type = ECSegmenteTypeOriginalIpas;
            break;
            //dylib
        case 3:
            type = ECSegmenteTypeDylibs;
            break;
    }
    
    ECFileManageController* fileVc = [ECFileManageController new];
    fileVc.segmentType = type;
    fileVc.choosed = YES;
    @weakify(self);
    fileVc.fileChooseBlock = ^(NSArray<ECFile *>* files) {
        @strongify(self);

        switch (index) {
                //p12
            case 0:
            {
                if (files.count > 0)  {
                    
                    ECCertificateFile* choose_cer = self.choosed_cer;
                    ECCertificateFile* cer = (ECCertificateFile *)files.firstObject;
                    if (choose_cer && ![cer.name isEqualToString:choose_cer.name]) {
                        self.choosed_prov = nil;
                        self.provLabel.text = @"请选择";
                    }
                    self.cerLabel.text = cer.file_name;
                    self.choosed_cer = cer;
                }
            }
                break;
                //ipa
            case 2:
            {
                if (!files || files.count == 0) {
                    
                    self.ipaLabel.text = @"请选择";
                    self.choosed_ipas = nil;

                } else {
                    
                    ECApplicationFile* ipa = (ECApplicationFile *)files.firstObject;
                    NSString* fileName = [ipa.file_name stringByReplacingOccurrencesOfString:@".app" withString:@""];
                    if (ipa.resigned) {
                        fileName = [NSString stringWithFormat:@"[%@] %@", [[NSDate getTimeStrWithLong:ipa.resigned_time] substringWithRange:NSMakeRange(5, 14)], fileName];
                    }

                    self.choosed_ipas = files;
                    if (files.count > 1) {
                        self.ipaLabel.text = [NSString stringWithFormat:@"%@等%d个包", fileName, (int)files.count];
                    } else {
                        self.ipaLabel.text = fileName;
                    }
                }
                
                [self setupBundleNameAndIDField];
            }
                break;

            default:
                break;
        }
    };
    
    [self.navigationController pushViewController:fileVc animated:YES];
}

- (void)setupBundleNameAndIDField{
    
    self.bundleIdField.enabled = self.choosed_ipas.count == 1;
    self.bundleNameField.enabled = self.choosed_ipas.count == 1;

    if (self.choosed_ipas.count != 1) {
        self.bundleIdField.text = nil;
        self.bundleNameField.text = nil;
        self.bundleVersionField.text = nil;
        return;
    }
    
    ECApplicationFile* ipa = (ECApplicationFile *)self.choosed_ipas.firstObject;
    NSDictionary* dic = [[ECFileManager sharedManager] getPlistInfo:ipa];
    self.bundleIdField.text = [dic objectForKey:@"CFBundleIdentifier"];
    self.bundleNameField.text = [dic objectForKey:@"CFBundleDisplayName"] ?: [dic objectForKey:@"CFBundleName"];
    self.bundleVersionField.text = [dic objectForKey:@"CFBundleShortVersionString"];
}

- (IBAction)moreAction:(SPButton *)sender {
    sender.selected = !sender.selected;
    
    self.moreSettingViewHeightConstraint.constant = sender.selected?160:0;
    [self updateConstraintsWithAnimationForView:self.moreSettingView completeAlpha:sender.selected?1:0];
}

- (void)updateConstraintsWithAnimationForView:(UIView *)view completeAlpha:(CGFloat)alpha{
    
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];

    [UIView animateWithDuration:0.3 animations:^{
        view.alpha = alpha;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (ECSignProgressView *)signProgressView{
    if (!_signProgressView) {
        _signProgressView = [[ECSignProgressView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    }
    return _signProgressView;
}

- (void)didReceiveMemoryWarning{
    NSLog(@"Sign Memory warning...");
}


@end
