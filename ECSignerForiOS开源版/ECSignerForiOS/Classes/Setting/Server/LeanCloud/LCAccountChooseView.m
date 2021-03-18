//
//  LCAccountChooseView.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "LCAccountChooseView.h"
#import "ECConst.h"
#import "ECAlertView.h"
#import "UIWindow+Current.h"

@interface LCAccountChooseView ()<UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic)  UITableView *contentTableView;
@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, copy) NSString* choose_appID;

@end


@implementation LCAccountChooseView

- (instancetype)initWithFrame:(CGRect)frame accounts:(NSArray<LCAccount *> *)accounts currentAccount:(NSString *)appID{
    if (self = [super initWithFrame:frame]) {
        self.choose_appID = appID;
        self.accounts = accounts;
        [self setup];
    }
    return self;
}


- (void)setup{
    
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.contentTableView];
}

- (void)addAccountAction{
    self.addAccount?self.addAccount():nil;
}

#pragma mark --- uitableviewdelegate ---
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
 
    LCAccount* account = self.accounts[indexPath.row];
    self.chooseAccount?self.chooseAccount(account):nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.accounts.count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"LCAccountChooseViewCellIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"LCAccountChooseViewCellIdentifier"];
    }
    
    LCAccount* account = self.accounts[indexPath.row];
    BOOL selected = [account.appID isEqualToString:self.choose_appID];
    
    cell.textLabel.text = account.name;
    cell.textLabel.textColor = selected ? MAIN_COLOR : HexColor(@"333333");
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17];

    cell.detailTextLabel.text = [NSString stringWithFormat:@"appID:%@",account.appID];
    cell.detailTextLabel.textColor = selected ? MAIN_COLOR : HexColor(@"666666");
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView* header = [[UIView alloc]initWithFrame:CGRectMake(0, 0, tableView.width, 40)];
    header.backgroundColor = UIColor.whiteColor;
    
    UILabel* titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(50, 0, tableView.width-100, 40)];
    titleLabel.text = @"请选择";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = HexColor(@"333333");
    titleLabel.font = [UIFont systemFontOfSize:16];
    [header addSubview:titleLabel];
    
    UIButton* startButton = [[UIButton alloc]initWithFrame:CGRectMake(tableView.width-45, 0, 40, 40)];
    [startButton setImage:[UIImage imageNamed:@"file_add"] forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(addAccountAction) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:startButton];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    return 40;
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{

    LCAccount* account = self.accounts[indexPath.row];

    if ([account.appID isEqualToString:self.choose_appID]) {
        return @[];
    }
    
    UITableViewRowAction* editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"编辑" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        self.editAccount?self.editAccount(account, NO):nil;
    }];
    
    UITableViewRowAction* deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        UIAlertController* alert = [ECAlertView alertWithTitle:@"确定删除吗？" message:nil cancelBlock:nil confirmBlock:^{
            
            self.editAccount?self.editAccount(account, YES):nil;
        }];
        
        [[UIWindow currentViewController] presentViewController:alert animated:YES completion:nil];
        
    }];
    
    return @[deleteAction,editAction];
}


-(UITableView *)contentTableView{
    if (!_contentTableView) {
        _contentTableView = [[UITableView alloc]initWithFrame:self.bounds style:UITableViewStylePlain];
        _contentTableView.delegate = self;
        _contentTableView.dataSource = self;
        _contentTableView.backgroundColor = [UIColor clearColor];
        _contentTableView.tableFooterView = [UIView new];
        _contentTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    return _contentTableView;
}

@end
