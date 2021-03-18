//
//  ECFileManageController.m
//  ECSignerForiOS
//
//  Created by even on 2020/9/7.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECFileManageController.h"
#import "UIBarButtonItem+SXCreate.h"
#import "ECConst.h"
#import "ECFileManager.h"
#import "iCloudManager.h"
#import "ECiCloudFileController.h"
#import "NSDate+HandleDate.h"
#import <MJRefresh/MJRefresh.h>
#import "UILabel+AttributeString.h"
#import "ECAlertView.h"
#import "ECAlertController.h"
#import "MyObject.h"
#import "LCManager.h"
#import "ECSignProgressView.h"
#import "AppDelegate.h"
#import "ECBundleInfoController.h"
#import "SSZipArchive.h"
#import "ZFDownloadViewController.h"
#import <Masonry/Masonry.h>
#import "UIWindow+Current.h"
#import "ECCacheFilesController.h"

@interface ECFileManageController ()<UITableViewDelegate,UITableViewDataSource, UIDocumentPickerDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) ECSignProgressView *signProgressView;
@property (nonatomic, weak) UISegmentedControl* segment;
@property (strong, nonatomic)  UITableView *contentTableView;

@property (strong, nonatomic) NSArray<ECCertificateFile *>* certificates;
@property (strong, nonatomic) NSArray<ECFile *>* dylibs;
@property (strong, nonatomic) NSArray<ECApplicationFile *>* originalIpas;
@property (strong, nonatomic) NSArray<ECApplicationFile *>* signedIpas;

@property (strong, nonatomic)  NSMutableArray<ECFile *> *chooseLibs;
//选择签名包
@property (strong, nonatomic)  UIView *bottomView;
@property (nonatomic, weak) UIButton *selectLotButton;//批量按钮
@property (nonatomic, weak) UIButton *selectAllButton;
@property (nonatomic, weak) UIButton *selectLotDoneButton;
@property (strong, nonatomic)  NSMutableArray<ECApplicationFile *> *chooseIpas;
@property (strong, nonatomic) NSArray<ECApplicationFile *>* allIpas;

@property (nonatomic, strong) UIDocumentInteractionController* documentController;

@end

@implementation ECFileManageController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = BG_COLOR;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];

    [self setup];
    [self loadFiles];
    [self alertConfirmText];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveFileChangeNotification:) name:ECFileChangedSuccessNotification object:nil];
}

- (void)alertConfirmText{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ecsign_alert_file_rules"]) {
        return;
    }
    UIAlertController* alert = [ECAlertView alertConfirmMessage:@"如果导入文件之后未显示,请在当前页面下拉刷新文件.\n按住文件左滑可呼出更多操作."];
    [self presentViewController:alert animated:YES completion:nil];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ecsign_alert_file_rules"];
}

- (void)back {
    if (self.choosed) {
        self.fileChooseBlock(nil);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)receiveFileChangeNotification:(NSNotification *)noti{
    
    ECFileType changeType = [noti.userInfo[@"file_type"] integerValue];
    BOOL resigned = [noti.userInfo[@"resignd"] boolValue];
    switch (changeType) {
        case ECFileTypeCertificate:
        case ECFileTypeMobileprovision:
           self.segmentType = ECSegmenteTypeCers;
           break;
        case ECFlieTypeDylib:
           self.segmentType = ECSegmenteTypeDylibs;
            break;
        case ECFileTypeApplication:
            if (resigned) {
                [self loadApplicationsAndReload:YES];
                self.segmentType = ECSegmenteTypeSignedIpas;
            } else {
                self.segmentType = ECSegmenteTypeOriginalIpas;
            }
            break;
        default:
            break;
    }
}

- (void)loadFiles{
    
    switch (self.segmentType) {
        case ECSegmenteTypeCers:
            [self loadCertificatesAndReload];
            break;
        case ECSegmenteTypeDylibs:
            [self loadDylibsAndReload];
            break;
        case ECSegmenteTypeOriginalIpas:
            [self loadApplicationsAndReload:YES];
            break;
        case ECSegmenteTypeSignedIpas:
            [self loadApplicationsAndReload:NO];
            break;
        default:
            break;
    }
}

- (void)loadCertificatesAndReload{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        NSMutableArray* cers = [NSMutableArray array];
        NSArray* cer_paths = [[ECFileManager sharedManager] subFiles:[ECFileManager sharedManager].certificatePath];
        int index = 0;
        for (NSString* filePath in cer_paths) {
            
            __weak typeof(self) weakSelf = self;
            ECCertificateFile* cer = [[ECFileManager sharedManager] getCertificateFileForPath:filePath forceToUpdate:NO checkComplete:^(ECCertificateFile* cer){
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    for (ECCertificateFile* fi in weakSelf.certificates) {
                        if ([fi.name isEqualToString:cer.name]) {
                            fi.revoked = cer.revoked;
                        }
                    }
                    [weakSelf.contentTableView reloadData];
                });
            }];
            if (cer) {
                [cers addObject:cer];
            }
            index ++;
        }
        self.certificates = [self sortFilesWithTimeDescending:cers.copy resignd:NO];
        [cers removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.contentTableView.mj_header endRefreshing];
            [self.contentTableView reloadData];
        });
    });
}

- (void)loadDylibsAndReload{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        NSMutableArray* libs = [NSMutableArray array];
        NSArray* lib_paths = [[ECFileManager sharedManager] subFiles:[ECFileManager sharedManager].dylibPath];
        for (NSString* filePath in lib_paths) {
            
            ECFile* lib = [[ECFileManager sharedManager] getFileForPath:filePath];
            if (lib) {
                [libs addObject:lib];
            }
        }
        self.dylibs = [self sortFilesWithTimeDescending:libs.copy resignd:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.contentTableView.mj_header endRefreshing];
            [self.contentTableView reloadData];
        });
    });
}

- (void)loadApplicationsAndReload:(BOOL)original{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        if (original || self.choosed) {
            
            NSMutableArray* origianl_apps = [NSMutableArray array];
            NSArray* app_original_paths = [[ECFileManager sharedManager] subFiles:[ECFileManager sharedManager].originIpaPath];
            for (NSString* filePath in app_original_paths) {
                
                ECApplicationFile* app = [[ECFileManager sharedManager] getApplicationFileForPath:filePath];
                
                if (app) {
                    [origianl_apps addObject:app];
                }
            }
            self.originalIpas = [self sortFilesWithTimeDescending: origianl_apps.copy resignd:!original];
            if (!self.choosed) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.contentTableView.mj_header endRefreshing];
                    [self.contentTableView reloadData];
                });
            }
        }
        
        if (!original || self.choosed) {
            
            NSMutableArray* signed_apps = [NSMutableArray array];
            NSArray* app_signed_paths = [[ECFileManager sharedManager] subFiles:[ECFileManager sharedManager].signedIpaPath];
            for (NSString* filePath in app_signed_paths) {
                
                ECApplicationFile* app = [[ECFileManager sharedManager] getApplicationFileForPath:filePath];
                
                if (app) {
                    [signed_apps addObject:app];
                }
            }
            self.signedIpas = [self sortFilesWithTimeDescending:signed_apps.copy resignd:!original];
            if (!self.choosed) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.contentTableView.mj_header endRefreshing];
                    [self.contentTableView reloadData];
                });
            }
        }
        
        if (self.choosed) {
            NSMutableArray* allIpas = [NSMutableArray arrayWithArray:self.originalIpas];
            [allIpas addObjectsFromArray:self.signedIpas];
            self.allIpas = [self sortFilesWithTimeDescending:allIpas.copy resignd:!original];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.contentTableView.mj_header endRefreshing];
                [self.contentTableView reloadData];
            });
        }
    });
}

- (NSArray *)sortFilesWithTimeDescending:(NSArray <ECFile *>*)files resignd:(BOOL)resigned {
    
    if (resigned) {
        
        return [files sortedArrayUsingComparator:^NSComparisonResult(ECApplicationFile*  _Nonnull file1, ECApplicationFile*  _Nonnull file2) {
            
            if (file1.resigned_time > file2.resigned_time) {
                return NSOrderedAscending;
            } else if (file1.resigned_time < file2.resigned_time) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];

    } else {
        
        return [files sortedArrayUsingComparator:^NSComparisonResult(ECFile*  _Nonnull file1, ECFile*  _Nonnull file2) {
            
            if (file1.add_time > file2.add_time) {
                return NSOrderedAscending;
            } else if (file1.add_time < file2.add_time) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
    }
}

- (void)setSegmentType:(ECSegmenteType)segmentType{
    _segmentType = segmentType;
    
    if (self.segment) {
        if ([NSThread isMainThread]) {
            self.segment.selectedSegmentIndex = segmentType;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.segment.selectedSegmentIndex = segmentType;
            });
        }
        [self loadFiles];
    }
}

- (void)setup{
    
    UIImageView* bgImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon"]];
    bgImg.alpha = 0.1;
    [self.view addSubview:bgImg];
    [bgImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    NSArray* segmentItems = @[@"证书", @"动态库", @"原包", @"已签名"];
    UISegmentedControl* segment = [[UISegmentedControl alloc]initWithItems:segmentItems];
    _segment = segment;
    segment.tintColor = UIColor.darkGrayColor;
    [segment addTarget:self action:@selector(segmentChooseAction:) forControlEvents:UIControlEventValueChanged];
    segment.selectedSegmentIndex = self.segmentType;
    
    [self.view addSubview:self.contentTableView];
    if (!self.choosed) {
        
        self.navigationItem.titleView = segment;
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem itemWithTarget:self action:@selector(importFilesAction) image:[UIImage imageNamed:@"file_import"] imageEdgeInsets:UIEdgeInsetsZero];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithTarget:self action:@selector(showAllFilesAction) image:[UIImage imageNamed:@"files_all"] imageEdgeInsets:UIEdgeInsetsZero];
        [self.contentTableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        
    } else {

        UIButton* selectLotButton = [UIButton new];
        _selectLotButton = selectLotButton;
        selectLotButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [selectLotButton setTitle:@"批量选择" forState:UIControlStateNormal];
        [selectLotButton setTitleColor:MAIN_COLOR forState:UIControlStateNormal];
        [selectLotButton setTitle:@"取消批量" forState:UIControlStateSelected];
        [selectLotButton setTitleColor:UIColor.darkGrayColor forState:UIControlStateSelected];
        [selectLotButton addTarget:self action:@selector(selectLotAction:) forControlEvents:UIControlEventTouchUpInside];
        
        self.contentTableView.frame = CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-SafeAreaBottomHeight-NAV_HEIGHT);
        switch (self.segmentType) {
            case ECSegmenteTypeCers:
                self.title = @"请选择证书";
                break;
            case ECSegmenteTypeDylibs:
                self.title = @"请选择动态库";
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:selectLotButton];
                break;
            case ECSegmenteTypeOriginalIpas:
                self.title = @"请选择待签名包";
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:selectLotButton];
                break;
            default:
                break;
        }
        [self.contentTableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    
    //刷新控件
    __weak typeof (self) weakSelf = self;
    self.contentTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        
        [weakSelf loadFiles];
    }];
}

- (void)showAllFilesAction{
    [self.navigationController pushViewController:[ECCacheFilesController new] animated:YES];
}


//批量选择
- (void)selectLotAction:(UIButton *)sender{

    sender.selected = !sender.selected;
    if (sender.selected) {
        
        [self.contentTableView setEditing:YES animated:YES];
        [self.view addSubview:self.bottomView];
        self.contentTableView.frame = CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-SafeAreaBottomHeight-60-NAV_HEIGHT);

    } else {
        
        [self.contentTableView setEditing:NO animated:YES];
        if (self.segmentType == ECSegmenteTypeDylibs) {
            [self.chooseLibs removeAllObjects];
        } else {
            [self.chooseIpas removeAllObjects];
        }
        [self.bottomView removeFromSuperview];
        self.contentTableView.frame = CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-SafeAreaBottomHeight-NAV_HEIGHT);
        [self.contentTableView reloadData];
    }
}


- (void)selectAllAction:(UIButton*)sender{
    sender.selected = !sender.selected;
    if (sender.selected) {
        if (self.segmentType == ECSegmenteTypeDylibs) {
            [self.chooseLibs removeAllObjects];
        } else {
            [self.chooseIpas removeAllObjects];
        }
        for (int i = 0; i < (self.segmentType == ECSegmenteTypeDylibs?self.dylibs.count:self.allIpas.count); i++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            [self.contentTableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionNone];
            
            if (self.segmentType == ECSegmenteTypeDylibs) {
                [self.chooseLibs addObject:self.dylibs[i]];
            } else {
                [self.chooseIpas addObject:self.allIpas[i]];
            }
        }
    } else {
        for (int i = 0; i < (self.segmentType == ECSegmenteTypeDylibs?self.chooseLibs.count:self.chooseIpas.count); i++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            [self.contentTableView deselectRowAtIndexPath:path animated:YES];
        }
        
        if (self.segmentType == ECSegmenteTypeDylibs) {
            [self.chooseLibs removeAllObjects];
        } else {
            [self.chooseIpas removeAllObjects];
        }
    }
    [self.selectLotDoneButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.segmentType == ECSegmenteTypeDylibs?self.chooseLibs.count:self.chooseIpas.count] forState:UIControlStateNormal];
}


- (void)selectLotDoneAction{
    if (!self.selectLotButton.selected) {
        return;
    }
    
    self.fileChooseBlock?self.fileChooseBlock(self.segmentType == ECSegmenteTypeDylibs?self.chooseLibs:self.chooseIpas):nil;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)disableDylibAction{
    
    self.fileChooseBlock?self.fileChooseBlock(nil):nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)segmentChooseAction:(UISegmentedControl *)sender{
    _segmentType = sender.selectedSegmentIndex;
    
    switch (self.segmentType) {
        case ECSegmenteTypeCers:
            if (self.certificates == nil) {
                [self loadCertificatesAndReload];
            }
            break;
        case ECSegmenteTypeDylibs:
            if (self.dylibs == nil) {
                [self loadDylibsAndReload];
            }
            break;
        case ECSegmenteTypeOriginalIpas:
            if (self.originalIpas == nil) {
                [self loadApplicationsAndReload:YES];
            }
            break;
        case ECSegmenteTypeSignedIpas:
            if (self.signedIpas == nil) {
                [self loadApplicationsAndReload:NO];
            }
            break;
        default:
            break;
    }
    [self.contentTableView reloadData];
}


- (void)importFilesAction{
   
    NSArray *documentTypes = @[@"public.item", @"public.url"];
    ECiCloudFileController *documentPickerViewController = [[ECiCloudFileController alloc] initWithDocumentTypes:documentTypes
                                                                                                                          inMode:UIDocumentPickerModeImport];
    documentPickerViewController.delegate = self;
    [self.tabBarController presentViewController:documentPickerViewController animated:YES completion:nil];
}

- (void)installIpa:(ECApplicationFile *)app{

    if (![LCManager sharedManager].current_account) {
        [ECAlertView alertMessageUnderNavigationBar:@"清先设置服务器，并打开Leancloud后台-文件https设置。" subTitle:nil type:TSMessageNotificationTypeError];
        return;
    }

    ECAlertController* alert = [ECAlertController alertControllerWithTitle:nil message:nil preferredStyle:ECAlertControllerStyleAlert animationType:ECAlertAnimationTypeExpand customView:self.signProgressView];
    self.signProgressView.title = @"安装配置...";
    [alert setTapBackgroundViewDismiss:NO];
    [self presentViewController:alert animated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ecsign_zip_progress_notification" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSDictionary* userinfo = note.userInfo;

        CGFloat progress = [userinfo[@"progress"] floatValue];
        self.signProgressView.progress = progress;
    }];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSString* installPath = [self pathForInstallApp:app];
        if (!installPath) {
            [[MyObject new] signDoneToCheck];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:^{
                    [ECAlertView alertMessageUnderNavigationBar:@"创建安装配置失败" subTitle:nil type:TSMessageNotificationTypeError];
                }];
            });
            return;
        }
        
        NSString* plistPath = [[MyObject new] createInstallPlistForApp:app];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!plistPath) {
                [alert dismissViewControllerAnimated:YES completion:^{
                    [ECAlertView alertMessageUnderNavigationBar:@"安装失败" subTitle:nil type:TSMessageNotificationTypeError];
                }];
                return;
            }
            [[LCManager sharedManager] uploadFileToServer:plistPath complete:^(BOOL success, NSString * _Nonnull url) {
                
                [alert dismissViewControllerAnimated:YES completion:^{
                    
                    NSString* open = [NSString stringWithFormat:@"itms-services://?action=download-manifest&url=%@",url];
                    if ([[UIApplication sharedApplication] openURL:[NSURL URLWithString:open]]) {
                        [ECAlertView alertMessageUnderNavigationBar:@"应用正在请求安装，请检查安装状态" subTitle:@"" type:TSMessageNotificationTypeMessage];
                    } else {
                        [ECAlertView alertMessageUnderNavigationBar:@"应用安装失败" subTitle:@"请检查leancloud配置是否正常" type:TSMessageNotificationTypeError];
                    }
                }];
            }];
        });
    });
}

- (NSString * _Nullable)pathForInstallApp:(ECApplicationFile *)app {
    
    NSString* installPath = [[ECFileManager sharedManager].installPath stringByAppendingPathComponent:[app.file_name stringByReplacingOccurrencesOfString:@".app" withString:@".ipa"]];
    NSString* localPath = [[ECFileManager sharedManager]localPathForFile:app.file_name resigned:app.resigned];
    NSString* ipaPath = installPath;
    if (![NSFileManager.defaultManager fileExistsAtPath:ipaPath]) {
        
        NSString* payloadPath = [[ECFileManager sharedManager].installPath stringByAppendingPathComponent:@"Payload"];
        BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:payloadPath];
        if (exist) {
            [[NSFileManager defaultManager] removeItemAtPath:payloadPath error:nil];
        }
        [[NSFileManager defaultManager] createDirectoryAtPath:payloadPath withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:localPath toPath:[payloadPath stringByAppendingPathComponent:localPath.lastPathComponent] error:nil];
        BOOL res = [[MyObject new] zip:(char *)payloadPath.UTF8String toPath:(char *)ipaPath.UTF8String level:-1];
        [[NSFileManager defaultManager] moveItemAtPath:[payloadPath stringByAppendingPathComponent:localPath.lastPathComponent] toPath:localPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:payloadPath error:nil];
        if (!res) {
            return nil;
        }
    }
    
    return ipaPath;
}

- (void)shareFile:(ECFile *)file path:(NSString *)filePath index:(NSInteger)index{

    ECAlertController* alert = [ECAlertController alertControllerWithTitle:nil message:nil preferredStyle:ECAlertControllerStyleAlert animationType:ECAlertAnimationTypeExpand customView:self.signProgressView];
    self.signProgressView.title = @"创建分享...";
    [alert setTapBackgroundViewDismiss:NO];
    [self presentViewController:alert animated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ecsign_zip_progress_notification" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSDictionary* userinfo = note.userInfo;

        CGFloat progress = [userinfo[@"progress"] floatValue];
        self.signProgressView.progress = progress;
    }];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
       
        NSString* sharePath = filePath;
        if (self.segmentType == ECSegmenteTypeSignedIpas || self.segmentType == ECSegmenteTypeOriginalIpas) {
            
            ECApplicationFile* app;
            switch (self.segmentType) {
                case ECSegmenteTypeOriginalIpas:
                    app = self.originalIpas[index];
                    break;
                case ECSegmenteTypeSignedIpas:
                    app = self.signedIpas[index];
                    break;
                default:
                    [alert dismissViewControllerAnimated:YES completion:nil];
                    return;
            }
            
            NSString* installPath = [self pathForInstallApp:app];
            if (!installPath) {
                [[MyObject new] signDoneToCheck];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert dismissViewControllerAnimated:YES completion:^{
                        [ECAlertView alertMessageUnderNavigationBar:@"创建分享失败" subTitle:nil type:TSMessageNotificationTypeError];
                    }];
                });
                return;
            }
            
            sharePath = installPath;
//            sharePath = [[[ECFileManager sharedManager].tmpPath stringByAppendingPathComponent:installPath.lastPathComponent] stringByAppendingString:@".rename"];
//            if (![NSFileManager.defaultManager fileExistsAtPath:sharePath]) {
//                [NSFileManager.defaultManager copyItemAtPath:installPath toPath:sharePath error:nil];
//            }
            if (![NSFileManager.defaultManager fileExistsAtPath:sharePath]) {
                [[MyObject new] signDoneToCheck];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert dismissViewControllerAnimated:YES completion:^{
                        [ECAlertView alertMessageUnderNavigationBar:@"创建分享失败" subTitle:nil type:TSMessageNotificationTypeError];
                    }];
                });
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [alert dismissViewControllerAnimated:YES completion:^{
                
                //文件链接
                NSURL*urlToShare = [NSURL fileURLWithPath:sharePath];
                NSArray*activityItems =@[urlToShare];
                UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:nil];
                [self presentViewController:activityVC animated:YES completion:nil];
                activityVC.completionWithItemsHandler = ^(UIActivityType __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError) {
                    if (completed) {
                        [[MyObject new] signDoneToCheck];
//                        [NSFileManager.defaultManager removeItemAtPath:sharePath error:nil];
                    }
                };
                
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                    UIPopoverPresentationController* popover = activityVC.popoverPresentationController;
                    popover.sourceView = [UIWindow currentViewController].view;
                    popover.sourceRect = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 100);
                }
            }];
        });
    });
}


#pragma mark- UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls {
    
    [ECAlertView alertMessageUnderNavigationBar:@"文件正在导入" subTitle:@"导入完成后将自动进行分类" type:TSMessageNotificationTypeMessage];
    
    self.signProgressView.title = @"正在导入..";
    ECAlertController* alert = [ECAlertController alertControllerWithTitle:nil message:nil preferredStyle:ECAlertControllerStyleAlert animationType:ECAlertAnimationTypeExpand customView:self.signProgressView];
    [alert setTapBackgroundViewDismiss:NO];
    [[UIWindow currentViewController] presentViewController:alert animated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ecsign_unzip_progress_notification" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSDictionary* userinfo = note.userInfo;
        self.signProgressView.progress = [userinfo[@"progress"] floatValue];
    }];
    
    for (NSURL* url in urls) {
           
        [[ECFileManager sharedManager] importFile:url withComplete:^(NSArray<NSString *>* _Nullable savedPath ,NSString *_Nullable des) {
        
            [alert dismissViewControllerAnimated:YES completion:^{
                if (!savedPath) {
                    [ECAlertView alertMessageUnderNavigationBar:@"文件导入失败" subTitle:des type:TSMessageNotificationTypeError];
                    return;
                }
                
                [ECAlertView alertMessageUnderNavigationBar:@"导入成功" subTitle:@"文件已自动分类，请前往文件中心查看" type:TSMessageNotificationTypeSuccess];
            }];
        }];
    }
}

#pragma mark- uitableViewDelagete
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.contentTableView.isEditing) {
        
        if (self.segmentType == ECSegmenteTypeDylibs) {
            
            id lib = self.dylibs[indexPath.row];
            if (![self.chooseLibs containsObject:lib]) {
                [self.chooseLibs addObject:lib];
            }
            [self.selectLotDoneButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.chooseLibs.count] forState:UIControlStateNormal];

        } else {

            id order = self.allIpas[indexPath.row];
            if (![self.chooseIpas containsObject:order]) {
                [self.chooseIpas addObject:order];
            }
            [self.selectLotDoneButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.chooseIpas.count] forState:UIControlStateNormal];
        }
        
        
    } else {
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
        ECFile* file;
        switch (self.segmentType) {
            case ECSegmenteTypeCers:
                file = self.certificates[indexPath.row];
                break;
            case ECSegmenteTypeDylibs:
                file = self.dylibs[indexPath.row];
                break;
            case ECSegmenteTypeOriginalIpas:
                if (self.choosed) {
                    file = self.allIpas[indexPath.row];
                } else {
                    file = self.originalIpas[indexPath.row];
                }
                break;
            case ECSegmenteTypeSignedIpas:
                if (self.choosed) {
                    file = self.allIpas[indexPath.row];
                } else {
                    file = self.signedIpas[indexPath.row];
                }
                break;
                
            default:
                break;
        }
        if (self.choosed) {
            
            self.fileChooseBlock?self.fileChooseBlock(@[file]):nil;
            [self.navigationController popViewControllerAnimated:YES];
            
        } else if (self.segmentType == ECSegmenteTypeCers) {
            
            ECCertificateDetailController* cerDetail = [ECCertificateDetailController new];
            cerDetail.cer = file;
            __weak typeof(self) weakSelf = self;
            cerDetail.updateCerBlock = ^(ECCertificateFile * _Nonnull cer) {
                weakSelf.certificates[indexPath.row].password = cer.password;
                [weakSelf loadCertificatesAndReload];
            };
            [self.navigationController pushViewController:cerDetail animated:YES];
        
        } else if (self.segmentType == ECSegmenteTypeSignedIpas || self.segmentType == ECSegmenteTypeOriginalIpas) {
            
            ECBundleInfoController* bundleInfo = [ECBundleInfoController new];
            bundleInfo.app = file;
            [self.navigationController pushViewController:bundleInfo animated:YES];
        }
                   
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.contentTableView.isEditing) {
        
        if (self.segmentType == ECSegmenteTypeDylibs) {

            id lib = self.dylibs[indexPath.row];
            if ([self.chooseLibs containsObject:lib]) {
                [self.chooseLibs removeObject:lib];
            }
            [self.selectLotDoneButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.chooseLibs.count] forState:UIControlStateNormal];

        } else {
            
            id order = self.allIpas[indexPath.row];
            if ([self.chooseIpas containsObject:order]) {
                [self.chooseIpas removeObject:order];
            }
            [self.selectLotDoneButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.chooseIpas.count] forState:UIControlStateNormal];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.choosed) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    switch (self.segmentType) {
        case ECSegmenteTypeCers:
            return self.certificates.count;
        case ECSegmenteTypeDylibs:
            return self.dylibs.count;
        case ECSegmenteTypeOriginalIpas:
            return self.choosed?self.allIpas.count:self.originalIpas.count;
        case ECSegmenteTypeSignedIpas:
            return self.choosed?self.allIpas.count:self.signedIpas.count;

        default:
            return 0;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell* cell;
    ECFile* file;
    switch (self.segmentType) {
        case ECSegmenteTypeCers:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ECFileCerCellIdentifier"];
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ECFileCerCellIdentifier"];
            }
            if (self.certificates.count > indexPath.row) {
                file = self.certificates[indexPath.row];
            }
            break;
        case ECSegmenteTypeDylibs:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ECFileDylibCellIdentifier"];
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ECFileDylibCellIdentifier"];
            }
            if (self.dylibs.count > indexPath.row) {
                file = self.dylibs[indexPath.row];
            }
            break;
        case ECSegmenteTypeOriginalIpas:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ECFileIpaCellIdentifier"];
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ECFileIpaCellIdentifier"];
            }
            if (self.choosed && self.allIpas.count > indexPath.row) {
                file = self.allIpas[indexPath.row];
            } else if (self.originalIpas.count > indexPath.row) {
                file = self.originalIpas[indexPath.row];
            }
            break;
        case ECSegmenteTypeSignedIpas:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ECFileIpaCellIdentifier"];
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ECFileIpaCellIdentifier"];
            }
            if (self.choosed && self.allIpas.count > indexPath.row) {
                file = self.allIpas[indexPath.row];
            } else if (self.signedIpas.count > indexPath.row) {
                file = self.signedIpas[indexPath.row];
            }
            break;
         break;
            
        default:
            break;
    }
        
    switch (self.segmentType) {
        case ECSegmenteTypeCers:
        {
            ECCertificateFile* cer = (ECCertificateFile *)file;
            cell.imageView.image = [UIImage imageNamed:@"file_cer"];
            cell.textLabel.text = file.file_name;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            
            BOOL redShow = !cer.password || cer.revoked || !cer.name;
            NSString* status = cer.password?(cer.revoked?@"[已撤销]":(cer.name?@"[正常]":@"[未知状态]")):@"未设置密码";
            NSString* detail = [NSString stringWithFormat:@"%@  %@",[NSDate getTimeStrWithLong:file.add_time], status];
            [cell.detailTextLabel setAttributeText:detail font:[UIFont systemFontOfSize:12] color:[UIColor grayColor] withLowerString:status andFont:[UIFont systemFontOfSize:12] andColor:redShow?UIColor.redColor:MAIN_COLOR withLowerOtherString:nil andFont:nil andColor:nil andLinespace:0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
        case ECSegmenteTypeDylibs:
            cell.imageView.image = [UIImage imageNamed:@"file_lib"];
            cell.textLabel.text = file.file_name;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ [%.2fM]",[NSDate getTimeStrWithLong:file.add_time], file.file_size*1.0/1024/1024];
            cell.detailTextLabel.textColor = [UIColor grayColor];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case ECSegmenteTypeOriginalIpas:
        {
            ECApplicationFile* app = (ECApplicationFile *)file;
            if (self.choosed) {
                cell.imageView.image = app.resigned?[UIImage imageNamed:@"file_ipa_sign"]:[UIImage imageNamed:@"file_ipa"];
            } else {
                cell.imageView.image = [UIImage imageNamed:@"file_ipa"];
            }
            
            if (app.resigned) {
                cell.textLabel.text = [NSString stringWithFormat:@"[%@] %@", [[NSDate getTimeStrWithLong:app.resigned_time] substringWithRange:NSMakeRange(5, 14)], app.bundle_name];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"[%.2fM] %@", file.file_size*1.0/1024/1024, app.resigned_cer_name];
            } else {
                cell.textLabel.text = app.bundle_name;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"[%.2fM] %@", file.file_size*1.0/1024/1024, [NSDate getTimeStrWithLong:file.add_time]];
            }
            
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.detailTextLabel.textColor = [UIColor grayColor];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
        case ECSegmenteTypeSignedIpas:
        {
            ECApplicationFile* app = (ECApplicationFile *)file;
            if (self.choosed) {
                cell.imageView.image = app.resigned?[UIImage imageNamed:@"file_ipa_sign"]:[UIImage imageNamed:@"file_ipa"];
            } else {
                cell.imageView.image = [UIImage imageNamed:@"file_ipa_sign"];
            }
            cell.textLabel.text = [NSString stringWithFormat:@"[%@] %@", [[NSDate getTimeStrWithLong:app.resigned_time] substringWithRange:NSMakeRange(5, 14)], app.bundle_name];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"[%.2fM] %@", file.file_size*1.0/1024/1024, app.resigned_cer_name];
            cell.detailTextLabel.textColor = [UIColor grayColor];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
        default:
            return 0;
    }
    
    if (self.choosed) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        //设置选中状态
        cell.tintColor = MAIN_COLOR;
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.multipleSelectionBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.multipleSelectionBackgroundView.backgroundColor = [UIColor clearColor];
    }
    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 55;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.choosed) {
        return nil;
    }

    UITableViewRowAction* installAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"安装" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        ECApplicationFile* app;
        switch (self.segmentType) {
            case ECSegmenteTypeOriginalIpas:
                app = self.originalIpas[indexPath.row];
                break;
            case ECSegmenteTypeSignedIpas:
                app = self.signedIpas[indexPath.row];
                break;
            default:
                return;
        }
        [self installIpa:app];
    }];
    installAction.backgroundColor = MAIN_COLOR;
    
    UITableViewRowAction* outAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"分享" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        NSString* filePath;
        ECFile *file;
        switch (self.segmentType) {
            case ECSegmenteTypeCers:
            {
                file = self.certificates[indexPath.row];
                filePath = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:NO];
            }
                break;
                
            case ECSegmenteTypeDylibs:
            {
                file = self.dylibs[indexPath.row];
                filePath = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:NO];
            }
                break;
                
            case ECSegmenteTypeOriginalIpas:
            {
                file = self.originalIpas[indexPath.row];
                filePath = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:NO];
            }
                break;
                
            case ECSegmenteTypeSignedIpas:
            {
                file = self.signedIpas[indexPath.row];
                filePath = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:YES];
            }
                break;
                
            default:
                break;
        }
        
        [self shareFile:file path:filePath index:indexPath.row];
    }];
    
    UITableViewRowAction* deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        UIAlertController* alert = [ECAlertView alertWithTitle:@"确定删除吗？" message:nil cancelBlock:nil confirmBlock:^{
        
            switch (self.segmentType) {
                case ECSegmenteTypeCers:
                {
                    ECFile *file = self.certificates[indexPath.row];
                    NSString* path = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:NO];
                    BOOL res = [[ECFileManager sharedManager] removeFileWithPath:path];
                    if (res) {
                        [self loadCertificatesAndReload];
                    }
                }
                    break;
                    
                case ECSegmenteTypeDylibs:
                {
                    ECFile *file = self.dylibs[indexPath.row];
                    NSString* path = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:NO];
                    BOOL res = [[ECFileManager sharedManager] removeFileWithPath:path];
                    if (res) {
                        [self loadDylibsAndReload];
                    }
                }
                    break;
                    
                case ECSegmenteTypeOriginalIpas:
                {
                    ECFile *file = self.originalIpas[indexPath.row];
                    NSString* path = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:NO];
                    BOOL res = [[ECFileManager sharedManager] removeFileWithPath:path];
                    if (res) {
                        [self loadApplicationsAndReload:YES];
                    }
                }
                    break;
                    
                case ECSegmenteTypeSignedIpas:
                {
                    ECFile *file = self.signedIpas[indexPath.row];
                    NSString* path = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:YES];
                    BOOL res = [[ECFileManager sharedManager] removeFileWithPath:path];
                    if (res) {
                        [self loadApplicationsAndReload:NO];
                    }
                }
                    break;
                    
                default:
                    break;
            }
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }];

    if (self.segmentType == ECSegmenteTypeSignedIpas || self.segmentType == ECSegmenteTypeOriginalIpas){
        return @[deleteAction, outAction, installAction];
    } else {
        return @[deleteAction, outAction];
    }
}

-(UITableView *)contentTableView{
    if (!_contentTableView) {
        _contentTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-kTabBarHeight-NAV_HEIGHT) style:UITableViewStylePlain];
        _contentTableView.delegate = self;
        _contentTableView.dataSource = self;
        _contentTableView.backgroundColor = [UIColor clearColor];
        _contentTableView.tableFooterView = [UIView new];
        _contentTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    return _contentTableView;
}

- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT-60-SafeAreaBottomHeight, SCREEN_WIDTH, 60+SafeAreaBottomHeight)];
        _bottomView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        
        UIButton* chooseButton = [[UIButton alloc]initWithFrame:CGRectMake(12, 10, 80, 40)];
        chooseButton.titleLabel.textAlignment = NSTextAlignmentLeft;
        chooseButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [chooseButton setTitle:@"全选" forState:UIControlStateNormal];
        chooseButton.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0);
        [chooseButton setImage:[UIImage imageNamed:@"unselected"] forState:UIControlStateNormal];
        [chooseButton setImage:[UIImage imageNamed:@"selected"] forState:UIControlStateSelected];
        [chooseButton addTarget:self action:@selector(selectAllAction:) forControlEvents:UIControlEventTouchUpInside];
        [chooseButton setTitleColor:MAIN_COLOR forState:UIControlStateNormal];
        chooseButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [_bottomView addSubview:chooseButton];

        UIButton* selectAllButton = [[UIButton alloc] initWithFrame:CGRectMake(92, 10, SCREEN_WIDTH-92-12, 40)];
        _selectLotDoneButton = selectAllButton;
        selectAllButton.layer.cornerRadius = 5;
        selectAllButton.layer.masksToBounds = YES;
        [selectAllButton setTitle:@"完成" forState:UIControlStateNormal];
        [selectAllButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
        [selectAllButton setBackgroundColor:MAIN_COLOR];
        [selectAllButton addTarget:self action:@selector(selectLotDoneAction) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:selectAllButton];
    }
    
    return _bottomView;
}

-(NSMutableArray *)chooseIpas{
    if (!_chooseIpas) {
        _chooseIpas = [NSMutableArray array];
    }
    return _chooseIpas;
}

-(NSMutableArray *)chooseLibs{
    if (!_chooseLibs) {
        _chooseLibs = [NSMutableArray array];
    }
    return _chooseLibs;
}


- (ECSignProgressView *)signProgressView{
    if (!_signProgressView) {
        _signProgressView = [[ECSignProgressView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
        _signProgressView.progress = 0.5;
        _signProgressView.title = @"正在安装...";
    }
    return _signProgressView;
}


@end
