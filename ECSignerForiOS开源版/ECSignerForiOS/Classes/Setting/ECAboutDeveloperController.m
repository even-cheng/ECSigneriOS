//
//  ECAboutDeveloperController.m
//  ECSignerForiOS
//
//  Created by Even on 2020/9/28.
//  Copyright © 2020 even_cheng. All rights reserved.
//

#import "ECAboutDeveloperController.h"

@interface ECAboutDeveloperController ()
@property (weak, nonatomic) IBOutlet UIButton *versionButton;

@end

@implementation ECAboutDeveloperController

-(instancetype)init{
    
    if (self = [super init]) {
        self =[[UIStoryboard storyboardWithName:@"ECAboutDeveloperController" bundle:nil]instantiateViewControllerWithIdentifier:@"ECAboutDeveloperController"];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"关于ECSigner";
    
    NSString* version = [NSString stringWithFormat:@"开源v %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [self.versionButton setTitle:version forState:UIControlStateNormal];
}

- (IBAction)contactDev{
    
    NSString *url = @"mqq://im/chat?chat_type=wpa&uin=492293215&version=1&src_type=web";
    NSURL *qqURL = [NSURL URLWithString:url];
    [[UIApplication sharedApplication] openURL:qqURL options:@{} completionHandler:nil];
}

- (IBAction)joinGroup{
    NSString *urlStr = [NSString stringWithFormat:@"mqqapi://card/show_pslcard?src_type=internal&version=1&uin=%@&key=%@&card_type=group&source=external&jump_from=webapi", @"837459998",@"1d5d753b3547dbe14fcf72195a649aeac403d0a72c0f5656069d7d1f6bafd432"];
    NSURL *url = [NSURL URLWithString:urlStr];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (IBAction)gotoGithub:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/even-cheng"] options:@{} completionHandler:nil];
}

@end
