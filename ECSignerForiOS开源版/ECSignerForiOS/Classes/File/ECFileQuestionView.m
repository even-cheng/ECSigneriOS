//
//  ECFileQuestionView.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECFileQuestionView.h"
#import "ECConst.h"
#import "NSString+Length.h"

@interface ECFileQuestionView ()<UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic)  UITableView *contentTableView;
@property (nonatomic, strong) NSArray *questions;

@end

@implementation ECFileQuestionView

-(instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup{

    self.backgroundColor = [UIColor whiteColor];

    self.questions = @[
                           @{@"question":@"如何导入文件？", @"answer":@"1，您可以在QQ或者微信等应用中直接分享到ECSigner。\n\n2，您可以在文件列表右上角点击加号，进入您的本机文件或者iCloud文件夹中进行选取。"},
                           @{@"question":@"支持哪些文件格式？", @"answer":@"支持后缀为 .ipa、.mobileProvision、.P12、.dylib、.a、.framework、.zip、.rar、.ecsigner等格式文件。"},
                           @{@"question":@"大文件导入之后一直解压不成功？", @"answer":@"您可以手动修改.ipa后缀为.zip,然后解压得到Payload文件夹,将Payload文件夹内的文件修改后缀为.ecsigner, 然后将修改之后的文件导入到ECSigner中即可."},
                           @{@"question":@"如果导入压缩文件怎么解压？", @"answer":@"导入压缩文件会自动解压到对应的格式列表，直接去文件-列表查看即可。"},
                           @{@"question":@"导入文件提示格式不支持怎么办？", @"answer":@"参考以上问题，暂不支持文件夹导入。"},
                           @{@"question":@"分享文件到QQ提示不支持怎么办？", @"answer":@"由于第三方应用有文件大小限制，这里建议选择存储到‘文件’（建议选择我的iPhone），保存之后您可以到第三方APP（如QQ）,在聊天页面选择文件-iPhone文件-选择要发送的文件（如果第三方不支持.ipa文件,您可以在文件APP中压缩之后再去发送.）"},
                           @{@"question":@"证书文件状态提示未知状态？", @"answer":@"根证书服务器可能不稳定，请刷新列表或者在证书详情手动刷新状态"},
                           @{@"question":@"为什么会要求网络权限？", @"answer":@"1，证书的撤销状态是需要使用到苹果的底层接口去实时获取的，这里会请求证书的根服务器。\n\n2，签名加锁时需要访问您的LeanCloud服务器去同步您签过得包信息。\n\n3，在服务器选项中，我们需要使用网络去获取您LeanCloud服务器中的数据并展示给您。"},
                           @{@"question":@"我是否可以关闭网络权限？", @"answer":@"当然可以。您可以前往系统设置中去完全关闭APP的网络权限，但是此时您仅可以使用本APP进行本地签名，无法使用加锁、远程控制、数据展示和证书状态检测等功能。"},
                           @{@"question":@"使用本APP签名是否有证书泄露风险？", @"answer":@"您可以完全放心。app中任何网络请求都不会携带您的证书和密码等信息，您的本机证书也是加密存储，其他人是无法获取的。"},
                           @{@"question":@"除了iOS以外，是否还有其他客户端？", @"answer":@"暂时只提供iOS和macOS客户端，mac端(基础版不支持加锁，支持超级签)请前往GitHub下载：https://github.com/even-cheng/ECSigner ，高级版请联系开发者。"},
                           @{@"question":@"怎么收费？", @"answer":@"开发者管理,基础签名和安装功能免费使用, 其它高级功能收费, iOS端 600/年, Mac端 600/年, 一起购买 900/年."},
                           @{@"question":@"时间锁管理服务器是否收费？", @"answer":@"服务器默认为Leancloud（第三方免费服务器），由用户自行注册账号和新建应用，然后在APP内填写对应的appid等字段即可，全程不需要提供您的服务器账号密码，确保您的数据安全。"},
                           @{@"question":@"无法安装？", @"answer":@"请前往leancloud后台-存储-文件-设置，打开https。或者在leancloud后台自行配置自己的域名和ssl证书来使用此功能。"},
                           @{@"question":@"开发者管理中创建的证书需要输入密码？？", @"answer":@"使用ECSigner创建的证书下载到文件中，默认密码为:ec_123"},
                           @{@"question":@"支持哪些下载格式？", @"answer":@"应用内下载中心支持ipa,zip,rar,mobileprovision,p12.framework.dylib等格式。另外还支持用于IPA分发的.plist文件，可以直接解析出IPA地址并自动完成下载和分类。"},
                           @{@"question":@"Leancloud无法获取加锁数据？", @"answer":@"免费版本的服务器为共享域名，不能保证不会改变，如果域名有变化请及时在APP-管理，更新您的服务器配置。有安全需求较高的可以自行配置域名。当然，您也可以放心，如果您签的包和服务器离线，也不会影响您的时间锁正常运行，只是您无法再后台控制，到了加锁截止时间，应用也会提示并退出。"},
                           @{@"question":@"还有疑问？", @"answer":@"前往设置-关于-联系开发者"}
                           ];
    [self addSubview:self.contentTableView];
}

- (void)closeAlertAction{
    self.alertCloseBlock?self.alertCloseBlock():nil;
}

#pragma mark --- uitableviewdelegate ---
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return self.questions.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 1;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ECFileQuestionViewCellIdentifier"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ECFileQuestionViewCellIdentifier"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSString* answer = [self.questions[indexPath.section] objectForKey:@"answer"];

    cell.textLabel.text = answer;
    cell.textLabel.textColor = UIColor.darkGrayColor;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.numberOfLines = 0;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString* answer = [self.questions[indexPath.section] objectForKey:@"answer"];
    CGFloat height = [NSString heightForString:answer font:15 width:SCREEN_WIDTH-24];
    return height+40;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    return [self.questions[section] objectForKey:@"question"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 35;
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
