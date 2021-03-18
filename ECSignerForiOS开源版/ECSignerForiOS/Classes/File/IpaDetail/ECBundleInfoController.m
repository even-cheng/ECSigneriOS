//
//  ECBundleInfoController.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/25.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECBundleInfoController.h"
#import "ECConst.h"
#import "NSDate+HandleDate.h"
#import "ECFileManager.h"
#import "MyObject.h"
#import "ECAlertView.h"
#import "ECProvDetailController.h"
#import <Masonry/Masonry.h>
#import "ECAlertView.h"
#import "ECSignProgressView.h"
#import "ECAlertController.h"

@interface ECBundleInfoController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) ECSignProgressView *signProgressView;

@property (strong, nonatomic) UITableView *contentTableView;
@property (nonatomic, strong) NSArray *info;
@property (nonatomic, strong) NSArray<NSDictionary*> *dylibs;
@property (nonatomic, strong) NSArray<ECMobileProvisionFile *> *provs;

//选择签名包
@property (strong, nonatomic)  UIView *bottomView;
@property (nonatomic, weak) UIButton *selectLotButton;//批量按钮
@property (nonatomic, weak) UIButton *selectAllButton;
@property (nonatomic, weak) UIButton *selectLotDoneButton;
@property (strong, nonatomic)  NSMutableArray<NSDictionary *> *chooseLibs;

@end

@implementation ECBundleInfoController

- (void)back {
    if (self.choosed) {
        self.choosedLibBlock(nil);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString* name = [self.app.file_name stringByReplacingOccurrencesOfString:@".app" withString:@""];
    self.title = name;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    if (self.choosed) {
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [ECAlertView alertMessageUnderNavigationBar:@"请谨慎使用动态移除" subTitle:@"部分包移除动态库之后可能导致闪退,请确认风险再进行操作" type:TSMessageNotificationTypeWarning];
        });
        self.title = @"请选择待移除库";
        UIButton* selectLotButton = [UIButton new];
        _selectLotButton = selectLotButton;
        selectLotButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [selectLotButton setTitle:@"批量选择" forState:UIControlStateNormal];
        [selectLotButton setTitleColor:MAIN_COLOR forState:UIControlStateNormal];
        [selectLotButton setTitle:@"取消批量" forState:UIControlStateSelected];
        [selectLotButton setTitleColor:UIColor.darkGrayColor forState:UIControlStateSelected];
        [selectLotButton addTarget:self action:@selector(selectLotIpaAction:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:selectLotButton];
    
    } else {
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(editIpaInfoAction)];
    }
    
    self.info = @[
    @{@"文件大小：":[NSString stringWithFormat:@"%.2fM",self.app.file_size/1024.0/1024.0]},
    @{@"添加时间：":[NSDate getTimeStrWithLong:self.app.add_time]},
    ];
  
    [self setup];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self getInfo];
    });
}

- (void)setup{
    [self.view addSubview:self.contentTableView];
}

- (void)getInfo{
    
    NSMutableArray* arr = [NSMutableArray arrayWithArray:self.info];
    NSDictionary* dic = [[ECFileManager sharedManager] getInfoAndProfilesInBundle:self.app];
    
    NSDictionary* info = [dic objectForKey:@"info"];
    NSString* profilePath = [dic objectForKey:@"profile"];
    
    if (info.allKeys.count == 0) {
        return;
    }
    
    NSString* executableName = [info objectForKey:@"CFBundleExecutable"];
    [self checkExecutableFiles:executableName];

    [arr addObject:@{@"包名":[info objectForKey:@"CFBundleDisplayName"]?:[info objectForKey:@"CFBundleName"]}];
    [arr addObject:@{@"包ID":[info objectForKey:@"CFBundleIdentifier"]?:@""}];
    [arr addObject:@{@"版本号":[info objectForKey:@"CFBundleShortVersionString"]?:@""}];
    [arr addObject:@{@"构建号":[info objectForKey:@"CFBundleVersion"]?:@""}];
    [arr addObject:@{@"执行文件":[info objectForKey:@"CFBundleExecutable"]?:@""}];
    [arr addObject:@{@"最低支持iOS版本":[info objectForKey:@"MinimumOSVersion"]?:@""}];

    self.info = arr.copy;
    
    ECMobileProvisionFile* profile = [[ECFileManager sharedManager] getMobileProvisionFileForPath:profilePath];
    if (profile) {
        self.provs = @[profile];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.contentTableView reloadData];
    });
}

- (void)editIpaInfoAction{
    
}

- (void)checkExecutableFiles:(NSString *)exeName{
    
    NSString* appPath = [[ECFileManager sharedManager] localPathForFile:self.app.file_name resigned:self.app.resigned];
    NSString* appExecutablePath = [appPath stringByAppendingPathComponent:exeName];
    NSArray* dylibs = [[MyObject new] checkLibsFromExecutable:appExecutablePath];
    
    NSString * executablePath = appExecutablePath.lastPathComponent;

    NSMutableArray* arr = [NSMutableArray array];
    for (NSString* lib in dylibs) {
        NSDictionary* dic = @{@"inject_name":lib, @"executable_name":executablePath};
        [arr addObject:dic];
    }
    
    self.dylibs = arr.copy;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.contentTableView reloadData];
    });
}

- (void)deepCheckAction{
    
    UIAlertController* alert = [ECAlertView alertWithTitle:@"开启深度扫描？" message:@"可能需要一点时间" cancelBlock:^{
        
    } confirmBlock:^{
        
        [self startDeepCheckLibs];
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

//高级版功能
- (void)startDeepCheckLibs{
    
    
}

//批量选择
- (void)selectLotIpaAction:(UIButton *)sender{

    sender.selected = !sender.selected;
    if (sender.selected) {
        
        [self.contentTableView setEditing:YES animated:YES];
        [self.view addSubview:self.bottomView];
        self.contentTableView.frame = CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-SafeAreaBottomHeight-60-NAV_HEIGHT);

    } else {
        
        [self.contentTableView setEditing:NO animated:YES];
        [self.chooseLibs removeAllObjects];
        [self.bottomView removeFromSuperview];
        self.contentTableView.frame = CGRectMake(0, NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT-SafeAreaBottomHeight-NAV_HEIGHT);
        [self.contentTableView reloadData];
    }
}


- (void)selectAllAction:(UIButton*)sender{
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.chooseLibs removeAllObjects];
        for (int i = 0; i < self.dylibs.count; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            [self.contentTableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self.chooseLibs addObject:self.dylibs[i]];
        }
    } else {
        for (int i = 0; i < self.chooseLibs.count; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            [self.contentTableView deselectRowAtIndexPath:path animated:YES];
        }
        [self.chooseLibs removeAllObjects];
    }
    [self.selectLotDoneButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.chooseLibs.count] forState:UIControlStateNormal];
}


- (void)selectLotDoneAction{
    if (!self.selectLotButton.selected) {
        return;
    }
    
    self.choosedLibBlock?self.choosedLibBlock(self.chooseLibs.copy):nil;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark- uitableViewDelagete
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.contentTableView.isEditing) {
        id order = self.dylibs[indexPath.row];
        if ([self.chooseLibs containsObject:order]) {
            [self.chooseLibs removeObject:order];
        }
    }
    [self.selectLotDoneButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.chooseLibs.count] forState:UIControlStateNormal];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!self.choosed) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        if (indexPath.section == 0) {
            switch (indexPath.row) {
                case 2:
                case 3:
                {
                    NSDictionary* dic = self.info[indexPath.row];
                    UIPasteboard.generalPasteboard.string = [dic allValues].lastObject;
                }
                    break;
                    
                default:
                    break;
            }
            
        } if (indexPath.section == 1) {
            
            ECMobileProvisionFile* prov = self.provs[indexPath.row];

            ECProvDetailController* provDetail = [ECProvDetailController new];
            provDetail.prov = prov;
            [self.navigationController pushViewController:provDetail animated:YES];
            
        } else if (indexPath.section == 2) {
            
            UIAlertController* alert = [ECAlertView alertWithTitle:@"保存到本地文件？" message:nil cancelBlock:nil confirmBlock:^{
                
                NSDictionary* lib = self.dylibs[indexPath.row];
                NSString* inject_name = [lib objectForKey:@"inject_name"];
                
                NSString* appPath = [[ECFileManager sharedManager] localPathForFile:self.app.file_name resigned:self.app.resigned];
                NSString* libPath = [[inject_name stringByReplacingOccurrencesOfString:@"@rpath/" withString:@"Frameworks/"] stringByReplacingOccurrencesOfString:@"@executable_path/" withString:@""];
                if ([libPath.lastPathComponent componentsSeparatedByString:@"."].count > 1) {//.a .dylib .xxx
                    libPath = [appPath stringByAppendingPathComponent:libPath];
                }else {//.framework
                    NSString *libSuperDirectory = [libPath stringByDeletingLastPathComponent];
                    libPath = [appPath stringByAppendingPathComponent:libSuperDirectory];
                }

                if (![[NSFileManager defaultManager] fileExistsAtPath:libPath]) {
                    [ECAlertView alertMessageUnderNavigationBar:@"无法访问原文件" subTitle:nil type:TSMessageNotificationTypeError];
                    return;
                }
                
                NSString* savedPath = [ECFileManager.sharedManager.dylibPath stringByAppendingPathComponent:inject_name.lastPathComponent];
                if ([[NSFileManager defaultManager] fileExistsAtPath:savedPath]) {
                    [ECAlertView alertMessageUnderNavigationBar:@"本地文件已存在" subTitle:nil type:TSMessageNotificationTypeError];
                    return;
                }
                
                BOOL res = [[NSFileManager defaultManager] copyItemAtPath:libPath toPath:savedPath error:nil];
                if (res) {
                    [ECAlertView alertMessageUnderNavigationBar:@"保存成功，请前往文件-动态库查看" subTitle:nil type:TSMessageNotificationTypeSuccess];
                    [[NSNotificationCenter defaultCenter] postNotificationName:ECFileChangedSuccessNotification object:nil userInfo:@{@"file_type":@(ECFlieTypeDylib)}];
                } else {
                    [ECAlertView alertMessageUnderNavigationBar:@"保存失败" subTitle:nil type:TSMessageNotificationTypeError];
                }
            }];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        return;
    }
    
    id lib = self.dylibs[indexPath.row];
    if (self.contentTableView.isEditing) {
        
        if (![self.chooseLibs containsObject:lib]) {
            [self.chooseLibs addObject:lib];
        }
        [self.selectLotDoneButton setTitle:[NSString stringWithFormat:@"完成(%ld)",self.chooseLibs.count] forState:UIControlStateNormal];
        
    } else if (self.choosed) {
            
        self.choosedLibBlock?self.choosedLibBlock(@[lib]):nil;
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{

    return self.choosed?1:3;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (self.choosed) {
        return self.dylibs.count;
    } else {
        
        switch (section) {
            case 0:
                return self.info.count;
            case 1:
                return self.provs.count;
            case 2:
                return self.dylibs.count;
                
            default:
                return 0;
        }
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ECBundleInfoCellIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ECBundleInfoCellIdentifier"];
    }
    
    NSString* name = @"";
    NSString* value = @"";
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (self.choosed) {
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
        cell.textLabel.numberOfLines = 0;
        NSDictionary* lib = self.dylibs[indexPath.row];
        name = [lib objectForKey:@"inject_name"];
    
    } else {
        
        switch (indexPath.section) {
            case 0:
            {
                NSDictionary* dic = self.info[indexPath.row];
                name = dic.allKeys.firstObject;
                value = dic.allValues.firstObject;
                cell.textLabel.numberOfLines = 1;
                cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
            }
                break;
            case 1:
            {
                cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
                cell.textLabel.numberOfLines = 0;
                NSString* content = self.provs[indexPath.row].file_name;
                name = content;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
                break;
            case 2:
            {
                cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
                cell.textLabel.numberOfLines = 0;
                NSDictionary* lib = self.dylibs[indexPath.row];
                name = [lib objectForKey:@"inject_name"];
            }
                break;
                
            default:
                break;
        }
    }
    
    cell.textLabel.text = name;
    cell.textLabel.textColor = [UIColor darkGrayColor];
     
    cell.detailTextLabel.text = value;
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
    
    if (self.choosed) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        //设置选中状态
        cell.tintColor = MAIN_COLOR;
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.multipleSelectionBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.multipleSelectionBackgroundView.backgroundColor = [UIColor clearColor];
    }
    
    return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView* header = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40)];
    header.backgroundColor = BG_COLOR;
    
    UILabel* titleLab = [[UILabel alloc]init];
    titleLab.textColor = UIColor.darkGrayColor;
    switch (section) {
        case 0:
            titleLab.text = self.choosed?@"已加载库":@"基本信息";
            break;
        case 1:
            titleLab.text = @"签名文件";
            break;
        case 2:
            titleLab.text = @"已加载库";
            break;
        default:
            break;
    }
    titleLab.font = [UIFont boldSystemFontOfSize:16];
    [header addSubview:titleLab];
    [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(header).offset(12);
        make.centerY.equalTo(header);
    }];
    
    UIButton* ationButton = [UIButton new];
    ationButton.hidden = (self.choosed && section!=0) || (!self.choosed && section != 2);
    [ationButton setTitleColor:MAIN_COLOR forState:UIControlStateNormal];
    [ationButton setTitle:@"未找到?" forState:UIControlStateNormal];
    ationButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [ationButton addTarget:self action:@selector(deepCheckAction) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:ationButton];
    [ationButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(header).offset(-12);
        make.centerY.equalTo(header);
    }];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
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
        _signProgressView.title = @"正在扫描...";
    }
    return _signProgressView;
}


@end
