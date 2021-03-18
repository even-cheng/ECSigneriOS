//
//  ECCertificateDetailController.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/8.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECCertificateDetailController.h"
#import "ECConst.h"
#import "ECProvDetailController.h"
#import "ECFileManager.h"
#import "ECCertificateDetailHeaderView.h"
#import "ECAlertView.h"
#import "UIWindow+Current.h"

@interface ECCertificateDetailController ()<UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) UITableView *contentTableView;
@property (strong, nonatomic) NSArray<ECMobileProvisionFile *>* provs;
@property (nonatomic, strong) ECCertificateDetailHeaderView *detailHeaderView;
@property (nonatomic, weak) UIButton *modifyButton;

@end

@implementation ECCertificateDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = self.cer.file_name;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];

    [self setup];
    
    if (self.cer && !self.cer.name && !self.choosed) {
        [self updateCerInfoWithUpdate:NO];
    } else {
        [self loadProvisionFiles];
    }
}

- (void)back {
    if (self.choosed) {
        self.fileChooseBlock(nil);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)modifyPasswordAction:(UIButton *)sender{
    sender.selected = !sender.selected;
    self.detailHeaderView.modify = sender.selected;
    if (!sender.selected) {
        [self.detailHeaderView update];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self updateCerInfoWithUpdate:YES];
        });
    }
}

- (void)setup{
    
    if (!self.choosed) {
        self.contentTableView.tableHeaderView = self.detailHeaderView;
        self.detailHeaderView.file = self.cer;
        UIButton* modifyPwdBtn = [UIButton new];
        _modifyButton = modifyPwdBtn;
        [modifyPwdBtn setTitle:@"修改密码" forState:UIControlStateNormal];
        [modifyPwdBtn setTitle:@"完成" forState:UIControlStateSelected];
        [modifyPwdBtn setTitleColor:MAIN_COLOR forState:UIControlStateNormal];
        modifyPwdBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [modifyPwdBtn addTarget:self action:@selector(modifyPasswordAction:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:modifyPwdBtn];

    } else {
        self.title = @"请选择描述文件";
    }
    [self.view addSubview:self.contentTableView];
}

- (void)loadProvisionFiles{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSMutableArray* provs = [NSMutableArray array];
        NSArray* prov_paths = [[ECFileManager sharedManager] allFiles:[ECFileManager sharedManager].mobileProvisionPath];
        for (NSString* filePath in prov_paths) {
            
            ECMobileProvisionFile* prov = [[ECFileManager sharedManager] getMobileProvisionFileForPath:filePath];
            if ([prov.team_identifier containsObject:self.cer.organization_unit]) {
                [provs addObject:prov];
            }
        }
        self.provs = provs.copy;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentTableView reloadData];
        });
    });
}

- (void)updateCerInfoWithUpdate:(BOOL)forceToUpdate{
    
    __weak typeof(self) weakSelf = self;
    ECCertificateFile* file = [[ECFileManager sharedManager] getCertificateFileForPath:[[ECFileManager sharedManager] localPathForFile:self.cer.file_name resigned:NO] forceToUpdate:forceToUpdate checkComplete:^(ECCertificateFile* cer){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.cer.revoked = cer.revoked;
            [weakSelf.contentTableView reloadData];
            if (forceToUpdate) {
                [ECAlertView alertMessageUnderNavigationBar:@"证书状态更新成功" subTitle:nil type:TSMessageNotificationTypeSuccess];
            }
        });
    }];
    
    if (file.name) {
        self.cer = file;
        self.detailHeaderView.file = file;
        self.updateCerBlock?self.updateCerBlock(file):nil;
        [self loadProvisionFiles];
    }
}

- (void)reloadCertificateInfo{
    [self updateCerInfoWithUpdate:YES];
}
    

#pragma mark- uitableViewDelagete
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ECFile* file = self.provs[indexPath.row];
    if (self.choosed) {
        
        self.fileChooseBlock?self.fileChooseBlock(@[file]):nil;
        [self.navigationController popViewControllerAnimated:YES];

    } else {
        
        ECProvDetailController* provDetail = [ECProvDetailController new];
        provDetail.prov = file;
        [self.navigationController pushViewController:provDetail animated:YES];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.provs.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ECCerDetailCellIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ECCerDetailCellIdentifier"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    ECMobileProvisionFile* file = self.provs[indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"file_prov"];
    cell.textLabel.text = file.file_name;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.detailTextLabel.text = file.app_id;
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

    if (self.choosed) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.choosed) {
        return nil;
    }
    
    UITableViewRowAction* outAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"分享" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        ECFile *file = self.provs[indexPath.row];
        NSString* filePath = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:NO];

        //文件链接
        NSURL*urlToShare = [NSURL fileURLWithPath:filePath];
        NSArray*activityItems =@[urlToShare];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:nil];
        
        //排除这些选项
        activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll];
        [self presentViewController:activityVC animated:YES completion:nil];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
            UIPopoverPresentationController* popover = activityVC.popoverPresentationController;
            popover.sourceView = [UIWindow currentViewController].view;
            popover.sourceRect = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 100);
        }
    }];
    
    UITableViewRowAction* deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        UIAlertController* alert = [ECAlertView alertWithTitle:@"确定删除吗？" message:nil cancelBlock:nil confirmBlock:^{
            
            ECFile *file = self.provs[indexPath.row];
            NSString* path = [[ECFileManager sharedManager] localPathForFile:file.file_name resigned:YES];
            BOOL res = [[ECFileManager sharedManager] removeFileWithPath:path];
            if (res) {
                [self loadProvisionFiles];
            }
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }];
    
    return @[deleteAction, outAction];
}

-(UITableView *)contentTableView{
    if (!_contentTableView) {
        _contentTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-NAV_HEIGHT) style:UITableViewStylePlain];
        _contentTableView.delegate = self;
        _contentTableView.dataSource = self;
        _contentTableView.backgroundColor = [UIColor whiteColor];
        _contentTableView.tableFooterView = [UIView new];
        _contentTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    return _contentTableView;
}

- (ECCertificateDetailHeaderView *)detailHeaderView{
    if (!_detailHeaderView) {
        _detailHeaderView = [[NSBundle mainBundle] loadNibNamed:@"ECCertificateDetailHeaderView" owner:self options:nil].lastObject;
        _detailHeaderView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 325);
        
        @weakify(self);
        _detailHeaderView.reloadBlock = ^{
            @strongify(self);
            [self reloadCertificateInfo];
        };
    }
    return _detailHeaderView;
}

@end
