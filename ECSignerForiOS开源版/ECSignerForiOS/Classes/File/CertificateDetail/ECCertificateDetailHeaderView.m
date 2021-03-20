//
//  ECCertificateDetailHeaderView.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/8.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECCertificateDetailHeaderView.h"
#import "NSDate+HandleDate.h"
#import "ECConst.h"
#import "ECFileManager.h"

@interface ECCertificateDetailHeaderView()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerBgView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *expireTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *userIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *organizationUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *areaLabel;
@property (weak, nonatomic) IBOutlet UITextField *pwdField;
@property (weak, nonatomic) IBOutlet UIButton *reloadStateButton;

@end


@implementation ECCertificateDetailHeaderView

-(void)awakeFromNib{
    [super awakeFromNib];
    
    self.headerBgView.layer.shadowColor = [UIColor grayColor].CGColor;
    self.headerBgView.layer.shadowOffset = CGSizeZero;
    self.headerBgView.layer.shadowRadius = 1;
    self.headerBgView.layer.shadowOpacity = 0.5;
    
    self.pwdField.enabled = NO;
    self.pwdField.delegate = self;
    [self.pwdField setAttributedPlaceholder:[[NSMutableAttributedString alloc] initWithString:@"未设置密码" attributes:
                                     @{NSForegroundColorAttributeName:UIColor.redColor,
                                       NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                     ]];
}

- (IBAction)pwdSecretAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.pwdField.secureTextEntry = !sender.selected;
}

- (void)update;{

    NSString* pass = self.pwdField.text;
    if (pass.length == 0) {
        pass = @"";
    }

    [[NSUserDefaults standardUserDefaults] setObject:pass forKey:[NSString stringWithFormat:@"password-%@", self.file.file_name]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.file.password = pass;
}

- (void)setModify:(BOOL)modify{
    _modify = modify;
    
    self.pwdField.enabled = modify;
    if (!modify) {
        [self.pwdField resignFirstResponder];
    } else {
        [self.pwdField becomeFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

- (void)setFile:(ECCertificateFile *)file{
    _file = file;
    
    self.reloadStateButton.enabled = YES;
    self.nameLabel.text = file.name;
    self.expireTimeLabel.text = [NSDate getTimeStrWithLong:file.expire_time];
    self.statusLabel.text = file.revoked?@"已撤销":@"正常";
    self.statusLabel.textColor = file.revoked?UIColor.redColor:MAIN_COLOR;
    self.userIDLabel.text = file.user_ID;
    self.organizationNameLabel.text = file.organization;
    self.organizationUnitLabel.text = file.organization_unit;
    self.areaLabel.text = file.country;
    self.pwdField.text = file.password.length > 0 ? file.password : @"无密码";
}

- (IBAction)reloadStateAction:(UIButton *)sender {
    sender.enabled = NO;
    self.reloadBlock?self.reloadBlock():nil;
}

@end
