//
//  ECCacheFilesController.m
//  ECSignerForiOS
//
//  Created by 快游 on 2020/11/6.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECCacheFilesController.h"
#import "UIBarButtonItem+SXCreate.h"
#import "ECConst.h"
#import "ECFileManager.h"
#import "ZFDownloadViewController.h"
#import "SPButton.h"
#import "ECCacheFileTypeChooseView.h"
#import "TM_CoverView.h"
#import "ECAlertView.h"

@interface ECCacheFilesController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak) SPButton *filterButton;
@property (nonatomic, strong) ECCacheFileTypeChooseView *chooseView;
@property (strong, nonatomic)  UITableView *contentTableView;
@property (nonatomic, strong) NSArray *files;
@property (nonatomic, strong) TM_CoverView *coverView;
@property (nonatomic, assign) ECCacheFileType choosedType;

@end

@implementation ECCacheFilesController

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    if (self.chooseView.y == 0 && self.chooseView.superview) {
        [self.coverView removeCover];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"本地文件";
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithTarget:self action:@selector(downloadAction) image:[UIImage imageNamed:@"file_download"] imageEdgeInsets:UIEdgeInsetsZero];
    
    SPButton* filterButton = [[SPButton alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
    _filterButton = filterButton;
    filterButton.imagePosition = SPButtonImagePositionRight;
    filterButton.imageTitleSpace = 3;
    [filterButton setTitle:@"描述文件" forState:UIControlStateNormal];
    [filterButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    filterButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [filterButton addTarget:self action:@selector(chooseTypeAction) forControlEvents:UIControlEventTouchUpInside];
    [filterButton setImage:[UIImage imageNamed:@"allfiles_open"] forState:UIControlStateNormal];
    self.navigationItem.titleView = filterButton;
    
    [self.view addSubview:self.contentTableView];
    
    self.choosedType = ECCacheFileTypeProfile;
    [self loadFilesWithType];
}


- (void)downloadAction{
    
    ZFDownloadViewController* download = [ZFDownloadViewController new];
    [self.navigationController pushViewController:download animated:YES];
}

- (void)chooseType:(ECCacheFileType)type{
    [self.coverView removeCover];
    self.choosedType = type;
    [self.filterButton setTitle:self.chooseView.fileTypes[type] forState:UIControlStateNormal];
    [self loadFilesWithType];
}

- (void)chooseTypeAction{
    
    if (self.chooseView.y == 0 && self.chooseView.superview) {
        [self.coverView removeCover];
        return;
    }
    
    [self.coverView coverWithView:self.chooseView andPopCoverViewBlock:^{
        
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.chooseView.y = 0;
        } completion:nil];
        
    } andCloseBlock:^{
        
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.chooseView.y = -200;
        } completion:nil];
    }];
}


- (void)loadFilesWithType{
    
    NSString* filePath;
    switch (self.choosedType) {
        case ECCacheFileTypeCertificate:
            filePath = [ECFileManager sharedManager].certificatePath;
            
            break;
        case ECCacheFileTypeProfile:
            filePath = [ECFileManager sharedManager].mobileProvisionPath;

            break;
        case ECCacheFileTypeLibs:
            filePath = [ECFileManager sharedManager].dylibPath;

            break;
        case ECCacheFileTypeOriginalPackages:
            filePath = [ECFileManager sharedManager].originIpaPath;

            break;
        case ECCacheFileTypeResignedPackages:
            filePath = [ECFileManager sharedManager].signedIpaPath;

            break;
        case ECCacheFileTypeZipFile:
            filePath = [ECFileManager sharedManager].zipPath;

            break;
        case ECCacheFileTypeDownloadFile:
            filePath = [ECFileManager sharedManager].downloadPath;

            break;

        case ECCacheFileTypeInstall:
            filePath = [ECFileManager sharedManager].installPath;

            break;
        default:
            break;
    }
    if (!filePath) {
        return;
    }
    
    NSArray* files = [[ECFileManager sharedManager] subFiles:filePath];
    self.files = files;
    [self.contentTableView reloadData];
}

- (void)clearAllAction{
    
    if (self.files.count == 0) {
        return;
    }
    UIAlertController* alert = [ECAlertView alertWithTitle:@"确认全部删除？" message:nil cancelBlock:nil confirmBlock:^{
        
        for (NSString* filePath in self.files) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        [self notiToFiles];
        [self loadFilesWithType];
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)notiToFiles{
    
    ECFileType type = ECFileTypeUnknown;
    switch (self.choosedType) {
        case ECCacheFileTypeCertificate:
            type = ECFileTypeCertificate;
            break;
        case ECCacheFileTypeProfile:
            type = ECFileTypeMobileprovision;
            break;
        case ECCacheFileTypeLibs:
            type = ECFlieTypeDylib;
            break;
        case ECCacheFileTypeOriginalPackages:
        case ECCacheFileTypeResignedPackages:
            type = ECFileTypeApplication;
            break;
            
        default:
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(type), @"resignd":@(self.choosedType==ECCacheFileTypeResignedPackages)}];
}

#pragma mark --- uitableviewdelegate ---
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.files.count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ECCacheFilesCellIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ECCacheFilesCellIdentifier"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSString* filePath = self.files[indexPath.row];

    cell.textLabel.text = filePath.lastPathComponent;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingHead;
    cell.textLabel.textColor = UIColor.darkGrayColor;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 44;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return YES;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if (self.files.count==0) {
        return nil;
    }
    UIButton* clearAllButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 44)];
    [clearAllButton setBackgroundColor:BG_COLOR];
    [clearAllButton setTitle:@"删除以下全部文件" forState:UIControlStateNormal];
    [clearAllButton setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    clearAllButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [clearAllButton addTarget:self action:@selector(clearAllAction) forControlEvents:UIControlEventTouchUpInside];
    return clearAllButton;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return self.files.count>0?44:0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
 
    UITableViewRowAction* deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        NSString* filePath = self.files[indexPath.row];
        BOOL res = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        if (res) {

            [self notiToFiles];
            [self loadFilesWithType];
        }
    }];
    
    return @[deleteAction];
}


-(UITableView *)contentTableView{
    if (!_contentTableView) {
        _contentTableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _contentTableView.delegate = self;
        _contentTableView.dataSource = self;
        _contentTableView.backgroundColor = [UIColor clearColor];
        _contentTableView.tableFooterView = [UIView new];
        _contentTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    return _contentTableView;
}

- (ECCacheFileTypeChooseView *)chooseView{
    if (!_chooseView) {
        _chooseView = [[ECCacheFileTypeChooseView alloc]initWithFrame:CGRectMake(0, -200, SCREEN_WIDTH, 200)];
        _chooseView.backgroundColor = UIColor.whiteColor;
        @weakify(self);
        _chooseView.chooseBlock = ^(ECCacheFileType chooseType) {
            @strongify(self);
            [self chooseType:chooseType];
        };
    }
    
    return _chooseView;
}

- (TM_CoverView *)coverView{
    
    if (!_coverView) {
        _coverView = [[TM_CoverView alloc]initWithFrame:CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-NAV_HEIGHT)];
        _coverView.clipsToBounds = YES;
//        [_coverView disEnabledTouch];
    }
    
    return _coverView;
}

@end
