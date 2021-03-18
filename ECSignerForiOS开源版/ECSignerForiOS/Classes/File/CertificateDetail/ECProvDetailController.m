//
//  ECProvDetailController.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/8.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECProvDetailController.h"
#import "ECConst.h"
#import "NSDate+HandleDate.h"

@interface ECProvDetailController ()<UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic)  UITableView *contentTableView;

@end

@implementation ECProvDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"XC com cloudcc CloudCC sk";
    
    [self setup];
}

- (void)setup{
    [self.view addSubview:self.contentTableView];
}


#pragma mark- uitableViewDelagete
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    switch (section) {
        case 0:
            return 7;
        case 1:
            return self.prov.certificates.count;
        case 2:
            return self.prov.provisions_all_devices?1:self.prov.device_udids.count;
        default:
            return 0;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ECProvDetailCellIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ECProvDetailCellIdentifier"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.numberOfLines = 0;

    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"文件名称";
                    cell.detailTextLabel.text = self.prov.file_name;
                    break;
                case 1:
                    cell.textLabel.text = @"App ID Name";
                    cell.detailTextLabel.text = self.prov.app_id_name;
                    break;
                case 2:
                    cell.textLabel.text = @"App ID";
                    cell.detailTextLabel.text = self.prov.app_id;
                    break;
                case 3:
                    cell.textLabel.text = @"Team";
                    cell.detailTextLabel.text = self.prov.team;
                    break;
                case 4:
                    cell.textLabel.text = @"UUID";
                    cell.detailTextLabel.text = self.prov.uuid;
                    break;
                case 5:
                    cell.textLabel.text = @"Creation Date";
                    cell.detailTextLabel.text = [NSDate getTimeStrWithLong:self.prov.create_date];
                    break;
                case 6:
                    cell.textLabel.text = @"Expiration Date";
                    cell.detailTextLabel.text = [NSDate getTimeStrWithLong:self.prov.expiration_date];
                    break;
                    
                default:
                    break;
            }
        }
            break;
        case 1:
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = self.prov.certificates[indexPath.row];
            cell.detailTextLabel.numberOfLines = 1;
            break;
        case 2:
            cell.textLabel.text = nil;
            if (self.prov.provisions_all_devices) {
                cell.detailTextLabel.text = @"不限设备";
            } else {
                cell.detailTextLabel.text = self.prov.device_udids[indexPath.row];
            }
            break;
        default:
            break;
    }
    
    
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return @"基本信息";
        case 1:
            return @"证书文件";
        case 2:
            return @"注册设备";
        default:
            return @"";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 35;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (indexPath.section) {
        case 0:
            return 50;
        case 1:
            return 50;
        default:
            return 35;
    }
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

@end
