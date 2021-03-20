//
//  ZFDownloadViewController.m
//  ZFDownload
//
//  Created by 任子丰 on 16/5/16.
//  Copyright © 2016年 任子丰. All rights reserved.
//

#import "ZFDownloadViewController.h"
#import "ZFDownloadManager.h"
#import "ZFDownloadingCell.h"
#import "ZFDownloadedCell.h"
#import "ECFileManager.h"
#import "ECAlertView.h"
#import "AppDelegate.h"
#import "UIBarButtonItem+SXCreate.h"
#import "KP_BaseWebViewController.h"

#define  DownloadManager  [ZFDownloadManager sharedDownloadManager]

@interface ZFDownloadViewController ()<ZFDownloadDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (atomic, strong) NSMutableArray *downloadObjectArr;

@end

@implementation ZFDownloadViewController

-(instancetype)init{
    
    if (self = [super init]) {
        self = [[UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass(self.class)];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 更新数据源
    [self initData];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, -49, 0);
    self.tableView.rowHeight = 70;
    DownloadManager.downloadDelegate = self;
    self.title = @"下载中心";
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithTarget:self action:@selector(openWeb) title:@"网址下载" titleEdgeInsets:UIEdgeInsetsZero];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ecsign_reload_download" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        [self initData];
    }];
}

- (void)openWeb{
    
    KP_BaseWebViewController* web = [KP_BaseWebViewController new];
    [self.navigationController pushViewController:web animated:YES];
    
    web.dismissWebBlock = ^(NSString * _Nullable downloadUrl) {
        if (!downloadUrl) {
            return;
        }
        // 此处是截取的下载地址，可以自己根据服务器的视频名称来赋值
        NSString *name = downloadUrl.lastPathComponent;
        NSString* subffix = [name componentsSeparatedByString:@"."].lastObject;
        if (![subffix isEqualToString:@"ipa"] && ![subffix isEqualToString:@"zip"]) {
            subffix = @"ipa";
        }
        name = [NSString stringWithFormat:@"%ld.%@", (long)NSDate.date.timeIntervalSince1970, subffix];
        [[ZFDownloadManager sharedDownloadManager] downFileUrl:downloadUrl filename:name fileimage:nil];
    };
}

- (void)initData
{
    [DownloadManager startLoad];
    NSMutableArray *downladed = DownloadManager.finishedlist;
    NSMutableArray *downloading = DownloadManager.downinglist;
    self.downloadObjectArr = @[].mutableCopy;
    [self.downloadObjectArr addObject:downladed];
    [self.downloadObjectArr addObject:downloading];
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 0;
    }
    NSArray *sectionArray = self.downloadObjectArr[section];
    return sectionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        ZFDownloadedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadedCell"];
        ZFFileModel *fileInfo = self.downloadObjectArr[indexPath.section][indexPath.row];
        cell.fileInfo = fileInfo;
        return cell;
    } else if (indexPath.section == 1) {
        ZFDownloadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"downloadingCell"];
        ZFHttpRequest *request = self.downloadObjectArr[indexPath.section][indexPath.row];
        if (request == nil) { return nil; }
        ZFFileModel *fileInfo = [request.userInfo objectForKey:@"File"];
        
        __weak typeof(self) weakSelf = self;
        // 下载按钮点击时候的要刷新列表
        cell.btnClickBlock = ^{
            [weakSelf initData];
        };
        // 下载模型赋值
        cell.fileInfo = fileInfo;
        // 下载的request
        cell.request = request;
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        ZFFileModel *fileInfo = self.downloadObjectArr[indexPath.section][indexPath.row];
        [DownloadManager deleteFinishFile:fileInfo];
    }else if (indexPath.section == 1) {
        ZFHttpRequest *request = self.downloadObjectArr[indexPath.section][indexPath.row];
        [DownloadManager deleteRequest:request];
    }
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
}

#pragma mark - ZFDownloadDelegate

// 开始下载
- (void)startDownload:(ZFHttpRequest *)request
{
    NSLog(@"开始下载!");
}

// 下载中
- (void)updateCellProgress:(ZFHttpRequest *)request
{
    ZFFileModel *fileInfo = [request.userInfo objectForKey:@"File"];
    [self performSelectorOnMainThread:@selector(updateCellOnMainThread:) withObject:fileInfo waitUntilDone:YES];
}

// 下载完成
- (void)finishedDownload:(ZFHttpRequest *)request
{
    [ECAlertView alertMessageUnderNavigationBar:@"文件下载完成,正在为您解析,请勿退出后台" subTitle:@"解析完成后自动导入并分类" type:TSMessageNotificationTypeMessage];

    [[ECFileManager sharedManager] importFile:request.downloadDestinationPath withComplete:^(NSArray<NSString *>* _Nullable savedPath, NSString* _Nullable des) {
       
        if (!savedPath) {
            [ECAlertView alertMessageUnderNavigationBar:@"文件导入失败" subTitle:des type:TSMessageNotificationTypeError];
            return;
        }
        
        ZFFileModel *fileInfo = [request.userInfo objectForKey:@"File"];
        if (fileInfo) {
            [DownloadManager deleteFinishFile:fileInfo];
        }
        [self initData];

        [ECAlertView alertMessageUnderNavigationBar:@"导入成功" subTitle:@"文件已自动分类，请前往文件中心刷新查看" type:TSMessageNotificationTypeSuccess];
    }];
    
}


- (void)checkZippath{
    
    AppDelegate* del = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [del checkAndUnzipFile];
}

// 更新下载进度
- (void)updateCellOnMainThread:(ZFFileModel *)fileInfo
{
    NSArray *cellArr = [self.tableView visibleCells];
    for (id obj in cellArr) {
        if([obj isKindOfClass:[ZFDownloadingCell class]]) {
            ZFDownloadingCell *cell = (ZFDownloadingCell *)obj;
            if([cell.fileInfo.fileURL isEqualToString:fileInfo.fileURL]) {
                cell.fileInfo = fileInfo;
            }
        }
    }
}

@end

