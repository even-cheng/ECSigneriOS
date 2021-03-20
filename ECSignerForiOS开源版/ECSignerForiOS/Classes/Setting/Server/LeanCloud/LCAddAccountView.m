//
//  LCAddAccountView.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/16.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "LCAddAccountView.h"

@interface LCAddAccountView ()

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *appIDField;
@property (weak, nonatomic) IBOutlet UITextField *appKeyField;
@property (weak, nonatomic) IBOutlet UITextField *urlField;

@end

@implementation LCAddAccountView

+ (instancetype)addView;{
    
    LCAddAccountView* addView = [[NSBundle mainBundle] loadNibNamed:@"LCAddAccountView" owner:self options:0].lastObject;
    return addView;
}

- (void)setAccount:(LCAccount *)account{
    if (!account) {
        return;
    }
    _account = account;
    self.nameField.text = account.name;
    self.appIDField.text = account.appID;
    self.appKeyField.text = account.appKey;
    self.urlField.text = account.serverUrl;
    self.appIDField.enabled = NO;
    self.appKeyField.enabled = NO;
    self.appKeyField.textColor = UIColor.grayColor;
    self.appIDField.textColor = UIColor.grayColor;
}


- (IBAction)confirmAction:(id)sender {
    
    NSString* name = self.nameField.text;
    NSString* appid = self.appIDField.text;
    NSString* appkey = self.appKeyField.text;
    NSString* url = self.urlField.text;
    
    if (name.length == 0 || appid.length == 0 || appkey.length == 0 || url.length == 0) {
        return;
    }
    
    self.confirmBlock?self.confirmBlock(name, appid, appkey, url):nil;
}


@end
